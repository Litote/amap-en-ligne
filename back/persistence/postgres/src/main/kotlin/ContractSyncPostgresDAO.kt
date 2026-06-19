@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ContractSyncDAO
import persistence.model.Contract
import persistence.model.ContractMember
import persistence.model.ContractStatus
import persistence.model.DeliveryTemplate
import persistence.model.Member
import persistence.model.Organization
import persistence.model.ProductPrice
import persistence.model.SharedBasket
import serialization.json
import java.sql.ResultSet
import kotlin.time.ExperimentalTime

private val productPriceListSerializer = ListSerializer(ProductPrice.serializer())
private val contractMemberListSerializer = ListSerializer(ContractMember.serializer())
private val sharedBasketListSerializer = ListSerializer(SharedBasket.serializer())

@Single(createdAtStart = true, binds = [ContractSyncDAO::class])
internal class ContractSyncPostgresDAO(
    private val client: PostgresClient,
) : ContractSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<Contract> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT contract_id, name, organization_id, producer_account_id, product_prices_json,
                           min_delivery_date, max_delivery_date, delivery_count,
                           season_year, coordinators, members, status, delivery_template_id, shared_baskets,
                           is_main_contract
                    FROM contract
                    WHERE organization_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toContract())
                            }
                        }
                    }
                }
        }

    override suspend fun put(
        contract: Contract,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO contract (
                        contract_id, name, organization_id, producer_account_id, product_prices_json,
                        min_delivery_date, max_delivery_date, delivery_count,
                        season_year, coordinators, members, status, delivery_template_id, shared_baskets,
                        is_main_contract
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?::jsonb, ?::jsonb, ?, ?, ?::jsonb, ?)
                    ON CONFLICT (contract_id)
                    DO UPDATE SET
                        name = EXCLUDED.name,
                        organization_id = EXCLUDED.organization_id,
                        producer_account_id = EXCLUDED.producer_account_id,
                        product_prices_json = EXCLUDED.product_prices_json,
                        min_delivery_date = EXCLUDED.min_delivery_date,
                        max_delivery_date = EXCLUDED.max_delivery_date,
                        delivery_count = EXCLUDED.delivery_count,
                        season_year = EXCLUDED.season_year,
                        coordinators = EXCLUDED.coordinators,
                        members = EXCLUDED.members,
                        status = EXCLUDED.status,
                        delivery_template_id = EXCLUDED.delivery_template_id,
                        shared_baskets = EXCLUDED.shared_baskets,
                        is_main_contract = EXCLUDED.is_main_contract
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, contract.contractId.id)
                    stmt.setString(2, contract.name)
                    stmt.setString(3, contract.organizationId.id)
                    stmt.setString(4, contract.producerAccountId.id)
                    stmt.setString(5, json.encodeToString(productPriceListSerializer, contract.productPrices))
                    stmt.setString(6, contract.minDeliveryDate.toString())
                    stmt.setString(7, contract.maxDeliveryDate.toString())
                    stmt.setInt(8, contract.deliveryCount)
                    stmt.setInt(9, contract.seasonYear)
                    stmt.setString(
                        10,
                        json.encodeToString(
                            ListSerializer(String.serializer()),
                            contract.coordinators.map { it.id },
                        ),
                    )
                    stmt.setString(
                        11,
                        json.encodeToString(contractMemberListSerializer, contract.members),
                    )
                    stmt.setString(12, contract.status.name)
                    stmt.setString(13, contract.deliveryTemplateId?.id)
                    stmt.setString(
                        14,
                        json.encodeToString(sharedBasketListSerializer, contract.sharedBaskets),
                    )
                    stmt.setBoolean(15, contract.isMainContract)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }

    override suspend fun delete(
        contractId: Id<Contract>,
        organizationId: Id<Organization>,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "DELETE FROM contract WHERE contract_id = ? AND organization_id = ?",
                ).use { stmt ->
                    stmt.setString(1, contractId.id)
                    stmt.setString(2, organizationId.id)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

private fun ResultSet.toContract(): Contract =
    Contract(
        contractId = getString("contract_id").toId(),
        name = getString("name"),
        organizationId = getString("organization_id").toId(),
        producerAccountId = getString("producer_account_id").toId(),
        productPrices =
            json.decodeFromString(
                productPriceListSerializer,
                getString("product_prices_json") ?: "[]",
            ),
        minDeliveryDate = LocalDate.parse(getString("min_delivery_date")),
        maxDeliveryDate = LocalDate.parse(getString("max_delivery_date")),
        deliveryCount = getInt("delivery_count"),
        seasonYear = getInt("season_year"),
        coordinators =
            json
                .decodeFromString(
                    ListSerializer(String.serializer()),
                    getString("coordinators") ?: "[]",
                ).map { it.toId<Member>() },
        members =
            json.decodeFromString(
                contractMemberListSerializer,
                getString("members") ?: "[]",
            ),
        status = getString("status")?.let { ContractStatus.valueOf(it) } ?: ContractStatus.IN_PREPARATION,
        deliveryTemplateId = getString("delivery_template_id")?.toId<DeliveryTemplate>(),
        sharedBaskets =
            json.decodeFromString(
                sharedBasketListSerializer,
                getString("shared_baskets") ?: "[]",
            ),
        isMainContract = getBoolean("is_main_contract"),
    )
