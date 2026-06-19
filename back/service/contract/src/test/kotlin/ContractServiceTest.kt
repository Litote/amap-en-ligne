@file:OptIn(ExperimentalTime::class)

package contract

import authentication.AuthenticatedInfo
import authentication.Role
import id.Id
import id.toId
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.minus
import kotlinx.datetime.todayIn
import persistence.changes.ClientMutation
import persistence.changes.ContractPayload
import persistence.changes.Delete
import persistence.changes.MutationErrorCode
import persistence.changes.MutationStatus
import persistence.changes.Upsert
import persistence.dao.ContractSyncDAO
import persistence.dao.OrganizationSyncDAO
import persistence.model.BasketSize
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.ContractStatus
import persistence.model.Delivery
import persistence.model.EntityType
import persistence.model.MemberContractStatus
import persistence.model.MemberSubscription
import persistence.model.ProductPrice
import persistence.model.SharedBasket
import persistence.model.pickerFor
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

internal class ContractServiceTest {
    private val organizationId = "org-1"
    private val contractId = "contract-1"
    private val adminAuth =
        AuthenticatedInfo(
            memberId = "caller-1",
            firstName = "Admin",
            lastName = "User",
            email = "admin@example.com",
            organizationId = organizationId,
            roles = listOf(Role.ADMIN),
        )
    private val volunteerAuth =
        AuthenticatedInfo(
            memberId = "caller-2",
            firstName = "Volunteer",
            lastName = "User",
            email = "volunteer@example.com",
            organizationId = organizationId,
            roles = listOf(Role.VOLUNTEER),
        )
    private val noOrgAuth =
        AuthenticatedInfo(
            memberId = "caller-3",
            firstName = "No",
            lastName = "Org",
            email = "noorg@example.com",
            organizationId = null,
            roles = listOf(Role.ADMIN),
        )

    private fun buildContract(
        id: String = contractId,
        orgId: String = organizationId,
        maxDeliveryDate: LocalDate = LocalDate(2025, 12, 31),
        name: String = "Contrat printemps 2025",
        productPrices: List<ProductPrice> =
            listOf(
                ProductPrice(productTypeId = "pt-tomato", basketSize = null),
                ProductPrice(productTypeId = "pt-eggs", basketSize = null),
            ),
    ): Contract =
        Contract(
            contractId = id.toId(),
            name = name,
            organizationId = orgId.toId(),
            producerAccountId = "producer-1".toId(),
            minDeliveryDate = LocalDate(2025, 1, 1),
            maxDeliveryDate = maxDeliveryDate,
            deliveryCount = 20,
            seasonYear = 2025,
            productPrices = productPrices,
        )

    private fun buildService(
        dao: ContractSyncDAO,
        orgDAO: OrganizationSyncDAO = mockk(relaxed = true),
    ): ContractService = ContractService(dao, orgDAO)

    private fun buildMutation(contract: Contract): ClientMutation =
        ClientMutation(
            clientOpId = "op-1",
            op = Upsert(ContractPayload(contract)),
        )

    @Test
    fun `GIVEN volunteer caller WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract = buildContract()

            val outcome = service.applyUpsert(volunteerAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN volunteer caller WHEN delete THEN REJECTED FORBIDDEN`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val op = Delete(EntityType.Contract, contractId)
            val mutation = ClientMutation(clientOpId = "op-del", op = op)

