package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentMemberJoinRequestSyncTest : E2eTestSupport() {
    private val organizationId = "member-join-sync-e2e-org-${System.currentTimeMillis()}"
    private val adminEmail = "member-join-sync-admin@test.invalid"
    private val adminPassword = "MemberJoinSync123!"
    private val requesterEmail = "member-join-requester+$organizationId@test.invalid"

    @Test
    fun `GIVEN a public member join request WHEN admin approves it via sync THEN pending member data is created`() {
        ContainerSuite.insertOrganization(
            organizationId = organizationId,
            name = "AMAP Member Join E2E",
            contactEmail = "contact+$organizationId@test.invalid",
        )
        ContainerSuite.insertServer(
            serverId = "member-join-sync-server",
            name = "Member Join Sync Server",
            url = "https://member-join-sync.test.invalid",
        )
        // memberId == sub by invariant: insert the admin so AuthorizedScopeResolver can resolve the org scope
        ContainerSuite.insertMember(
            memberId = "member-join-sync-admin-sub",
            organizationId = organizationId,
            roles = listOf("ADMIN"),
            firstName = "Join",
            lastName = "Admin",
            email = adminEmail,
        )
        val token =
            ContainerSuite.mintGoTrueToken(
                subject = "member-join-sync-admin-sub",
                email = adminEmail,
                roles = listOf("ADMIN"),
                organizationId = organizationId,
            )

        runFlutterTests(
            testFile = "test/acceptance/cross_component/member_join_request_sync_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "BEARER_TOKEN" to token,
                    "ORGANIZATION_ID" to organizationId,
                    "REQUESTER_EMAIL" to requesterEmail,
                ),
        )
    }
}
