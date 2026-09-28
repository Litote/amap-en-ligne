package notificationpublisher

import persistence.model.Member
import persistence.model.NotificationChannel

/** Outbound channels the member opted into, derived from their synced preferences. */
fun Member.optedNotificationChannels(): Set<NotificationChannel> =
    buildSet {
        if (userPreferences.emailNotificationsEnabled) add(NotificationChannel.EMAIL)
        if (userPreferences.pushNotificationsEnabled) add(NotificationChannel.PUSH)
    }