            val outcome = service.applyDelete(volunteerAuth, mutation, op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.delete(any(), any(), any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN upsert THEN APPLIED`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract = buildContract()
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(contractId, outcome.serverEntityId)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN admin caller WHEN delete THEN APPLIED`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val op = Delete(EntityType.Contract, contractId)
            val mutation = ClientMutation(clientOpId = "op-del", op = op)
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()
            coEvery { dao.delete(any(), any(), any()) } returns Unit

            val outcome = service.applyDelete(adminAuth, mutation, op)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(contractId, outcome.serverEntityId)
            coVerify(exactly = 1) { dao.delete(any(), any(), any()) }
        }

    @Test
    fun `GIVEN contract with active members WHEN delete THEN REJECTED CONFLICT`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val op = Delete(EntityType.Contract, contractId)
            val mutation = ClientMutation(clientOpId = "op-del", op = op)
            val contractWithMembers =
                buildContract().copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "member-1".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                                subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns listOf(contractWithMembers)

            val outcome = service.applyDelete(adminAuth, mutation, op)

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONFLICT, outcome.error?.code)
            coVerify(exactly = 0) { dao.delete(any(), any(), any()) }
        }

    @Test
    fun `GIVEN contract with only cancelled members WHEN delete THEN APPLIED`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val op = Delete(EntityType.Contract, contractId)
            val mutation = ClientMutation(clientOpId = "op-del", op = op)
            val contractWithCancelledMembers =
                buildContract().copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "member-1".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.CANCELLED,
                                subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns listOf(contractWithCancelledMembers)
            coEvery { dao.delete(any(), any(), any()) } returns Unit

            val outcome = service.applyDelete(adminAuth, mutation, op)

            assertEquals(MutationStatus.APPLIED, outcome.status)
            assertEquals(contractId, outcome.serverEntityId)
            coVerify(exactly = 1) { dao.delete(any(), any(), any()) }
        }

    @Test
    fun `GIVEN caller without organization id WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract = buildContract()

            val outcome = service.applyUpsert(noOrgAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN organization id mismatch WHEN upsert THEN REJECTED FORBIDDEN`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract = buildContract(orgId = "other-org")

            val outcome = service.applyUpsert(adminAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    // ---- Contract ended guard (CONTRACT_ENDED) ----

    @Test
    fun `GIVEN ended contract WHEN upsert adds a new member THEN REJECTED CONTRACT_ENDED`() =
        runTest {
            val today = Clock.System.todayIn(TimeZone.UTC)
            val pastDate = today.minus(1, DateTimeUnit.DAY)
            val dao = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(dao, orgDAO)
            val persistedContract = buildContract(maxDeliveryDate = pastDate)
            val updatedContract =
                persistedContract.copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "new-member".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                                subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns listOf(persistedContract)

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedContract), ContractPayload(updatedContract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONTRACT_ENDED, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN ended contract WHEN upsert sets existing member status COMPLETED THEN APPLIED`() =
        runTest {
            val today = Clock.System.todayIn(TimeZone.UTC)
            val pastDate = today.minus(1, DateTimeUnit.DAY)
            val dao = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(dao, orgDAO)
            val existingMember =
                ContractMember(
                    memberId = "member-1".toId(),
                    subscriptionInstant = Instant.fromEpochMilliseconds(0),
                    status = MemberContractStatus.ACTIVE,
                    subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                )
            val persistedContract = buildContract(maxDeliveryDate = pastDate).copy(members = listOf(existingMember))
            val updatedContract =
                persistedContract.copy(
                    members = listOf(existingMember.copy(status = MemberContractStatus.COMPLETED)),
                )
            coEvery { dao.getByOrganizationId(any()) } returns listOf(persistedContract)
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedContract), ContractPayload(updatedContract))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN ended contract WHEN upsert removes a member THEN APPLIED`() =
        runTest {
            val today = Clock.System.todayIn(TimeZone.UTC)
            val pastDate = today.minus(1, DateTimeUnit.DAY)
            val dao = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(dao, orgDAO)
            val existingMember =
                ContractMember(
                    memberId = "member-1".toId(),
                    subscriptionInstant = Instant.fromEpochMilliseconds(0),
                    status = MemberContractStatus.ACTIVE,
                    subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                )
            val persistedContract = buildContract(maxDeliveryDate = pastDate).copy(members = listOf(existingMember))
            val updatedContract = persistedContract.copy(members = emptyList())
            coEvery { dao.getByOrganizationId(any()) } returns listOf(persistedContract)
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedContract), ContractPayload(updatedContract))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN contract with maxDeliveryDate today WHEN upsert adds a new member THEN APPLIED`() =
        runTest {
            val today = Clock.System.todayIn(TimeZone.UTC)
            val dao = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(dao, orgDAO)
            val persistedContract = buildContract(maxDeliveryDate = today)
            val updatedContract =
                persistedContract.copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "new-member".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                                subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns listOf(persistedContract)
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedContract), ContractPayload(updatedContract))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN tmp_ contract with past dates and members WHEN upsert THEN APPLIED`() =
        runTest {
            val today = Clock.System.todayIn(TimeZone.UTC)
            val pastDate = today.minus(1, DateTimeUnit.DAY)
            val dao = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(dao, orgDAO)
            // A tmp_ contract is not persisted yet — getByOrganizationId returns empty
            val tmpContract =
                buildContract(id = "tmp_new-contract", maxDeliveryDate = pastDate).copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "member-1".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                                subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(tmpContract), ContractPayload(tmpContract))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN contract with ENDED status WHEN upsert adds a new member THEN REJECTED CONTRACT_ENDED`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(dao, orgDAO)
            // maxDeliveryDate is in the future, but status is manually ENDED
            val persistedContract = buildContract(maxDeliveryDate = LocalDate(2099, 12, 31)).copy(status = ContractStatus.ENDED)
            val updatedContract =
                persistedContract.copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "new-member".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                                subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns listOf(persistedContract)

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedContract), ContractPayload(updatedContract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONTRACT_ENDED, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN contract with ACTIVE status and past max date WHEN upsert adds a new member THEN REJECTED CONTRACT_ENDED`() =
        runTest {
            val today = Clock.System.todayIn(TimeZone.UTC)
            val pastDate = today.minus(1, DateTimeUnit.DAY)
            val dao = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(dao, orgDAO)
            val persistedContract = buildContract(maxDeliveryDate = pastDate).copy(status = ContractStatus.ACTIVE)
            val updatedContract =
                persistedContract.copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "new-member".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                                subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns listOf(persistedContract)

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedContract), ContractPayload(updatedContract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.CONTRACT_ENDED, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN contract with ENDED status WHEN upsert without new members THEN APPLIED`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val orgDAO = mockk<OrganizationSyncDAO>(relaxed = true)
            val service = buildService(dao, orgDAO)
            val existingMember =
                ContractMember(
                    memberId = "member-1".toId(),
                    subscriptionInstant = Instant.fromEpochMilliseconds(0),
                    status = MemberContractStatus.ACTIVE,
                    subscriptions = listOf(MemberSubscription(productTypeId = "pt-tomato")),
                )
            // status ENDED but maxDeliveryDate in the future — only status triggers the block for new members
            val persistedContract =
                buildContract(maxDeliveryDate = LocalDate(2099, 12, 31))
                    .copy(status = ContractStatus.ENDED, members = listOf(existingMember))
            // update without adding new members (just change an existing member's status)
            val updatedContract =
                persistedContract.copy(
                    members = listOf(existingMember.copy(status = MemberContractStatus.COMPLETED)),
                )
            coEvery { dao.getByOrganizationId(any()) } returns listOf(persistedContract)
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedContract), ContractPayload(updatedContract))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    // ---- Uniqueness guard (UNIQUE_VIOLATION) ----

    @Test
    fun `GIVEN duplicate name WHEN create THEN UNIQUE_VIOLATION`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val existingContract = buildContract(id = "contract-existing", name = "Contrat printemps 2025")
            val newContract = buildContract(id = "tmp_new-contract", name = "Contrat printemps 2025")
            coEvery { dao.getByOrganizationId(any()) } returns listOf(existingContract)

            val outcome = service.applyUpsert(adminAuth, buildMutation(newContract), ContractPayload(newContract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN same name on update of same contract WHEN update THEN APPLIED`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract = buildContract(name = "Contrat printemps 2025")
            coEvery { dao.getByOrganizationId(any()) } returns listOf(contract)
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN name already taken by different contract WHEN update THEN UNIQUE_VIOLATION`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val otherContract = buildContract(id = "contract-other", name = "Contrat printemps 2025")
            val contractToUpdate = buildContract(id = contractId, name = "Contrat automne 2025")
            val updatedContract = contractToUpdate.copy(name = "Contrat printemps 2025")
            coEvery { dao.getByOrganizationId(any()) } returns listOf(otherContract, contractToUpdate)

            val outcome = service.applyUpsert(adminAuth, buildMutation(updatedContract), ContractPayload(updatedContract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.UNIQUE_VIOLATION, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    // ---- Subscription validation (INVALID_SUBSCRIPTION) ----

    @Test
    fun `GIVEN member with empty subscriptions WHEN upsert THEN REJECTED INVALID_SUBSCRIPTION`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contractWithEmptySubscriptions =
                buildContract().copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "member-1".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                                subscriptions = emptyList(),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()

            val outcome =
                service.applyUpsert(
                    adminAuth,
                    buildMutation(contractWithEmptySubscriptions),
                    ContractPayload(contractWithEmptySubscriptions),
                )

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_SUBSCRIPTION, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN member subscription with unknown product type WHEN upsert THEN REJECTED INVALID_SUBSCRIPTION`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contractWithUnknownProduct =
                buildContract().copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "member-1".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                                subscriptions = listOf(MemberSubscription(productTypeId = "pt-unknown")),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()

            val outcome =
                service.applyUpsert(
                    adminAuth,
                    buildMutation(contractWithUnknownProduct),
                    ContractPayload(contractWithUnknownProduct),
                )

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_SUBSCRIPTION, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN member subscription with basket size not matching product price WHEN upsert THEN REJECTED INVALID_SUBSCRIPTION`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contractWithMismatchedSize =
                buildContract(
                    productPrices =
                        listOf(
                            ProductPrice(productTypeId = "pt-tomato", basketSize = null),
                        ),
                ).copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "member-1".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                                subscriptions =
                                    listOf(
                                        MemberSubscription(
                                            productTypeId = "pt-tomato",
                                            basketSize = BasketSize("small"),
                                        ),
                                    ),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()

            val outcome =
                service.applyUpsert(
                    adminAuth,
                    buildMutation(contractWithMismatchedSize),
                    ContractPayload(contractWithMismatchedSize),
                )

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_SUBSCRIPTION, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN member subscription with basket size matching product price WHEN upsert THEN APPLIED`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val basketSizeSmall = BasketSize("small")
            val contractWithMatchedSize =
                buildContract(
                    productPrices =
                        listOf(
                            ProductPrice(
                                productTypeId = "pt-tomato",
                                basketSize = basketSizeSmall,
                            ),
                        ),
                ).copy(
                    members =
                        listOf(
                            ContractMember(
                                memberId = "member-1".toId(),
                                subscriptionInstant = Instant.fromEpochMilliseconds(0),
                                status = MemberContractStatus.ACTIVE,
                                subscriptions =
                                    listOf(
                                        MemberSubscription(
                                            productTypeId = "pt-tomato",
                                            basketSize = basketSizeSmall,
                                        ),
                                    ),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome =
                service.applyUpsert(
                    adminAuth,
                    buildMutation(contractWithMatchedSize),
                    ContractPayload(contractWithMatchedSize),
                )

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN contract with no members WHEN upsert THEN APPLIED`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contractNoMembers = buildContract()
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(contractNoMembers), ContractPayload(contractNoMembers))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    // ---- Shared basket validation (INVALID_SHARED_BASKET) ----

    private fun member(
        id: String,
        productTypeId: String = "pt-tomato",
        basketSize: BasketSize? = null,
    ): ContractMember =
        ContractMember(
            memberId = id.toId(),
            subscriptionInstant = Instant.fromEpochMilliseconds(0),
            status = MemberContractStatus.ACTIVE,
            subscriptions = listOf(MemberSubscription(productTypeId = productTypeId, basketSize = basketSize)),
        )

    @Test
    fun `GIVEN shared basket with a single member WHEN upsert THEN REJECTED INVALID_SHARED_BASKET`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract =
                buildContract().copy(
                    members = listOf(member("member-a")),
                    sharedBaskets = listOf(SharedBasket(sharedBasketId = "sb-1".toId(), memberIds = listOf("member-a".toId()))),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()

            val outcome = service.applyUpsert(adminAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_SHARED_BASKET, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN shared basket referencing a non contract member WHEN upsert THEN REJECTED INVALID_SHARED_BASKET`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract =
                buildContract().copy(
                    members = listOf(member("member-a")),
                    sharedBaskets =
                        listOf(
                            SharedBasket(
                                sharedBasketId = "sb-1".toId(),
                                memberIds = listOf("member-a".toId(), "ghost".toId()),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()

            val outcome = service.applyUpsert(adminAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_SHARED_BASKET, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN a member in two shared baskets WHEN upsert THEN REJECTED INVALID_SHARED_BASKET`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract =
                buildContract().copy(
                    members = listOf(member("member-a"), member("member-b"), member("member-c")),
                    sharedBaskets =
                        listOf(
                            SharedBasket(sharedBasketId = "sb-1".toId(), memberIds = listOf("member-a".toId(), "member-b".toId())),
                            SharedBasket(sharedBasketId = "sb-2".toId(), memberIds = listOf("member-b".toId(), "member-c".toId())),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()

            val outcome = service.applyUpsert(adminAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_SHARED_BASKET, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN shared basket members with divergent subscriptions WHEN upsert THEN REJECTED INVALID_SHARED_BASKET`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract =
                buildContract().copy(
                    members = listOf(member("member-a", productTypeId = "pt-tomato"), member("member-b", productTypeId = "pt-eggs")),
                    sharedBaskets =
                        listOf(
                            SharedBasket(sharedBasketId = "sb-1".toId(), memberIds = listOf("member-a".toId(), "member-b".toId())),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()

            val outcome = service.applyUpsert(adminAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.REJECTED, outcome.status)
            assertEquals(MutationErrorCode.INVALID_SHARED_BASKET, outcome.error?.code)
            coVerify(exactly = 0) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN a valid shared basket with two members sharing a subscription WHEN upsert THEN APPLIED`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract =
                buildContract().copy(
                    members = listOf(member("member-a"), member("member-b")),
                    sharedBaskets =
                        listOf(
                            SharedBasket(sharedBasketId = "sb-1".toId(), memberIds = listOf("member-a".toId(), "member-b".toId())),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()
            coEvery { dao.put(any(), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            coVerify(exactly = 1) { dao.put(any(), any()) }
        }

    @Test
    fun `GIVEN tmp_ shared basket id WHEN upsert THEN real id allocated persisted and not echoed`() =
        runTest {
            val dao = mockk<ContractSyncDAO>()
            val service = buildService(dao)
            val contract =
                buildContract().copy(
                    members = listOf(member("member-a"), member("member-b")),
                    sharedBaskets =
                        listOf(
                            SharedBasket(
                                sharedBasketId = "tmp_sb-1".toId(),
                                memberIds = listOf("member-a".toId(), "member-b".toId()),
                            ),
                        ),
                )
            coEvery { dao.getByOrganizationId(any()) } returns emptyList()
            val persisted = slot<Contract>()
            coEvery { dao.put(capture(persisted), any()) } returns Unit

            val outcome = service.applyUpsert(adminAuth, buildMutation(contract), ContractPayload(contract))

            assertEquals(MutationStatus.APPLIED, outcome.status)
            // serverEntityId carries the contract id only, never the nested shared basket id
            assertEquals(contractId, outcome.serverEntityId)
            val storedId =
                persisted.captured.sharedBaskets
                    .single()
                    .sharedBasketId.id
            assertFalse(storedId.startsWith(ClientMutation.TMP_ID_PREFIX))
        }

    // ---- Alternation helper ----

    private fun deliveries(vararg ids: String): List<Id<Delivery>> = ids.map { it.toId<Delivery>() }

    @Test
    fun `GIVEN two members WHEN pickerFor across deliveries THEN alternates round-robin`() {
        val basket = SharedBasket(sharedBasketId = "sb-1".toId(), memberIds = listOf("a".toId(), "b".toId()))
        val ordered = deliveries("d0", "d1", "d2", "d3")
        assertEquals("a", basket.pickerFor(ordered, "d0".toId())?.id)
        assertEquals("b", basket.pickerFor(ordered, "d1".toId())?.id)
        assertEquals("a", basket.pickerFor(ordered, "d2".toId())?.id)
        assertEquals("b", basket.pickerFor(ordered, "d3".toId())?.id)
    }

    @Test
    fun `GIVEN an anchor delivery WHEN pickerFor THEN rotation starts at the anchor`() {
        val basket =
            SharedBasket(
                sharedBasketId = "sb-1".toId(),
                memberIds = listOf("a".toId(), "b".toId()),
                anchorDeliveryId = "d1".toId(),
            )
        val ordered = deliveries("d0", "d1", "d2")
        assertEquals("a", basket.pickerFor(ordered, "d1".toId())?.id)
        assertEquals("b", basket.pickerFor(ordered, "d2".toId())?.id)
        assertEquals("b", basket.pickerFor(ordered, "d0".toId())?.id)
    }

    @Test
    fun `GIVEN a single delivery WHEN pickerFor THEN returns the first member`() {
        val basket = SharedBasket(sharedBasketId = "sb-1".toId(), memberIds = listOf("a".toId(), "b".toId()))
        assertEquals("a", basket.pickerFor(deliveries("only"), "only".toId())?.id)
    }

    @Test
    fun `GIVEN an unknown anchor WHEN pickerFor THEN falls back to index zero`() {
        val basket =
            SharedBasket(
                sharedBasketId = "sb-1".toId(),
                memberIds = listOf("a".toId(), "b".toId()),
                anchorDeliveryId = "gone".toId(),
            )
        val ordered = deliveries("d0", "d1")
        assertEquals("a", basket.pickerFor(ordered, "d0".toId())?.id)
        assertEquals("b", basket.pickerFor(ordered, "d1".toId())?.id)
    }

    @Test
    fun `GIVEN a delivery not in the contract WHEN pickerFor THEN returns null`() {
        val basket = SharedBasket(sharedBasketId = "sb-1".toId(), memberIds = listOf("a".toId(), "b".toId()))
        assertNull(basket.pickerFor(deliveries("d0"), "other".toId()))
    }
}
