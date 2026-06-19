@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import kotlinx.serialization.builtins.ListSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ProducerAccountSyncDAO
import persistence.model.BasketSize
import persistence.model.LinkedProducerAccount
import persistence.model.Organization
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.ProducerManagementMode
import persistence.model.ProducerOrganization
import persistence.model.ProducerProduct
import persistence.model.ProductType
import persistence.model.UserPreferences
import serialization.json
import java.sql.ResultSet
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [ProducerAccountSyncDAO::class])
internal class ProducerAccountSyncPostgresDAO(
    private val client: PostgresClient,
) : ProducerAccountSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<ProducerAccount> =
        client.dataSource.query { conn ->
            val producerIds =
                conn
                    .prepareStatement(
                        """
                        SELECT pa.producer_account_id, pa.name, pa.contact_email, pa.address,
                               pa.website, pa.active_status, pa.created_instant, pa.last_updated_instant,
                               pa.user_preferences, pa.management_mode, pa.linked_producer_account_id,
                               pa.linked_producer_account_name
                        FROM producer_account pa
                        INNER JOIN organization_producer op ON pa.producer_account_id = op.producer_account_id
                        WHERE op.organization_id = ?
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId.id)
                        stmt.executeQuery().use { rs ->
                            buildList {
                                while (rs.next()) {
                                    add(rs.toProducerAccountBase())
                                }
                            }
                        }
                    }

            producerIds.map { producer ->
                val organizations =
                    conn
                        .prepareStatement(
                            """
                            SELECT organization_id, association_instant, status
                            FROM organization_producer
                            WHERE producer_account_id = ?
                            """.trimIndent(),
                        ).use { stmt ->
                            stmt.setString(1, producer.producerAccountId.id)
                            stmt.executeQuery().use { rs ->
                                buildList {
                                    while (rs.next()) {
                                        add(rs.toProducerOrganization())
                                    }
                                }
                            }
                        }

                val products =
                    conn
                        .prepareStatement(
                            """
                            SELECT product_type_id, name, description, supported_basket_sizes
                            FROM product_type
                            WHERE producer_account_id = ?
                            """.trimIndent(),
                        ).use { stmt ->
                            stmt.setString(1, producer.producerAccountId.id)
                            stmt.executeQuery().use { rs ->
                                buildList {
                                    while (rs.next()) {
                                        add(rs.toProducerProduct())
                                    }
                                }
                            }
                        }

                producer.copy(organizations = organizations, products = products)
            }
        }

    override suspend fun put(
        producerAccount: ProducerAccount,
        organizationId: Id<Organization>,
        changes: List<Change>,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO producer_account (
                        producer_account_id, name, contact_email, address, website,
                        active_status, created_instant, last_updated_instant, user_preferences,
                        management_mode, linked_producer_account_id, linked_producer_account_name
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?::jsonb, ?, ?, ?)
                    ON CONFLICT (producer_account_id)
                    DO UPDATE SET
                        name = EXCLUDED.name,
                        contact_email = EXCLUDED.contact_email,
                        address = EXCLUDED.address,
                        website = EXCLUDED.website,
                        active_status = EXCLUDED.active_status,
                        created_instant = EXCLUDED.created_instant,
                        last_updated_instant = EXCLUDED.last_updated_instant,
                        user_preferences = EXCLUDED.user_preferences,
                        management_mode = EXCLUDED.management_mode,
                        linked_producer_account_id = EXCLUDED.linked_producer_account_id,
                        linked_producer_account_name = EXCLUDED.linked_producer_account_name
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerAccount.producerAccountId.id)
                    stmt.setString(2, producerAccount.name)
                    stmt.setString(3, producerAccount.contactEmail)
                    stmt.setString(4, producerAccount.address)
                    stmt.setString(5, producerAccount.website)
                    stmt.setBoolean(6, producerAccount.activeStatus)
                    stmt.setLong(7, producerAccount.createdInstant.toEpochMilliseconds())
                    stmt.setLong(8, producerAccount.lastUpdatedInstant.toEpochMilliseconds())
                    stmt.setString(9, json.encodeToString(UserPreferences.serializer(), producerAccount.userPreferences))
                    stmt.setString(10, producerAccount.managementMode.name)
                    stmt.setString(11, producerAccount.linkedProducerAccount?.producerAccountId?.id)
                    stmt.setString(12, producerAccount.linkedProducerAccount?.name)
                    stmt.executeUpdate()
                }
            // Upsert the organization association
            val orgAssoc = producerAccount.organizations.firstOrNull { it.organizationId == organizationId }
            if (orgAssoc != null) {
                conn
                    .prepareStatement(
                        """
                        INSERT INTO organization_producer (organization_id, producer_account_id, association_instant, status)
                        VALUES (?, ?, ?, ?)
                        ON CONFLICT (organization_id, producer_account_id)
                        DO UPDATE SET
                            association_instant = EXCLUDED.association_instant,
                            status = EXCLUDED.status
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId.id)
                        stmt.setString(2, producerAccount.producerAccountId.id)
                        stmt.setLong(3, orgAssoc.associationInstant.toEpochMilliseconds())
                        stmt.setString(4, orgAssoc.status.name)
                        stmt.executeUpdate()
                    }
            } else {
                conn
                    .prepareStatement(
                        """
                        INSERT INTO organization_producer (organization_id, producer_account_id, association_instant, status)
                        VALUES (?, ?, ?, 'ACTIVE')
                        ON CONFLICT (organization_id, producer_account_id) DO NOTHING
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId.id)
                        stmt.setString(2, producerAccount.producerAccountId.id)
                        stmt.setLong(3, producerAccount.createdInstant.toEpochMilliseconds())
                        stmt.executeUpdate()
                    }
            }
            if (producerAccount.managementMode == ProducerManagementMode.NO_ACCOUNT) {
                conn
                    .prepareStatement(
                        "DELETE FROM product_type WHERE producer_account_id = ?",
                    ).use { stmt ->
                        stmt.setString(1, producerAccount.producerAccountId.id)
                        stmt.executeUpdate()
                    }
                for (product in producerAccount.products) {
                    conn
                        .prepareStatement(
                            """
                            INSERT INTO product_type (producer_account_id, product_type_id, name, description, supported_basket_sizes)
                            VALUES (?, ?, ?, ?, ?::jsonb)
                            ON CONFLICT (producer_account_id, product_type_id)
                            DO UPDATE SET
                                name = EXCLUDED.name,
                                description = EXCLUDED.description,
                                supported_basket_sizes = EXCLUDED.supported_basket_sizes
                            """.trimIndent(),
                        ).use { stmt ->
                            stmt.setString(1, producerAccount.producerAccountId.id)
                            stmt.setString(2, product.productTypeId.id)
                            stmt.setString(3, product.name)
                            stmt.setString(4, product.description)
                            stmt.setString(5, json.encodeToString(ListSerializer(BasketSize.serializer()), product.supportedBasketSizes))
                            stmt.executeUpdate()
                        }
                }
            }
            upsertChanges(conn, changes)
        }
    }

    override suspend fun delete(
        producerAccountId: Id<ProducerAccount>,
        organizationId: Id<Organization>,
        changes: List<Change>,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "DELETE FROM organization_producer WHERE producer_account_id = ? AND organization_id = ?",
                ).use { stmt ->
                    stmt.setString(1, producerAccountId.id)
                    stmt.setString(2, organizationId.id)
                    stmt.executeUpdate()
                }
            upsertChanges(conn, changes)
        }
    }

    override suspend fun findById(producerAccountId: Id<ProducerAccount>): ProducerAccount? =
        client.dataSource.query { conn ->
            val producer =
                conn
                    .prepareStatement(
                        """
                        SELECT producer_account_id, name, contact_email, address,
                               website, active_status, created_instant, last_updated_instant,
                               user_preferences, management_mode, linked_producer_account_id,
                               linked_producer_account_name
                        FROM producer_account
                        WHERE producer_account_id = ?
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, producerAccountId.id)
                        stmt.executeQuery().use { rs ->
                            if (rs.next()) rs.toProducerAccountBase() else null
                        }
                    }
            producer?.let { base ->
                val organizations =
                    conn
                        .prepareStatement(
                            """
                            SELECT organization_id, association_instant, status
                            FROM organization_producer
                            WHERE producer_account_id = ?
                            """.trimIndent(),
                        ).use { stmt ->
                            stmt.setString(1, producerAccountId.id)
                            stmt.executeQuery().use { rs ->
                                buildList {
                                    while (rs.next()) add(rs.toProducerOrganization())
                                }
                            }
                        }
                base.copy(organizations = organizations)
            }
        }

    override suspend fun updateActiveStatus(
        producerAccountId: Id<ProducerAccount>,
        activeStatus: Boolean,
        changes: List<Change>,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    UPDATE producer_account
                    SET active_status = ?, last_updated_instant = ?
                    WHERE producer_account_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setBoolean(1, activeStatus)
                    stmt.setLong(2, System.currentTimeMillis())
                    stmt.setString(3, producerAccountId.id)
                    stmt.executeUpdate()
                }
            upsertChanges(conn, changes)
        }
    }

    override suspend fun listAll(): List<ProducerAccount> =
        client.dataSource.query { conn ->
            val producers =
                conn
                    .prepareStatement(
                        """
                        SELECT producer_account_id, name, contact_email, address,
                               website, active_status, created_instant, last_updated_instant,
                               user_preferences, management_mode, linked_producer_account_id,
                               linked_producer_account_name
                        FROM producer_account
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.executeQuery().use { rs ->
                            buildList {
                                while (rs.next()) {
                                    add(rs.toProducerAccountBase())
                                }
                            }
                        }
                    }

            producers.map { producer ->
                val organizations =
                    conn
                        .prepareStatement(
                            """
                            SELECT organization_id, association_instant, status
                            FROM organization_producer
                            WHERE producer_account_id = ?
                            """.trimIndent(),
                        ).use { stmt ->
                            stmt.setString(1, producer.producerAccountId.id)
                            stmt.executeQuery().use { rs ->
                                buildList {
                                    while (rs.next()) {
                                        add(rs.toProducerOrganization())
                                    }
                                }
                            }
                        }
                val products =
                    conn
                        .prepareStatement(
                            """
                            SELECT product_type_id, name, description, supported_basket_sizes
                            FROM product_type
                            WHERE producer_account_id = ?
                            """.trimIndent(),
                        ).use { stmt ->
                            stmt.setString(1, producer.producerAccountId.id)
                            stmt.executeQuery().use { rs ->
                                buildList {
                                    while (rs.next()) {
                                        add(rs.toProducerProduct())
                                    }
                                }
                            }
                        }
                producer.copy(organizations = organizations, products = products)
            }
        }

    override suspend fun search(
        organizationId: Id<Organization>,
        query: String,
    ): List<ProducerAccount> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT pa.producer_account_id, pa.name, pa.contact_email, pa.address,
                           pa.website, pa.active_status, pa.created_instant, pa.last_updated_instant,
                           pa.user_preferences, pa.management_mode, pa.linked_producer_account_id,
                           pa.linked_producer_account_name
                    FROM producer_account pa
                    WHERE pa.active_status = TRUE
                      AND pa.management_mode = 'ACCOUNT_BACKED'
                      AND (LOWER(pa.name) LIKE LOWER(?) OR LOWER(pa.contact_email) LIKE LOWER(?))
                      AND pa.producer_account_id NOT IN (
                          SELECT op.producer_account_id
                          FROM organization_producer op
                          WHERE op.organization_id = ?
                            AND op.status IN ('ACTIVE', 'SUSPENDED')
                      )
                      AND pa.producer_account_id NOT IN (
                          SELECT source.linked_producer_account_id
                          FROM producer_account source
                          INNER JOIN organization_producer op ON source.producer_account_id = op.producer_account_id
                          WHERE source.management_mode = 'NO_ACCOUNT'
                            AND source.linked_producer_account_id IS NOT NULL
                            AND op.organization_id = ?
                            AND op.status IN ('ACTIVE', 'SUSPENDED')
                      )
                    LIMIT 20
                    """.trimIndent(),
                ).use { stmt ->
                    val pattern = "%$query%"
                    stmt.setString(1, pattern)
                    stmt.setString(2, pattern)
                    stmt.setString(3, organizationId.id)
                    stmt.setString(4, organizationId.id)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toProducerAccountBase())
                            }
                        }
                    }
                }
        }

    override suspend fun createInitial(
        producerAccount: ProducerAccount,
        organizationId: Id<Organization>,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO producer_account(
                        producer_account_id, name, contact_email, active_status, created_instant, last_updated_instant,
                        management_mode, linked_producer_account_id, linked_producer_account_name
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerAccount.producerAccountId.id)
                    stmt.setString(2, producerAccount.name)
                    stmt.setString(3, producerAccount.contactEmail)
                    stmt.setBoolean(4, producerAccount.activeStatus)
                    stmt.setLong(5, producerAccount.createdInstant.toEpochMilliseconds())
                    stmt.setLong(6, producerAccount.lastUpdatedInstant.toEpochMilliseconds())
                    stmt.setString(7, producerAccount.managementMode.name)
                    stmt.setString(8, producerAccount.linkedProducerAccount?.producerAccountId?.id)
                    stmt.setString(9, producerAccount.linkedProducerAccount?.name)
                    stmt.executeUpdate()
                }
            conn
                .prepareStatement(
                    """
                    INSERT INTO organization_producer(organization_id, producer_account_id, association_instant, status)
                    VALUES (?, ?, ?, 'ACTIVE')
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.setString(2, producerAccount.producerAccountId.id)
                    stmt.setLong(3, producerAccount.createdInstant.toEpochMilliseconds())
                    stmt.executeUpdate()
                }
        }
    }

    override suspend fun createStandalone(producerAccount: ProducerAccount) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO producer_account(
                        producer_account_id, name, contact_email, active_status, created_instant, last_updated_instant,
                        management_mode, linked_producer_account_id, linked_producer_account_name
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (producer_account_id) DO NOTHING
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerAccount.producerAccountId.id)
                    stmt.setString(2, producerAccount.name)
                    stmt.setString(3, producerAccount.contactEmail)
                    stmt.setBoolean(4, producerAccount.activeStatus)
                    stmt.setLong(5, producerAccount.createdInstant.toEpochMilliseconds())
                    stmt.setLong(6, producerAccount.lastUpdatedInstant.toEpochMilliseconds())
                    stmt.setString(7, producerAccount.managementMode.name)
                    stmt.setString(8, producerAccount.linkedProducerAccount?.producerAccountId?.id)
                    stmt.setString(9, producerAccount.linkedProducerAccount?.name)
                    stmt.executeUpdate()
                }
        }
    }

    override suspend fun updateProfile(
        producerAccount: ProducerAccount,
        changes: List<Change>,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    UPDATE producer_account
                    SET name = ?, contact_email = ?, address = ?, website = ?, last_updated_instant = ?
                    WHERE producer_account_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerAccount.name)
                    stmt.setString(2, producerAccount.contactEmail)
                    stmt.setString(3, producerAccount.address)
                    stmt.setString(4, producerAccount.website)
                    stmt.setLong(5, producerAccount.lastUpdatedInstant.toEpochMilliseconds())
                    stmt.setString(6, producerAccount.producerAccountId.id)
                    stmt.executeUpdate()
                }
            upsertChanges(conn, changes)
        }
    }
}

private fun ResultSet.toProducerAccountBase(): ProducerAccount =
    ProducerAccount(
        producerAccountId = getString("producer_account_id").toId(),
        name = getString("name"),
        contactEmail = getString("contact_email"),
        address = getString("address"),
        website = getString("website"),
        activeStatus = getBoolean("active_status"),
        createdInstant = Instant.fromEpochMilliseconds(getLong("created_instant")),
        lastUpdatedInstant = Instant.fromEpochMilliseconds(getLong("last_updated_instant")),
        users = emptyList(),
        organizations = emptyList(),
        products = emptyList(),
        userPreferences = json.decodeFromString(UserPreferences.serializer(), getString("user_preferences")),
        managementMode =
            getString("management_mode")?.let(ProducerManagementMode::valueOf)
                ?: ProducerManagementMode.ACCOUNT_BACKED,
        linkedProducerAccount =
            getString("linked_producer_account_id")?.toId<ProducerAccount>()?.let { linkedProducerAccountId ->
                LinkedProducerAccount(
                    producerAccountId = linkedProducerAccountId,
                    name = getString("linked_producer_account_name") ?: "",
                )
            },
    )

private fun ResultSet.toProducerOrganization(): ProducerOrganization =
    ProducerOrganization(
        organizationId = getString("organization_id").toId<Organization>(),
        associationInstant = Instant.fromEpochMilliseconds(getLong("association_instant")),
        status = OrganizationProducerStatus.valueOf(getString("status")),
    )

private fun ResultSet.toProducerProduct(): ProducerProduct =
    ProducerProduct(
        name = getString("name"),
        productTypeId = getString("product_type_id").toId<ProductType>(),
        supportedBasketSizes =
            json.decodeFromString(
                ListSerializer(BasketSize.serializer()),
                getString("supported_basket_sizes"),
            ),
        description = getString("description"),
    )
