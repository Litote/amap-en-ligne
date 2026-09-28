@file:OptIn(kotlin.time.ExperimentalTime::class)

package persistence.changes

import id.toId
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import persistence.model.ActivityType
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.BasketSize
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.DeliveryContract
import persistence.model.DeliveryContractStatus
import persistence.model.DeliveryStatus
import persistence.model.DeliveryTemplate
import persistence.model.DevicePlatform
import persistence.model.DeviceToken
import persistence.model.ErrorReport
import persistence.model.MemberContractStatus
import persistence.model.MemberInvitation
import persistence.model.MemberInvitationStatus
import persistence.model.MemberSlot
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.OwnerInvitation
import persistence.model.OwnerInvitationStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.Product
import persistence.model.ProductType
import persistence.model.RegistrationStatus
import persistence.model.SlotStatus
import persistence.model.UserPreferences
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.time.Instant

private val NOW = Instant.fromEpochMilliseconds(1_000L)
private const val ORG_ID = "org-1"
private const val REAL_PRODUCER_ID = "pa-real"
private const val TMP_PRODUCER_ID = "tmp_producer"
private const val REAL_PRODUCT_TYPE_ID = "pt-real"
private const val TMP_PRODUCT_TYPE_ID = "tmp_producttype"
private const val REAL_TEMPLATE_ID = "tmpl-real"
private const val TMP_TEMPLATE_ID = "tmp_template"
private const val REAL_CONTRACT_ID = "contract-real"
private const val TMP_CONTRACT_ID = "tmp_contract"

