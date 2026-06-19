package persistence.postgres

import id.toId
import org.koin.core.annotation.Single
import persistence.dao.OrganizationDAO
import persistence.model.Organization
import persistence.model.PublicOrganizationSummary

@Single(createdAtStart = true, binds = [OrganizationDAO::class])
internal class OrganizationPostgresDAO(
    private val client: PostgresClient,
) : OrganizationDAO {
    override suspend fun listActive(): List<PublicOrganizationSummary> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT organization_id, name, contact_email, active_status
                    FROM organization
                    WHERE active_status = true
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(
                                    PublicOrganizationSummary(
                                        organizationId = rs.getString("organization_id").toId(),
                                        name = rs.getString("name"),
                                        contactEmail = rs.getString("contact_email"),
                                        activeStatus = rs.getBoolean("active_status"),
                                    ),
                                )
                            }
                        }
                    }
                }
        }

    override suspend fun create(organization: Organization) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO organization(
                        organization_id, name, contact_email, active_status, timezone, default_language,
                        website, default_delivery_template_id, created_instant, last_updated_instant
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organization.organizationId.id)
                    stmt.setString(2, organization.name)
                    stmt.setString(3, organization.contactEmail)
                    stmt.setBoolean(4, organization.activeStatus)
                    stmt.setString(5, organization.timezone.id)
                    stmt.setString(6, organization.defaultLanguage)
                    stmt.setString(7, organization.website)
                    stmt.setString(8, organization.defaultDeliveryTemplateId?.id)
                    stmt.setLong(9, organization.createdInstant.toEpochMilliseconds())
                    stmt.setLong(10, organization.lastUpdatedInstant.toEpochMilliseconds())
                    stmt.executeUpdate()
                }
        }
    }
}
