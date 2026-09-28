@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import id.Id
import id.toId
import kotlinx.serialization.builtins.ListSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.BasketExchangeSyncDAO
import persistence.model.BasketExchange
import persistence.model.BasketExchangeRequest
import persistence.model.BasketExchangeRequestStatus
import persistence.model.BasketExchangeStatus
import persistence.model.Member
import persistence.model.Organization
import serialization.json
import java.sql.ResultSet
import java.sql.Types
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

private val requestListSerializer = ListSerializer(BasketExchangeRequest.serializer())

@Single(createdAtStart = true, binds = [BasketExchangeSyncDAO::class])
internal class BasketExchangeSyncPostgresDAO(
    private val client: PostgresClient,
) : BasketExchangeSyncDAO {
    override suspend fun getByOrganizationId(organizationId: Id<Organization>): List<BasketExchange> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT basket_exchange_id, organization_id, delivery_id, contract_id,
                           offering_member_id, motive, status, created_at, decided_at,
                           accepted_request_id, requests_json
                    FROM basket_exchange
                    WHERE organization_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toBasketExchange())
                            }
                        }
                    }
                }
        }

    override suspend fun findById(
        organizationId: Id<Organization>,
        basketExchangeId: Id<BasketExchange>,
    ): BasketExchange? =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT basket_exchange_id, organization_id, delivery_id, contract_id,
                           offering_member_id, motive, status, created_at, decided_at,
                           accepted_request_id, requests_json
                    FROM basket_exchange
                    WHERE organization_id = ? AND basket_exchange_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, organizationId.id)
                    stmt.setString(2, basketExchangeId.id)
                    stmt.executeQuery().use { rs ->
                        if (rs.next()) rs.toBasketExchange() else null
                    }
                }
        }

    override suspend fun put(
        basketExchange: BasketExchange,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO basket_exchange (
                        basket_exchange_id, organization_id, delivery_id, contract_id,
                        offering_member_id, motive, status, created_at, decided_at,
                        accepted_request_id, requests_json
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (basket_exchange_id)
                    DO UPDATE SET
                        organization_id = EXCLUDED.organization_id,
                        delivery_id = EXCLUDED.delivery_id,
                        contract_id = EXCLUDED.contract_id,
                        offering_member_id = EXCLUDED.offering_member_id,
                        motive = EXCLUDED.motive,
                        status = EXCLUDED.status,
                        created_at = EXCLUDED.created_at,
                        decided_at = EXCLUDED.decided_at,
                        accepted_request_id = EXCLUDED.accepted_request_id,
                        requests_json = EXCLUDED.requests_json
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, basketExchange.basketExchangeId.id)
                    stmt.setString(2, basketExchange.organizationId.id)
                    stmt.setString(3, basketExchange.deliveryId.id)
                    stmt.setString(4, basketExchange.contractId.id)
                    stmt.setString(5, basketExchange.offeringMemberId.id)
                    if (basketExchange.motive == null) {
                        stmt.setNull(6, Types.VARCHAR)
                    } else {
                        stmt.setString(6, basketExchange.motive)
                    }
                    stmt.setString(7, basketExchange.status.name)
                    stmt.setLong(8, basketExchange.createdAt.toEpochMilliseconds())
                    val decidedAt = basketExchange.decidedAt
                    if (decidedAt == null) {
                        stmt.setNull(9, Types.BIGINT)
                    } else {
                        stmt.setLong(9, decidedAt.toEpochMilliseconds())
                    }
                    val acceptedRequestId = basketExchange.acceptedRequestId
                    if (acceptedRequestId == null) {
                        stmt.setNull(10, Types.VARCHAR)
                    } else {
                        stmt.setString(10, acceptedRequestId.id)
                    }
                    stmt.setString(11, json.encodeToString(requestListSerializer, basketExchange.requests))
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }

    override suspend fun delete(
        organizationId: Id<Organization>,
        basketExchangeId: Id<BasketExchange>,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    "DELETE FROM basket_exchange WHERE basket_exchange_id = ? AND organization_id = ?",
                ).use { stmt ->
                    stmt.setString(1, basketExchangeId.id)
                    stmt.setString(2, organizationId.id)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

private fun ResultSet.toBasketExchange(): BasketExchange =
    BasketExchange(
        basketExchangeId = getString("basket_exchange_id").toId(),
        organizationId = getString("organization_id").toId(),
        deliveryId = getString("delivery_id").toId(),
        contractId = getString("contract_id").toId(),
        offeringMemberId = getString("offering_member_id").toId<Member>(),
        motive = getString("motive"),
        status = BasketExchangeStatus.valueOf(getString("status")),
        createdAt = Instant.fromEpochMilliseconds(getLong("created_at")),
        decidedAt = getLong("decided_at").takeIf { !wasNull() }?.let { Instant.fromEpochMilliseconds(it) },
        acceptedRequestId =
            getString("accepted_request_id")?.toId<BasketExchangeRequest>(),
        requests =
            json.decodeFromString(
                requestListSerializer,
                getString("requests_json") ?: "[]",
            ),
    )
