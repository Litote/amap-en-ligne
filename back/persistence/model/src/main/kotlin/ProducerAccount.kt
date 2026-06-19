@file:OptIn(ExperimentalTime::class)

package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/**
 * Producer entity that groups members working for a production unit with embedded users, organizations and products.
 */
@Serializable
data class ProducerAccount(
    @SerialName("producer_account_id") val producerAccountId: Id<ProducerAccount>,
    val name: String,
    @SerialName("contact_email") val contactEmail: String? = null,
    val address: String? = null,
    val website: String? = null,
    @SerialName("active_status") val activeStatus: Boolean,
    @SerialName("created_instant") val createdInstant: Instant,
    @SerialName("last_updated_instant") val lastUpdatedInstant: Instant,
    val users: List<ProducerUser> = emptyList(),
    val organizations: List<ProducerOrganization> = emptyList(),
    val products: List<ProducerProduct> = emptyList(),
    @SerialName("user_preferences") val userPreferences: UserPreferences =
        UserPreferences(
            emailNotificationsEnabled = true,
            pushNotificationsEnabled = false,
            lastUpdatedInstant = Instant.fromEpochMilliseconds(0L),
        ),
    @SerialName("management_mode") val managementMode: ProducerManagementMode = ProducerManagementMode.ACCOUNT_BACKED,
    @SerialName("linked_producer_account") val linkedProducerAccount: LinkedProducerAccount? = null,
)

@Serializable
enum class ProducerManagementMode {
    ACCOUNT_BACKED,
    NO_ACCOUNT,
}

@Serializable
data class LinkedProducerAccount(
    @SerialName("producer_account_id") val producerAccountId: Id<ProducerAccount>,
    val name: String,
)

/**
 * Producer user association (embedded in ProducerAccount).
 */
@Serializable
data class ProducerUser(
    @SerialName("producer_id") val producerId: Id<Producer>,
    val role: ProducerRole,
    @SerialName("association_instant") val associationInstant: Instant,
    val status: ProducerStatus,
)

/**
 * Producer-Organization association (embedded in ProducerAccount).
 */
@Serializable
data class ProducerOrganization(
    @SerialName("organization_id") val organizationId: Id<Organization>,
    @SerialName("association_instant") val associationInstant: Instant,
    val status: OrganizationProducerStatus,
)

/**
 * Product definition for this producer (embedded in ProducerAccount).
 */
@Serializable
data class ProducerProduct(
    val name: String,
    @SerialName("product_type_id") val productTypeId: Id<ProductType>,
    @SerialName("supported_basket_sizes") val supportedBasketSizes: List<BasketSize>,
    val description: String? = null,
)
