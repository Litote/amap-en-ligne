package core

import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlin.test.Test
import kotlin.test.assertEquals

class FrenchDatesTest {
    @Test
    fun `the first of the month reads 1er`() {
        assertEquals("1er octobre 2026", LocalDate(2026, 10, 1).toFrenchLongDate())
    }

    @Test
    fun `other days read as numbers`() {
        assertEquals("15 octobre 2026", LocalDate(2026, 10, 15).toFrenchLongDate())
        assertEquals("31 décembre 2026", LocalDate(2026, 12, 31).toFrenchLongDate())
    }

    @Test
    fun `a time reads with an h`() {
        assertEquals("18h00", LocalDateTime(2026, 10, 1, 18, 0).time.toFrenchTime())
        assertEquals("9h05", LocalDateTime(2026, 10, 1, 9, 5).time.toFrenchTime())
    }
}
