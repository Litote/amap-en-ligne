package i18n

import kotlinx.datetime.IllegalTimeZoneException
import kotlinx.datetime.TimeZone
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class TimeZoneIdSerializerTest {
    @Test
    fun `GIVEN a time zone WHEN encoded THEN its identifier is written`() {
        assertEquals("\"Europe/Paris\"", Json.encodeToString(TimeZoneIdSerializer, TimeZone.of("Europe/Paris")))
    }

    @Test
    fun `GIVEN an identifier WHEN decoded THEN the time zone is restored`() {
        assertEquals(TimeZone.of("America/Cayenne"), Json.decodeFromString(TimeZoneIdSerializer, "\"America/Cayenne\""))
    }

    @Test
    fun `GIVEN an unknown identifier WHEN decoded THEN decoding fails`() {
        assertFailsWith<IllegalTimeZoneException> {
            Json.decodeFromString(TimeZoneIdSerializer, "\"Mars/Olympus\"")
        }
    }
}
