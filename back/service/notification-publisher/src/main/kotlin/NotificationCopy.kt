package notificationpublisher

import persistence.model.NotificationCategory
import persistence.model.NotificationCopyOverride

/** Resolved title/body for a notification, after applying any org-level override. */
data class NotificationCopy(
    val title: String,
    val body: String,
)

/**
 * Resolves the title/body to use for [category], preferring a non-blank admin override
 * (see `Organization.notificationOverrides`) over the hardcoded [defaultTitle] /
 * [defaultBody]. Each part falls back independently. Overrides are applied verbatim.
 */
fun Map<NotificationCategory, NotificationCopyOverride>.resolveCopy(
    category: NotificationCategory,
    defaultTitle: String,
    defaultBody: String,
): NotificationCopy {
    val override = this[category]
    return NotificationCopy(
        title = override?.title?.takeIf { it.isNotBlank() } ?: defaultTitle,
        body = override?.body?.takeIf { it.isNotBlank() } ?: defaultBody,
    )
}
