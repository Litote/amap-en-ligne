import 'dart:async';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/domain/sync/change.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Owns the full sync round-trip: read local cursors + pending mutations,
/// POST `/v1/sync`, apply the response atomically, drain pending mutations,
/// remap server-allocated ids for `tmp_*` creations.
///
/// Pure orchestration — no triggers, no connectivity, no scheduling. The
/// caller (a Bloc in the presentation layer) decides when to call `sync`.
class SyncRepository {
  SyncRepository({
    required AppDatabase db,
    required SyncApi api,
    Map<EntityType, EntitySyncHandler>? handlers,
  }) : _db = db,
       _api = api,
       _handlers = handlers ?? buildEntitySyncHandlers();

  final AppDatabase _db;
  final SyncApi _api;
  final Map<EntityType, EntitySyncHandler> _handlers;

  // Deduplicates concurrent sync() calls: if a sync is already in progress,
  // subsequent callers join it instead of starting a second HTTP request.
  Completer<SyncOutcome>? _inflightSync;

  Future<void> resetAllCursors() => _db.resetAllCursors();

  Future<void> clearAll() => _db.clearAll();

  Future<SyncOutcome> sync({required String tenantId}) async {
    if (_inflightSync != null) {
      return _inflightSync!.future;
    }
    final completer = Completer<SyncOutcome>();
    _inflightSync = completer;
    try {
      final result = await _doSync(tenantId: tenantId);
      completer.complete(result);
      return result;
    } finally {
      _inflightSync = null;
    }
  }

  Future<SyncOutcome> _doSync({required String tenantId}) async {
    try {
      final cursors = await _db.readAllScopeCursors();
      final pending = await _db.readPendingMutationEntries();
      final scopedPending = pending
          .where((entry) => entry.scopeKey != null)
          .toList();

      final response = await _api.sync(
        SyncRequest(
          cursors: cursors,
          mutations: scopedPending.map((entry) => entry.mutation).toList(),
        ),
      );
      final memberOrOwnerUpdated = await _applyResponse(
        response,
        scopedPending,
      );
      final rejected = response.mutations
          .where((m) => m.status == MutationStatus.rejected)
          .toList();
      if (rejected.isNotEmpty) {
        await Sentry.captureMessage(
          'Sync: ${rejected.length} mutation(s) rejected',
          level: SentryLevel.warning,
          withScope: (scope) {
            scope.setContexts('rejected_mutations', {
              'items': rejected
                  .map(
                    (m) => {
                      'clientOpId': m.clientOpId,
                      'code': m.error?.code.name,
                      'message': m.error?.message,
                    },
                  )
                  .toList(),
            });
          },
        );
      }
      return SyncOutcome.success(
        rejectedMutations: rejected,
        memberOrOwnerUpdated: memberOrOwnerUpdated,
      );
    } on DioException catch (e) {
      // Transport-level errors are expected offline behaviour, surfaced to
      // the user as "server unreachable"; HTTP errors mean the server already
      // knows. Neither needs Sentry noise.
      if (_isServerUnreachable(e)) return const SyncOutcome.networkFailure();
      return SyncOutcome.failure(e.message ?? 'Network error');
    } on FormatException catch (e, s) {
      // Protocol mismatch between front and back (JSON deserialization failure).
      await Sentry.captureException(e, stackTrace: s);
      return SyncOutcome.failure(e.message);
    } catch (e, s) {
      // Unexpected error (database, drift, OPFS, …) — server has no visibility.
      await Sentry.captureException(e, stackTrace: s);
      return SyncOutcome.failure('$e');
    }
  }

  /// Whether [e] means the server could not be reached at all, as opposed to
  /// the server answering with an error. `unknown` covers adapter-specific
  /// transport failures (e.g. a SocketException surfacing mid-response) that
  /// dio does not classify; matched on the message because `dart:io` types
  /// are unavailable on web.
  static bool _isServerUnreachable(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    DioExceptionType.unknown => e.error.toString().contains('SocketException'),
    DioExceptionType.badResponse ||
    DioExceptionType.badCertificate ||
    DioExceptionType.cancel => false,
  };