internal class EntityPayloadTest {
    // -------------------------------------------------------------------------
    // extractTmpId
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN ProductTypePayload with tmp_ id WHEN extractTmpId THEN returns the tmp id`() {
        val payload =
            ProductTypePayload(
                ProductType(
                    productTypeId = "tmp_pt-1".toId(),
                    producerAccountId = REAL_PRODUCER_ID.toId(),
                    name = "Carrots",
                ),
            )
        assertEquals("tmp_pt-1", payload.extractTmpId())
    }

    @Test
    fun `GIVEN ProductTypePayload with real id WHEN extractTmpId THEN returns null`() {
        val payload =
            ProductTypePayload(
                ProductType(
                    productTypeId = "pt-real-1".toId(),
                    producerAccountId = REAL_PRODUCER_ID.toId(),
                    name = "Carrots",
                ),
            )
        assertNull(payload.extractTmpId())
    }

    @Test
    fun `GIVEN ProducerAccountPayload with tmp_ id WHEN extractTmpId THEN returns the tmp id`() {
        val payload = ProducerAccountPayload(minimalProducerAccount(TMP_PRODUCER_ID))
        assertEquals(TMP_PRODUCER_ID, payload.extractTmpId())
    }

    @Test
    fun `GIVEN ProducerAccountPayload with real id WHEN extractTmpId THEN returns null`() {
        val payload = ProducerAccountPayload(minimalProducerAccount(REAL_PRODUCER_ID))
        assertNull(payload.extractTmpId())
    }

    @Test
    fun `GIVEN DeliveryTemplatePayload with tmp_ id WHEN extractTmpId THEN returns the tmp id`() {
        val payload =
            DeliveryTemplatePayload(
                DeliveryTemplate(
                    deliveryTemplateId = TMP_TEMPLATE_ID.toId(),
                    organizationId = ORG_ID.toId(),
                    name = "Template A",
                    standardStartTime = "08:00",
                    standardEndTime = "12:00",
                ),
            )
        assertEquals(TMP_TEMPLATE_ID, payload.extractTmpId())
    }

    @Test
    fun `GIVEN DeliveryTemplatePayload with real id WHEN extractTmpId THEN returns null`() {
        val payload =
            DeliveryTemplatePayload(
                DeliveryTemplate(
                    deliveryTemplateId = REAL_TEMPLATE_ID.toId(),
                    organizationId = ORG_ID.toId(),
                    name = "Template A",
                    standardStartTime = "08:00",
                    standardEndTime = "12:00",
                ),
            )
        assertNull(payload.extractTmpId())
    }

    @Test
    fun `GIVEN ContractPayload with tmp_ id WHEN extractTmpId THEN returns the tmp id`() {
        val payload = ContractPayload(minimalContract(TMP_CONTRACT_ID))
        assertEquals(TMP_CONTRACT_ID, payload.extractTmpId())
    }

    @Test
    fun `GIVEN ContractPayload with real id WHEN extractTmpId THEN returns null`() {
        val payload = ContractPayload(minimalContract(REAL_CONTRACT_ID))
        assertNull(payload.extractTmpId())
    }

    @Test
    fun `GIVEN MemberInvitationPayload with tmp_ id WHEN extractTmpId THEN returns the tmp id`() {
        val payload =
            MemberInvitationPayload(
                MemberInvitation(
                    invitationId = "tmp_inv-1",
                    organizationId = ORG_ID.toId(),
                    email = "member@example.com",
                    firstName = "Alice",
                    lastName = "Dupont",
                    roles = emptySet(),
                    status = MemberInvitationStatus.PENDING_ACTIVATION,
                    createdAt = NOW,
                    expiresAt = NOW,
                ),
            )
        assertEquals("tmp_inv-1", payload.extractTmpId())
    }

    @Test
    fun `GIVEN MemberInvitationPayload with real id WHEN extractTmpId THEN returns null`() {
        val payload =
            MemberInvitationPayload(
                MemberInvitation(
                    invitationId = "inv-real-1",
                    organizationId = ORG_ID.toId(),
                    email = "member@example.com",
                    firstName = "Alice",
                    lastName = "Dupont",
                    roles = emptySet(),
                    status = MemberInvitationStatus.PENDING_ACTIVATION,
                    createdAt = NOW,
                    expiresAt = NOW,
                ),
            )
        assertNull(payload.extractTmpId())
    }

    @Test
    fun `GIVEN OwnerInvitationPayload with tmp_ id WHEN extractTmpId THEN returns the tmp id`() {
        val payload =
            OwnerInvitationPayload(
                OwnerInvitation(
                    invitationId = "tmp_owinv-1".toId(),
                    firstName = "Bob",
                    lastName = "Martin",
                    email = "owner@example.com",
                    status = OwnerInvitationStatus.PENDING_ACTIVATION,
                    submittedAt = NOW,
                ),
            )
        assertEquals("tmp_owinv-1", payload.extractTmpId())
    }

    @Test
    fun `GIVEN OwnerInvitationPayload with real id WHEN extractTmpId THEN returns null`() {
        val payload =
            OwnerInvitationPayload(
                OwnerInvitation(
                    invitationId = "owinv-real".toId(),
                    firstName = "Bob",
                    lastName = "Martin",
                    email = "owner@example.com",
                    status = OwnerInvitationStatus.PENDING_ACTIVATION,
                    submittedAt = NOW,
                ),
            )
        assertNull(payload.extractTmpId())
    }

    @Test
    fun `GIVEN BasketExchangePayload with tmp_ id WHEN extractTmpId THEN returns the tmp id`() {
        val payload = BasketExchangePayload(minimalBasketExchange("tmp_bex-1"))
        assertEquals("tmp_bex-1", payload.extractTmpId())
    }

    @Test
    fun `GIVEN BasketExchangePayload with real id WHEN extractTmpId THEN returns null`() {
        val payload = BasketExchangePayload(minimalBasketExchange("bex-real"))
        assertNull(payload.extractTmpId())
    }

    @Test
    fun `GIVEN DeviceTokenPayload with tmp_ id WHEN extractTmpId THEN returns the tmp id`() {
        val payload =
            DeviceTokenPayload(
                DeviceToken(
                    deviceTokenId = "tmp_tok-1".toId(),
                    recipientScope = "member:sub-1",
                    platform = DevicePlatform.ANDROID,
                    token = "fcm-token",
                    createdAt = NOW,
                    lastSeenAt = NOW,
                ),
            )
        assertEquals("tmp_tok-1", payload.extractTmpId())
    }

    @Test
    fun `GIVEN DeviceTokenPayload with real id WHEN extractTmpId THEN returns null`() {
        val payload =
            DeviceTokenPayload(
                DeviceToken(
                    deviceTokenId = "tok-real".toId(),
                    recipientScope = "member:sub-1",
                    platform = DevicePlatform.ANDROID,
                    token = "fcm-token",
                    createdAt = NOW,
                    lastSeenAt = NOW,
                ),
            )
        assertNull(payload.extractTmpId())
    }

    // OrganizationPayload never carries a tmp_ own id — it represents an existing org.
    @Test
    fun `GIVEN OrganizationPayload WHEN extractTmpId THEN returns null`() {
        val payload = OrganizationPayload(minimalOrganization())
        assertNull(payload.extractTmpId())
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — empty map
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN OrganizationPayload and empty map WHEN rewriteTmpIds THEN returns same instance`() {
        val payload = OrganizationPayload(minimalOrganization())
        assertSame(payload, payload.rewriteTmpIds(emptyMap()))
    }

