import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_preferences.dart';
import 'package:amap_en_ligne/domain/model/user_preferences.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Repository for [Member] entities.
///
/// Reads are served from the local drift cache.
/// Mutations apply an optimistic local update and enqueue a
/// [ClientMutation] for the next sync flush.
class MemberRepository {
  MemberRepository({required AppDatabase db, required IdGenerator idGenerator})
    : _db = db,
      _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  /// Reactive stream of **all** [Member] rows across all organisations.
  /// Used by instance-wide views (OWNER role).
  Stream<List<Member>> watchAll() => _db.watchAllMembers();

  Stream<List<Member>> watch(String organizationId) =>
      _db.watchMembersForTenant(organizationId);

  /// Reactive stream of the single [Member] whose [Member.memberId] matches
  /// [memberId].
  ///
  /// Emits `null` when no row with that [memberId] exists locally (not yet
  /// synced or user not yet a member of any AMAP). If multiple rows somehow
  /// share the same id, emits the first one — the single-AMAP invariant is
  /// assumed.
  Stream<Member?> watchMyMember(String memberId) => _db
      .watchAllMembers()
      .map((list) => list.where((m) => m.memberId == memberId).firstOrNull)
      .distinct();

  /// Updates the roles of [member] optimistically in the local cache and
  /// enqueues a pending [ClientMutation] for the server.
  Future<void> setRoles(
    String organizationId,
    Member member,
    Set<Role> newRoles,
  ) async {
    final updated = member.copyWith(roles: newRoles);
    await _db.transaction(() async {
      await _db.upsertMember(organizationId, updated);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(payload: MemberPayload(member: updated)),
        ),
        scopeKey: organizationScopeKey(organizationId),
      );
    });
  }

  /// Updates the [MemberPreferences] and [UserPreferences] of the member
  /// identified by ([memberId], [organizationId]) optimistically in the local
  /// cache and enqueues a pending [ClientMutation] for the server.
  ///
  /// Throws a [StateError] when no matching row exists in the local cache —
  /// the UI should only call this after the member has been loaded.
  Future<void> updatePreferences({
    required String memberId,
    required String organizationId,
    required MemberPreferences memberPreferences,
    required UserPreferences userPreferences,
  }) async {
    await _db.transaction(() async {
      final current = await _db.getMember(organizationId, memberId);
      if (current == null) {
        throw StateError(
          'Member $memberId in organization $organizationId not found in cache',
        );
      }
      final updated = current.copyWith(
        memberPreferences: memberPreferences,
        userPreferences: userPreferences,
      );
      await _db.upsertMember(organizationId, updated);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(payload: MemberPayload(member: updated)),
        ),
        scopeKey: organizationScopeKey(organizationId),
      );
    });
  }

  /// Removes the membership identified by [memberId] from [organizationId].
  ///
  /// **Optimistic** — deletes the local row immediately, then enqueues a
  /// `Delete` mutation. If the server rejects (e.g. LAST_ADMIN), the caller
  /// must re-sync to restore the row.
  Future<void> removeMembership({
    required String memberId,
    required String organizationId,
  }) async {
    await _db.transaction(() async {
      await _db.deleteMember(organizationId, memberId);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Delete(entityType: EntityType.member, entityId: memberId),
        ),
        scopeKey: organizationScopeKey(organizationId),
      );
    });
  }

  /// Flips [Member.accountStatus] to [MemberAccountStatus.suspended].
  ///
  /// Optimistic write + Upsert mutation. The back's [MemberService] routes
  /// the transition to `UserAccountService.suspend` which bans the auth
  /// user globally and notifies emails. Rejections (`LAST_ADMIN`,
  /// `SELF_ACTION_FORBIDDEN`) surface via the next sync's
  /// `MutationOutcome`, correlated by the returned `clientOpId`.
  Future<String> suspend({
    required String memberId,
    required String organizationId,
  }) => _flipAccountStatus(
    memberId: memberId,
    organizationId: organizationId,
    target: MemberAccountStatus.suspended,
  );

  /// Flips [Member.accountStatus] to [MemberAccountStatus.active].
  ///
  /// Optimistic write + Upsert mutation. Symmetric to [suspend].
  Future<String> reactivate({
    required String memberId,
    required String organizationId,
  }) => _flipAccountStatus(
    memberId: memberId,
    organizationId: organizationId,
    target: MemberAccountStatus.active,
  );

  /// Anonymises the member identified by ([memberId], [organizationId]).
  ///
  /// Optimistic local delete + `Delete` mutation. On the back, OWNER callers
  /// trigger `UserAccountService.delete` which deletes the auth user and
  /// writes one `AccountDeletionLog`. Member rows are anonymised in place
  /// server-side, so a subsequent sync may restore the row with PII
  /// nulled out — this repository removes it locally for snappy UX and
  /// relies on the sync feed to converge.
  Future<String> delete({
    required String memberId,
    required String organizationId,
  }) async {
    final clientOpId = _idGen.next();
    await _db.transaction(() async {
      await _db.deleteMember(organizationId, memberId);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: clientOpId,
          op: Delete(entityType: EntityType.member, entityId: memberId),
        ),
        scopeKey: organizationScopeKey(organizationId),
      );
    });
    return clientOpId;
  }

  /// Updates the profile fields (first name, last name, email, phone) of the
  /// member identified by ([memberId], [organizationId]).
  ///
  /// Optimistic write + Upsert mutation. Throws a [StateError] when no
  /// matching row exists in the local cache.
  Future<String> updateProfile({
    required String memberId,
    required String organizationId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    final clientOpId = _idGen.next();
    await _db.transaction(() async {
      final current = await _db.getMember(organizationId, memberId);
      if (current == null) {
        throw StateError(
          'Member $memberId in organization $organizationId not found in cache',
        );
      }
      final updated = current.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );
      await _db.upsertMember(organizationId, updated);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: clientOpId,
          op: Upsert(payload: MemberPayload(member: updated)),
        ),
        scopeKey: organizationScopeKey(organizationId),
      );
    });
    return clientOpId;
  }

  Future<String> _flipAccountStatus({
    required String memberId,
    required String organizationId,
    required MemberAccountStatus target,
  }) async {
    final clientOpId = _idGen.next();
    await _db.transaction(() async {
      final current = await _db.getMember(organizationId, memberId);
      if (current == null) {
        throw StateError(
          'Member $memberId in organization $organizationId not found in cache',
        );
      }
      final updated = current.copyWith(
        accountStatus: target,
        activeStatus: target == MemberAccountStatus.active,
      );
      await _db.upsertMember(organizationId, updated);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: clientOpId,
          op: Upsert(payload: MemberPayload(member: updated)),
        ),
        scopeKey: organizationScopeKey(organizationId),
      );
    });
    return clientOpId;
  }
}