  /// Applies the full sync response inside a single drift transaction.
  ///
  /// Returns `true` when at least one [Member] or [Owner] payload was upserted
  /// during this response, so the caller can trigger a token refresh to pick up
  /// any role changes made server-side.
  Future<bool> _applyResponse(
    SyncResponse response,
    List<PendingClientMutation> sentMutations,
  ) => _db.transaction(() async {
    await _synchronizeAuthorizedScopes(response.authorizedScopes);
    var memberOrOwnerUpdated = false;
    for (final entry in response.results.entries) {
      if (await _applyScopeResult(entry.key, entry.value)) {
        memberOrOwnerUpdated = true;
      }
    }
    await _reconcileMutations(response.mutations, sentMutations);
    return memberOrOwnerUpdated;
  });

  Future<void> _synchronizeAuthorizedScopes(
    List<String> authorizedScopes,
  ) async {
    final authorized = authorizedScopes.toSet();
    final known = (await _db.readAllScopeCursors()).keys.toSet();
    final removed = known.difference(authorized);
    for (final scopeKey in removed) {
      await _db.clearScopeData(scopeKey);
      await _db.deleteCursor(scopeKey);
    }
    await _db.dropPendingMutationsForScopes(removed);
    await _db.dropPendingMutationsWithoutScope();
    for (final scopeKey in authorized.difference(known)) {
      await _db.writeCursor(scopeKey, null);
    }
  }

  /// Returns `true` when at least one [Member] or [Owner] payload was upserted.
  Future<bool> _applyScopeResult(
    String scopeKey,
    ScopeSyncResult result,
  ) async {
    var memberOrOwnerUpdated = false;
    switch (result) {
      case BootstrapScopeSyncResult(:final items, :final nextCursor):
        await _db.clearScopeData(scopeKey);
        for (final item in items) {
          if (_isMemberOrOwnerPayload(item)) memberOrOwnerUpdated = true;
          await _applyPayload(item);
        }
        await _db.writeCursor(scopeKey, nextCursor);
      case IncrementalScopeSyncResult(:final changes, :final nextCursor):
        for (final change in changes) {
          if (_isMemberOrOwnerChange(change)) memberOrOwnerUpdated = true;
          await _applyChange(scopeKey, change);
        }
        await _db.writeCursor(scopeKey, nextCursor);
    }
    return memberOrOwnerUpdated;
  }

  static bool _isMemberOrOwnerPayload(EntityPayload payload) =>
      payload.entityType == EntityType.member ||
      payload.entityType == EntityType.owner;

  static bool _isMemberOrOwnerChange(Change change) =>
      change.op == ChangeOp.upsert &&
      (change.entityType == EntityType.member ||
          change.entityType == EntityType.owner);

  Future<void> _applyChange(String scopeKey, Change change) async {
    switch (change.op) {
      case ChangeOp.upsert:
        final payload = change.payload;
        if (payload != null) await _applyPayload(payload);
      case ChangeOp.delete:
        await _deleteEntity(change.entityType, change.entityId, scopeKey);
    }
  }

  Future<void> _applyPayload(EntityPayload payload) async {
    await _handlerFor(payload.entityType).applyPayload(_db, payload);
  }

  Future<void> _deleteEntity(
    EntityType type,
    String entityId,
    String scopeKey,
  ) => _handlerFor(
    type,
  ).deleteEntity(_db, entityId: entityId, scopeKey: scopeKey);

