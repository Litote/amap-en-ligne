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

internal class DynamoClient(
    private val properties: Properties,
) {
    val client: DynamoDbClient = createDynamoDbClient(properties)
    private val mapper: DynamoDbMapper = DynamoDbMapper(client)

    val table: String = properties.property("DYNAMO_TABLE", "data")
    val changesByCursorIndex: String = properties.property("DYNAMO_CHANGES_GSI", "by_cursor")
    val productTypeTable = mapper.getProductTypeDynamoTable(table)

    private companion object {
        fun createDynamoDbClient(properties: Properties) =
            when (properties.propertyOrNull("APP_MODE")) {
                "local" -> {
                    DynamoDbClient {
                        endpointUrl =
                            Url.parse(properties.property("DYNAMO_LOCAL_ENDPOINT", "http://127.0.0.1:8000"))
                        region = properties.property("AWS_REGION", "eu-west-3")
                        httpClient = CrtHttpEngine()
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
