package notificationpublisher

import persistence.model.NotificationCategory
import persistence.model.NotificationCopyOverride
import kotlin.test.Test
import kotlin.test.assertEquals

internal class NotificationCopyTest {
    @Test
    fun `GIVEN no override WHEN resolveCopy THEN returns defaults`() {
        val copy =
            emptyMap<NotificationCategory, NotificationCopyOverride>()
                .resolveCopy(NotificationCategory.SLOT_CANCELLED, "Default title", "Default body")
        assertEquals("Default title", copy.title)
        assertEquals("Default body", copy.body)
    }

    @Test
    fun `GIVEN a full override WHEN resolveCopy THEN returns the override verbatim`() {
        val overrides =
            mapOf(
                NotificationCategory.SLOT_CANCELLED to
                    NotificationCopyOverride(title = "Custom", body = "Custom body"),
            )
        val copy = overrides.resolveCopy(NotificationCategory.SLOT_CANCELLED, "Default title", "Default body")
        assertEquals("Custom", copy.title)
        assertEquals("Custom body", copy.body)
    }

    @Test
    fun `GIVEN a partial or blank override WHEN resolveCopy THEN each part falls back independently`() {
        val overrides =
            mapOf(
                NotificationCategory.SLOT_CANCELLED to
                    NotificationCopyOverride(title = "Only title", body = "  "),
            )
        val copy = overrides.resolveCopy(NotificationCategory.SLOT_CANCELLED, "Default title", "Default body")
        assertEquals("Only title", copy.title)
        assertEquals("Default body", copy.body)
    }

    @Test
    fun `GIVEN an override for a different category WHEN resolveCopy THEN returns defaults`() {
        val overrides =
            mapOf(
                NotificationCategory.SLOT_RESCHEDULED to
                    NotificationCopyOverride(title = "Other", body = "Other"),
            )
        val copy = overrides.resolveCopy(NotificationCategory.SLOT_CANCELLED, "Default title", "Default body")
        assertEquals("Default title", copy.title)
        assertEquals("Default body", copy.body)
    }
}
