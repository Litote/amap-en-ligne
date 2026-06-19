package deploy.jvm

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import java.net.URI
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.sql.DriverManager
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * End-to-end round-trip of the organization backup feature against real Postgres:
 * export org A over HTTP, then import the archive into a fresh empty org B and verify
 * the data lands through the real DAOs (denormalisation + Change writes included).
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
internal class OrganizationBackupIntegrationTest : JvmSyncTestSupport() {
    private val orgA = "org-a"
    private val orgB = "org-b"
    private val adminA = "admin-a"
    private val adminB = "admin-b"
    private val aliceId = "alice-member"

    private fun adminToken(
        sub: String,
        org: String,
    ) = mintGoTrueToken(subject = sub, roles = listOf("ADMIN"), organizationId = org)

    private fun getExport(
        organizationId: String,
        token: String,
    ): HttpResponse<String> {
        val request =
            HttpRequest
                .newBuilder()
                .uri(URI("http://127.0.0.1:$port/v1/admin/organizations/$organizationId/export"))
                .header("Authorization", "Bearer $token")
                .GET()
                .build()
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString())
    }

    private fun postImport(
        organizationId: String,
        token: String,
        body: String,
    ): HttpResponse<String> {
        val request =
            HttpRequest
                .newBuilder()
                .uri(URI("http://127.0.0.1:$port/v1/admin/organizations/$organizationId/import"))
                .header("Authorization", "Bearer $token")
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build()
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString())
    }

    private fun queryString(
        sql: String,
        param: String,
    ): String? =
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn.prepareStatement(sql).use { stmt ->
                    stmt.setString(1, param)
                    stmt.executeQuery().use { rs -> if (rs.next()) rs.getString(1) else null }
                }
            }

    @Test
    fun `GIVEN org with data WHEN export then import into empty org THEN data lands with target org id`() {
        // Source org A with two members.
        insertOrganizationDirectly(orgA, name = "AMAP du Test")
        insertMemberDirectly(adminA, orgA, listOf("ADMIN"))
        insertMemberDirectly(aliceId, orgA, listOf("MEMBER"))

        // Export org A as its admin.
        val exportResponse = getExport(orgA, adminToken(adminA, orgA))
        assertEquals(200, exportResponse.statusCode())
        val archive = exportResponse.body()
        assertTrue(archive.contains("\"format_version\":1"))
        assertTrue(archive.contains(aliceId))

        // Fresh empty org B with only its bootstrap admin.
        insertOrganizationDirectly(orgB, name = "Coquille vide")
        insertMemberDirectly(adminB, orgB, listOf("ADMIN"))

        // Import the archive into org B as its admin (the admin's own row is ignored by the
        // empty-target guard).
        val importResponse = postImport(orgB, adminToken(adminB, orgB), archive)
        assertEquals(200, importResponse.statusCode(), importResponse.body())
        assertTrue(importResponse.body().contains("\"organization_id\":\"$orgB\""))

        // Alice landed in org B (id preserved, organization rewritten to the target).
        assertEquals(
            orgB,
            queryString("SELECT organization_id FROM member WHERE member_id = ?", aliceId),
        )
        // Org B took the source org's name.
        assertEquals(
            "AMAP du Test",
            queryString("SELECT name FROM organization WHERE organization_id = ?", orgB),
        )
    }

    @Test
    fun `GIVEN source and target both with members WHEN import THEN members merge`() {
        insertOrganizationDirectly(orgA, name = "AMAP du Test")
        insertMemberDirectly(adminA, orgA, listOf("ADMIN"))
        insertMemberDirectly(aliceId, orgA, listOf("MEMBER"))
        val archive = getExport(orgA, adminToken(adminA, orgA)).body()

        // Target org B already has a non-caller member.
        insertOrganizationDirectly(orgB, name = "Pas vide")
        insertMemberDirectly(adminB, orgB, listOf("ADMIN"))
        insertMemberDirectly("bob-member", orgB, listOf("MEMBER"))

        val importResponse = postImport(orgB, adminToken(adminB, orgB), archive)
        assertEquals(200, importResponse.statusCode())
        // Alice from the export lands in org B alongside Bob.
        assertEquals(
            orgB,
            queryString("SELECT organization_id FROM member WHERE member_id = ?", aliceId),
        )
    }
}
