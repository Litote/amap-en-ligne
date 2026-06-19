package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentInvitationSyncTest : E2eTestSupport() {
    private val organizationId = "invitation-sync-e2e-org-${System.currentTimeMillis()}"

    @Test
    fun `GIVEN admin sync token WHEN flutter creates and resends a member invitation THEN pending invitation state is preserved`() {
        ContainerSuite.insertOrganization(
            organizationId = organizationId,
            name = "AMAP Invitations E2E",
            contactEmail = "contact+$organizationId@test.invalid",
        )
        // memberId == sub by invariant: insert the admin so AuthorizedScopeResolver can resolve the org scope
        ContainerSuite.insertMember(
            memberId = "admin-sub-invitation-sync",
            organizationId = organizationId,
            roles = listOf("ADMIN"),
            firstName = "Test",
            lastName = "Admin",
            email = "admin-invitation-sync@test.invalid",
        )
        val token =
            ContainerSuite.mintGoTrueToken(
                subject = "admin-sub-invitation-sync",
                email = "admin-invitation-sync@test.invalid",
                roles = listOf("ADMIN"),
                organizationId = organizationId,
            )

        runFlutterTests(
            testFile = "test/acceptance/cross_component/invitation_sync_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "BEARER_TOKEN" to token,
                    "ORGANIZATION_ID" to organizationId,
                ),
        )
    }
}
