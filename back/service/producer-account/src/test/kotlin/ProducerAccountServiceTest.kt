@file:OptIn(ExperimentalTime::class)

package produceraccount

import authentication.AuthenticatedInfo
import authentication.Role
import core.UserProvisioningPort
import email.AccountLifecycleEmailPort
import email.AccountLifecycleRole
import email.OwnersBroadcastEvent
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
import persistence.changes.ProducerAccountPayload
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.dao.OrganizationSyncDAO
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.BasketSize
import persistence.model.LinkedProducerAccount
import persistence.model.Organization
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerOrganization
import persistence.model.ProducerProduct
import persistence.model.Product
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class ProducerAccountServiceTest {
    private val producerAccountSyncDAO = mockk<ProducerAccountSyncDAO>()
    private val organizationSyncDAO = mockk<OrganizationSyncDAO>(relaxed = true)
    private val userProvisioningPort = mockk<UserProvisioningPort>(relaxed = true)
    private val accountLifecycleEmailPort = mockk<AccountLifecycleEmailPort>(relaxed = true)
    private val accountDeletionLogDAO =
        mockk<persistence.dao.AccountDeletionLogDAO>(relaxed = true)
    private val service =
        ProducerAccountService(
            producerAccountSyncDAO,
            organizationSyncDAO,
            userProvisioningPort,
            accountLifecycleEmailPort,
            accountDeletionLogDAO,
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

    private val adminAuth =
        AuthenticatedInfo(
            memberId = "admin-1",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            organizationId = "org-1",
            roles = listOf(Role.ADMIN),
        )

    private fun producer(
        id: String = "pa-1",
        activeStatus: Boolean = true,
    ): ProducerAccount =
        ProducerAccount(
            producerAccountId = id.toId(),
            name = "Producer $id",
            contactEmail = "$id@example.com",
            address = null,
            website = null,
            activeStatus = activeStatus,
            createdInstant = Instant.fromEpochMilliseconds(1L),
            lastUpdatedInstant = Instant.fromEpochMilliseconds(2L),
        )

    private fun organizationLink(organizationId: String) =
        ProducerOrganization(
            organizationId = organizationId.toId(),
            associationInstant = Instant.fromEpochMilliseconds(3L),
            status = OrganizationProducerStatus.ACTIVE,
        )

    // -------------------------------------------------------------------------
    // snapshot
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN InstanceOwner scope WHEN snapshot THEN returns listAll`() =
        runTest {
            val producers = listOf(producer("pa-a"), producer("pa-b"))
            coEvery { producerAccountSyncDAO.listAll() } returns producers

            val payloads = service.snapshot(ownerAuth, SyncScope.InstanceOwner)

            assertEquals(2, payloads.size)
            assertTrue(payloads.any { it.producerAccount.producerAccountId.id == "pa-a" })
            assertTrue(payloads.any { it.producerAccount.producerAccountId.id == "pa-b" })
        }

    @Test
    fun `GIVEN Organization scope WHEN snapshot THEN delegates to getByOrganizationId via legacy snapshot`() =
        runTest {
            coEvery {
                producerAccountSyncDAO.getByOrganizationId("org-1".toId())
            } returns listOf(producer("pa-org1"))

            val payloads = service.snapshot(adminAuth, SyncScope.Organization("org-1"))

            assertEquals(1, payloads.size)
            assertEquals(
                "pa-org1",
                payloads
                    .first()
                    .producerAccount.producerAccountId.id,
            )
        }

    @Test
    fun `GIVEN ProducerAccount scope WHEN snapshot THEN returns empty list`() =
        runTest {
            val payloads =
                service.snapshot(adminAuth, SyncScope.ProducerAccount("pa-1"))
            assertTrue(payloads.isEmpty())
        }

    // -------------------------------------------------------------------------
    // suspend / reactivate (Phase 2 OWNER lifecycle)
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN unknown producer WHEN suspend THEN NotFound`() =
        runTest {
            coEvery { producerAccountSyncDAO.findById(any()) } returns null

            val result = service.suspend(actorSub = "sub-owner", producerAccountId = "pa-1")

            assertIs<ProducerLifecycleOutcome.NotFound>(result)
            coVerify(exactly = 0) { producerAccountSyncDAO.updateActiveStatus(any(), any(), any()) }
        }

    @Test
    fun `GIVEN active producer WHEN suspend THEN active_status flipped + email + broadcast`() =
        runTest {
            val producer = producer("pa-1", activeStatus = true)
            coEvery { producerAccountSyncDAO.findById(any()) } returns producer
            coEvery { producerAccountSyncDAO.updateActiveStatus(any(), any(), any()) } returns Unit

            val changesSlot = slot<List<Change>>()
            coEvery {
                producerAccountSyncDAO.updateActiveStatus(any(), any(), capture(changesSlot))
            } returns Unit

            val result = service.suspend(actorSub = "sub-owner", producerAccountId = "pa-1")

            assertIs<ProducerLifecycleOutcome.Success>(result)
            coVerify(exactly = 1) {
                producerAccountSyncDAO.updateActiveStatus(producer.producerAccountId, false, any())
            }
            coVerify(exactly = 1) { accountLifecycleEmailPort.notifyAccountSuspended(any()) }
            coVerify(exactly = 1) {
                accountLifecycleEmailPort.notifyOwnersOfLifecycleEvent(
                    event = OwnersBroadcastEvent.ACCOUNT_SUSPENDED,
                    actorOwnerEmail = any(),
                    impactedRole = AccountLifecycleRole.PRODUCER,
                )
            }
            // At minimum, one Change is fanned out on the instance-owner scope.
            assertTrue(
                changesSlot.captured.any { it.scopeKey == SyncScope.InstanceOwner.key },
            )
        }

    @Test
    fun `GIVEN already suspended producer WHEN suspend THEN idempotent (no DAO write, no email)`() =
        runTest {
            val producer = producer("pa-1", activeStatus = false)
            coEvery { producerAccountSyncDAO.findById(any()) } returns producer

            val result = service.suspend(actorSub = "sub-owner", producerAccountId = "pa-1")

            assertIs<ProducerLifecycleOutcome.Success>(result)
            coVerify(exactly = 0) { producerAccountSyncDAO.updateActiveStatus(any(), any(), any()) }
            coVerify(exactly = 0) { accountLifecycleEmailPort.notifyAccountSuspended(any()) }
        }

    @Test
    fun `GIVEN suspended producer WHEN reactivate THEN active_status flipped + email`() =
        runTest {
            val producer = producer("pa-1", activeStatus = false)
            coEvery { producerAccountSyncDAO.findById(any()) } returns producer
            coEvery { producerAccountSyncDAO.updateActiveStatus(any(), any(), any()) } returns Unit

            val result = service.reactivate(actorSub = "sub-owner", producerAccountId = "pa-1")

            assertIs<ProducerLifecycleOutcome.Success>(result)
            coVerify(exactly = 1) {
                producerAccountSyncDAO.updateActiveStatus(producer.producerAccountId, true, any())
            }
            coVerify(exactly = 1) { accountLifecycleEmailPort.notifyAccountReactivated(any()) }
        }

    // -------------------------------------------------------------------------
    // applyUpsert routing (OWNER path)
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN OWNER caller flipping active_status to false WHEN applyUpsert THEN delegates to suspend`() =
        runTest {
            val producer = producer("pa-1", activeStatus = true)
            coEvery { producerAccountSyncDAO.findById(any()) } returns producer
            coEvery { producerAccountSyncDAO.updateActiveStatus(any(), any(), any()) } returns Unit

            val payload = ProducerAccountPayload(producer.copy(activeStatus = false))
            val mutation = ClientMutation(clientOpId = "op-1", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(ownerAuth, mutation, payload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) {
                producerAccountSyncDAO.updateActiveStatus(producer.producerAccountId, false, any())
            }
        }

    @Test
    fun `GIVEN OWNER caller flipping active_status to true on missing producer WHEN applyUpsert THEN REJECTED NOT_FOUND`() =
        runTest {
            coEvery { producerAccountSyncDAO.findById(any()) } returns null

            val payload = ProducerAccountPayload(producer("pa-1", activeStatus = true))
            val mutation = ClientMutation(clientOpId = "op-2", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(ownerAuth, mutation, payload)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.NOT_FOUND, outcome.error?.code)
        }

    @Test
    fun `GIVEN ADMIN creating tmp no-account producer WHEN applyUpsert THEN real id allocated and org normalized`() =
        runTest {
            val putSlot = slot<ProducerAccount>()
            coEvery { producerAccountSyncDAO.put(capture(putSlot), any(), any()) } returns Unit

            val payload =
                ProducerAccountPayload(
                    producer("tmp_new").copy(
                        producerAccountId = "tmp_new".toId(),
                        managementMode = ProducerManagementMode.NO_ACCOUNT,
                        organizations = emptyList(),
                    ),
                )
            val mutation = ClientMutation(clientOpId = "op-create", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(adminAuth, mutation, payload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertNotEquals("tmp_new", outcome.serverEntityId)
            assertEquals(ProducerManagementMode.NO_ACCOUNT, putSlot.captured.managementMode)
            assertEquals(listOf("org-1"), putSlot.captured.organizations.map { it.organizationId.id })
        }

    @Test
    fun `GIVEN no-account producer with multiple organizations WHEN applyUpsert THEN REJECTED INVALID_PAYLOAD`() =
        runTest {
            val payload =
                ProducerAccountPayload(
                    producer("tmp_new").copy(
                        producerAccountId = "tmp_new".toId(),
                        managementMode = ProducerManagementMode.NO_ACCOUNT,
                        organizations = listOf(organizationLink("org-1"), organizationLink("org-2")),
                    ),
                )
            val mutation = ClientMutation(clientOpId = "op-invalid", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(adminAuth, mutation, payload)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_PAYLOAD, outcome.error?.code)
            coVerify(exactly = 0) { producerAccountSyncDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN existing no-account producer WHEN admin updates name THEN APPLIED`() =
        runTest {
            val existing =
                producer("pa-no-account").copy(
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations = listOf(organizationLink("org-1")),
                    products = emptyList(),
                )
            coEvery { producerAccountSyncDAO.findById(existing.producerAccountId) } returns existing
            coEvery { producerAccountSyncDAO.put(any(), any(), any()) } returns Unit

            val payload =
                ProducerAccountPayload(
                    existing.copy(
                        name = "Updated name",
                    ),
                )
            val mutation = ClientMutation(clientOpId = "op-update-no-account", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(adminAuth, mutation, payload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { producerAccountSyncDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN existing no-account producer with linked target WHEN admin links it THEN APPLIED`() =
        runTest {
            val source =
                producer("pa-source").copy(
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations = listOf(organizationLink("org-1")),
                )
            val target =
                producer("pa-target").copy(
                    name = "Account Backed Target",
                    managementMode = ProducerManagementMode.ACCOUNT_BACKED,
                )
            coEvery { producerAccountSyncDAO.findById("pa-source".toId()) } returns source
            coEvery { producerAccountSyncDAO.findById("pa-target".toId()) } returns target
            coEvery { producerAccountSyncDAO.getByOrganizationId("org-1".toId()) } returns listOf(source)

            val putSlot = slot<ProducerAccount>()
            coEvery { producerAccountSyncDAO.put(capture(putSlot), any(), any()) } returns Unit

            val payload =
                ProducerAccountPayload(
                    source.copy(
                        linkedProducerAccount =
                            LinkedProducerAccount(
                                producerAccountId = target.producerAccountId,
                                name = "Account Backed Target",
                            ),
                    ),
                )
            val mutation = ClientMutation(clientOpId = "op-link", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(adminAuth, mutation, payload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { producerAccountSyncDAO.put(any(), any(), any()) }
        }

    @Test
    fun `GIVEN existing no-account producer linking to already used target WHEN admin updates it THEN REJECTED CONFLICT`() =
        runTest {
            val source =
                producer("pa-source").copy(
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations = listOf(organizationLink("org-1")),
                )
            val conflictingSource =
                producer("pa-source-2").copy(
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations = listOf(organizationLink("org-1")),
                    linkedProducerAccount = LinkedProducerAccount("pa-target".toId(), "Account Backed Target"),
                )
            val target =
                producer("pa-target").copy(
                    managementMode = ProducerManagementMode.ACCOUNT_BACKED,
                )
            coEvery { producerAccountSyncDAO.findById("pa-source".toId()) } returns source
            coEvery { producerAccountSyncDAO.findById("pa-target".toId()) } returns target
            coEvery { producerAccountSyncDAO.getByOrganizationId("org-1".toId()) } returns listOf(source, conflictingSource)

            val payload =
                ProducerAccountPayload(
                    source.copy(
                        linkedProducerAccount = LinkedProducerAccount("pa-target".toId(), "ignored"),
                    ),
                )
            val mutation = ClientMutation(clientOpId = "op-link-conflict", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(adminAuth, mutation, payload)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
            coVerify(exactly = 0) { producerAccountSyncDAO.put(any(), any(), any()) }
        }

    // -------------------------------------------------------------------------
    // delete (Phase 2.5)
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN unknown producer WHEN delete THEN NotFound`() =
        runTest {
            coEvery { producerAccountSyncDAO.findById(any()) } returns null

            val result = service.delete(actorSub = "sub-owner", producerAccountId = "pa-1")

            assertIs<ProducerLifecycleOutcome.NotFound>(result)
            coVerify(exactly = 0) { userProvisioningPort.deleteUser(any()) }
            coVerify(exactly = 0) { accountDeletionLogDAO.append(any()) }
        }

    @Test
    fun `GIVEN producer with linked auth users WHEN delete THEN each auth user deleted + audit appended + active flipped`() =
        runTest {
            val producer = producer("pa-1", activeStatus = true)
            coEvery { producerAccountSyncDAO.findById(any()) } returns producer
            coEvery { userProvisioningPort.listAuthSubsByProducerAccount("pa-1") } returns
                listOf("sub-p1", "sub-p2")
            coEvery { producerAccountSyncDAO.updateActiveStatus(any(), any(), any()) } returns Unit

            val auditEntries = mutableListOf<persistence.model.AccountDeletionLog>()
            coEvery { accountDeletionLogDAO.append(capture(auditEntries)) } returns Unit

            val result = service.delete(actorSub = "sub-owner", producerAccountId = "pa-1")

            assertIs<ProducerLifecycleOutcome.Success>(result)
            coVerify(exactly = 1) { userProvisioningPort.deleteUser("sub-p1") }
            coVerify(exactly = 1) { userProvisioningPort.deleteUser("sub-p2") }
            assertEquals(2, auditEntries.size)
            assertTrue(auditEntries.all { it.deletedRole == persistence.model.DeletedAccountRole.PRODUCER })
            coVerify(exactly = 1) {
                producerAccountSyncDAO.updateActiveStatus(producer.producerAccountId, false, any())
            }
            coVerify(exactly = 1) { accountLifecycleEmailPort.notifyAccountDeleted(any()) }
        }

    @Test
    fun `GIVEN producer with no auth user WHEN delete THEN one audit entry written and active flipped`() =
        runTest {
            val producer = producer("pa-1", activeStatus = true)
            coEvery { producerAccountSyncDAO.findById(any()) } returns producer
            coEvery { userProvisioningPort.listAuthSubsByProducerAccount("pa-1") } returns emptyList()
            coEvery { producerAccountSyncDAO.updateActiveStatus(any(), any(), any()) } returns Unit

            val auditEntries = mutableListOf<persistence.model.AccountDeletionLog>()
            coEvery { accountDeletionLogDAO.append(capture(auditEntries)) } returns Unit

            val result = service.delete(actorSub = "sub-owner", producerAccountId = "pa-1")

            assertIs<ProducerLifecycleOutcome.Success>(result)
            coVerify(exactly = 0) { userProvisioningPort.deleteUser(any()) }
            assertEquals(1, auditEntries.size)
            assertEquals(persistence.model.DeletedAccountRole.PRODUCER, auditEntries.single().deletedRole)
        }

    @Test
    fun `GIVEN already inactive producer WHEN delete THEN active_status NOT re-written (idempotent)`() =
        runTest {
            val producer = producer("pa-1", activeStatus = false)
            coEvery { producerAccountSyncDAO.findById(any()) } returns producer
            coEvery { userProvisioningPort.listAuthSubsByProducerAccount("pa-1") } returns emptyList()

            val result = service.delete(actorSub = "sub-owner", producerAccountId = "pa-1")

            assertIs<ProducerLifecycleOutcome.Success>(result)
            coVerify(exactly = 0) { producerAccountSyncDAO.updateActiveStatus(any(), any(), any()) }
        }

    @Test
    fun `GIVEN OWNER caller WHEN applyDelete THEN routes to delete`() =
        runTest {
            val producer = producer("pa-1", activeStatus = true)
            coEvery { producerAccountSyncDAO.findById(any()) } returns producer
            coEvery { userProvisioningPort.listAuthSubsByProducerAccount(any()) } returns emptyList()
            coEvery { producerAccountSyncDAO.updateActiveStatus(any(), any(), any()) } returns Unit

            val op =
                persistence.changes.Delete(
                    entityType = persistence.model.EntityType.ProducerAccount,
                    entityId = "pa-1",
                )
            val mutation = ClientMutation(clientOpId = "op-del", op = op)

            val outcome = service.applyDelete(ownerAuth, mutation, op)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) {
                producerAccountSyncDAO.updateActiveStatus(producer.producerAccountId, false, any())
            }
        }

    // -------------------------------------------------------------------------
    // updateProfile
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN producer account not found WHEN updateProfile THEN NotFound`() =
        runTest {
            coEvery { producerAccountSyncDAO.findById(any()) } returns null

            val result =
                service.updateProfile(
                    producerAccountId = "pa-1",
                    update = ProducerAccountProfileUpdate("New Name", null, null, null),
                )

            assertIs<ProducerLifecycleOutcome.NotFound>(result)
            coVerify(exactly = 0) { producerAccountSyncDAO.updateProfile(any(), any()) }
        }

    @Test
    fun `GIVEN producer exists WHEN updateProfile THEN Success and profile fields updated`() =
        runTest {
            val producer = producer("pa-1", activeStatus = true)
            val updatedSlot = slot<ProducerAccount>()
            coEvery { producerAccountSyncDAO.findById(any()) } returns producer
            coEvery { producerAccountSyncDAO.updateProfile(capture(updatedSlot), any()) } returns Unit

            val result =
                service.updateProfile(
                    producerAccountId = "pa-1",
                    update =
                        ProducerAccountProfileUpdate(
                            name = "Updated Farm",
                            contactEmail = "farm@example.com",
                            address = "12 rue des Champs",
                            website = "https://farm.example.com",
                        ),
                )

            assertIs<ProducerLifecycleOutcome.Success>(result)
            coVerify(exactly = 1) { producerAccountSyncDAO.updateProfile(any(), any()) }
            assertEquals("Updated Farm", updatedSlot.captured.name)
            assertEquals("farm@example.com", updatedSlot.captured.contactEmail)
            assertEquals("12 rue des Champs", updatedSlot.captured.address)
            assertEquals("https://farm.example.com", updatedSlot.captured.website)
            // activeStatus must be unchanged
            assertEquals(producer.activeStatus, updatedSlot.captured.activeStatus)
            // lastUpdatedInstant must be bumped
            assert(updatedSlot.captured.lastUpdatedInstant > producer.lastUpdatedInstant)
        }

    @Test
    fun `GIVEN producer exists WHEN updateProfile with null optional fields THEN nulls persisted`() =
        runTest {
            val producer = producer("pa-1").copy(contactEmail = "old@example.com", address = "old address")
            val updatedSlot = slot<ProducerAccount>()
            coEvery { producerAccountSyncDAO.findById(any()) } returns producer
            coEvery { producerAccountSyncDAO.updateProfile(capture(updatedSlot), any()) } returns Unit

            service.updateProfile(
                producerAccountId = "pa-1",
                update = ProducerAccountProfileUpdate("New Name", null, null, null),
            )

            assertEquals(null, updatedSlot.captured.contactEmail)
            assertEquals(null, updatedSlot.captured.address)
            assertEquals(null, updatedSlot.captured.website)
        }

    // -------------------------------------------------------------------------
    // applyUpsert routing (PRODUCER self-profile path)
    // -------------------------------------------------------------------------

    private val producerAuth =
        AuthenticatedInfo(
            memberId = "producer-sub-123",
            firstName = "Producer",
            lastName = "User",
            email = "producer@example.com",
            organizationId = null,
            roles = listOf(Role.PRODUCER),
        )

    @Test
    fun `GIVEN PRODUCER caller WHEN sync upsert with own profile THEN profile updated`() =
        runTest {
            val producer =
                producer("producer-sub-123").copy(
                    producerAccountId = "producer-sub-123".toId(),
                )
            val updatedSlot = slot<ProducerAccount>()
            coEvery { producerAccountSyncDAO.findById("producer-sub-123".toId()) } returns producer
            coEvery { producerAccountSyncDAO.updateProfile(capture(updatedSlot), any()) } returns Unit

            val updatedProducer = producer.copy(name = "New Farm Name", contactEmail = "new@farm.com")
            val payload = ProducerAccountPayload(updatedProducer)
            val mutation = ClientMutation(clientOpId = "op-producer-self", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(producerAuth, mutation, payload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { producerAccountSyncDAO.updateProfile(any(), any()) }
            assertEquals("New Farm Name", updatedSlot.captured.name)
        }

    @Test
    fun `GIVEN PRODUCER caller WHEN sync upsert with different producerAccountId THEN FORBIDDEN`() =
        runTest {
            val otherProducer = producer("other-producer-id")
            val payload = ProducerAccountPayload(otherProducer)
            val mutation = ClientMutation(clientOpId = "op-producer-other", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(producerAuth, mutation, payload)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { producerAccountSyncDAO.updateProfile(any(), any()) }
            coVerify(exactly = 0) { producerAccountSyncDAO.findById(any()) }
        }

    @Test
    fun `GIVEN PRODUCER caller WHEN sync upsert with own id but account not found THEN NOT_FOUND`() =
        runTest {
            coEvery { producerAccountSyncDAO.findById("producer-sub-123".toId()) } returns null

            val producer =
                producer("producer-sub-123").copy(
                    producerAccountId = "producer-sub-123".toId(),
                )
            val payload = ProducerAccountPayload(producer)
            val mutation = ClientMutation(clientOpId = "op-producer-not-found", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(producerAuth, mutation, payload)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.NOT_FOUND, outcome.error?.code)
        }

    // -------------------------------------------------------------------------
    // deriveOrganizationProducts — NO_ACCOUNT product derivation
    // -------------------------------------------------------------------------

    private fun buildOrg(
        id: String = "org-1",
        products: List<Product> = emptyList(),
    ): Organization =
        Organization(
            organizationId = id.toId(),
            name = "AMAP Test",
            contactEmail = "contact@example.com",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            createdInstant = Instant.fromEpochMilliseconds(1L),
            lastUpdatedInstant = Instant.fromEpochMilliseconds(2L),
            products = products,
        )

    @Test
    fun `GIVEN admin upserts NO_ACCOUNT producer with products WHEN applyUpsert THEN organization products derived from ProducerAccount`() =
        runTest {
            val productTypeId = "pt-1"
            val existingNoAccountProducer =
                producer("pa-no-account").copy(
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations = listOf(organizationLink("org-1")),
                    products =
                        listOf(
                            ProducerProduct(
                                name = "Vegetables",
                                productTypeId = productTypeId.toId(),
                                supportedBasketSizes = listOf(BasketSize("small")),
                                description = "Fresh vegetables",
                            ),
                        ),
                )
            val currentOrg = buildOrg(products = emptyList())

            coEvery { producerAccountSyncDAO.findById(existingNoAccountProducer.producerAccountId) } returns existingNoAccountProducer
            coEvery { producerAccountSyncDAO.put(any(), any(), any()) } returns Unit
            coEvery { organizationSyncDAO.getById("org-1".toId()) } returns currentOrg

            val orgSlot = io.mockk.slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(orgSlot), any()) } returns Unit

            val updatedProducer = existingNoAccountProducer.copy(name = "Vegetables Farm")
            val payload = ProducerAccountPayload(updatedProducer)
            val mutation = ClientMutation(clientOpId = "op-derive", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(adminAuth, mutation, payload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            // organizationSyncDAO.put must have been called to derive products
            coVerify(exactly = 1) { organizationSyncDAO.put(any(), any()) }
            // The derived org product must match the ProducerAccount product
            val storedProducts = orgSlot.captured.products
            assertEquals(1, storedProducts.size)
            val storedProduct = storedProducts.single()
            assertEquals("Vegetables", storedProduct.name)
            assertEquals(productTypeId, storedProduct.productTypeId.id)
            assertEquals(existingNoAccountProducer.producerAccountId, storedProduct.producerAccountId)
            assertEquals("Fresh vegetables", storedProduct.description)
        }

    @Test
    fun `GIVEN admin upserts NO_ACCOUNT producer with products WHEN org not found THEN org derivation skipped gracefully`() =
        runTest {
            val existingNoAccountProducer =
                producer("pa-no-account").copy(
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations = listOf(organizationLink("org-1")),
                    products =
                        listOf(
                            ProducerProduct(
                                name = "Carrots",
                                productTypeId = "pt-carrot".toId(),
                                supportedBasketSizes = listOf(BasketSize("large")),
                            ),
                        ),
                )

            coEvery { producerAccountSyncDAO.findById(existingNoAccountProducer.producerAccountId) } returns existingNoAccountProducer
            coEvery { producerAccountSyncDAO.put(any(), any(), any()) } returns Unit
            coEvery { organizationSyncDAO.getById("org-1".toId()) } returns null

            val payload = ProducerAccountPayload(existingNoAccountProducer)
            val mutation = ClientMutation(clientOpId = "op-derive-no-org", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(adminAuth, mutation, payload)

            // Org not found: derivation is skipped, upsert succeeds
            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 0) { organizationSyncDAO.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin upserts NO_ACCOUNT producer removing all products WHEN applyUpsert THEN org products for that producer cleared`() =
        runTest {
            val existingProduct =
                Product(
                    name = "Old Vegetables",
                    productTypeId = "pt-old".toId(),
                    producerAccountId = "pa-no-account".toId(),
                    supportedBasketSizes = listOf(BasketSize("small")),
                )
            val currentOrg = buildOrg(products = listOf(existingProduct))

            val existingNoAccountProducer =
                producer("pa-no-account").copy(
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations = listOf(organizationLink("org-1")),
                    products = emptyList(), // all products removed
                )

            coEvery { producerAccountSyncDAO.findById(existingNoAccountProducer.producerAccountId) } returns existingNoAccountProducer
            coEvery { producerAccountSyncDAO.put(any(), any(), any()) } returns Unit
            coEvery { organizationSyncDAO.getById("org-1".toId()) } returns currentOrg

            val orgSlot = io.mockk.slot<Organization>()
            coEvery { organizationSyncDAO.put(capture(orgSlot), any()) } returns Unit

            val payload = ProducerAccountPayload(existingNoAccountProducer)
            val mutation = ClientMutation(clientOpId = "op-clear-products", op = Upsert(payload = payload))

            val outcome = service.applyUpsert(adminAuth, mutation, payload)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { organizationSyncDAO.put(any(), any()) }
            assertTrue(orgSlot.captured.products.isEmpty())
        }
}