  Future<void> _reconcileMutations(
    List<MutationOutcome> outcomes,
    List<PendingClientMutation> sentMutations,
  ) async {
    final pendingByOpId = {
      for (final entry in sentMutations) entry.clientOpId: entry,
    };
    for (final outcome in outcomes) {
      if (outcome.status != MutationStatus.applied) continue;
      final originalEntry = pendingByOpId[outcome.clientOpId];
      final serverEntityId = outcome.serverEntityId;
      if (originalEntry == null || serverEntityId == null) continue;
      await _maybeRemapTmpId(originalEntry.mutation, serverEntityId);
      await _rewriteQueuedMutationReferences(
        originalEntry,
        serverEntityId: serverEntityId,
      );
    }
    if (outcomes.isNotEmpty) {
      await _db.drainPendingMutations(outcomes.map((o) => o.clientOpId));
    }
  }

  Future<void> _maybeRemapTmpId(
    ClientMutation original,
    String serverEntityId,
  ) async {
    final op = original.op;
    if (op is! Upsert) return;
    final payload = op.payload;
    await _handlerFor(
      payload.entityType,
    ).remapTmpId(_db, payload: payload, serverEntityId: serverEntityId);
  }

  EntitySyncHandler _handlerFor(EntityType type) {
    final handler = _handlers[type];
    if (handler == null) {
      throw StateError('No sync handler registered for $type.');
    }
    return handler;
  }

  Future<void> _rewriteQueuedMutationReferences(
    PendingClientMutation originalEntry, {
    required String serverEntityId,
  }) async {
    final original = originalEntry.mutation;
    final op = original.op;
    if (op is! Upsert) return;
    final payload = op.payload;
    final type = payload.entityType;
    final oldId = _entityIdForPayload(payload);
    if (!oldId.startsWith(ClientMutation.tmpIdPrefix) ||
        oldId == serverEntityId) {
      return;
    }

    final handler = _handlerFor(type);
    final pending = await _db.readPendingMutationEntries();
    for (final entry in pending) {
      if (entry.clientOpId == original.clientOpId) continue;
      if (entry.scopeKey != null && entry.scopeKey != originalEntry.scopeKey) {
        continue;
      }
      final rewritten = handler.rewriteMutationReference(
        entry.mutation,
        oldId: oldId,
        newId: serverEntityId,
      );
      if (rewritten != entry.mutation) {
        await _db.replacePendingMutation(
          entry,
          mutation: rewritten,
          scopeKey: entry.scopeKey ?? originalEntry.scopeKey,
        );
      }
    }
  }

  String _entityIdForPayload(EntityPayload payload) => switch (payload) {
    ProductTypePayload(:final productType) => productType.productTypeId,
    OrganizationPayload(:final organization) => organization.organizationId,
    ProducerAccountPayload(:final producerAccount) =>
      producerAccount.producerAccountId,
    MemberPayload(:final member) => member.memberId,
    MemberJoinRequestPayload(:final memberJoinRequest) =>
      memberJoinRequest.requestId,
    ContractPayload(:final contract) => contract.contractId,
    DeliveryTemplatePayload(:final deliveryTemplate) =>
      deliveryTemplate.deliveryTemplateId,
    OrganizationRequestPayload(:final organizationRequest) =>
      organizationRequest.requestId,
    ProducerRequestPayload(:final producerRequest) => producerRequest.requestId,
    OwnerPayload(:final owner) => owner.ownerId,
    MemberInvitationPayload(:final memberInvitation) =>
      memberInvitation.invitationId,
    OwnerInvitationPayload(:final ownerInvitation) =>
      ownerInvitation.invitationId,
    BasketExchangePayload(:final basketExchange) =>
      basketExchange.basketExchangeId,
    NotificationPayload(:final notification) => notification.notificationId,
    DeviceTokenPayload(:final deviceToken) => deviceToken.deviceTokenId,
    AttendanceEmailRequestPayload(:final attendanceEmailRequest) =>
      attendanceEmailRequest.attendanceEmailRequestId,
    ErrorReportPayload(:final errorReport) => errorReport.errorReportId,
  };
}
