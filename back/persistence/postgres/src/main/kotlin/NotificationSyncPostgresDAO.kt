@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.NotificationSyncDAO
import persistence.model.Notification
import persistence.model.NotificationCategory
import persistence.model.NotificationType
import java.sql.ResultSet
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [NotificationSyncDAO::class])
internal class NotificationSyncPostgresDAO(
    private val client: PostgresClient,
) : NotificationSyncDAO {
    override suspend fun getByRecipientScope(recipientScope: String): List<Notification> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT notification_id, recipient_scope, notification_type, category,
                           title, body, deep_link, related_entity_id, created_at, read_at
                    FROM notification
                    WHERE recipient_scope = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, recipientScope)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toNotification())
                            }
                        }
                    }
                }
        }

    override suspend fun findById(
        recipientScope: String,
        notificationId: Id<Notification>,
    ): Notification? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT notification_id, recipient_scope, notification_type, category,
                           title, body, deep_link, related_entity_id, created_at, read_at
                    FROM notification
                    WHERE recipient_scope = ? AND notification_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, recipientScope)
                    stmt.setString(2, notificationId.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toNotification() else null
                    }
                }
        }

    override suspend fun put(
        notification: Notification,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO notification (
                        notification_id, recipient_scope, notification_type, category,
                        title, body, deep_link, related_entity_id, created_at, read_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (notification_id)
                    DO UPDATE SET
                        recipient_scope = EXCLUDED.recipient_scope,
                        notification_type = EXCLUDED.notification_type,
                        category = EXCLUDED.category,
                        title = EXCLUDED.title,
                        body = EXCLUDED.body,
                        deep_link = EXCLUDED.deep_link,
                        related_entity_id = EXCLUDED.related_entity_id,
                        created_at = EXCLUDED.created_at,
                        read_at = EXCLUDED.read_at
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, notification.notificationId.id)
                    stmt.setString(2, notification.recipientScope)
                    stmt.setString(3, notification.type.name)
                    stmt.setString(4, notification.category.name)
                    stmt.setString(5, notification.title)
                    stmt.setString(6, notification.body)
                    stmt.setString(7, notification.deepLink)
                    stmt.setString(8, notification.relatedEntityId)
                    stmt.setLong(9, notification.createdAt.toEpochMilliseconds())
                    val readAt = notification.readAt
                    if (readAt == null) {
                        stmt.setNull(10, java.sql.Types.BIGINT)
                    } else {
                        stmt.setLong(10, readAt.toEpochMilliseconds())
                    }
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }

    override suspend fun delete(
        recipientScope: String,
        notificationId: Id<Notification>,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "DELETE FROM notification WHERE recipient_scope = ? AND notification_id = ?",
                ).use { stmt ->
                    stmt.setString(1, recipientScope)
                    stmt.setString(2, notificationId.id)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

@OptIn(ExperimentalTime::class)
private fun ResultSet.toNotification(): Notification =
    Notification(
        notificationId = getString("notification_id").toId(),
        recipientScope = getString("recipient_scope"),
        type = NotificationType.valueOf(getString("notification_type")),
        category = NotificationCategory.valueOf(getString("category")),
        title = getString("title"),
        body = getString("body"),
        deepLink = getString("deep_link"),
        relatedEntityId = getString("related_entity_id"),
        createdAt = Instant.fromEpochMilliseconds(getLong("created_at")),
        readAt = getLong("read_at").takeUnless { wasNull() }?.let { Instant.fromEpochMilliseconds(it) },
    )
