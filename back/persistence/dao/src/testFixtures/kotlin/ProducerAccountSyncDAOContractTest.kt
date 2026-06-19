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
import persistence.changes.ProducerAccountPayload
import persistence.changes.SyncScope
import persistence.model.BasketSize
import persistence.model.EntityType
import persistence.model.LinkedProducerAccount
import persistence.model.Organization
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerOrganization
import persistence.model.ProducerProduct
import persistence.model.ProductType
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Execution(ExecutionMode.SAME_THREAD)
abstract class ProducerAccountSyncDAOContractTest {
    protected abstract val producerAccountSyncDAO: ProducerAccountSyncDAO
    protected abstract val changeDAO: ChangeDAO

    /** Pre-insert the organization row so FK constraints are satisfied. */
    protected abstract fun insertOrganization(organizationId: String)

    protected fun newOrganizationId() = UUID.randomUUID().toString()

    protected fun buildProducerAccount(producerAccountId: String = UUID.randomUUID().toString()): ProducerAccount =
        ProducerAccount(
            producerAccountId = producerAccountId.toId(),
            name = "Producer $producerAccountId",
            contactEmail = "producer-$producerAccountId@example.com",
            address = null,
            website = null,
            activeStatus = true,
            createdInstant = Instant.fromEpochMilliseconds(1_000_000L),
            lastUpdatedInstant = Instant.fromEpochMilliseconds(2_000_000L),
            organizations = emptyList(),
        )

    protected fun buildUpsertChange(
        producer: ProducerAccount,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.ProducerAccount,
            entityId = producer.producerAccountId.id,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.UPSERT,
            payload = ProducerAccountPayload(producer),
            producedAt = System.currentTimeMillis(),
        )

    protected fun buildDeleteChange(
        producerAccountId: String,
        organizationId: String,
    ): Change =
        Change(
            cursor = Cursor.next(),
            entityType = EntityType.ProducerAccount,
            entityId = producerAccountId,
            scopeKey = SyncScope.Organization(organizationId).key,
            op = ChangeOp.DELETE,
            payload = null,
            producedAt = System.currentTimeMillis(),
        )

    @Test
    fun `GIVEN a producer WHEN put then getByOrganizationId THEN returns it`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer = buildProducerAccount()

            producerAccountSyncDAO.put(producer, orgId.toId<Organization>(), listOf(buildUpsertChange(producer, orgId)))

