package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

/**
 * Cross-component E2E test for the contract weekly deliveries feature:
 * - tmp_* contract + organization batch upsert with delivery linking the tmp_ id
 * - Back rewrites the delivery link to the real allocated id
 * - Self-subscription to an IN_PREPARATION contract is rejected for non-privileged members
 *
 * Kotlin side validates real backend behavior; Flutter side (contract_weekly_deliveries_e2e_test.dart)
 * validates that the client-side tmp_* remap propagates correctly through the local cache.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class ContractWeeklyDeliveriesE2eTest : E2eTestSupport() {
    private val organizationId = "contract-weekly-e2e-org-${System.currentTimeMillis()}"

    @Test
    fun `GIVEN admin org scope WHEN batch with tmp contract and linked delivery upserted THEN delivery persists with real contract id`() {
        ContainerSuite.insertOrganization(
            organizationId = organizationId,
            name = "AMAP Contract Weekly E2E",
            contactEmail = "contact+$organizationId@test.invalid",
        )
        // memberId == sub by invariant: insert the admin so AuthorizedScopeResolver can resolve the org scope
        ContainerSuite.insertMember(
            memberId = "contract-weekly-e2e-admin-sub",
            organizationId = organizationId,
            roles = listOf("ADMIN"),
            firstName = "Test",
            lastName = "Admin",
            email = "contract-weekly-e2e-admin@test.invalid",
        )
        val adminToken =
            ContainerSuite.mintGoTrueToken(
                subject = "contract-weekly-e2e-admin-sub",
                email = "contract-weekly-e2e-admin@test.invalid",
                roles = listOf("ADMIN"),
                organizationId = organizationId,
            )
        val memberToken =
            ContainerSuite.mintGoTrueToken(
                subject = "contract-weekly-e2e-member-sub",
                email = "contract-weekly-e2e-member@test.invalid",
                roles = listOf("MEMBER"),
                organizationId = organizationId,
            )

        runFlutterTests(
            testFile = "test/acceptance/cross_component/contract_weekly_deliveries_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "ADMIN_TOKEN" to adminToken,
                    "MEMBER_TOKEN" to memberToken,
                    "ORGANIZATION_ID" to organizationId,
                ),
        )
    }
}
