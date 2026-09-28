package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import java.sql.DriverManager
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentAdminManagedProducerLifecycleTest : E2eTestSupport() {
    private val unique = System.currentTimeMillis()
    private val organizationId = "producer-lifecycle-org-$unique"
    private val adminToken =
        ContainerSuite.mintGoTrueToken(
            subject = "producer-lifecycle-admin-sub-$unique",
            email = "producer-lifecycle-admin+$unique@test.invalid",
            roles = listOf("ADMIN", "COORDINATOR"),
            organizationId = organizationId,
            producerAccountId = organizationId,
        )
    private val createdNoAccountName = "Verger du Bourg $unique"
    private val createdNoAccountEmail = "verger-du-bourg+$unique@test.invalid"

    @Test
    fun `GIVEN admin org scope WHEN admin creates AMAP-managed producer with products and delivery THEN mutations persist`() {
        ContainerSuite.insertOrganization(
            organizationId = organizationId,
            name = "AMAP Producteurs $unique",
            contactEmail = "contact+$organizationId@test.invalid",
        )
        // memberId == sub by invariant: insert the admin so AuthorizedScopeResolver can resolve the org scope
        ContainerSuite.insertMember(
            memberId = "producer-lifecycle-admin-sub-$unique",
            organizationId = organizationId,
            roles = listOf("ADMIN", "COORDINATOR"),
            firstName = "Test",
            lastName = "Admin",
            email = "producer-lifecycle-admin+$unique@test.invalid",
        )

        runFlutterTests(
            testFile = "test/acceptance/cross_component/admin_managed_producer_lifecycle_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "BEARER_TOKEN" to adminToken,
                    "ORGANIZATION_ID" to organizationId,
                    "NO_ACCOUNT_NAME" to createdNoAccountName,
                    "NO_ACCOUNT_EMAIL" to createdNoAccountEmail,
                ),
        )

        val createdProducerId = readProducerAccountIdByContactEmail(createdNoAccountEmail)
        assertNotNull(createdProducerId)
        assertEquals("NO_ACCOUNT", readProducerManagementMode(createdProducerId))
        assertNull(readLinkedProducerAccountId(createdProducerId))
        assertEquals(1, countOrganizationProducerRows(organizationId, createdProducerId))
        assertEquals(
            2,
            countOrganizationProducts(
                organizationId = organizationId,
                producerAccountId = createdProducerId,
                productNames = listOf("Pommes", "Jus de pomme"),
            ),
        )
        assertEquals(1, countOrganizationDeliveries(organizationId))
    }

    private fun readProducerAccountIdByContactEmail(email: String): String? =
        DriverManager
            .getConnection(
                ContainerSuite.postgres.jdbcUrl,
                ContainerSuite.postgres.username,
                ContainerSuite.postgres.password,
            ).use { conn ->
                conn
                    .prepareStatement(
                        "SELECT producer_account_id FROM producer_account WHERE contact_email = ?",
                    ).use { stmt ->
                        stmt.setString(1, email)
                        stmt.executeQuery().use { rs ->
                            if (rs.next()) rs.getString("producer_account_id") else null
                        }
                    }
            }

    private fun readProducerManagementMode(producerAccountId: String): String? =
        readProducerColumn(
            producerAccountId = producerAccountId,
            column = "management_mode",
        )

    private fun readLinkedProducerAccountId(producerAccountId: String): String? =
        readProducerColumn(
            producerAccountId = producerAccountId,
            column = "linked_producer_account_id",
        )

    private fun readProducerColumn(
        producerAccountId: String,
        column: String,
    ): String? =
        DriverManager
            .getConnection(
                ContainerSuite.postgres.jdbcUrl,
                ContainerSuite.postgres.username,
                ContainerSuite.postgres.password,
            ).use { conn ->
                conn
                    .prepareStatement(
                        "SELECT $column FROM producer_account WHERE producer_account_id = ?",
                    ).use { stmt ->
                        stmt.setString(1, producerAccountId)
                        stmt.executeQuery().use { rs ->
                            if (rs.next()) rs.getString(column) else null
                        }
                    }
            }

    private fun countOrganizationProducerRows(
        organizationId: String,
        producerAccountId: String,
    ): Int =
        DriverManager
            .getConnection(
                ContainerSuite.postgres.jdbcUrl,
                ContainerSuite.postgres.username,
                ContainerSuite.postgres.password,
            ).use { conn ->
                conn
                    .prepareStatement(
                        """
                        SELECT COUNT(*)
                        FROM organization_producer
                        WHERE organization_id = ? AND producer_account_id = ?
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId)
                        stmt.setString(2, producerAccountId)
                        stmt.executeQuery().use { rs ->
                            rs.next()
                            rs.getInt(1)
                        }
                    }
            }

    private fun countOrganizationProducts(
        organizationId: String,
        producerAccountId: String,
        productNames: List<String>,
    ): Int =
        DriverManager
            .getConnection(
                ContainerSuite.postgres.jdbcUrl,
                ContainerSuite.postgres.username,
                ContainerSuite.postgres.password,
            ).use { conn ->
                conn
                    .prepareStatement(
                        """
                        SELECT COUNT(*)
                        FROM organization_product
                        WHERE organization_id = ?
                          AND producer_account_id = ?
                          AND name = ANY (?)
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId)
                        stmt.setString(2, producerAccountId)
                        stmt.setArray(3, conn.createArrayOf("text", productNames.toTypedArray()))
                        stmt.executeQuery().use { rs ->
                            rs.next()
                            rs.getInt(1)
                        }
                    }
            }

    private fun countOrganizationDeliveries(organizationId: String): Int =
        DriverManager
            .getConnection(
                ContainerSuite.postgres.jdbcUrl,
                ContainerSuite.postgres.username,
                ContainerSuite.postgres.password,
            ).use { conn ->
                conn
                    .prepareStatement(
                        """
                        SELECT COALESCE(jsonb_array_length(deliveries), 0)
                        FROM organization
                        WHERE organization_id = ?
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId)
                        stmt.executeQuery().use { rs ->
                            rs.next()
                            rs.getInt(1)
                        }
                    }
            }
}
