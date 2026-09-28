package persistence.dynamo

import aws.sdk.kotlin.services.dynamodb.model.AttributeDefinition
import aws.sdk.kotlin.services.dynamodb.model.BillingMode
import aws.sdk.kotlin.services.dynamodb.model.CreateTableRequest
import aws.sdk.kotlin.services.dynamodb.model.DeleteTableRequest
import aws.sdk.kotlin.services.dynamodb.model.GlobalSecondaryIndex
import aws.sdk.kotlin.services.dynamodb.model.KeySchemaElement
import aws.sdk.kotlin.services.dynamodb.model.KeyType
import aws.sdk.kotlin.services.dynamodb.model.Projection
import aws.sdk.kotlin.services.dynamodb.model.ProjectionType
import aws.sdk.kotlin.services.dynamodb.model.ScalarAttributeType
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.future.asCompletableFuture
import properties.Properties
import java.util.UUID
import java.util.concurrent.TimeUnit

internal object DynamoTestInfra {
    fun ensureStarted() {
        synchronized(DynamoTestInfra) {
            if (!isDynamoRunning()) {
                startDynamo()
                waitForDynamo()
            }
        }
    }

    fun newClient(): DynamoClient {
        val tableName = "data-test-${UUID.randomUUID()}"
        val properties =
            object : Properties {
                override fun propertyOrNull(name: String): String? =
                    when (name) {
                        "APP_MODE" -> "local"
                        "DYNAMO_LOCAL_ENDPOINT" -> "http://127.0.0.1:8001"
                        "DYNAMO_TABLE" -> tableName
                        else -> null
                    }
            }
        return DynamoClient(properties)
    }

    fun createTable(client: DynamoClient) {
        repeat(10) { attempt ->
            try {
                CoroutineScope(Dispatchers.IO)
                    .async { doCreateTable(client) }
                    .asCompletableFuture()
                    // Bounded wait: the AWS CRT engine has no request timeout, so a stuck call to
                    // DynamoDB-Local would otherwise block forever and hang the whole `test` task
                    // (observed as a 6h CI hang). A deadline turns it into a retryable failure.
                    .get(OPERATION_TIMEOUT_SECONDS, TimeUnit.SECONDS)
                return
            } catch (e: Exception) {
                if (attempt == 9) throw e
                Thread.sleep(500)
            }
        }
    }

    fun deleteTable(client: DynamoClient) {
        CoroutineScope(Dispatchers.IO)
            .async {
                client.client.deleteTable(DeleteTableRequest { tableName = client.table })
                client.client.close()
            }.asCompletableFuture()
            .get(OPERATION_TIMEOUT_SECONDS, TimeUnit.SECONDS)
    }

    private const val OPERATION_TIMEOUT_SECONDS = 15L

    private suspend fun doCreateTable(client: DynamoClient) {
        client.client.createTable(
            CreateTableRequest {
                tableName = client.table
                attributeDefinitions =
                    listOf(
                        AttributeDefinition {
                            attributeName = "pk"
                            attributeType = ScalarAttributeType.S
                        },
                        AttributeDefinition {
                            attributeName = "sk"
                            attributeType = ScalarAttributeType.S
                        },
                        AttributeDefinition {
                            attributeName = "change_pk"
                            attributeType = ScalarAttributeType.S
                        },
                        AttributeDefinition {
                            attributeName = "cursor"
                            attributeType = ScalarAttributeType.S
                        },
                        AttributeDefinition {
                            attributeName = "organization_name"
                            attributeType = ScalarAttributeType.S
                        },
                        AttributeDefinition {
                            attributeName = "admin_email"
                            attributeType = ScalarAttributeType.S
                        },
                    )
                keySchema =
                    listOf(
                        KeySchemaElement {
                            attributeName = "pk"
                            keyType = KeyType.Hash
                        },
                        KeySchemaElement {
                            attributeName = "sk"
                            keyType = KeyType.Range
                        },
                    )
                globalSecondaryIndexes =
                    listOf(
                        GlobalSecondaryIndex {
                            indexName = "by_cursor"
                            keySchema =
                                listOf(
                                    KeySchemaElement {
                                        attributeName = "change_pk"
                                        keyType = KeyType.Hash
                                    },
                                    KeySchemaElement {
                                        attributeName = "cursor"
                                        keyType = KeyType.Range
                                    },
                                )
                            projection = Projection { projectionType = ProjectionType.All }
                        },
                        GlobalSecondaryIndex {
                            indexName = "by_organization_name"
                            keySchema =
                                listOf(
                                    KeySchemaElement {
                                        attributeName = "organization_name"
                                        keyType = KeyType.Hash
                                    },
                                )
                            projection = Projection { projectionType = ProjectionType.KeysOnly }
                        },
                        GlobalSecondaryIndex {
                            indexName = "by_admin_email"
                            keySchema =
                                listOf(
                                    KeySchemaElement {
                                        attributeName = "admin_email"
                                        keyType = KeyType.Hash
                                    },
                                )
                            projection = Projection { projectionType = ProjectionType.KeysOnly }
                        },
                    )
                billingMode = BillingMode.PayPerRequest
            },
        )
    }

    private fun isDynamoRunning(): Boolean {
        val process =
            ProcessBuilder("docker", "inspect", "--format={{.State.Running}}", "dynamodb-local")
                .redirectErrorStream(true)
                .start()
        process.waitFor()
        return process.inputStream
            .bufferedReader()
            .readText()
            .trim() == "true"
    }

    private fun startDynamo() {
        ProcessBuilder("docker", "compose", "-f", "src/test/docker/docker-compose.yml", "up", "-d")
            .inheritIO()
            .start()
            .waitFor()
    }

    private fun waitForDynamo() {
        repeat(30) {
            try {
                val connection =
                    java.net
                        .URI("http://localhost:8001")
                        .toURL()
                        .openConnection() as java.net.HttpURLConnection
                connection.connectTimeout = 1000
                connection.readTimeout = 1000
                connection.requestMethod = "GET"
                connection.connect()
                connection.disconnect()
                return
            } catch (_: Exception) {
                Thread.sleep(1000)
            }
        }
        error("DynamoDB local did not start within 30 seconds")
    }
}
