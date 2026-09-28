package persistence.model

import id.Id
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Server(
    @SerialName("server_id")
    val serverId: Id<Server>,
    val name: String,
    val url: String,
)
