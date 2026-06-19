package persistence.changes

import id.toId
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import persistence.model.AttendanceEmailRequest
import persistence.model.BasketExchange
import persistence.model.Contract
import persistence.model.DeliveryContract
import persistence.model.DeliveryTemplate
import persistence.model.DeviceToken
import persistence.model.EntityType
import persistence.model.ErrorReport
import persistence.model.Member
import persistence.model.MemberInvitation
import persistence.model.MemberJoinRequest
import persistence.model.Notification
import persistence.model.Organization
import persistence.model.OrganizationRequest
import persistence.model.Owner
import persistence.model.OwnerInvitation
import persistence.model.Producer
import persistence.model.ProducerAccount
import persistence.model.ProducerRequest
import persistence.model.ProductType

/**
 * Polymorphic carrier for the typed body of an entity in the sync protocol.
 *
 * The discriminator value matches the corresponding [EntityType] constant.
 */
@Serializable
sealed interface EntityPayload {
    val entityType: EntityType

    /**
     * Rewrites `tmp_*` FK references using the provided [tmpIdMap].
     * The default implementation returns `this` unchanged.
     * Override on payloads that embed FK references to other entities that may
     * carry `tmp_*` ids allocated earlier in the same sync batch.
     */
    fun rewriteTmpIds(tmpIdMap: Map<String, String>): EntityPayload = this

    /**
     * Extracts the entity's own `tmp_*` id when this payload represents a new
     * entity creation (i.e. the entity id starts with [ClientMutation.TMP_ID_PREFIX]).
     * Returns `null` for payloads that never carry `tmp_*` own ids, or when the
     * id is a real server-allocated id.
     */
    fun extractTmpId(): String? = null
}

@Serializable
@SerialName("ProductType")
data class ProductTypePayload(
    val productType: ProductType,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.ProductType

    override fun extractTmpId(): String? = productType.productTypeId.id.takeIf { it.startsWith(ClientMutation.TMP_ID_PREFIX) }
}

@Serializable
@SerialName("Organization")
data class OrganizationPayload(
    val organization: Organization,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.Organization

    override fun rewriteTmpIds(tmpIdMap: Map<String, String>): EntityPayload {
        if (tmpIdMap.isEmpty()) return this
        val org = organization
        val rewrittenProducers =
            org.producers.map { producer ->
                tmpIdMap[producer.producerAccountId.id]
                    ?.let { producer.copy(producerAccountId = it.toId()) }
                    ?: producer
            }
        val rewrittenProducts =
            org.products.map { product ->
                val newProducerAccountId =
                    tmpIdMap[product.producerAccountId.id]?.toId()
                        ?: product.producerAccountId
                val newProductTypeId =
                    tmpIdMap[product.productTypeId.id]?.toId()
                        ?: product.productTypeId
                if (newProducerAccountId != product.producerAccountId || newProductTypeId != product.productTypeId) {
                    product.copy(producerAccountId = newProducerAccountId, productTypeId = newProductTypeId)
                } else {
                    product
                }
            }
        val rewrittenDefaultTemplateId =
            org.defaultDeliveryTemplateId?.let { templateId ->
                tmpIdMap[templateId.id]?.toId() ?: templateId
            }
        val rewrittenDeliveries =
            org.deliveries.map { delivery ->
                val newTemplateId =
                    delivery.deliveryTemplateId?.let { templateId ->
                        tmpIdMap[templateId.id]?.toId() ?: templateId
                    }
                val rewrittenContracts =
                    delivery.contracts.map { contract ->
                        tmpIdMap[contract.contractId.id]
                            ?.let { contract.copy(contractId = it.toId()) }
                            ?: contract
                    }
                val rewrittenBasketDescriptions =
                    delivery.basketDescriptions.map { desc ->
                        tmpIdMap[desc.productTypeId.id]
                            ?.let { desc.copy(productTypeId = it.toId()) }
                            ?: desc
                    }
                if (
                    newTemplateId != delivery.deliveryTemplateId ||
                    rewrittenContracts != delivery.contracts ||
                    rewrittenBasketDescriptions != delivery.basketDescriptions
                ) {
                    delivery.copy(
                        deliveryTemplateId = newTemplateId,
                        contracts = rewrittenContracts,
                        basketDescriptions = rewrittenBasketDescriptions,
                    )
                } else {
                    delivery
                }
            }
        if (
            rewrittenProducers == org.producers &&
            rewrittenProducts == org.products &&
            rewrittenDefaultTemplateId == org.defaultDeliveryTemplateId &&
            rewrittenDeliveries == org.deliveries
        ) {
            return this
        }
        return copy(
            organization =
                org.copy(
                    producers = rewrittenProducers,
                    products = rewrittenProducts,
                    defaultDeliveryTemplateId = rewrittenDefaultTemplateId,
                    deliveries = rewrittenDeliveries,
                ),
        )
    }
}

