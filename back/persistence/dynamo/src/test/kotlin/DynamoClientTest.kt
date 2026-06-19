package persistence.dynamo

import aws.sdk.kotlin.runtime.auth.credentials.EnvironmentCredentialsProvider
import aws.smithy.kotlin.runtime.http.engine.crt.CrtHttpEngine
import org.junit.jupiter.api.Test
import properties.Properties
import kotlin.test.assertIs

class DynamoClientTest {
    @Test
    fun `creates local mode client`() {
        val dynamoClient =
            DynamoClient(
                object : Properties {
                    override fun propertyOrNull(name: String): String? =
                        when (name) {
                            "APP_MODE" -> "local"
                            else -> null
                        }
                },
            )

        try {
            checkNotNull(dynamoClient.client.config.endpointUrl)
        } finally {
            dynamoClient.client.close()
        }
    }

    @Test
    fun `uses CRT http engine in aws mode`() {
        val dynamoClient =
            DynamoClient(
                object : Properties {
                    override fun propertyOrNull(name: String): String? = null
                },
            )

        try {
            assertIs<CrtHttpEngine>(dynamoClient.client.config.httpClient)
            assertIs<EnvironmentCredentialsProvider>(dynamoClient.client.config.credentialsProvider)
        } finally {
            dynamoClient.client.close()
        }
    }
}
