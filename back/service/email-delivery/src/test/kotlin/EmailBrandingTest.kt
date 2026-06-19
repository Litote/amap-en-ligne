package email.delivery

import persistence.model.EmailMessage
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class EmailBrandingTest {
    @Test
    fun `GIVEN email message WHEN withInstanceBranding applied THEN subject is prefixed and footer is appended`() {
        val message = EmailMessage("user@example.org", "Invitation à rejoindre votre AMAP", "Bonjour,\n\nCorps du mail.")
        val branded = message.withInstanceBranding("https://test.example.org")
        assertEquals("[AmapEnLigne] Invitation à rejoindre votre AMAP", branded.subject)
        assertTrue(branded.body.endsWith("\n\nAmapEnLigne: https://test.example.org"))
        assertEquals("user@example.org", branded.to)
    }

    @Test
    fun `GIVEN email message WHEN withInstanceBranding applied THEN original message is not mutated`() {
        val original = EmailMessage("a@b.com", "Sujet", "Corps")
        original.withInstanceBranding("https://test.example.org")
        assertEquals("Sujet", original.subject)
    }

    @Test
    fun `GIVEN a subject already prefixed with an AMAP tag WHEN withInstanceBranding applied THEN it is not double-branded`() {
        val message = EmailMessage("user@example.org", "[Ma Super AMAP] Créneau annulé", "Corps")
        val branded = message.withInstanceBranding("https://test.example.org")
        assertEquals("[Ma Super AMAP] Créneau annulé", branded.subject)
        // The instance footer is still appended.
        assertTrue(branded.body.endsWith("\n\nAmapEnLigne: https://test.example.org"))
    }
}