@Serializable
@SerialName("ProducerAccount")
data class ProducerAccountPayload(
    val producerAccount: ProducerAccount,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.ProducerAccount

    override fun extractTmpId(): String? = producerAccount.producerAccountId.id.takeIf { it.startsWith(ClientMutation.TMP_ID_PREFIX) }

    override fun rewriteTmpIds(tmpIdMap: Map<String, String>): EntityPayload {
        if (tmpIdMap.isEmpty()) return this
        val rewrittenProducts =
            producerAccount.products.map { product ->
                tmpIdMap[product.productTypeId.id]
                    ?.let { product.copy(productTypeId = it.toId()) }
                    ?: product
            }
        return if (rewrittenProducts == producerAccount.products) {
            this
        } else {
            copy(producerAccount = producerAccount.copy(products = rewrittenProducts))
        }
    }
}

@Serializable
@SerialName("Member")
data class MemberPayload(
    val member: Member,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.Member
}

@Serializable
@SerialName("MemberJoinRequest")
data class MemberJoinRequestPayload(
    val memberJoinRequest: MemberJoinRequest,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.MemberJoinRequest
}

@Serializable
@SerialName("MemberInvitation")
data class MemberInvitationPayload(
    val memberInvitation: MemberInvitation,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.MemberInvitation

    override fun extractTmpId(): String? = memberInvitation.invitationId.takeIf { it.startsWith(ClientMutation.TMP_ID_PREFIX) }
}

@Serializable
@SerialName("Contract")
data class ContractPayload(
    val contract: Contract,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.Contract

    override fun extractTmpId(): String? = contract.contractId.id.takeIf { it.startsWith(ClientMutation.TMP_ID_PREFIX) }
}

@Serializable
@SerialName("DeliveryTemplate")
data class DeliveryTemplatePayload(
    val deliveryTemplate: DeliveryTemplate,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.DeliveryTemplate

    override fun extractTmpId(): String? = deliveryTemplate.deliveryTemplateId.id.takeIf { it.startsWith(ClientMutation.TMP_ID_PREFIX) }
}

@Serializable
@SerialName("OrganizationRequest")
data class OrganizationRequestPayload(
    val organizationRequest: OrganizationRequest,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.OrganizationRequest
}

@Serializable
@SerialName("ProducerRequest")
data class ProducerRequestPayload(
    val producerRequest: ProducerRequest,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.ProducerRequest
}

@Serializable
@SerialName("Owner")
data class OwnerPayload(
    val owner: Owner,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.Owner
}

@Serializable
@SerialName("OwnerInvitation")
data class OwnerInvitationPayload(
    val ownerInvitation: OwnerInvitation,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.OwnerInvitation

    override fun extractTmpId(): String? = ownerInvitation.invitationId.id.takeIf { it.startsWith(ClientMutation.TMP_ID_PREFIX) }
}

@Serializable
@SerialName("BasketExchange")
data class BasketExchangePayload(
    val basketExchange: BasketExchange,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.BasketExchange

    override fun extractTmpId(): String? = basketExchange.basketExchangeId.id.takeIf { it.startsWith(ClientMutation.TMP_ID_PREFIX) }

    override fun rewriteTmpIds(tmpIdMap: Map<String, String>): EntityPayload {
        if (tmpIdMap.isEmpty()) return this
        val exchange = basketExchange
        val newContractId =
            tmpIdMap[exchange.contractId.id]?.toId<DeliveryContract>()
                ?: exchange.contractId
        return if (newContractId != exchange.contractId) {
            copy(basketExchange = exchange.copy(contractId = newContractId))
        } else {
            this
        }
    }
}

@Serializable
@SerialName("Notification")
data class NotificationPayload(
    val notification: Notification,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.Notification
}

@Serializable
@SerialName("DeviceToken")
data class DeviceTokenPayload(
    val deviceToken: DeviceToken,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.DeviceToken

    override fun extractTmpId(): String? = deviceToken.deviceTokenId.id.takeIf { it.startsWith(ClientMutation.TMP_ID_PREFIX) }
}

@Serializable
@SerialName("AttendanceEmailRequest")
data class AttendanceEmailRequestPayload(
    val attendanceEmailRequest: AttendanceEmailRequest,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.AttendanceEmailRequest

    override fun extractTmpId(): String? =
        attendanceEmailRequest.attendanceEmailRequestId.id.takeIf {
            it.startsWith(ClientMutation.TMP_ID_PREFIX)
        }
}

@Serializable
@SerialName("Producer")
data class ProducerPayload(
    val producer: Producer,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.Producer
    // producerId is always the auth sub — never a tmp_* client-generated id
}

@Serializable
@SerialName("ErrorReport")
data class ErrorReportPayload(
    val errorReport: ErrorReport,
) : EntityPayload {
    override val entityType: EntityType get() = EntityType.ErrorReport

    override fun extractTmpId(): String? = errorReport.errorReportId.id.takeIf { it.startsWith(ClientMutation.TMP_ID_PREFIX) }
}
