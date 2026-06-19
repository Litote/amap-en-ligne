package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class EarlySlot(
    @SerialName("arrival_time") val arrivalTime: String,
    val explanation: String? = null,
    @SerialName("max_volunteers") val maxVolunteers: Int,
)

@Serializable
data class DeliveryTemplate(
    @SerialName("delivery_template_id") val deliveryTemplateId: Id<DeliveryTemplate>,
    @SerialName("organization_id") val organizationId: Id<Organization>,
    val name: String,
    @SerialName("standard_start_time") val standardStartTime: String,
    @SerialName("standard_end_time") val standardEndTime: String,
    @SerialName("volunteer_arrival_time") val volunteerArrivalTime: String? = null,
    @SerialName("desired_volunteer_count") val desiredVolunteerCount: Int = 0,
    @SerialName("early_slot") val earlySlot: EarlySlot? = null,
)
