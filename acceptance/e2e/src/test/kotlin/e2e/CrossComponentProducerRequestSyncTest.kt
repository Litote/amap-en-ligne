package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import java.sql.DriverManager
import kotlin.test.assertEquals

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentProducerRequestSyncTest : E2eTestSupport() {
    private val unique = System.currentTimeMillis()
    private val producerName = "Ferme Producteur E2E $unique"
    private val adminEmail = "producer-request+$unique@test.invalid"

    @Test
    fun `GIVEN a public producer request WHEN owner approves it via sync THEN producer activation is provisioned`() {
        val ownerToken =
            ContainerSuite.mintGoTrueToken(
                subject = "owner-sub-producer-request-sync-$unique",
                email = "owner-producer-request-sync@test.invalid",
                roles = listOf("OWNER"),
                producerAccountId = null,
            )

        runFlutterTests(
            testFile = "test/acceptance/cross_component/producer_request_sync_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "OWNER_BEARER_TOKEN" to ownerToken,
                    "PRODUCER_REQUEST_NAME" to producerName,
                    "PRODUCER_REQUEST_EMAIL" to adminEmail,
                ),
        )

        assertEquals("PRODUCER", readLatestActivationKind(adminEmail))
    }

    private fun readLatestActivationKind(email: String): String? =
        DriverManager
            .getConnection(
                ContainerSuite.postgres.jdbcUrl,
                ContainerSuite.postgres.username,
                ContainerSuite.postgres.password,
            ).use { conn ->
                conn
                    .prepareStatement(
                        "SELECT kind FROM activation_token WHERE admin_email = ? ORDER BY created_at DESC LIMIT 1",
                    ).use { stmt ->
                        stmt.setString(1, email)
                        stmt.executeQuery().use { rs ->
                            if (rs.next()) rs.getString("kind") else null
                        }
                    }
            }
}
