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
import persistence.changes.DeviceTokenPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.DeviceTokenSyncDAO
import persistence.model.DevicePlatform
import persistence.model.DeviceToken
import persistence.model.EntityType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private const val MEMBER_ID = "member-1"
private const val DEVICE_TOKEN_ID = "dev-1"

internal class DeviceTokenServiceTest {
    private val deviceTokenSyncDAO = mockk<DeviceTokenSyncDAO>(relaxed = true)
    private val scopeResolver =
        AuthorizedScopeResolver(
            mockk<persistence.dao.MemberSyncDAO>(relaxed = true).also {
                io.mockk.coEvery { it.findOrganizationIdBySub(MEMBER_ID) } returns "org-1".toId()
                io.mockk.coEvery { it.findOrganizationIdBySub(not(MEMBER_ID)) } returns null
            },
            mockk<persistence.dao.ProducerSyncDAO>(relaxed = true),
        )
    private val service = DeviceTokenService(deviceTokenSyncDAO, scopeResolver)

    private val auth =
        AuthenticatedInfo(
            memberId = MEMBER_ID,
            firstName = "M",
            lastName = "M",
            email = "m@example.com",
            organizationId = "org-1",
        )

    private val ownScope = SyncScope.Member(MEMBER_ID).key

    private fun deviceToken(
        id: String = DEVICE_TOKEN_ID,
        scope: String = ownScope,
        token: String = "fcm-token-1",
    ) = DeviceToken(
        deviceTokenId = id.toId(),
        recipientScope = scope,
        platform = DevicePlatform.ANDROID,
        token = token,
        createdAt = Instant.fromEpochMilliseconds(1_700_000_000_000),
        lastSeenAt = Instant.fromEpochMilliseconds(1_700_000_000_000),
    )

    private fun upsert(t: DeviceToken) = ClientMutation(clientOpId = "op", op = Upsert(DeviceTokenPayload(t)))

    @Test
    fun `GIVEN a foreign recipient scope WHEN applyUpsert THEN FORBIDDEN`() =
        runTest {
            val foreign = deviceToken(scope = SyncScope.Member("other").key)
            val outcome = service.applyUpsert(auth, upsert(foreign), DeviceTokenPayload(foreign))
            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN a tmp id with a new token WHEN applyUpsert THEN APPLIED with a server-allocated id`() =
        runTest {
            coEvery { deviceTokenSyncDAO.getByRecipientScope(ownScope) } returns emptyList()
            val tmp = deviceToken(id = "tmp_x")
            val outcome = service.applyUpsert(auth, upsert(tmp), DeviceTokenPayload(tmp))
            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertTrue(outcome.serverEntityId?.startsWith("tmp_") == false)
            coVerify { deviceTokenSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN an already registered token WHEN applyUpsert THEN it reuses the existing row id`() =
        runTest {
            val existing = deviceToken(id = "dev-existing", token = "fcm-token-1")
            coEvery { deviceTokenSyncDAO.getByRecipientScope(ownScope) } returns listOf(existing)
            val tmp = deviceToken(id = "tmp_x", token = "fcm-token-1")
            val outcome = service.applyUpsert(auth, upsert(tmp), DeviceTokenPayload(tmp))
            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals("dev-existing", outcome.serverEntityId)
            coVerify { deviceTokenSyncDAO.put(match { it.deviceTokenId.id == "dev-existing" }, any()) }
        }

    @Test
    fun `GIVEN a non-tmp id with a new token WHEN applyUpsert THEN APPLIED with the same id`() =
        runTest {
            coEvery { deviceTokenSyncDAO.getByRecipientScope(ownScope) } returns emptyList()
            val token = deviceToken()
            val outcome = service.applyUpsert(auth, upsert(token), DeviceTokenPayload(token))
            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(DEVICE_TOKEN_ID, outcome.serverEntityId)
        }

    @Test
    fun `GIVEN an existing device token WHEN applyDelete THEN APPLIED and deleted`() =
        runTest {
            coEvery { deviceTokenSyncDAO.findById(ownScope, DEVICE_TOKEN_ID.toId()) } returns deviceToken()
            val outcome =
                service.applyDelete(
                    auth,
                    ClientMutation(clientOpId = "op", op = Delete(EntityType.DeviceToken, DEVICE_TOKEN_ID)),
                    Delete(EntityType.DeviceToken, DEVICE_TOKEN_ID),
                )
            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify { deviceTokenSyncDAO.delete(ownScope, DEVICE_TOKEN_ID.toId(), any()) }
        }

    @Test
    fun `GIVEN an unknown device token WHEN applyDelete THEN NOT_FOUND`() =
        runTest {
            coEvery { deviceTokenSyncDAO.findById(ownScope, DEVICE_TOKEN_ID.toId()) } returns null
            val outcome =
                service.applyDelete(
                    auth,
                    ClientMutation(clientOpId = "op", op = Delete(EntityType.DeviceToken, DEVICE_TOKEN_ID)),
                    Delete(EntityType.DeviceToken, DEVICE_TOKEN_ID),
                )
            assertEquals(MutationErrorCode.NOT_FOUND, outcome.error?.code)
        }

    @Test
    fun `GIVEN device tokens WHEN snapshot on own member scope THEN returns them`() =
        runTest {
            coEvery { deviceTokenSyncDAO.getByRecipientScope(ownScope) } returns listOf(deviceToken())
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
