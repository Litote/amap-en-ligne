import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Repository for [Owner] entities.
///
/// Reads are served from the local drift cache. Lifecycle mutations
/// (suspend / reactivate / delete) enqueue a [ClientMutation] for the next
/// sync flush — the back applies them via `OwnerService.suspend / reactivate
/// / delete` (see `back/service/data/.../OwnerService.kt`).
class OwnerRepository {
  OwnerRepository({required AppDatabase db, IdGenerator? idGenerator})
    : _db = db,
      _idGen = idGenerator ?? IdGenerator();

  final AppDatabase _db;
  final IdGenerator _idGen;

  /// Reactive stream of all owners in the local cache.
  Stream<List<Owner>> watchAll() => _db.watchOwners();

  /// Reactive stream of the [Owner] for the current user identified by
  /// [ownerId].
  /// Emits null when the cache has no matching row.
  Stream<Owner?> watchMySelf(String ownerId) => _db.watchOwnerById(ownerId);

  /// Returns the owner with the given [ownerId], or null if not found.
  Future<Owner?> findById(String ownerId) => _db.findOwnerById(ownerId);

  /// Suspends [ownerId] by enqueuing an Upsert mutation with
  /// `accountStatus = SUSPENDED`. **Not optimistic** — the back rejects with
  /// `LAST_OWNER` if this would be the last active Owner, or
  /// `SELF_ACTION_FORBIDDEN` if the caller is the target.
  Future<String> suspend(String ownerId) =>
      _enqueueStatusChange(ownerId, AccountStatus.suspended);

  /// Reactivates [ownerId] by enqueuing an Upsert mutation with
  /// `accountStatus = ACTIVE`. Symmetric of [suspend].
  Future<String> reactivate(String ownerId) =>
      _enqueueStatusChange(ownerId, AccountStatus.active);

  /// Deletes [ownerId] by enqueuing a Delete mutation. **Not optimistic** —
  /// the back rejects with `LAST_OWNER` / `SELF_ACTION_FORBIDDEN` and
  /// writes a privacy-preserving record to `account_deletion_log` on success.
  Future<String> delete(String ownerId) async {
    final clientOpId = _idGen.next();
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: clientOpId,
        op: Delete(entityType: EntityType.owner, entityId: ownerId),
      ),
      scopeKey: instanceOwnerScopeKey,
    );
    return clientOpId;
  }

  /// Optimistically persists [userPreferences] for [ownerId] in the local
  /// drift cache and enqueues an Upsert mutation for the next sync flush.
  ///
  /// TODO(sync): The back-end `OwnerService` does not yet have a dedicated
  /// preferences endpoint; the mutation will be applied once the server-side
  /// handler is in place.
  Future<void> updateUserPreferences(
    String ownerId,
    UserPreferences userPreferences,
  ) async {
    await _db.updateOwnerUserPreferences(ownerId, userPreferences);
    final existing = await _db.findOwnerById(ownerId);
    if (existing == null) return;
    final clientOpId = _idGen.next();
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: clientOpId,
        op: Upsert(payload: OwnerPayload(owner: existing)),
      ),
      scopeKey: instanceOwnerScopeKey,
    );
  }

  /// Optimistically writes the owner's profile fields ([firstName], [lastName],
  /// [email], [phone]) to the local drift cache and enqueues an Upsert mutation
  /// for the next sync flush so the back applies the change.
  Future<void> updateProfile({
    required String ownerId,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    await _db.updateOwnerProfile(
      ownerId: ownerId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
    );
    final updated = await _db.findOwnerById(ownerId);
    if (updated == null) return;
    final clientOpId = _idGen.next();
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: clientOpId,
        op: Upsert(payload: OwnerPayload(owner: updated)),
      ),
      scopeKey: instanceOwnerScopeKey,
    );
  }

  Future<String> _enqueueStatusChange(
    String ownerId,
    AccountStatus status,
  ) async {
    final existing = await _db.findOwnerById(ownerId);
    if (existing == null) throw StateError('Owner $ownerId not found in cache');
    final clientOpId = _idGen.next();
    final updated = existing.copyWith(
      accountStatus: status,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _db.enqueuePendingMutation(
      ClientMutation(
        clientOpId: clientOpId,
        op: Upsert(payload: OwnerPayload(owner: updated)),
      ),
      scopeKey: instanceOwnerScopeKey,
    );
    return clientOpId;
  }
}