    @Test
    fun `GIVEN BasketExchangePayload and empty map WHEN rewriteTmpIds THEN returns same instance`() {
        val payload = BasketExchangePayload(minimalBasketExchange("bex-1"))
        assertSame(payload, payload.rewriteTmpIds(emptyMap()))
    }

    @Test
    fun `GIVEN ProducerAccountPayload and empty map WHEN rewriteTmpIds THEN returns same instance`() {
        val payload = ProducerAccountPayload(minimalProducerAccount(REAL_PRODUCER_ID))
        assertSame(payload, payload.rewriteTmpIds(emptyMap()))
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — unrelated ids
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN OrganizationPayload with real ids and unrelated map WHEN rewriteTmpIds THEN unchanged`() {
        val org =
            minimalOrganization()
                .copy(
                    producers =
                        listOf(
                            OrganizationProducer(
                                producerAccountId = REAL_PRODUCER_ID.toId(),
                                associationInstant = NOW,
                                status = OrganizationProducerStatus.ACTIVE,
                            ),
                        ),
                )
        val payload = OrganizationPayload(org)
        val result = payload.rewriteTmpIds(mapOf("unrelated-tmp" to "unrelated-real"))
        assertSame(payload, result)
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — OrganizationPayload.producers[].producerAccountId
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN OrganizationPayload with tmp producerAccountId in producers WHEN rewriteTmpIds THEN producer id rewritten`() {
        val org =
            minimalOrganization().copy(
                producers =
                    listOf(
                        OrganizationProducer(
                            producerAccountId = TMP_PRODUCER_ID.toId(),
                            associationInstant = NOW,
                            status = OrganizationProducerStatus.ACTIVE,
                        ),
                    ),
            )
        val payload = OrganizationPayload(org)
        val result = payload.rewriteTmpIds(mapOf(TMP_PRODUCER_ID to REAL_PRODUCER_ID))

        val rewritten = result as OrganizationPayload
        assertEquals(
            REAL_PRODUCER_ID,
            rewritten.organization.producers
                .single()
                .producerAccountId.id,
        )
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — OrganizationPayload.products[].producerAccountId
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN OrganizationPayload with tmp producerAccountId in products WHEN rewriteTmpIds THEN product producer id rewritten`() {
        val org =
            minimalOrganization().copy(
                products =
                    listOf(
                        Product(
                            name = "Carrots",
                            productTypeId = REAL_PRODUCT_TYPE_ID.toId(),
                            producerAccountId = TMP_PRODUCER_ID.toId(),
                            supportedBasketSizes = listOf(BasketSize("small")),
                        ),
                    ),
            )
        val payload = OrganizationPayload(org)
        val result = payload.rewriteTmpIds(mapOf(TMP_PRODUCER_ID to REAL_PRODUCER_ID))

        val rewritten = result as OrganizationPayload
        assertEquals(
            REAL_PRODUCER_ID,
            rewritten.organization.products
                .single()
                .producerAccountId.id,
        )
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — OrganizationPayload.products[].productTypeId
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN OrganizationPayload with tmp productTypeId in products WHEN rewriteTmpIds THEN product type id rewritten`() {
        val org =
            minimalOrganization().copy(
                products =
                    listOf(
                        Product(
                            name = "Carrots",
                            productTypeId = TMP_PRODUCT_TYPE_ID.toId(),
                            producerAccountId = REAL_PRODUCER_ID.toId(),
                            supportedBasketSizes = listOf(BasketSize("small")),
                        ),
                    ),
            )
        val payload = OrganizationPayload(org)
        val result = payload.rewriteTmpIds(mapOf(TMP_PRODUCT_TYPE_ID to REAL_PRODUCT_TYPE_ID))

        val rewritten = result as OrganizationPayload
        assertEquals(
            REAL_PRODUCT_TYPE_ID,
            rewritten.organization.products
                .single()
                .productTypeId.id,
        )
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — OrganizationPayload.deliveries[].deliveryTemplateId
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN OrganizationPayload with tmp deliveryTemplateId in delivery WHEN rewriteTmpIds THEN delivery template id rewritten`() {
        val delivery = minimalDelivery(templateId = TMP_TEMPLATE_ID)
        val org = minimalOrganization().copy(deliveries = listOf(delivery))
        val payload = OrganizationPayload(org)
        val result = payload.rewriteTmpIds(mapOf(TMP_TEMPLATE_ID to REAL_TEMPLATE_ID))

        val rewritten = result as OrganizationPayload
        assertEquals(
            REAL_TEMPLATE_ID,
            rewritten.organization.deliveries
                .single()
                .deliveryTemplateId
                ?.id,
        )
    }

    @Test
    fun `GIVEN OrganizationPayload with tmp defaultDeliveryTemplateId WHEN rewriteTmpIds THEN default template id rewritten`() {
        val org =
            minimalOrganization().copy(
                defaultDeliveryTemplateId = TMP_TEMPLATE_ID.toId(),
            )
        val payload = OrganizationPayload(org)
        val result = payload.rewriteTmpIds(mapOf(TMP_TEMPLATE_ID to REAL_TEMPLATE_ID))

        val rewritten = result as OrganizationPayload
        assertEquals(REAL_TEMPLATE_ID, rewritten.organization.defaultDeliveryTemplateId?.id)
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — OrganizationPayload.deliveries[].contracts[].contractId
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN OrganizationPayload with tmp contractId in delivery contract WHEN rewriteTmpIds THEN contract id rewritten`() {
        val delivery = minimalDelivery(contractId = TMP_CONTRACT_ID)
        val org = minimalOrganization().copy(deliveries = listOf(delivery))
        val payload = OrganizationPayload(org)
        val result = payload.rewriteTmpIds(mapOf(TMP_CONTRACT_ID to REAL_CONTRACT_ID))

        val rewritten = result as OrganizationPayload
        assertEquals(
            REAL_CONTRACT_ID,
            rewritten.organization.deliveries
                .single()
                .contracts
                .single()
                .contractId.id,
        )
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — OrganizationPayload.deliveries[].basketDescriptions[].productTypeId
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN OrganizationPayload with tmp productTypeId in basketDescriptions WHEN rewriteTmpIds THEN rewritten`() {
        val delivery =
            minimalDelivery().copy(
                basketDescriptions =
                    listOf(
                        persistence.model.BasketDeliveryDescription(
                            productTypeId = TMP_PRODUCT_TYPE_ID.toId(),
                            basketSizeName = "small",
                        ),
                    ),
            )
        val org = minimalOrganization().copy(deliveries = listOf(delivery))
        val payload = OrganizationPayload(org)
        val result = payload.rewriteTmpIds(mapOf(TMP_PRODUCT_TYPE_ID to REAL_PRODUCT_TYPE_ID))

        val rewritten = result as OrganizationPayload
        assertEquals(
            REAL_PRODUCT_TYPE_ID,
            rewritten.organization.deliveries
                .single()
                .basketDescriptions
                .single()
                .productTypeId.id,
        )
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — ProducerAccountPayload.products[].productTypeId
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN ProducerAccountPayload with tmp productTypeId in products WHEN rewriteTmpIds THEN product type id rewritten`() {
        val account =
            minimalProducerAccount(REAL_PRODUCER_ID).copy(
                products =
                    listOf(
                        persistence.model.ProducerProduct(
                            name = "Carrots",
                            productTypeId = TMP_PRODUCT_TYPE_ID.toId(),
                            supportedBasketSizes = emptyList(),
                        ),
                    ),
            )
        val payload = ProducerAccountPayload(account)
        val result = payload.rewriteTmpIds(mapOf(TMP_PRODUCT_TYPE_ID to REAL_PRODUCT_TYPE_ID))

        val rewritten = result as ProducerAccountPayload
        assertEquals(
            REAL_PRODUCT_TYPE_ID,
            rewritten.producerAccount.products
                .single()
                .productTypeId.id,
        )
    }

    @Test
    fun `GIVEN ProducerAccountPayload with real productTypeId and unrelated map WHEN rewriteTmpIds THEN unchanged`() {
        val account =
            minimalProducerAccount(REAL_PRODUCER_ID).copy(
                products =
                    listOf(
                        persistence.model.ProducerProduct(
                            name = "Carrots",
                            productTypeId = REAL_PRODUCT_TYPE_ID.toId(),
                            supportedBasketSizes = emptyList(),
                        ),
                    ),
            )
        val payload = ProducerAccountPayload(account)
        assertSame(payload, payload.rewriteTmpIds(mapOf("tmp_unrelated" to "real-unrelated")))
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — BasketExchangePayload.contractId
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN BasketExchangePayload with tmp contractId WHEN rewriteTmpIds THEN contract id rewritten`() {
        val exchange =
            minimalBasketExchange("bex-1").copy(
                contractId = TMP_CONTRACT_ID.toId(),
            )
        val payload = BasketExchangePayload(exchange)
        val result = payload.rewriteTmpIds(mapOf(TMP_CONTRACT_ID to REAL_CONTRACT_ID))

        val rewritten = result as BasketExchangePayload
        assertEquals(REAL_CONTRACT_ID, rewritten.basketExchange.contractId.id)
    }

    @Test
    fun `GIVEN BasketExchangePayload with real contractId and unrelated map WHEN rewriteTmpIds THEN unchanged`() {
        val payload = BasketExchangePayload(minimalBasketExchange("bex-1"))
        val result = payload.rewriteTmpIds(mapOf("tmp_unrelated" to "real-unrelated"))
        assertSame(payload, result)
    }

    // -------------------------------------------------------------------------
    // rewriteTmpIds — multiple FKs rewritten in one pass
    // -------------------------------------------------------------------------

    @Test
    fun `GIVEN OrganizationPayload with multiple tmp FKs WHEN rewriteTmpIds THEN all rewritten`() {
        val org =
            minimalOrganization().copy(
                producers =
                    listOf(
                        OrganizationProducer(
                            producerAccountId = TMP_PRODUCER_ID.toId(),
                            associationInstant = NOW,
                            status = OrganizationProducerStatus.ACTIVE,
                        ),
                    ),
                products =
                    listOf(
                        Product(
                            name = "Carrots",
                            productTypeId = TMP_PRODUCT_TYPE_ID.toId(),
                            producerAccountId = TMP_PRODUCER_ID.toId(),
                            supportedBasketSizes = listOf(BasketSize("small")),
                        ),
                    ),
                deliveries =
                    listOf(
                        minimalDelivery(templateId = TMP_TEMPLATE_ID, contractId = TMP_CONTRACT_ID),
                    ),
            )
        val payload = OrganizationPayload(org)
        val tmpIdMap =
            mapOf(
                TMP_PRODUCER_ID to REAL_PRODUCER_ID,
                TMP_PRODUCT_TYPE_ID to REAL_PRODUCT_TYPE_ID,
                TMP_TEMPLATE_ID to REAL_TEMPLATE_ID,
                TMP_CONTRACT_ID to REAL_CONTRACT_ID,
            )
        val result = payload.rewriteTmpIds(tmpIdMap) as OrganizationPayload

        assertEquals(
            REAL_PRODUCER_ID,
            result.organization.producers
                .single()
                .producerAccountId.id,
        )
        assertEquals(
            REAL_PRODUCT_TYPE_ID,
            result.organization.products
                .single()
                .productTypeId.id,
        )
        assertEquals(
            REAL_PRODUCER_ID,
            result.organization.products
                .single()
                .producerAccountId.id,
        )
        assertEquals(
            REAL_TEMPLATE_ID,
            result.organization.deliveries
                .single()
                .deliveryTemplateId
                ?.id,
        )
        assertEquals(
            REAL_CONTRACT_ID,
            result.organization.deliveries
                .single()
                .contracts
                .single()
                .contractId.id,
        )
    }

    // -------------------------------------------------------------------------
    // Helper builders
    // -------------------------------------------------------------------------

    private fun minimalProducerAccount(id: String): ProducerAccount =
        ProducerAccount(
            producerAccountId = id.toId(),
            name = "Producer $id",
            activeStatus = true,
            createdInstant = NOW,
            lastUpdatedInstant = NOW,
            managementMode = ProducerManagementMode.ACCOUNT_BACKED,
            userPreferences =
                UserPreferences(
                    emailNotificationsEnabled = true,
                    pushNotificationsEnabled = false,
                    lastUpdatedInstant = NOW,
                ),
        )

    private fun minimalContract(id: String): Contract =
        Contract(
            contractId = id.toId(),
            name = "Test contract",
            organizationId = ORG_ID.toId(),
            producerAccountId = "producer-1".toId(),
            minDeliveryDate = LocalDate(2024, 1, 1),
            maxDeliveryDate = LocalDate(2024, 12, 31),
            deliveryCount = 10,
            seasonYear = 2024,
        )

    private fun minimalOrganization(): Organization =
        Organization(
            organizationId = ORG_ID.toId(),
            name = "My AMAP",
            contactEmail = "contact@example.com",
            activeStatus = true,
            timezone = TimeZone.of("Europe/Paris"),
            defaultLanguage = "fr",
            createdInstant = NOW,
            lastUpdatedInstant = NOW,
        )

    private fun minimalDelivery(
        templateId: String? = null,
        contractId: String = REAL_CONTRACT_ID,
    ): persistence.model.Delivery =
        persistence.model.Delivery(
            deliveryId = "dlv-1".toId(),
            organizationId = ORG_ID.toId(),
            deliveryTemplateId = templateId?.toId(),
            scheduledDate = LocalDateTime(2024, 6, 15, 9, 0),
            status = DeliveryStatus.PLANNED,
            minVolunteersRequired = 2,
            contracts =
                listOf(
                    DeliveryContract(
                        contractId = contractId.toId(),
                        basketQuantity = 10,
                        deliveryDescription = "Delivery for contract $contractId",
                        status = DeliveryContractStatus.PENDING,
                    ),
                ),
        )

    private fun minimalBasketExchange(id: String): BasketExchange =
        BasketExchange(
            basketExchangeId = id.toId(),
            organizationId = ORG_ID.toId(),
            deliveryId = "dlv-1".toId(),
            contractId = REAL_CONTRACT_ID.toId(),
            offeringMemberId = "member-1".toId(),
            status = BasketExchangeStatus.OPEN,
            createdAt = NOW,
        )

    @Test
    fun `GIVEN ErrorReportPayload with tmp_ id WHEN extractTmpId THEN returns the tmp id`() {
        val payload =
            ErrorReportPayload(
                errorReport =
                    ErrorReport(
                        errorReportId = "tmp_rpt-1".toId(),
                        errorMessage = "Error",
                        reportedAt = NOW,
                    ),
            )
        assertEquals("tmp_rpt-1", payload.extractTmpId())
    }

    @Test
    fun `GIVEN ErrorReportPayload with real id WHEN extractTmpId THEN returns null`() {
        val payload =
            ErrorReportPayload(
                errorReport =
                    ErrorReport(
                        errorReportId = "rpt-real-1".toId(),
                        errorMessage = "Error",
                        reportedAt = NOW,
                    ),
            )
        assertNull(payload.extractTmpId())
    }
}
