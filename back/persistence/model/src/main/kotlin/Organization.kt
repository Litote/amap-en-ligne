@file:OptIn(ExperimentalTime::class)

package persistence.model

import i18n.Language
import id.Id
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Organization (AMAP) with embedded producers and products.
 */
@Serializable
data class Organization(
    @SerialName("organization_id") val organizationId: Id<Organization>,
    val name: String,
    val website: String? = null,
    @SerialName("default_delivery_template_id") val defaultDeliveryTemplateId: Id<DeliveryTemplate>? = null,
    @SerialName("contact_email") val contactEmail: String,
    @SerialName("active_status") val activeStatus: Boolean,
    val timezone: TimeZone,
    @SerialName("default_language") val defaultLanguage: Language,
    @SerialName("created_instant") val createdInstant: Instant,
    @SerialName("last_updated_instant") val lastUpdatedInstant: Instant,
    val producers: List<OrganizationProducer> = emptyList(),
    val products: List<Product> = emptyList(),
    val deliveries: List<Delivery> = emptyList(),
    // Flat, deduplicated catalog of the basket components (with their inline SVG icons) referenced by
    // deliveries' basket_descriptions. Stored once per component so the heavy SVG is not duplicated
    // per delivery, and member-synced (members don't sync the producer-account ProductType scope).
    @SerialName("item_types") val itemTypes: List<ItemType> = emptyList(),
    // Admin-authored per-category overrides of notification title/body for this AMAP.
    // Resolved at publish sites via NotificationCopy.resolve; empty ⇒ hardcoded defaults.
    @SerialName("notification_overrides")
    val notificationOverrides: Map<NotificationCategory, NotificationCopyOverride> = emptyMap(),
) {
    fun getNextDeliveries(
        startDate: Instant = Clock.System.now() - 2.hours,
        limit: Int = 2,
    ): List<Delivery> {
        val date = startDate.toLocalDateTime(timezone)
        return deliveries
            .asSequence()
            .filter { it.status.isActive() }
            .filter { it.scheduledDate > date }
            .sortedBy { it.scheduledDate }
            .take(limit)
            .toList()
    }

    fun getNextDeliveryRegistration(memberId: Id<Member>): Delivery? =
        deliveries
            .asSequence()
            .filter { it.status.isActive() }
            .filter { it.contracts.any { c -> c.slots.any { s -> s.registrations.any { r -> r.memberId == memberId } } } }
            .minByOrNull { it.scheduledDate }
}

/**
 * Organization-Producer Association (embedded in Organization).
 */
@Serializable
data class OrganizationProducer(
    @SerialName("producer_account_id") val producerAccountId: Id<ProducerAccount>,
    @SerialName("association_instant") val associationInstant: Instant,
    val status: OrganizationProducerStatus,
)

@Serializable
enum class OrganizationProducerStatus {
    ACTIVE,
    SUSPENDED,
    TERMINATED,
}

/**
 * Product definition (embedded in Organization).
 */
@Serializable
data class Product(
    val name: String,
    @SerialName("product_type_id") val productTypeId: Id<ProductType>,
    @SerialName("producer_account_id") val producerAccountId: Id<ProducerAccount>,
    @SerialName("supported_basket_sizes") val supportedBasketSizes: List<BasketSize>,
    val description: String? = null,
)

@Serializable
data class DeliveryItem(
    @SerialName("item_type_id") val itemTypeId: Id<ItemType>,
    // Tiny denormalised label snapshot (historical accuracy / resilience); the heavy SVG icon is
    // resolved by item_type_id from the org-level Organization.itemTypes catalog, not duplicated here.
    val name: String = "",
    val weight: String? = null,
)

@Serializable
data class BasketDeliveryDescription(
    @SerialName("product_type_id") val productTypeId: Id<ProductType>,
    @SerialName("basket_size_name") val basketSizeName: String,
    val items: List<DeliveryItem> = emptyList(),
)

/**
 *  delivery session with volunteer time slots and embedded contracts (embedded in Organization).
 */
