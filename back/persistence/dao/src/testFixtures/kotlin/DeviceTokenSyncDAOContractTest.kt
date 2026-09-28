@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.DeviceTokenPayload
import persistence.changes.SyncScope
import persistence.model.DevicePlatform
import persistence.model.DeviceToken
import persistence.model.EntityType
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
abstract class DeviceTokenSyncDAOContractTest {
    protected abstract val deviceTokenSyncDAO: DeviceTokenSyncDAO
    protected abstract val changeDAO: ChangeDAO

    private fun newSubject() = UUID.randomUUID().toString()

    private fun newDeviceTokenId() = UUID.randomUUID().toString()

    private fun recipientScope(subject: String) = SyncScope.Member(subject).key

    private fun buildDeviceToken(
        deviceTokenId: String = newDeviceTokenId(),
        recipientScope: String,
        token: String = "fcm-${UUID.randomUUID()}",
        lastSeenAt: Instant = Instant.fromEpochMilliseconds(1_700_000_000_000),
    ): DeviceToken =
        DeviceToken(
            deviceTokenId = deviceTokenId.toId(),
            recipientScope = recipientScope,
            platform = DevicePlatform.ANDROID,
            token = token,
            createdAt = Instant.fromEpochMilliseconds(1_700_000_000_000),
            lastSeenAt = lastSeenAt,
        )

    private fun buildUpsertChange(deviceToken: DeviceToken): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.DeviceToken,
            entityId = deviceToken.deviceTokenId.id,
            scopeKey = deviceToken.recipientScope,
            op = ChangeOp.UPSERT,
            payload = DeviceTokenPayload(deviceToken),
            producedAt = System.currentTimeMillis(),
        )

    private fun buildDeleteChange(
        deviceTokenId: String,
        recipientScope: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.DeviceToken,
            entityId = deviceTokenId,
            scopeKey = recipientScope,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a device token WHEN put then getByRecipientScope THEN returns it`() =
        runTest {
            val scope = recipientScope(newSubject())
            val deviceToken = buildDeviceToken(recipientScope = scope)

            deviceTokenSyncDAO.put(deviceToken, buildUpsertChange(deviceToken))

            val result = deviceTokenSyncDAO.getByRecipientScope(scope)
            assertEquals(1, result.size)
            assertEquals(deviceToken.deviceTokenId, result.first().deviceTokenId)
            assertEquals(deviceToken.token, result.first().token)
        }

    @Test
    fun `GIVEN no device tokens WHEN getByRecipientScope THEN returns empty list`() =
        runTest {
            val result = deviceTokenSyncDAO.getByRecipientScope(recipientScope(newSubject()))
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN device tokens for two recipients WHEN getByRecipientScope THEN returns only the right ones`() =
        runTest {
            val scopeA = recipientScope(newSubject())
            val scopeB = recipientScope(newSubject())
            val tokenA = buildDeviceToken(recipientScope = scopeA)
            val tokenB = buildDeviceToken(recipientScope = scopeB)

            deviceTokenSyncDAO.put(tokenA, buildUpsertChange(tokenA))
            deviceTokenSyncDAO.put(tokenB, buildUpsertChange(tokenB))

            val result = deviceTokenSyncDAO.getByRecipientScope(scopeA)
            assertEquals(1, result.size)
            assertEquals(tokenA.deviceTokenId, result.first().deviceTokenId)
        }

    @Test
    fun `GIVEN a device token WHEN findById THEN returns it`() =
        runTest {
            val scope = recipientScope(newSubject())
            val deviceToken = buildDeviceToken(recipientScope = scope)
            deviceTokenSyncDAO.put(deviceToken, buildUpsertChange(deviceToken))

            val found = deviceTokenSyncDAO.findById(scope, deviceToken.deviceTokenId)
            assertNotNull(found)
            assertEquals(DevicePlatform.ANDROID, found.platform)
        }

    @Test
    fun `GIVEN an existing device token WHEN put with a newer lastSeenAt THEN it is refreshed`() =
        runTest {
            val scope = recipientScope(newSubject())
            val deviceToken = buildDeviceToken(recipientScope = scope)
            deviceTokenSyncDAO.put(deviceToken, buildUpsertChange(deviceToken))

            val newer = Instant.fromEpochMilliseconds(1_700_000_500_000)
            val updated = deviceToken.copy(lastSeenAt = newer)
            deviceTokenSyncDAO.put(updated, buildUpsertChange(updated))

            val found = deviceTokenSyncDAO.findById(scope, deviceToken.deviceTokenId)
            assertEquals(newer, found?.lastSeenAt)
        }

    @Test
    fun `GIVEN an existing device token WHEN delete THEN getByRecipientScope returns empty`() =
        runTest {
            val scope = recipientScope(newSubject())
            val deviceToken = buildDeviceToken(recipientScope = scope)
            deviceTokenSyncDAO.put(deviceToken, buildUpsertChange(deviceToken))

            deviceTokenSyncDAO.delete(scope, deviceToken.deviceTokenId, buildDeleteChange(deviceToken.deviceTokenId.id, scope))

            assertTrue(deviceTokenSyncDAO.getByRecipientScope(scope).isEmpty())
        }

    @Test
    fun `GIVEN a device token WHEN put THEN change is recorded on the recipient scope`() =
        runTest {
            val scope = recipientScope(newSubject())
            val deviceToken = buildDeviceToken(recipientScope = scope)
            val change = buildUpsertChange(deviceToken)

            deviceTokenSyncDAO.put(deviceToken, change)

            val changes = changeDAO.since(scope, null)
            assertNotNull(changes.find { it.entityId == deviceToken.deviceTokenId.id })
        }
}
