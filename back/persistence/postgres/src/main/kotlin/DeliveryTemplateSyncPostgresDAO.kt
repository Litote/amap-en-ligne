package persistence.postgres

import id.Id
import id.toId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.DeliveryTemplateSyncDAO
import persistence.model.DeliveryTemplate
import persistence.model.EarlySlot
import persistence.model.Organization
import serialization.json
import java.sql.ResultSet
import java.sql.Types

@Single(createdAtStart = true, binds = [DeliveryTemplateSyncDAO::class])
internal class DeliveryTemplateSyncPostgresDAO(
    private val client: PostgresClient,
) : DeliveryTemplateSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<DeliveryTemplate> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT delivery_template_id, organization_id, name,
                           standard_start_time, standard_end_time, volunteer_arrival_time,
                           desired_volunteer_count, early_slot
                    FROM delivery_template
                    WHERE organization_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toDeliveryTemplate())
                            }
                        }
                    }
                }
        }

    override suspend fun put(
        deliveryTemplate: DeliveryTemplate,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO delivery_template (
                        delivery_template_id, organization_id, name,
                        standard_start_time, standard_end_time, desired_volunteer_count, early_slot,
                        volunteer_arrival_time
                    ) VALUES (?, ?, ?, ?, ?, ?, ?::jsonb, ?)
                    ON CONFLICT (delivery_template_id)
                    DO UPDATE SET
                        organization_id = EXCLUDED.organization_id,
                        name = EXCLUDED.name,
                        standard_start_time = EXCLUDED.standard_start_time,
                        standard_end_time = EXCLUDED.standard_end_time,
                        desired_volunteer_count = EXCLUDED.desired_volunteer_count,
                        early_slot = EXCLUDED.early_slot,
                        volunteer_arrival_time = EXCLUDED.volunteer_arrival_time
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, deliveryTemplate.deliveryTemplateId.id)
                    stmt.setString(2, deliveryTemplate.organizationId.id)
                    stmt.setString(3, deliveryTemplate.name)
                    stmt.setString(4, deliveryTemplate.standardStartTime)
                    stmt.setString(5, deliveryTemplate.standardEndTime)
                    stmt.setInt(6, deliveryTemplate.desiredVolunteerCount)
                    val earlySlotJson = deliveryTemplate.earlySlot?.let { json.encodeToString(EarlySlot.serializer(), it) }
                    if (earlySlotJson == null) {
                        stmt.setNull(7, Types.OTHER)
                    } else {
                        stmt.setString(7, earlySlotJson)
                    }
                    stmt.setString(8, deliveryTemplate.volunteerArrivalTime)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }

    override suspend fun delete(
        deliveryTemplateId: Id<DeliveryTemplate>,
        organizationId: Id<Organization>,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "DELETE FROM delivery_template WHERE delivery_template_id = ? AND organization_id = ?",
                ).use { stmt ->
                    stmt.setString(1, deliveryTemplateId.id)
                    stmt.setString(2, organizationId.id)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

private fun ResultSet.toDeliveryTemplate(): DeliveryTemplate =
    DeliveryTemplate(
        deliveryTemplateId = getString("delivery_template_id").toId(),
        organizationId = getString("organization_id").toId(),
        name = getString("name"),
        standardStartTime = getString("standard_start_time"),
        standardEndTime = getString("standard_end_time"),
        desiredVolunteerCount = getInt("desired_volunteer_count"),
        earlySlot = getString("early_slot")?.let { json.decodeFromString(EarlySlot.serializer(), it) },
        volunteerArrivalTime = getString("volunteer_arrival_time"),
    )
