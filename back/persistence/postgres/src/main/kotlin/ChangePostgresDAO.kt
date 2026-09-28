package persistence.postgres

import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.EntityPayload
import persistence.dao.ChangeDAO
import persistence.model.EntityType
import serialization.json
import java.sql.Connection
import java.sql.ResultSet
import java.sql.Types

private const val SELECT_CHANGE_COLUMNS = """
    SELECT cursor, entity_type, scope_key, entity_id, op, payload, produced_at
    FROM changes
    WHERE scope_key = ?
"""

@Single(createdAtStart = true, binds = [ChangeDAO::class])
internal class ChangePostgresDAO(
    private val client: PostgresClient,
) : ChangeDAO {
    override suspend fun countSince(
        scopeKey: String,
        cursor: String?,
        limit: Int,
    ): Int =
        client.dataSource.query { conn ->
            val sql =
                if (cursor == null) {
                    """
                    SELECT COUNT(*) AS row_count
                    FROM (
                        SELECT 1
                        FROM changes
                        WHERE scope_key = ?
                        LIMIT ?
                    ) counted
                    """.trimIndent()
                } else {
                    """
                    SELECT COUNT(*) AS row_count
                    FROM (
                        SELECT 1
                        FROM changes
                        WHERE scope_key = ? AND cursor > ?
                        LIMIT ?
                    ) counted
                    """.trimIndent()
                }
            conn.prepareStatement(sql).use { stmt ->
                stmt.setString(1, scopeKey)
                if (cursor == null) {
                    stmt.setInt(2, limit)
                } else {
                    stmt.setString(2, cursor)
                    stmt.setInt(3, limit)
                }
                stmt.executeQuery().use { rs ->
                    rs.next()
                    rs.getInt("row_count")
                }
            }
        }

    override suspend fun since(
        scopeKey: String,
        cursor: String?,
    ): List<Change> =
        client.dataSource.query { conn ->
            val sql =
                if (cursor == null) {
                    "$SELECT_CHANGE_COLUMNS ORDER BY cursor ASC"
                } else {
                    "$SELECT_CHANGE_COLUMNS AND cursor > ? ORDER BY cursor ASC"
                }
            conn.prepareStatement(sql.trimIndent()).use { stmt ->
                stmt.setString(1, scopeKey)
                if (cursor != null) {
                    stmt.setString(2, cursor)
                }
                stmt.executeQuery().use(::readChanges)
            }
        }
}

internal fun upsertChange(
    conn: Connection,
    change: Change,
) {
    conn
        .prepareStatement(
            """
            INSERT INTO changes (cursor, scope_key, entity_type, entity_id, op, payload, produced_at)
            VALUES (?, ?, ?, ?, ?, ?::jsonb, ?)
            ON CONFLICT (scope_key, entity_type, entity_id)
            DO UPDATE SET
                cursor = EXCLUDED.cursor,
                op = EXCLUDED.op,
                payload = EXCLUDED.payload,
                produced_at = EXCLUDED.produced_at
            """.trimIndent(),
        ).use { stmt ->
            stmt.setString(1, change.cursor)
            stmt.setString(2, change.scopeKey)
            stmt.setString(3, change.entityType.name)
            stmt.setString(4, change.entityId)
            stmt.setString(5, change.op.name)
            val payload = change.payload
            if (payload == null) {
                stmt.setNull(6, Types.OTHER)
            } else {
                stmt.setString(6, json.encodeToString(EntityPayload.serializer(), payload))
            }
            stmt.setLong(7, change.producedAt)
            stmt.executeUpdate()
        }
}

internal fun upsertChanges(
    conn: Connection,
    changes: List<Change>,
) {
    changes.forEach { upsertChange(conn, it) }
}

private fun readChanges(rs: ResultSet): List<Change> =
    buildList {
        while (rs.next()) {
            val payloadJson = rs.getString("payload")
            val payload =
                payloadJson?.let { json.decodeFromString(EntityPayload.serializer(), it) }
            add(
                Change(
                    cursor = rs.getString("cursor"),
                    entityType = EntityType.valueOf(rs.getString("entity_type")),
                    scopeKey = rs.getString("scope_key"),
                    entityId = rs.getString("entity_id"),
                    op = ChangeOp.valueOf(rs.getString("op")),
                    payload = payload,
                    producedAt = rs.getLong("produced_at"),
                ),
            )
        }
    }
