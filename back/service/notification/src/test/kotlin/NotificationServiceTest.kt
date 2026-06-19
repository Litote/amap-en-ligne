@file:OptIn(ExperimentalTime::class)

package notification

import authentication.AuthenticatedInfo
import core.AuthorizedScopeResolver
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.NotificationPayload
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.NotificationSyncDAO
import persistence.model.EntityType
import persistence.model.Notification
import persistence.model.NotificationCategory
import persistence.model.NotificationType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val MEMBER_ID = "member-1"
private const val NOTIF_ID = "notif-1"

internal class NotificationServiceTest {
    private val notificationSyncDAO = mockk<NotificationSyncDAO>(relaxed = true)
    private val scopeResolver =
        AuthorizedScopeResolver(
            mockk<persistence.dao.MemberSyncDAO>(relaxed = true).also {
                io.mockk.coEvery { it.findOrganizationIdBySub(MEMBER_ID) } returns "org-1".toId()
                io.mockk.coEvery { it.findOrganizationIdBySub(not(MEMBER_ID)) } returns null
            },
            mockk<persistence.dao.ProducerSyncDAO>(relaxed = true),
        )
    private val service = NotificationService(notificationSyncDAO, scopeResolver)

    private val auth =
        AuthenticatedInfo(
            memberId = MEMBER_ID,
            firstName = "M",
            lastName = "M",
            email = "m@example.com",
            organizationId = "org-1",
        )

    private val ownScope = SyncScope.Member(MEMBER_ID).key

    private fun notification(
        id: String = NOTIF_ID,
        scope: String = ownScope,
        readAt: Instant? = null,
        title: String = "Title",
    ) = Notification(
        notificationId = id.toId(),
        recipientScope = scope,
        type = NotificationType.INFO,
        category = NotificationCategory.GENERIC,
        title = title,
        body = "Body",
        createdAt = Instant.fromEpochMilliseconds(1_700_000_000_000),
        readAt = readAt,
    )

    private fun upsert(n: Notification) = ClientMutation(clientOpId = "op", op = Upsert(NotificationPayload(n)))

    @Test
    fun `GIVEN a foreign recipient scope WHEN applyUpsert THEN FORBIDDEN`() =
        runTest {
            val foreign = notification(scope = SyncScope.Member("other").key)
            val outcome = service.applyUpsert(auth, upsert(foreign), NotificationPayload(foreign))
            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN a tmp id WHEN applyUpsert THEN FORBIDDEN (clients cannot create)`() =
        runTest {
            val tmp = notification(id = "tmp_x")
            val outcome = service.applyUpsert(auth, upsert(tmp), NotificationPayload(tmp))
            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN an unknown notification WHEN applyUpsert THEN NOT_FOUND`() =
        runTest {
            coEvery { notificationSyncDAO.findById(ownScope, NOTIF_ID.toId()) } returns null
            val n = notification()
            val outcome = service.applyUpsert(auth, upsert(n), NotificationPayload(n))
            assertEquals(MutationErrorCode.NOT_FOUND, outcome.error?.code)
        }

    @Test
    fun `GIVEN a content change WHEN applyUpsert THEN FORBIDDEN`() =
        runTest {
            val existing = notification(title = "Original")
            coEvery { notificationSyncDAO.findById(ownScope, NOTIF_ID.toId()) } returns existing
            val tampered = existing.copy(title = "Tampered")
            val outcome = service.applyUpsert(auth, upsert(tampered), NotificationPayload(tampered))
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN only a read marker change WHEN applyUpsert THEN APPLIED and persisted`() =
        runTest {
            val existing = notification(readAt = null)
            coEvery { notificationSyncDAO.findById(ownScope, NOTIF_ID.toId()) } returns existing
            val read = existing.copy(readAt = Instant.fromEpochMilliseconds(1_700_000_500_000))
            val outcome = service.applyUpsert(auth, upsert(read), NotificationPayload(read))
            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify { notificationSyncDAO.put(read, any()) }
        }

    @Test
    fun `GIVEN an existing notification WHEN applyDelete THEN APPLIED and deleted`() =
        runTest {
            coEvery { notificationSyncDAO.findById(ownScope, NOTIF_ID.toId()) } returns notification()
            val outcome =
                service.applyDelete(
                    auth,
                    ClientMutation(clientOpId = "op", op = Delete(EntityType.Notification, NOTIF_ID)),
                    Delete(EntityType.Notification, NOTIF_ID),
                )
            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify { notificationSyncDAO.delete(ownScope, NOTIF_ID.toId(), any()) }
        }

    @Test
    fun `GIVEN notifications WHEN snapshot on own member scope THEN returns them`() =
        runTest {
            coEvery { notificationSyncDAO.getByRecipientScope(ownScope) } returns listOf(notification())
            val result = service.snapshot(auth, SyncScope.Member(MEMBER_ID))
            assertEquals(1, result.size)
        }

    @Test
    fun `GIVEN another member scope WHEN snapshot THEN empty`() =
        runTest {
            val result = service.snapshot(auth, SyncScope.Member("other"))
            assertEquals(0, result.size)
        }
}
