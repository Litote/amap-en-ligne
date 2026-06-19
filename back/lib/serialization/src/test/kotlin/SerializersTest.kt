package serialization

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class SerializersTest {
    @Test
    fun `test serialization of a list`() {
        val list = listOf(1, "string", true)
        val serialized = json.encodeToString(AnySerializer(), list)
        val expected = "[1,\"string\",true]"
        assertEquals(expected, serialized)
    }

    @Test
    fun `test serialization of a set`() {
        val set = setOf(1, "string", true)
        val serialized = json.encodeToString(AnySerializer(), set)
        val expected = "[1,\"string\",true]" // L'ordre peut varier pour les ensembles
        assertEquals(expected, serialized)
    }

    @Test
    fun `test serialization of a primitive value`() {
        val value = 42
        val serialized = json.encodeToString(AnySerializer(), value)
        val expected = "42"
        assertEquals(expected, serialized)
    }

    @Test
    fun `test serialization of a string`() {
        val value = "Hello, world!"
        val serialized = json.encodeToString(AnySerializer(), value)
        val expected = "\"Hello, world!\""
        assertEquals(expected, serialized)
    }
}
