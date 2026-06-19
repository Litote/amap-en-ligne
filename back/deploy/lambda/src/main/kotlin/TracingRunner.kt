package deploy.lambda

import id.toId
import io.github.oshai.kotlinlogging.KotlinLogging
import lambda.APIGatewayV2HTTPResponse
import persistence.changes.BootstrapScopeResult
import persistence.changes.EntityPayload
import persistence.changes.MutationError
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.MutationStatus
import persistence.changes.ProductTypePayload
import persistence.changes.SyncResponse
import persistence.changes.SyncScope
import persistence.model.ProductType
import serialization.json
import serialization.writeJson

/**
 * Local entry point used to drive the handler with the GraalVM
 * `native-image-agent` attached, so the agent can record the reflection,
 * resource, serialization and proxy usage required by `native-image`.
 *
 * Runs outside the AWS Lambda runtime (no `AWS_LAMBDA_RUNTIME_API`): it simply
 * constructs `DataLambda` and feeds it a few representative `POST /v1/sync`
 * events covering the read paths (bootstrap snapshot + incremental change
 * page) and the write path (UPSERT with `tmp_*` id, DELETE, REJECTED).
 * Failures during the invocation (e.g. no local DynamoDB running) are caught
 * so the trace keeps collecting metadata for the other code paths.
 */

private val sampleEvents =
    listOf(
        // bootstrap: empty cursors, no mutations → snapshot path with typed ProductType payloads
        """{"requestContext":{"http":{"path":"/v1/sync","method":"POST"}},"headers":{"authorization":"Bearer trace"},"body":"{\"cursors\":{}}"}""",
        // incremental: non-null cursor → ChangePage path
        """{"requestContext":{"http":{"path":"/v1/sync","method":"POST"}},"headers":{"authorization":"Bearer trace"},"body":"{\"cursors\":{\"ProductType\":\"01HK0\"}}"}""",
        // write path: UPSERT with tmp id (server allocates real id) + DELETE in the same batch
        """{"requestContext":{"http":{"path":"/v1/sync","method":"POST"}},"headers":{"authorization":"Bearer trace"},"body":"{\"cursors\":{},\"mutations\":[{\"client_op_id\":\"op-1\",\"op\":{\"type\":\"Upsert\",\"payload\":{\"type\":\"ProductType\",\"productType\":{\"product_type_id\":\"tmp_a\",\"producer_account_id\":\"acc\",\"supported_basket_sizes\":[{\"name\":\"3kg\"}],\"name\":\"Légumes\",\"description\":\"panier\"}}}},{\"client_op_id\":\"op-2\",\"op\":{\"type\":\"Delete\",\"entity_type\":\"ProductType\",\"entity_id\":\"pt-1\"}}]}"}""",
        // write path rejection: cross-tenant UPSERT → REJECTED outcome
        """{"requestContext":{"http":{"path":"/v1/sync","method":"POST"}},"headers":{"authorization":"Bearer trace"},"body":"{\"cursors\":{},\"mutations\":[{\"client_op_id\":\"op-3\",\"op\":{\"type\":\"Upsert\",\"payload\":{\"type\":\"ProductType\",\"productType\":{\"product_type_id\":\"pt-2\",\"producer_account_id\":\"other\",\"supported_basket_sizes\":[],\"name\":\"x\"}}}}]}"}""",
    )

fun main() {
    // TracingRunner is local-only by construction; force the local DynamoDB
    // endpoint so it works when launched directly (e.g. IntelliJ green-arrow),
    // not just via the Gradle `:tracing` task that sets this env var.
    System.setProperty("APP_MODE", "local")

    val response =
        APIGatewayV2HTTPResponse(
            statusCode = 200,
            headers = mapOf("content-type" to "application/json"),
            body =
                writeJson(
                    SyncResponse(
                        authorizedScopes = listOf(SyncScope.ProducerAccount("acc").key),
                        results =
                            mapOf(
                                SyncScope.ProducerAccount("acc").key to
                                    BootstrapScopeResult(
                                        items =
                                            listOf<EntityPayload>(
                                                ProductTypePayload(
                                                    ProductType("v".toId(), "b".toId(), emptyList(), "a", null),
                                                ),
                                            ),
                                        nextCursor = "01HK0",
                                    ),
                            ),
                        mutations =
                            listOf(
                                MutationOutcome(
                                    clientOpId = "op-1",
                                    status = MutationStatus.APPLIED,
                                    serverEntityId = "9c1f",
                                ),
                                MutationOutcome(
                                    clientOpId = "op-3",
                                    status = MutationStatus.REJECTED,
                                    error =
                                        MutationError(
                                            code = MutationErrorCode.FORBIDDEN,
                                            message = "producer_account_id mismatch",
                                        ),
                                ),
                            ),
                    ),
                ),
        )

    val serialized =
        json.encodeToString(
            APIGatewayV2HTTPResponse.serializer(),
            response,
        )

    val logger = KotlinLogging.logger {}
    logger.warn { serialized }

    val lambda = DataLambda()
    sampleEvents.forEachIndexed { index, event ->
        try {
            val result = lambda.handleRequest(event) { it }
            logger.warn { "[$index] -> $result" }
        } catch (t: Throwable) {
            logger.error { "[$index] failed: ${t.message}" }
        }
    }
}
