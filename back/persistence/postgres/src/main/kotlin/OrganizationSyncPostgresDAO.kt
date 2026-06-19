@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import kotlinx.datetime.TimeZone
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.OrganizationSyncDAO
import persistence.model.BasketSize
import persistence.model.Delivery
import persistence.model.DeliveryTemplate
import persistence.model.ItemType
import persistence.model.NotificationCategory
import persistence.model.NotificationCopyOverride
import persistence.model.Organization
import persistence.model.OrganizationProducer
import persistence.model.OrganizationProducerStatus
import persistence.model.ProducerAccount
import persistence.model.Product
import persistence.model.ProductType
import serialization.json
import java.sql.ResultSet
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

@Single(createdAtStart = true, binds = [OrganizationSyncDAO::class])
internal class OrganizationSyncPostgresDAO(
    private val client: PostgresClient,
) : OrganizationSyncDAO {
    override suspend fun getById(organizationId: Id<Organization>): Organization? =
        client.dataSource.query { conn ->
            val orgWithProducers =
                conn
                    .prepareStatement(
                        """
                        SELECT o.organization_id, o.name, o.contact_email, o.active_status,
                               o.timezone, o.default_language, o.website, o.default_delivery_template_id,
                               o.created_instant, o.last_updated_instant, o.deliveries, o.notification_overrides,
                               o.item_types,
                               op.producer_account_id, op.association_instant, op.status AS producer_status
                        FROM organization o
                        LEFT JOIN organization_producer op ON o.organization_id = op.organization_id
                        WHERE o.organization_id = ?
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId.id)
                        stmt.executeQuery().use { rs ->
                            var org: Organization? = null
                            val producers = mutableListOf<OrganizationProducer>()
                            while (rs.next()) {
                                if (org == null) {
                                    org = rs.toOrganizationBase()
                                }
                                val producerId = rs.getString("producer_account_id")
                                if (producerId != null) {
                                    producers.add(rs.toOrganizationProducer(producerId))
                                }
                            }
                            org?.copy(producers = producers)
                        }
                    } ?: return@query null

            val products =
                conn
                    .prepareStatement(
                        """
                        SELECT producer_account_id, product_type_id, name, supported_basket_sizes, description
                        FROM organization_product
                        WHERE organization_id = ?
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId.id)
                        stmt.executeQuery().use { rs ->
                            buildList {
                                while (rs.next()) {
                                    add(rs.toProduct())
                                }
                            }
                        }
                    }

            orgWithProducers.copy(products = products)
        }

    override suspend fun listAll(): List<Organization> =
        client.dataSource.query { conn ->
            val orgsById = LinkedHashMap<String, Organization>()
            val producersByOrgId = mutableMapOf<String, MutableList<OrganizationProducer>>()
            conn
                .prepareStatement(
                    """
                    SELECT o.organization_id, o.name, o.contact_email, o.active_status,
                           o.timezone, o.default_language, o.website, o.default_delivery_template_id,
                           o.created_instant, o.last_updated_instant, o.deliveries, o.notification_overrides,
                           o.item_types,
                           op.producer_account_id, op.association_instant, op.status AS producer_status
                    FROM organization o
                    LEFT JOIN organization_producer op ON o.organization_id = op.organization_id
                    ORDER BY o.organization_id
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.executeQuery().use { rs ->
                        while (rs.next()) {
                            val orgId = rs.getString("organization_id")
                            orgsById.getOrPut(orgId) { rs.toOrganizationBase() }
                            val producerId = rs.getString("producer_account_id")
                            if (producerId != null) {
                                producersByOrgId
                                    .getOrPut(orgId) { mutableListOf() }
                                    .add(rs.toOrganizationProducer(producerId))
                            }
                        }
                    }
                }

            val productsByOrgId = mutableMapOf<String, MutableList<Product>>()
            conn
                .prepareStatement(
                    """
                    SELECT organization_id, producer_account_id, product_type_id, name, supported_basket_sizes, description
                    FROM organization_product
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.executeQuery().use { rs ->
                        while (rs.next()) {
                            val orgId = rs.getString("organization_id")
                            productsByOrgId
                                .getOrPut(orgId) { mutableListOf() }
                                .add(rs.toProduct())
                        }
                    }
                }

            orgsById.entries.map { (orgId, org) ->
                org.copy(
                    producers = producersByOrgId[orgId] ?: emptyList(),
                    products = productsByOrgId[orgId] ?: emptyList(),
                )
            }
        }

    override suspend fun put(
        organization: Organization,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO organization (
                        organization_id, name, contact_email, active_status,
                        timezone, default_language, website, default_delivery_template_id, created_instant, last_updated_instant,
                        deliveries, notification_overrides, item_types
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?::jsonb, ?::jsonb, ?::jsonb)
                    ON CONFLICT (organization_id)
                    DO UPDATE SET
                        name = EXCLUDED.name,
                        contact_email = EXCLUDED.contact_email,
                        active_status = EXCLUDED.active_status,
                        timezone = EXCLUDED.timezone,
                        default_language = EXCLUDED.default_language,
                        website = EXCLUDED.website,
                        default_delivery_template_id = EXCLUDED.default_delivery_template_id,
                        created_instant = EXCLUDED.created_instant,
                        last_updated_instant = EXCLUDED.last_updated_instant,
                        deliveries = EXCLUDED.deliveries,
                        notification_overrides = EXCLUDED.notification_overrides,
                        item_types = EXCLUDED.item_types
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
                    stmt.setString(
                        11,
                        json.encodeToString(ListSerializer(Delivery.serializer()), organization.deliveries),
                    )
                    stmt.setString(
                        12,
                        json.encodeToString(
                            MapSerializer(NotificationCategory.serializer(), NotificationCopyOverride.serializer()),
                            organization.notificationOverrides,
                        ),
                    )
                    stmt.setString(
                        13,
                        json.encodeToString(ListSerializer(ItemType.serializer()), organization.itemTypes),
                    )
                    stmt.executeUpdate()
                }
            // Delete existing producer associations and re-insert
            conn
                .prepareStatement(
                    "DELETE FROM organization_producer WHERE organization_id = ?",
                ).use { stmt ->
                    stmt.setString(1, organization.organizationId.id)
                    stmt.executeUpdate()
                }
            for (producer in organization.producers) {
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
                        stmt.setString(1, organization.organizationId.id)
                        stmt.setString(2, producer.producerAccountId.id)
                        stmt.setLong(3, producer.associationInstant.toEpochMilliseconds())
                        stmt.setString(4, producer.status.name)
                        stmt.executeUpdate()
                    }
            }
            conn
                .prepareStatement(
                    "DELETE FROM organization_product WHERE organization_id = ?",
                ).use { stmt ->
                    stmt.setString(1, organization.organizationId.id)
                    stmt.executeUpdate()
                }
            for (product in organization.products) {
                conn
                    .prepareStatement(
                        """
                        INSERT INTO organization_product (organization_id, producer_account_id, product_type_id, name, supported_basket_sizes, description)
                        VALUES (?, ?, ?, ?, ?, ?)
                        ON CONFLICT (organization_id, producer_account_id, product_type_id)
                        DO UPDATE SET
                            name = EXCLUDED.name,
                            supported_basket_sizes = EXCLUDED.supported_basket_sizes,
                            description = EXCLUDED.description
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organization.organizationId.id)
                        stmt.setString(2, product.producerAccountId.id)
                        stmt.setString(3, product.productTypeId.id)
                        stmt.setString(4, product.name)
                        stmt.setString(
                            5,
                            json.encodeToString(ListSerializer(BasketSize.serializer()), product.supportedBasketSizes),
                        )
                        stmt.setString(6, product.description)
                        stmt.executeUpdate()
                    }
            }
            upsertChange(conn, change)
        }
    }

    override suspend fun delete(
        organizationId: Id<Organization>,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "DELETE FROM organization_producer WHERE organization_id = ?",
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.executeUpdate()
                }
            conn
                .prepareStatement(
                    "DELETE FROM organization WHERE organization_id = ?",
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

private fun ResultSet.toOrganizationBase(): Organization =
    Organization(
        organizationId = getString("organization_id").toId(),
        name = getString("name"),
        contactEmail = getString("contact_email"),
        activeStatus = getBoolean("active_status"),
        timezone = TimeZone.of(getString("timezone")),
        defaultLanguage = getString("default_language"),
        website = getString("website"),
        defaultDeliveryTemplateId = getString("default_delivery_template_id")?.toId<DeliveryTemplate>(),
        createdInstant = Instant.fromEpochMilliseconds(getLong("created_instant")),
        lastUpdatedInstant = Instant.fromEpochMilliseconds(getLong("last_updated_instant")),
        producers = emptyList(),
        products = emptyList(),
        deliveries =
            getString("deliveries")
                ?.let { json.decodeFromString(ListSerializer(Delivery.serializer()), it) }
                ?: emptyList(),
        itemTypes =
            getString("item_types")
                ?.let { json.decodeFromString(ListSerializer(ItemType.serializer()), it) }
                ?: emptyList(),
        notificationOverrides =
            getString("notification_overrides")
                ?.let {
                    json.decodeFromString(
                        MapSerializer(NotificationCategory.serializer(), NotificationCopyOverride.serializer()),
                        it,
                    )
                }
                ?: emptyMap(),
    )

private fun ResultSet.toOrganizationProducer(producerId: String): OrganizationProducer =
    OrganizationProducer(
        producerAccountId = producerId.toId<ProducerAccount>(),
        associationInstant = Instant.fromEpochMilliseconds(getLong("association_instant")),
        status = OrganizationProducerStatus.valueOf(getString("producer_status")),
    )

private fun ResultSet.toProduct(): Product =
    Product(
        name = getString("name"),
        productTypeId = getString("product_type_id").toId<ProductType>(),
        producerAccountId = getString("producer_account_id").toId<ProducerAccount>(),
        supportedBasketSizes =
            json.decodeFromString(
                ListSerializer(BasketSize.serializer()),
                getString("supported_basket_sizes"),
            ),
        description = getString("description"),
    )
