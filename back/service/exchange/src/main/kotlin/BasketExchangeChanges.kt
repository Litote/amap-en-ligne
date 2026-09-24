package exchange

import persistence.changes.BasketExchangePayload
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.Cursor
import persistence.changes.SyncScope
import persistence.model.BasketExchange
import persistence.model.EntityType

/** Builds the `organization:{id}` UPSERT [Change] emitted alongside every [BasketExchange] write. */
internal fun buildUpsertChange(
    organizationId: String,
    exchange: BasketExchange,
): Change =
    Change(
        cursor = Cursor.next(),
        entityType = EntityType.BasketExchange,
        entityId = exchange.basketExchangeId.id,
        scopeKey = SyncScope.Organization(organizationId).key,
        op = ChangeOp.UPSERT,
        payload = BasketExchangePayload(exchange),
        producedAt = System.currentTimeMillis(),
    )
