package i18n

import kotlinx.datetime.IllegalTimeZoneException
import kotlinx.datetime.TimeZone
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

/**
 * Serializes a [TimeZone] as its identifier (`"Europe/Paris"`), the wire and storage format.
 *
 * kotlinx-datetime ≥ 0.8 no longer serializes [TimeZone] by default. An unknown identifier is
 * rejected (no fallback, unlike [toTimeZone]) with a [SerializationException]: the payload carrying it
 * is undecodable. The exception is raised here because kotlinx-serialization ≥ 1.13 no longer wraps
 * the errors thrown by custom serializers.
 */
object TimeZoneIdSerializer : KSerializer<TimeZone> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("i18n.TimeZone", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: TimeZone,
    ) {
        encoder.encodeString(value.id)
    }

    override fun deserialize(decoder: Decoder): TimeZone {
        val id = decoder.decodeString()
        return try {
            TimeZone.of(id)
        } catch (e: IllegalTimeZoneException) {
            throw SerializationException("Unknown time zone identifier: $id", e)
        }
    }
}
