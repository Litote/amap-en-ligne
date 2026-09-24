package routing

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class PasswordPolicyTest {
    @Test
    fun `GIVEN a compliant password WHEN checked THEN no violation`() {
        assertNull(passwordPolicyViolation("Str0ngPassword"))
    }

    @Test
    fun `GIVEN non compliant passwords WHEN checked THEN the first violation is reported`() {
        assertEquals("password must be at least 12 characters long", passwordPolicyViolation("Sh0rt"))
        assertEquals("password must contain a lowercase letter", passwordPolicyViolation("ABCDEFGHIJK1"))
        assertEquals("password must contain an uppercase letter", passwordPolicyViolation("abcdefghijk1"))
        assertEquals("password must contain a digit", passwordPolicyViolation("Abcdefghijkl"))
    }
}
