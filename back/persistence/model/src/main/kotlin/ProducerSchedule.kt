package persistence.model

import id.Id
import kotlinx.datetime.LocalDateTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Read-only projection of one AMAP's deliveries that concern one producer, served on the
 * producer's private `producer-account:{id}` scope (a producer never receives the
 * `organization:{id}` scope, which carries members' personal data).
 *
 * Derived, never stored: computed from the [Organization] aggregate and the producer's
 * [Contract]s. It deliberately leaves out everything personal — coordinators, volunteer
 * slots and registrations — and keeps only what the producer needs to prepare its baskets.
 * One schedule per linked organization; its entity id is the [organizationId].
 */
@Serializable
data class ProducerSchedule(
    @SerialName("organization_id") val organizationId: Id<Organization>,
    @SerialName("producer_account_id") val producerAccountId: Id<ProducerAccount>,
    @SerialName("organization_name") val organizationName: String,
    val deliveries: List<ProducerScheduleDelivery> = emptyList(),
)

/** A delivery of the organization carrying at least one of the producer's contracts. */
@Serializable
data class ProducerScheduleDelivery(
    @SerialName("delivery_id") val deliveryId: Id<Delivery>,
    @SerialName("scheduled_date") val scheduledDate: LocalDateTime,
    val status: DeliveryStatus,
    /** Only the producer's own contracts linked to the delivery. */
    val contracts: List<ProducerScheduleContract> = emptyList(),
    /** Basket compositions of the producer's own products (informative). */
    @SerialName("basket_descriptions") val basketDescriptions: List<BasketDeliveryDescription> = emptyList(),
)

@Serializable
data class ProducerScheduleContract(
    @SerialName("contract_id") val contractId: Id<Contract>,
    @SerialName("contract_name") val contractName: String,
    @SerialName("basket_quantity") val basketQuantity: Int,
    val status: DeliveryContractStatus,
    /**
     * Lifecycle of the contract itself (not of its delivery link), so the producer can tell an
     * `IN_PREPARATION` contract from an active one. Always set by the projection; nullable only
     * for schedules written before the field existed.
     */
    @SerialName("contract_status") val contractStatus: ContractStatus? = null,
)
