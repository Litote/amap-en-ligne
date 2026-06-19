import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Repository for [ProducerAccount] entities.
///
/// Reads are served from the local drift cache. OWNER lifecycle mutations
/// (suspend / reactivate) enqueue a `ClientMutation` for the next sync flush
/// — the back applies them via `ProducerAccountService.suspend/reactivate`.
/// Full producer profile writes remain owned by the producer-side flows.
class ProducerAccountRepository {
  ProducerAccountRepository({required AppDatabase db, IdGenerator? idGenerator})
    : _db = db,
      _idGen = idGenerator ?? IdGenerator();

  final AppDatabase _db;
  final IdGenerator _idGen;

  /// Reactive stream of every [ProducerAccount] cached locally, deduplicated
  /// by `producerAccountId`. Used by OWNER instance-wide screens.
  Stream<List<ProducerAccount>> watchAll() => _db.watchAllProducerAccounts();

  /// Reactive stream of the [ProducerAccount] for [producerAccountId].
  /// Emits null when no matching row is cached locally.
  Stream<ProducerAccount?> watchMine(String producerAccountId) =>
      _db.watchProducerAccountById(producerAccountId);

  /// Suspends a producer account by enqueuing an Upsert with
  /// `activeStatus = false`. Non-optimistic — the back validates and the
  /// reactive stream reflects the change after the next sync.
  Future<String> suspend(String producerAccountId) =>
      _enqueueActiveStatus(producerAccountId, activeStatus: false);

  /// Reactivates a previously suspended producer account.
  Future<String> reactivate(String producerAccountId) =>
      _enqueueActiveStatus(producerAccountId, activeStatus: true);

  /// Deletes a producer account (Phase 2.5). The back enumerates the auth
  /// users tied to this producer and removes each from the auth provider,
  /// then flips `active_status = false` on the producer entity itself —
  /// per the spec, the producer row is preserved so it can be re-attached
  /// to a different user later.
  Future<String> delete(String producerAccountId) async {
    final clientOpId = _idGen.next();
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: clientOpId,
        op: Delete(
          entityType: EntityType.producerAccount,
          entityId: producerAccountId,
        ),
      ),
      scopeKey: instanceOwnerScopeKey,
    );
    return clientOpId;
  }

  /// Optimistically persists [userPreferences] for [producerAccountId] in the
  /// local drift cache and enqueues an Upsert mutation for the next sync flush.
  ///
  /// Pending back-end support (sync): there is no dedicated producer
  /// preferences endpoint on the `producer-account:{id}` scope yet; the
  /// mutation will be applied once the server-side handler is in place.
  Future<void> updateUserPreferences(
    String producerAccountId,
    UserPreferences userPreferences,
  ) async {
    await _db.updateProducerAccountUserPreferences(
      producerAccountId,
      userPreferences,
    );
  }

  /// Optimistically writes the producer's profile fields ([name], [contactEmail],
  /// [address], [website]) to the local drift cache and enqueues an Upsert
  /// mutation for the next sync flush so the back applies the change.
  Future<void> updateProfile({
    required String producerAccountId,
    required String name,
    String? contactEmail,
    String? address,
    String? website,
  }) async {
    await _db.updateProducerAccountProfile(
      producerAccountId: producerAccountId,
      name: name,
      contactEmail: contactEmail,
      address: address,
      website: website,
    );
    // Fetch the updated row from the cache to build the full payload.
    final all = await _db.watchAllProducerAccounts().first;
    final matches = all.where((p) => p.producerAccountId == producerAccountId);
    if (matches.isEmpty) return;
    final updated = matches.first;
    final clientOpId = _idGen.next();
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: clientOpId,
        op: Upsert(payload: ProducerAccountPayload(producerAccount: updated)),
      ),
      scopeKey: producerAccountScopeKey(producerAccountId),
    );
  }

  Future<String> _enqueueActiveStatus(
    String producerAccountId, {
    required bool activeStatus,
  }) async {
    // OWNER mutation: we don't have the full local producer row guaranteed,
    // so we send a minimal payload — the back loads the existing record and
    // only applies the `active_status` flip.
    final clientOpId = _idGen.next();
    final producer = (await _db.watchAllProducerAccounts().first).firstWhere(
      (p) => p.producerAccountId == producerAccountId,
      orElse: () => throw StateError(
        'ProducerAccount $producerAccountId not found in cache',
      ),
    );
    final updated = producer.copyWith(activeStatus: activeStatus);
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: clientOpId,
        op: Upsert(payload: ProducerAccountPayload(producerAccount: updated)),
      ),
      scopeKey: instanceOwnerScopeKey,
    );
    return clientOpId;
  }
}
