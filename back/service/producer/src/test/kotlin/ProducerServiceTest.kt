@file:OptIn(ExperimentalTime::class)

package producer

import authentication.AuthenticatedInfo
import authentication.Role
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import persistence.changes.Change
import persistence.changes.ClientMutation
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.ProducerPayload
import persistence.changes.Upsert
import persistence.dao.ProducerSyncDAO
import persistence.model.Producer
import persistence.model.ProducerPreferences
import persistence.model.ProducerRole
import persistence.model.ProducerStatus
import persistence.model.UserPreferences
import persistence.model.UserSettings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class ProducerServiceTest {
    private val producerSyncDAO = mockk<ProducerSyncDAO>()
    private val service = ProducerService(producerSyncDAO)

    private val producerAuth =
        AuthenticatedInfo(
            memberId = "producer-sub-1",
            firstName = "Alice",
            lastName = "Producer",
            email = "alice@producer.com",
            organizationId = null,
            producerAccountId = "account-1",
            roles = listOf(Role.PRODUCER),
        )

    private val ownerAuth =
        AuthenticatedInfo(
            memberId = "owner-1",
            firstName = "Owner",
            lastName = "User",
            email = "owner@example.com",
            organizationId = null,
            roles = listOf(Role.OWNER),
        )

    private fun buildProducer(
        producerId: String = "producer-sub-1",
        producerAccountId: String = "account-1",
    ): Producer {
        val now = Clock.System.now()
        return Producer(
            producerId = producerId.toId(),
            producerAccountId = producerAccountId.toId(),
            role = ProducerRole.OWNER,
            associationInstant = now,
            status = ProducerStatus.ACTIVE,
            producerPreferences =
                ProducerPreferences(
                    productionAlertsEnabled = true,
                    lastUpdatedInstant = now,
                ),
            userPreferences =
                UserPreferences(
                    emailNotificationsEnabled = true,
                    pushNotificationsEnabled = false,
                    lastUpdatedInstant = now,
                ),
            userSettings =
                UserSettings(
                    language = "fr",
                    timezone = TimeZone.of("Europe/Paris"),
                    serverId = "server-1".toId(),
                    lastUpdatedInstant = now,
                ),
        )
    }

    private fun buildMutation(producer: Producer): ClientMutation =
        ClientMutation(
            clientOpId = "op-1",
            op = Upsert(ProducerPayload(producer)),
        )

    @Test
    fun `GIVEN non-producer caller WHEN applyUpsert THEN returns FORBIDDEN`() =
        runTest {
            val producer = buildProducer()
            val mutation = buildMutation(producer)

            val outcome = service.applyUpsert(ownerAuth, mutation, ProducerPayload(producer))

            assertIs<persistence.changes.MutationOutcome>(outcome)
            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN producer updating another producer's profile WHEN applyUpsert THEN returns FORBIDDEN`() =
        runTest {
            val otherProducer = buildProducer(producerId = "other-producer-sub")
            val mutation = buildMutation(otherProducer)

            val outcome = service.applyUpsert(producerAuth, mutation, ProducerPayload(otherProducer))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
        }

    @Test
    fun `GIVEN producer WHEN applyUpsert with own producerId THEN persists and returns APPLIED`() =
        runTest {
            val producer = buildProducer()
            val mutation = buildMutation(producer)
            val changeSlot = slot<List<Change>>()
            coEvery { producerSyncDAO.findByProducerId(producer.producerId) } returns producer
            coEvery { producerSyncDAO.put(any(), capture(changeSlot)) } returns Unit

            val outcome = service.applyUpsert(producerAuth, mutation, ProducerPayload(producer))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(producer.producerId.id, outcome.serverEntityId)
            coVerify { producerSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN producer WHEN applyUpsert and producer not found THEN returns NOT_FOUND`() =
        runTest {
            val producer = buildProducer()
            val mutation = buildMutation(producer)
            coEvery { producerSyncDAO.findByProducerId(producer.producerId) } returns null

            val outcome = service.applyUpsert(producerAuth, mutation, ProducerPayload(producer))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.NOT_FOUND, outcome.error?.code)
        }

    @Test
    fun `GIVEN non-producer caller WHEN snapshot THEN returns empty`() =
        runTest {
            val result = service.snapshot(ownerAuth)
            assertEquals(emptyList(), result)
        }

    @Test
    fun `GIVEN producer with no producerAccountId enrichment WHEN snapshot THEN returns empty`() =
        runTest {
            val authWithoutAccount = producerAuth.copy(producerAccountId = null)
            val result = service.snapshot(authWithoutAccount)
            assertEquals(emptyList(), result)
        }

    @Test
    fun `GIVEN producer caller WHEN snapshot THEN returns producers for account`() =
        runTest {
            val producer = buildProducer()
            coEvery {
                producerSyncDAO.getByProducerAccountId("account-1".toId())
            } returns listOf(producer)

            val result = service.snapshot(producerAuth)

            assertEquals(listOf(ProducerPayload(producer)), result)
        }
}
