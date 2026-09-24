import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart'
    show MutationOutcome;

/// Sync handler for [BasketExchange] entities on the `organization:{id}` scope.
///
/// The back never allows applyDelete for BasketExchange — tombstones return
/// FORBIDDEN. [deleteEntity] mirrors the delete locally anyway in case a future
/// protocol revision adds tombstone support.
///
/// tmp_* id remap convention for nested requests:
/// When a client submits a request with a `tmp_*` [BasketExchangeRequest.requestId]
/// embedded in [BasketExchange.requests], the back allocates the real request id
/// server-side but returns [MutationOutcome.serverEntityId] = [BasketExchange.basketExchangeId]
/// (the outer aggregate id, not the inner request id). The handler remaps the
/// outer [basketExchangeId] only. The allocated request id is recovered by
/// re-reading the response [BasketExchange] payload returned by the next sync —
/// the back replaces the `tmp_*` request entry with the server-allocated row,
/// so [applyPayload] rewrites [requestsJson] with the authoritative list.
final class BasketExchangeSyncHandler implements EntitySyncHandler {
  const BasketExchangeSyncHandler();

  @override
  EntityType get entityType => EntityType.basketExchange;

  @override
  Future<void> applyPayload(AppDatabase db, EntityPayload payload) {
    if (payload is! BasketExchangePayload) {
      throw StateError(
        'Handler for $entityType cannot process payload for ${payload.entityType}.',
      );
    }
    return db.upsertBasketExchange(payload.basketExchange);
  }

  @override
  Future<void> deleteEntity(
    AppDatabase db, {
    required String entityId,
    required String scopeKey,
  }) =>
      // The back always returns FORBIDDEN for BasketExchange DELETE mutations.
      // We mirror the tombstone locally in case of a future protocol revision.
      db.deleteBasketExchange(entityId);

  @override
  Future<void> remapTmpId(
    AppDatabase db, {
    required EntityPayload payload,
    required String serverEntityId,
  }) {
    if (payload is! BasketExchangePayload) {
      return Future.value();
    }
    final exchange = payload.basketExchange;
    final localId = exchange.basketExchangeId;
    if (!localId.startsWith(ClientMutation.tmpIdPrefix) ||
        localId == serverEntityId) {
      return Future.value();
    }
    // Remap the outer basketExchangeId. Embedded request ids are recovered by
    // applyPayload rewriting requestsJson from the authoritative server payload.
    return db.remapBasketExchangeId(oldId: localId, newId: serverEntityId);
  }

  @override
  ClientMutation rewriteMutationReference(
    ClientMutation mutation, {
    required String oldId,
    required String newId,
  }) {
    final op = mutation.op;
    if (op case Upsert(:final payload)) {
      if (payload is! BasketExchangePayload) return mutation;
      final exchange = payload.basketExchange;
      if (exchange.basketExchangeId != oldId) return mutation;
      return mutation.copyWith(
        op: Upsert(
          payload: BasketExchangePayload(
            basketExchange: exchange.copyWith(basketExchangeId: newId),
          ),
        ),
      );
    }
    if (op case Delete(
      entityType: EntityType.basketExchange,
      entityId: final id,
    ) when id == oldId) {
      return mutation.copyWith(
        op: Delete(entityType: EntityType.basketExchange, entityId: newId),
      );
    }
    return mutation;
  }
}
