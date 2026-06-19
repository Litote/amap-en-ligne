package deploy.lambda

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
internal data class SnsEvent(
    @SerialName("Records") val records: List<SnsRecord>,
)

@Serializable
internal data class SnsRecord(
    @SerialName("Sns") val sns: SnsMessage,
)

@Serializable
internal data class SnsMessage(
    @SerialName("Message") val message: String,
)
