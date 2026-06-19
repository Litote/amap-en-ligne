package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

/**
 * Cross-component flow for slot cancellation (time-slot lifecycle):
 * a coordinator creates a delivery with a registered slot and cancels it
 * through `POST /v1/sync`; the registered member then bootstraps and must see
 * the slot CANCELLED with its registrations cascaded, plus a SLOT_CANCELLED
 * notification on their private `member:{sub}` feed.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentTimeSlotCancelSyncTest : E2eTestSupport() {
    private val organizationId = "time-slot-cancel-e2e-org-${System.currentTimeMillis()}"
    private val coordinatorSub = "time-slot-cancel-coordinator-sub"
    private val memberSub = "time-slot-cancel-member-sub"
    private val coordinatorEmail = "time-slot-cancel-coordinator@test.invalid"
    private val memberEmail = "time-slot-cancel-member@test.invalid"

    @Test
    fun `GIVEN a registered slot WHEN the coordinator cancels it via sync THEN the member sees the cancellation and is notified`() {
        ContainerSuite.insertOrganization(
            organizationId = organizationId,
            name = "AMAP Time Slot Cancel E2E",
            contactEmail = "contact+$organizationId@test.invalid",
        )
        // memberId == sub by invariant: insert both members so
        // AuthorizedScopeResolver can resolve the org scope for each caller.
        ContainerSuite.insertMember(
            memberId = coordinatorSub,
            organizationId = organizationId,
            roles = listOf("COORDINATOR"),
            firstName = "Coord",
            lastName = "Inator",
            email = coordinatorEmail,
        )
        ContainerSuite.insertMember(
            memberId = memberSub,
            organizationId = organizationId,
            roles = listOf("VOLUNTEER"),
            firstName = "Alice",
            lastName = "Volunteer",
            email = memberEmail,
        )

        val coordinatorToken =
            ContainerSuite.mintGoTrueToken(
                subject = coordinatorSub,
                email = coordinatorEmail,
                roles = listOf("COORDINATOR"),
                organizationId = organizationId,
            )
        val memberToken =
            ContainerSuite.mintGoTrueToken(
                subject = memberSub,
                email = memberEmail,
                roles = listOf("VOLUNTEER"),
                organizationId = organizationId,
            )

        runFlutterTests(
            testFile = "test/acceptance/cross_component/time_slot_cancel_sync_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "COORDINATOR_TOKEN" to coordinatorToken,
                    "MEMBER_TOKEN" to memberToken,
                    "ORGANIZATION_ID" to organizationId,
                    "MEMBER_SUB" to memberSub,
                ),
        )
    }
}
