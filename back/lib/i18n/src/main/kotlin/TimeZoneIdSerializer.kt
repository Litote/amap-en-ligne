package i18n

import kotlinx.datetime.TimeZone
import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

/**
 * Serializes a [TimeZone] as its identifier (`"Europe/Paris"`), the wire and storage format.
 *
 * kotlinx-datetime ≥ 0.8 no longer serializes [TimeZone] by default. An unknown identifier is
 * rejected (no fallback, unlike [toTimeZone]): the payload carrying it is undecodable.
 */
object TimeZoneIdSerializer : KSerializer<TimeZone> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("i18n.TimeZone", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: TimeZone,
    ) {
        encoder.encodeString(value.id)
    }

    override fun deserialize(decoder: Decoder): TimeZone = TimeZone.of(decoder.decodeString())
}
