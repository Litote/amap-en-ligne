package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import java.sql.DriverManager
import kotlin.test.assertEquals

/**
 * Cross-component round-trip of the organization backup feature: the Flutter [AdminApi]
 * exports a source organization over real HTTP and imports the archive into a fresh empty
 * target organization on the live backend; the Kotlin side then asserts the data landed in
 * Postgres with the target organization id.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentOrganizationBackupTest : E2eTestSupport() {
    private val unique = System.currentTimeMillis()
    private val sourceOrgId = "backup-source-org-$unique"
    private val targetOrgId = "backup-target-org-$unique"
    private val aliceId = "backup-alice-$unique"

    @Test
    fun `GIVEN owner token WHEN flutter exports an org and imports into an empty org THEN data lands on target`() {
        // Source org with two members.
        ContainerSuite.insertOrganization(
            organizationId = sourceOrgId,
            name = "AMAP Source $unique",
            contactEmail = "contact+$sourceOrgId@test.invalid",
        )
        ContainerSuite.insertMember(
            memberId = "backup-admin-$unique",
            organizationId = sourceOrgId,
            roles = listOf("ADMIN"),
            firstName = "Test",
            lastName = "Admin",
            email = "backup-admin+$unique@test.invalid",
        )
        ContainerSuite.insertMember(
            memberId = aliceId,
            organizationId = sourceOrgId,
            roles = listOf("MEMBER"),
            firstName = "Alice",
            lastName = "Member",
            email = "backup-alice+$unique@test.invalid",
        )

        // Empty target org (only the shell row — no members / contracts / …).
        ContainerSuite.insertOrganization(
            organizationId = targetOrgId,
            name = "Coquille vide $unique",
            contactEmail = "contact+$targetOrgId@test.invalid",
        )

        // OWNER token authorizes export of any org and import into any org.
        val ownerToken =
            ContainerSuite.mintGoTrueToken(
                subject = "backup-owner-sub-$unique",
                email = "backup-owner+$unique@test.invalid",
                roles = listOf("OWNER"),
            )

        runFlutterTests(
            testFile = "test/acceptance/cross_component/organization_backup_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "OWNER_TOKEN" to ownerToken,
                    "SOURCE_ORG_ID" to sourceOrgId,
                    "TARGET_ORG_ID" to targetOrgId,
                ),
        )

        // Alice landed in the target org (id preserved, organization rewritten to the target).
        assertEquals(targetOrgId, readMemberOrganizationId(aliceId))
        // The target org took the source org's name.
        assertEquals("AMAP Source $unique", readOrganizationName(targetOrgId))
    }

    private fun readMemberOrganizationId(memberId: String): String? =
        queryString("SELECT organization_id FROM member WHERE member_id = ?", memberId)

    private fun readOrganizationName(organizationId: String): String? =
        queryString("SELECT name FROM organization WHERE organization_id = ?", organizationId)

    private fun queryString(
        sql: String,
        param: String,
    ): String? =
        DriverManager
            .getConnection(
                ContainerSuite.postgres.jdbcUrl,
                ContainerSuite.postgres.username,
                ContainerSuite.postgres.password,
            ).use { conn ->
                conn.prepareStatement(sql).use { stmt ->
                    stmt.setString(1, param)
                    stmt.executeQuery().use { rs -> if (rs.next()) rs.getString(1) else null }
                }
            }
}
