package persistence.dynamo

import aws.sdk.kotlin.runtime.auth.credentials.EnvironmentCredentialsProvider
import aws.smithy.kotlin.runtime.http.engine.crt.CrtHttpEngine
import org.junit.jupiter.api.Test
import properties.Properties
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.time.Duration.Companion.seconds

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
    fun `local mode client fails fast instead of hanging on an unreachable DynamoDB-Local`() {
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
            val engine = assertIs<CrtHttpEngine>(dynamoClient.client.config.httpClient)
            assertEquals(5.seconds, engine.config.connectTimeout)
            assertEquals(10.seconds, engine.config.connectionAcquireTimeout)
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
