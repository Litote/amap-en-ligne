package core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class InputRulesTest {
    @Test
    fun `GIVEN emails WHEN checked THEN only local-at-domain-dot-tld shapes are valid`() {
        assertTrue(InputRules.isValidEmail("jean@example.com"))
        assertTrue(InputRules.isValidEmail(" jean+amap@example.co.uk "))
        assertFalse(InputRules.isValidEmail("not-an-email"))
        assertFalse(InputRules.isValidEmail("jean@example"))
        assertFalse(InputRules.isValidEmail("je an@example.com"))
    }

    @Test
    fun `GIVEN urls WHEN checked THEN only http and https with a host are valid`() {
        assertTrue(InputRules.isValidHttpUrl("https://amap.example.org"))
        assertTrue(InputRules.isValidHttpUrl("http://amap.example.org/page"))
        assertFalse(InputRules.isValidHttpUrl("ftp://amap.example.org"))
        assertFalse(InputRules.isValidHttpUrl("amap.example.org"))
    }

    @Test
    fun `GIVEN HH-MM strings WHEN parsed THEN minutes since midnight or null`() {
        assertEquals(18 * 60 + 30, InputRules.minutesOf("18:30"))
        assertNull(InputRules.minutesOf("25:00"))
        assertNull(InputRules.minutesOf("18h30"))
    }

    @Test
    fun `GIVEN field values WHEN required rules applied THEN reasons name the field`() {
        assertNull(InputRules.requireName("name", "AMAP"))
        assertEquals("name must not be blank", InputRules.requireName("name", "  "))
        assertEquals("name must not exceed 200 characters", InputRules.requireName("name", "x".repeat(201)))
        assertEquals("email is not a valid email address", InputRules.requireEmail("email", "bad"))
        assertNull(InputRules.optionalEmail("email", null))
        assertNull(InputRules.optionalEmail("email", " "))
        assertEquals("website is not a valid http(s) URL", InputRules.optionalHttpUrl("website", "nope"))
        assertEquals("count must be at least 1", InputRules.requireAtLeast("count", 0, 1))
    }
}
