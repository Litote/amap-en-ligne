@file:OptIn(ExperimentalTime::class)

package attendance

import authentication.AuthenticatedInfo
import authentication.Role
import email.AttendanceEmailPort
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import persistence.changes.AttendanceEmailRequestPayload
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.Upsert
import persistence.dao.AttendanceEmailRequestSyncDAO
import persistence.dao.BasketExchangeSyncDAO
import persistence.dao.MemberSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.AttendanceEmailRequest
import persistence.model.Delivery
import persistence.model.DeliveryStatus
import persistence.model.EntityType
import persistence.model.Organization
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

private const val ORG_ID = "org-1"
private const val DELIVERY_ID = "delivery-1"
private const val TMP_REQUEST_ID = "tmp_request-1"

internal class AttendanceEmailRequestServiceTest {
    private val attendanceEmailRequestSyncDAO = mockk<AttendanceEmailRequestSyncDAO>(relaxed = true)
    private val organizationSyncDAO = mockk<OrganizationSyncDAO>()
    private val basketExchangeSyncDAO = mockk<BasketExchangeSyncDAO>(relaxed = true)
    private val memberSyncDAO = mockk<MemberSyncDAO>(relaxed = true)
    private val attendanceEmailPort = mockk<AttendanceEmailPort>(relaxed = true)

    private val service =
        AttendanceEmailRequestService(
            attendanceEmailRequestSyncDAO,
            organizationSyncDAO,
            basketExchangeSyncDAO,
            memberSyncDAO,
            attendanceEmailPort,
        )

    private val coordinatorAuth =
        AuthenticatedInfo(
            memberId = "coordinator-1",
            firstName = "Coordinator",
            lastName = "User",
            email = "coordinator@example.com",
            organizationId = ORG_ID,
            roles = listOf(Role.COORDINATOR),
        )

    private val adminAuth =
        AuthenticatedInfo(
            memberId = "admin-1",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            organizationId = ORG_ID,
            roles = listOf(Role.ADMIN),
        )

    private val volunteerAuth =
        AuthenticatedInfo(
            memberId = "volunteer-1",
            firstName = "Volunteer",
            lastName = "User",
            email = "volunteer@example.com",
            organizationId = ORG_ID,
            roles = listOf(Role.VOLUNTEER),
        )

    private val noOrgAuth =
        AuthenticatedInfo(
            memberId = "caller-1",
            firstName = "No",
            lastName = "Org",
            email = "noorg@example.com",
            organizationId = null,
            roles = listOf(Role.COORDINATOR),
        )

    private fun buildDelivery(deliveryId: String = DELIVERY_ID): Delivery {
        val now = Clock.System.now()
        return Delivery(
            deliveryId = deliveryId.toId(),
            organizationId = ORG_ID.toId(),
            scheduledDate = kotlinx.datetime.LocalDateTime(2030, 1, 15, 18, 0),
            status = DeliveryStatus.PLANNED,
            minVolunteersRequired = 2,
        )
    }

    private fun buildOrganization(deliveries: List<Delivery> = listOf(buildDelivery())): Organization {
        val now = Clock.System.now()
        return Organization(
            organizationId = ORG_ID.toId(),
            name = "Test AMAP",
            contactEmail = "amap@example.com",
            activeStatus = true,
            timezone = kotlinx.datetime.TimeZone.UTC,
            defaultLanguage = "fr",
            createdInstant = now,
            lastUpdatedInstant = now,
            deliveries = deliveries,
        )
    }

    private fun buildRequest(
        requestId: String = TMP_REQUEST_ID,
        organizationId: String = ORG_ID,
        deliveryId: String = DELIVERY_ID,
    ): AttendanceEmailRequest =
        AttendanceEmailRequest(
            attendanceEmailRequestId = requestId.toId(),
            organizationId = organizationId.toId(),
            deliveryId = deliveryId,
            recipientEmail = "recipient@example.com",
            requestedAt = Clock.System.now(),
        )

    private fun buildMutation(request: AttendanceEmailRequest): ClientMutation =
        ClientMutation(
            clientOpId = "op-1",
            op = Upsert(AttendanceEmailRequestPayload(request)),
        )

    @Test
    fun `GIVEN coordinator caller WHEN upsert with tmp id THEN APPLIED and sentAt set and email sent`() =
        runTest {
            val request = buildRequest()
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(request), AttendanceEmailRequestPayload(request))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertNotNull(outcome.serverEntityId)
            coVerify(exactly = 1) { attendanceEmailRequestSyncDAO.put(any(), any()) }
            coVerify(exactly = 1) {
                attendanceEmailPort.sendAttendanceSheets(any(), any(), any(), any(), "recipient@example.com")
            }
        }

    @Test
    fun `GIVEN admin caller WHEN upsert THEN APPLIED`() =
        runTest {
            val request = buildRequest()
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()

            val outcome = service.applyUpsert(adminAuth, buildMutation(request), AttendanceEmailRequestPayload(request))

            assertEquals(MutationStatus.APPLIED, outcome.status)
        }

    @Test
    fun `GIVEN caller without organization id WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val request = buildRequest()

            val outcome = service.applyUpsert(noOrgAuth, buildMutation(request), AttendanceEmailRequestPayload(request))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { attendanceEmailRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val request = buildRequest()

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(request), AttendanceEmailRequestPayload(request))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { attendanceEmailRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN unknown delivery WHEN upsert THEN REJECTED NOT_FOUND`() =
        runTest {
            val request = buildRequest(deliveryId = "unknown-delivery")
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(request), AttendanceEmailRequestPayload(request))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.NOT_FOUND, outcome.error?.code)
            coVerify(exactly = 0) { attendanceEmailRequestSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN organization not found WHEN upsert THEN REJECTED NOT_FOUND`() =
        runTest {
            val request = buildRequest()
            coEvery { organizationSyncDAO.getById(any()) } returns null

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(request), AttendanceEmailRequestPayload(request))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.NOT_FOUND, outcome.error?.code)
        }

    @Test
    fun `WHEN applyDelete THEN REJECTED FORBIDDEN`() =
        runTest {
            val mutation =
                ClientMutation(
                    clientOpId = "op-delete",
                    op = Delete(EntityType.AttendanceEmailRequest, "request-1"),
                )

            val outcome = service.applyDelete(coordinatorAuth, mutation, Delete(EntityType.AttendanceEmailRequest, "request-1"))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN email send fails WHEN upsert THEN still APPLIED`() =
        runTest {
            val request = buildRequest()
            coEvery { organizationSyncDAO.getById(any()) } returns buildOrganization()
            coEvery {
                attendanceEmailPort.sendAttendanceSheets(any(), any(), any(), any(), any())
            } throws RuntimeException("SMTP error")

            val outcome = service.applyUpsert(coordinatorAuth, buildMutation(request), AttendanceEmailRequestPayload(request))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { attendanceEmailRequestSyncDAO.put(any(), any()) }
        }
}