            val result = producerAccountSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            assertEquals(producer.producerAccountId, result.first().producerAccountId)
        }

    @Test
    fun `GIVEN no producers WHEN getByOrganizationId THEN returns empty list`() =
        runTest {
            val result = producerAccountSyncDAO.getByOrganizationId(newOrganizationId().toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN multiple producers for same organization WHEN put THEN getByOrganizationId returns all`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer1 = buildProducerAccount()
            val producer2 = buildProducerAccount()

            producerAccountSyncDAO.put(producer1, orgId.toId<Organization>(), listOf(buildUpsertChange(producer1, orgId)))
            producerAccountSyncDAO.put(producer2, orgId.toId<Organization>(), listOf(buildUpsertChange(producer2, orgId)))

            val result = producerAccountSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(2, result.size)
            assertTrue(result.any { it.producerAccountId == producer1.producerAccountId })
            assertTrue(result.any { it.producerAccountId == producer2.producerAccountId })
        }

    @Test
    fun `GIVEN producers for two organizations WHEN getByOrganizationId THEN returns only the right ones`() =
        runTest {
            val orgA = newOrganizationId()
            val orgB = newOrganizationId()
            insertOrganization(orgA)
            insertOrganization(orgB)
            val producerA = buildProducerAccount()
            val producerB = buildProducerAccount()

            producerAccountSyncDAO.put(producerA, orgA.toId<Organization>(), listOf(buildUpsertChange(producerA, orgA)))
            producerAccountSyncDAO.put(producerB, orgB.toId<Organization>(), listOf(buildUpsertChange(producerB, orgB)))

            val result = producerAccountSyncDAO.getByOrganizationId(orgA.toId())
            assertEquals(1, result.size)
            assertEquals(producerA.producerAccountId, result.first().producerAccountId)
        }

    @Test
    fun `GIVEN an existing producer WHEN delete THEN getByOrganizationId returns empty`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer = buildProducerAccount()
            producerAccountSyncDAO.put(producer, orgId.toId<Organization>(), listOf(buildUpsertChange(producer, orgId)))

            producerAccountSyncDAO.delete(
                producer.producerAccountId,
                orgId.toId(),
                listOf(buildDeleteChange(producer.producerAccountId.id, orgId)),
            )

            val result = producerAccountSyncDAO.getByOrganizationId(orgId.toId())
            assertTrue(result.isEmpty())
        }

    @Test
    fun `GIVEN a producer WHEN put THEN change is recorded`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer = buildProducerAccount()
            val change = buildUpsertChange(producer, orgId)

            producerAccountSyncDAO.put(producer, orgId.toId<Organization>(), listOf(change))

            val changes = changeDAO.since(SyncScope.Organization(orgId).key, null)
            assertNotNull(changes.find { it.entityId == producer.producerAccountId.id })
        }

    @Test
    fun `GIVEN a producer WHEN put then getByOrganizationId THEN name is correct`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer = buildProducerAccount().copy(name = "Fermier Bio")

            producerAccountSyncDAO.put(producer, orgId.toId<Organization>(), listOf(buildUpsertChange(producer, orgId)))

            val result = producerAccountSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals("Fermier Bio", result.first().name)
        }

    @Test
    fun `GIVEN org and producer account WHEN createInitial THEN getByOrganizationId returns the account`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer = buildProducerAccount()

            producerAccountSyncDAO.createInitial(producer, orgId.toId())

            val result = producerAccountSyncDAO.getByOrganizationId(orgId.toId())
            assertEquals(1, result.size)
            assertEquals(producer.producerAccountId, result.first().producerAccountId)
            assertEquals(producer.name, result.first().name)
        }

    @Test
    fun `GIVEN standalone producer WHEN createStandalone THEN findById and listAll return it`() =
        runTest {
            val producer = buildProducerAccount()

            producerAccountSyncDAO.createStandalone(producer)

            val found = producerAccountSyncDAO.findById(producer.producerAccountId)
            assertNotNull(found)
            assertEquals(producer.producerAccountId, found.producerAccountId)
            assertTrue(producerAccountSyncDAO.listAll().any { it.producerAccountId == producer.producerAccountId })
        }

    @Test
    fun `GIVEN standalone producer WHEN search THEN it is returned for unrelated organizations`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer = buildProducerAccount().copy(name = "Standalone Producer")

            producerAccountSyncDAO.createStandalone(producer)

            val result = producerAccountSyncDAO.search(orgId.toId(), "standalone")
            assertTrue(result.any { it.producerAccountId == producer.producerAccountId })
        }

    @Test
    fun `GIVEN no-account producer WHEN search THEN it is excluded from candidates`() =
        runTest {
            val orgId = newOrganizationId()
            val otherOrgId = newOrganizationId()
            insertOrganization(orgId)
            insertOrganization(otherOrgId)
            val producer =
                buildProducerAccount().copy(
                    name = "No Account Producer",
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations =
                        listOf(
                            ProducerOrganization(
                                otherOrgId.toId(),
                                Instant.fromEpochMilliseconds(1_000_000L),
                                OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                )

            producerAccountSyncDAO.put(producer, otherOrgId.toId(), listOf(buildUpsertChange(producer, otherOrgId)))

            val result = producerAccountSyncDAO.search(orgId.toId(), "account")
            assertTrue(result.none { it.producerAccountId == producer.producerAccountId })
        }

    @Test
    fun `GIVEN producers with various statuses WHEN search THEN returns only active unassociated ones matching query`() =
        runTest {
            val orgId = newOrganizationId()
            val otherOrgId = newOrganizationId()
            insertOrganization(orgId)
            insertOrganization(otherOrgId)

            // Active producer already associated with the org under test — must be excluded
            val associated = buildProducerAccount().copy(name = "Ferme Dupont")
            producerAccountSyncDAO.put(associated, orgId.toId<Organization>(), listOf(buildUpsertChange(associated, orgId)))

            // Active producer associated only with another org — must appear in search results
            val available = buildProducerAccount().copy(name = "Ferme Martin")
            producerAccountSyncDAO.put(available, otherOrgId.toId<Organization>(), listOf(buildUpsertChange(available, otherOrgId)))

            val result = producerAccountSyncDAO.search(orgId.toId(), "ferme")

            assertTrue(result.none { it.producerAccountId == associated.producerAccountId })
            assertTrue(result.any { it.producerAccountId == available.producerAccountId })
        }

    @Test
    fun `GIVEN account-backed producer already linked from same organization WHEN search THEN it is excluded`() =
        runTest {
            val orgId = newOrganizationId()
            val otherOrgId = newOrganizationId()
            insertOrganization(orgId)
            insertOrganization(otherOrgId)

            val target = buildProducerAccount().copy(name = "Ferme Linkable")
            producerAccountSyncDAO.put(target, otherOrgId.toId(), listOf(buildUpsertChange(target, otherOrgId)))

            val source =
                buildProducerAccount().copy(
                    name = "No Account Source",
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations =
                        listOf(
                            ProducerOrganization(
                                orgId.toId(),
                                Instant.fromEpochMilliseconds(1_000_000L),
                                OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                    linkedProducerAccount =
                        LinkedProducerAccount(
                            producerAccountId = target.producerAccountId,
                            name = target.name,
                        ),
                )
            producerAccountSyncDAO.put(source, orgId.toId(), listOf(buildUpsertChange(source, orgId)))

            val result = producerAccountSyncDAO.search(orgId.toId(), "ferme")

            assertTrue(result.none { it.producerAccountId == target.producerAccountId })
        }

    @Test
    fun `GIVEN a producer WHEN findById THEN returns it`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer = buildProducerAccount()
            producerAccountSyncDAO.put(producer, orgId.toId<Organization>(), listOf(buildUpsertChange(producer, orgId)))

            val found = producerAccountSyncDAO.findById(producer.producerAccountId)
            assertNotNull(found)
            assertEquals(producer.producerAccountId, found.producerAccountId)
        }

    @Test
    fun `GIVEN no producer with this id WHEN findById THEN returns null`() =
        runTest {
            val result =
                producerAccountSyncDAO.findById(
                    java.util.UUID
                        .randomUUID()
                        .toString()
                        .toId(),
                )
            assertEquals(null, result)
        }

    @Test
    fun `GIVEN an active producer WHEN updateActiveStatus(false) THEN findById returns suspended`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer = buildProducerAccount()
            producerAccountSyncDAO.put(producer, orgId.toId<Organization>(), listOf(buildUpsertChange(producer, orgId)))

            val tombstone =
                Change(
                    cursor = Cursor.next(),
                    entityType = EntityType.ProducerAccount,
                    entityId = producer.producerAccountId.id,
                    scopeKey = SyncScope.InstanceOwner.key,
                    op = ChangeOp.UPSERT,
                    payload = ProducerAccountPayload(producer.copy(activeStatus = false)),
                    producedAt = System.currentTimeMillis(),
                )
            producerAccountSyncDAO.updateActiveStatus(
                producer.producerAccountId,
                activeStatus = false,
                changes = listOf(tombstone),
            )

            val found = producerAccountSyncDAO.findById(producer.producerAccountId)
            assertNotNull(found)
            assertEquals(false, found.activeStatus)
        }

    @Test
    fun `GIVEN producers across multiple organizations WHEN listAll THEN returns every distinct producer`() =
        runTest {
            val orgA = newOrganizationId()
            val orgB = newOrganizationId()
            insertOrganization(orgA)
            insertOrganization(orgB)
            val producerA = buildProducerAccount()
            val producerB = buildProducerAccount()

            producerAccountSyncDAO.put(producerA, orgA.toId<Organization>(), listOf(buildUpsertChange(producerA, orgA)))
            producerAccountSyncDAO.put(producerB, orgB.toId<Organization>(), listOf(buildUpsertChange(producerB, orgB)))

            val all = producerAccountSyncDAO.listAll()
            assertTrue(all.any { it.producerAccountId == producerA.producerAccountId })
            assertTrue(all.any { it.producerAccountId == producerB.producerAccountId })
        }

    @Test
    fun `GIVEN a producer visible in two organizations WHEN put THEN both organization scopes receive a change`() =
        runTest {
            val orgA = newOrganizationId()
            val orgB = newOrganizationId()
            insertOrganization(orgA)
            insertOrganization(orgB)
            val producer =
                buildProducerAccount().copy(
                    organizations =
                        listOf(
                            ProducerOrganization(orgA.toId(), Instant.fromEpochMilliseconds(1_000_000L), OrganizationProducerStatus.ACTIVE),
                            ProducerOrganization(orgB.toId(), Instant.fromEpochMilliseconds(1_000_000L), OrganizationProducerStatus.ACTIVE),
                        ),
                )

            producerAccountSyncDAO.put(
                producer,
                orgA.toId(),
                listOf(buildUpsertChange(producer, orgA), buildUpsertChange(producer, orgB)),
            )

            assertTrue(changeDAO.since(SyncScope.Organization(orgA).key, null).any { it.entityId == producer.producerAccountId.id })
            assertTrue(changeDAO.since(SyncScope.Organization(orgB).key, null).any { it.entityId == producer.producerAccountId.id })
        }

    @Test
    fun `GIVEN no-account producer with products WHEN put THEN products are returned by getByOrganizationId`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer =
                buildProducerAccount().copy(
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations =
                        listOf(
                            ProducerOrganization(
                                orgId.toId(),
                                Instant.fromEpochMilliseconds(1_000_000L),
                                OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                    products =
                        listOf(
                            ProducerProduct(
                                name = "Pommes",
                                productTypeId = "pt-pommes".toId<ProductType>(),
                                supportedBasketSizes = listOf(BasketSize("1 kg")),
                                description = null,
                            ),
                        ),
                )

            producerAccountSyncDAO.put(producer, orgId.toId(), listOf(buildUpsertChange(producer, orgId)))

            val result = producerAccountSyncDAO.getByOrganizationId(orgId.toId())
            val stored = result.single { it.producerAccountId == producer.producerAccountId }
            assertEquals(1, stored.products.size)
            assertEquals("Pommes", stored.products.single().name)
        }

    @Test
    fun `GIVEN no-account producer with products WHEN put twice THEN products are updated not duplicated`() =
        runTest {
            val orgId = newOrganizationId()
            insertOrganization(orgId)
            val producer =
                buildProducerAccount().copy(
                    managementMode = ProducerManagementMode.NO_ACCOUNT,
                    organizations =
                        listOf(
                            ProducerOrganization(
                                orgId.toId(),
                                Instant.fromEpochMilliseconds(1_000_000L),
                                OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                    products =
                        listOf(
                            ProducerProduct(
                                name = "Pommes",
                                productTypeId = "pt-pommes".toId<ProductType>(),
                                supportedBasketSizes = listOf(BasketSize("1 kg")),
                                description = null,
                            ),
                        ),
                )

            producerAccountSyncDAO.put(producer, orgId.toId(), listOf(buildUpsertChange(producer, orgId)))

            val updated =
                producer.copy(
                    products =
                        listOf(
                            ProducerProduct(
                                name = "Pommes Bio",
                                productTypeId = "pt-pommes".toId<ProductType>(),
                                supportedBasketSizes = listOf(BasketSize("1 kg"), BasketSize("2 kg")),
                                description = "Variété ancienne",
                            ),
                            ProducerProduct(
                                name = "Jus de pomme",
                                productTypeId = "pt-jus".toId<ProductType>(),
                                supportedBasketSizes = listOf(BasketSize("1 L")),
                                description = null,
                            ),
                        ),
                )
            producerAccountSyncDAO.put(updated, orgId.toId(), listOf(buildUpsertChange(updated, orgId)))

            val result = producerAccountSyncDAO.getByOrganizationId(orgId.toId())
            val stored = result.single { it.producerAccountId == producer.producerAccountId }
            assertEquals(2, stored.products.size)
            val apple = stored.products.single { it.productTypeId == "pt-pommes".toId<ProductType>() }
            assertEquals("Pommes Bio", apple.name)
            assertEquals("Variété ancienne", apple.description)
            assertEquals(2, apple.supportedBasketSizes.size)
        }
}
