@file:UseContextualSerialization(Any::class)

package serialization

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.InternalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationStrategy
import kotlinx.serialization.Serializer
import kotlinx.serialization.UseContextualSerialization
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.SetSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.decodeFromStream
import kotlinx.serialization.json.encodeToStream
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.contextual
import kotlinx.serialization.serializer
import java.io.BufferedReader
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.util.zip.GZIPInputStream
import java.util.zip.GZIPOutputStream

val json =
    Json {
        prettyPrint = false
        isLenient = true
        ignoreUnknownKeys = true
        coerceInputValues = true
        explicitNulls = false
        serializersModule =
            SerializersModule {
                contextual(AnySerializer())
            }
    }

class AnySerializer : KSerializer<Any> {
    override val descriptor: SerialDescriptor = buildClassSerialDescriptor("Any")

    @Suppress("UNCHECKED_CAST")
    @OptIn(InternalSerializationApi::class)
    override fun serialize(
        encoder: Encoder,
        value: Any,
    ) {
        when (value) {
            is List<*> -> {
                val listSerializer = ListSerializer(AnySerializer())
                encoder.encodeSerializableValue(listSerializer as SerializationStrategy<Any>, value)
            }

            is Set<*> -> {
                val setSerializer = SetSerializer(AnySerializer())
                encoder.encodeSerializableValue(setSerializer as SerializationStrategy<Any>, value)
            }

            is Map<*, *> -> {
                val mapSerializer = MapSerializer(String.serializer(), AnySerializer())
                encoder.encodeSerializableValue(mapSerializer as SerializationStrategy<Any>, value)
            }

            else -> {
                encoder.encodeSerializableValue(value::class.serializer() as SerializationStrategy<Any>, value)
            }
        }
    }

    override fun deserialize(decoder: Decoder): Any = error("no serialization class available")
}

@OptIn(ExperimentalSerializationApi::class)
inline fun <reified T : Any> readJson(input: InputStream): T = json.decodeFromStream<T>(input)

inline fun <reified T : Any> readJson(content: String): T = json.decodeFromString(content)

inline fun <reified T> loadResource(path: String): T =
    readJson(
        object {}::class.java
            .getResourceAsStream(path)
            .bufferedReader()
            .use(BufferedReader::readText),
    )

@OptIn(ExperimentalSerializationApi::class)
inline fun <reified T : Any> writeJson(
    content: T,
    output: OutputStream,
) = json.encodeToStream(content, output)

inline fun <reified T : Any> writeJson(content: T): String = json.encodeToString(content)

@OptIn(ExperimentalSerializationApi::class)
fun <T> encodeAndCompress(
    value: T,
    serializer: KSerializer<T>,
): ByteArray {
    val bos = ByteArrayOutputStream()
    GZIPOutputStream(bos).use { gzip ->
        json.encodeToStream(serializer, value, gzip)
    }
    return bos.toByteArray()
}

@OptIn(ExperimentalSerializationApi::class)
fun <T> decompressAndDecode(
    bytes: ByteArray,
    serializer: KSerializer<T>,
): T {
    GZIPInputStream(bytes.inputStream()).use { gis ->
        return json.decodeFromStream(serializer, gis)
    }
}
