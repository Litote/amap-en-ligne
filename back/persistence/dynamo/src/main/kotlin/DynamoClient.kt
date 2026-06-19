package persistence.dynamo

import aws.sdk.kotlin.hll.dynamodbmapper.DynamoDbMapper
import aws.sdk.kotlin.runtime.auth.credentials.EnvironmentCredentialsProvider
import aws.sdk.kotlin.runtime.auth.credentials.StaticCredentialsProvider
import aws.sdk.kotlin.services.dynamodb.DynamoDbClient
import aws.smithy.kotlin.runtime.auth.awscredentials.Credentials
import aws.smithy.kotlin.runtime.http.engine.crt.CrtHttpEngine
import aws.smithy.kotlin.runtime.net.url.Url
import persistence.dynamo.dynamodbmapper.generatedschemas.getProductTypeDynamoTable
import properties.Properties
import kotlin.time.Duration.Companion.seconds

internal class DynamoClient(
    private val properties: Properties,
) {
    val client: DynamoDbClient = createDynamoDbClient(properties)
    private val mapper: DynamoDbMapper = DynamoDbMapper(client)

    val table: String = properties.property("DYNAMO_TABLE", "data")
    val changesByCursorIndex: String = properties.property("DYNAMO_CHANGES_GSI", "by_cursor")
    val productTypeTable = mapper.getProductTypeDynamoTable(table)

    private companion object {
        // Local mode talks to a container on the CI runner/dev machine, so an unreachable or
        // never-accepting DynamoDB-Local must fail fast rather than rely on Gradle's per-test-task
        // timeout (10 min, see kotlin-convention.gradle.kts) or CI's job-level timeout-minutes as
        // the only backstop. connectTimeout/connectionAcquireTimeout are honored by CrtHttpEngine
        // (bounds TCP connect + pool-acquire); NOTE its read/write timeouts are not (see
        // CrtHttpEngine's own commented-out warning in aws.smithy.kotlin — a connection that
        // accepts the socket but then never answers is still only bounded by the Gradle/CI backstops.
        val LOCAL_CONNECT_TIMEOUT = 5.seconds
        val LOCAL_CONNECTION_ACQUIRE_TIMEOUT = 10.seconds

        fun createDynamoDbClient(properties: Properties) =
            when (properties.propertyOrNull("APP_MODE")) {
                "local" -> {
                    DynamoDbClient {
                        endpointUrl =
                            Url.parse(properties.property("DYNAMO_LOCAL_ENDPOINT", "http://127.0.0.1:8000"))
                        region = properties.property("AWS_REGION", "eu-west-3")
                        httpClient =
                            CrtHttpEngine {
                                connectTimeout = LOCAL_CONNECT_TIMEOUT
                                connectionAcquireTimeout = LOCAL_CONNECTION_ACQUIRE_TIMEOUT
                            }
                        credentialsProvider =
                            StaticCredentialsProvider(
                                Credentials(
                                    accessKeyId = "dummy",
                                    secretAccessKey = "dummy",
                                ),
                            )
                    }
                }

                else -> {
                    val region = properties.property("AWS_REGION", "eu-west-3")
                    DynamoDbClient {
                        this.region = region
                        endpointUrl = Url.parse("https://dynamodb.$region.amazonaws.com")
                        httpClient = CrtHttpEngine()
                        credentialsProvider = EnvironmentCredentialsProvider()
                    }
                }
            }
    }
}