@Serializable
data class Delivery(
    @SerialName("delivery_id") val deliveryId: Id<Delivery>,
    @SerialName("organization_id") val organizationId: Id<Organization>,
    @SerialName("delivery_template_id") val deliveryTemplateId: Id<DeliveryTemplate>? = null,
    @SerialName("scheduled_date") val scheduledDate: LocalDateTime,
    val status: DeliveryStatus,
    @SerialName("min_volunteers_required") val minVolunteersRequired: Int,
    // Per-delivery overrides of the template's slot times ("HH:MM"); null ⇒ fall back to the
    // linked template, then to the hard-coded defaults. An early slot may be defined here even
    // without a template.
    @SerialName("standard_end_time") val standardEndTime: String? = null,
    @SerialName("volunteer_arrival_time") val volunteerArrivalTime: String? = null,
    @SerialName("early_slot") val earlySlot: EarlySlot? = null,
    val contracts: List<DeliveryContract> = emptyList(),
    @SerialName("basket_descriptions") val basketDescriptions: List<BasketDeliveryDescription> = emptyList(),
)

@Serializable
enum class DeliveryStatus {
    PLANNED,
    CONFIRMED,
    IN_PROGRESS,
    COMPLETED,
    CANCELLED,
    ;

    fun isActive() = this != COMPLETED && this != CANCELLED
}

/**
 * Delivery-Contract Association with embedded slots and exchanges.
 */
@Serializable
data class DeliveryContract(
    @SerialName("contract_id") val contractId: Id<Contract>,
    val coordinators: List<Id<Member>> = emptyList(),
    @SerialName("basket_quantity") val basketQuantity: Int,
    @SerialName("delivery_description") val deliveryDescription: String,
    @SerialName("preparation_notes") val preparationNotes: String? = null,
    val status: DeliveryContractStatus,
    val slots: List<MemberSlot> = emptyList(),
    val exchanges: List<Exchange> = emptyList(),
)

@Serializable
enum class DeliveryContractStatus {
    PENDING,
    PREPARED,
    DISTRIBUTED,
}

@Serializable
enum class SlotKind {
    STANDARD,
    EARLY,
}

/**
 * Volunteer participation slot for a specific delivery contract.
 */
@Serializable
data class MemberSlot(
    @SerialName("slot_id") val slotId: String? = null,
    @SerialName("start_time") val startTime: LocalDateTime,
    @SerialName("end_time") val endTime: LocalDateTime,
    @SerialName("activity_type") val activityType: ActivityType,
    @SerialName("required_volunteers") val requiredVolunteers: Int,
    @SerialName("current_registrations") val currentRegistrations: Int,
    val status: SlotStatus,
    @SerialName("slot_kind") val slotKind: SlotKind = SlotKind.STANDARD,
    val registrations: List<MemberRegistration> = emptyList(),
)

@Serializable
enum class ActivityType {
    PREPARATION,
    RECEPTION,
    DISTRIBUTION,
}

@Serializable
enum class SlotStatus {
    OPEN,
    CRITICAL,
    FULL,
    CLOSED,
    CANCELLED,
}

/**
 * Member registration to a time slot.
 */
@Serializable
data class MemberRegistration(
    @SerialName("member_id") val memberId: Id<Member>,
    @SerialName("display_name") val displayName: String,
    @SerialName("member_email") val memberEmail: String,
    @SerialName("registration_instant") val registrationInstant: Instant,
    val status: RegistrationStatus,
)

@Serializable
enum class RegistrationStatus {
    REGISTERED,
    CONFIRMED,
    CANCELLED,
    COMPLETED,
}

/**
 * Member exchange request between members for delivery slots.
 */
@Serializable
data class Exchange(
    @SerialName("member_id") val memberId: Id<Member>,
    @SerialName("target_member_id") val targetMemberId: Id<Member>,
    @SerialName("exchange_instant") val exchangeInstant: Instant,
    val status: ExchangeStatus,
)

@Serializable
enum class ExchangeStatus {
    PENDING,
    ACCEPTED,
    REFUSED,
    CANCELLED,
}
