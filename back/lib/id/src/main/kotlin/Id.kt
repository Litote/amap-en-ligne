package id

import kotlinx.serialization.Serializable
import java.util.UUID

@JvmInline
@Serializable
value class Id<T>(
    val id: String,
)

inline fun <reified T : Any> String.toId(): Id<T> = Id(this)

@JvmName("nullableStringToId")
inline fun <reified T : Any> String?.toId(): Id<T>? = this?.toId()

inline fun <reified T : Any> generateId(): Id<T> = UUID.randomUUID().toString().toId()
