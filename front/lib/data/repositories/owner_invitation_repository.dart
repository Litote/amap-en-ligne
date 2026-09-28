import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/owner_invitation.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Repository for [OwnerInvitation] entities.
class OwnerInvitationRepository {
  OwnerInvitationRepository({required AppDatabase db, IdGenerator? idGenerator})
    : _db = db,
      _idGen = idGenerator ?? IdGenerator();

  final AppDatabase _db;
  final IdGenerator _idGen;

  Stream<List<OwnerInvitation>> watchAll() => _db.watchOwnerInvitations();

  Future<String> create({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final clientOpId = _idGen.next();
    final now = DateTime.now().toUtc();

    // Check if invitation with same email already exists — if so, reuse it
    final existingInvitations = await _db.getOwnerInvitations();
    OwnerInvitation? existing;
    for (final inv in existingInvitations) {
      if (inv.email.toLowerCase() == email.toLowerCase()) {
        existing = inv;
        break;
      }
    }

    final invitationId = existing?.invitationId ?? _idGen.nextTmpId();
    final invitation = OwnerInvitation(
      invitationId: invitationId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      status: InvitationStatus.pendingActivation,
      submittedAt: existing?.submittedAt ?? now.toIso8601String(),
      resendRequestedAt: existing?.resendRequestedAt,
      activatedAt: existing?.activatedAt,
    );
    await _db.transaction(() async {
      await _db.upsertOwnerInvitation(invitation);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: clientOpId,
          op: Upsert(
            payload: OwnerInvitationPayload(ownerInvitation: invitation),
          ),
        ),
        scopeKey: instanceOwnerScopeKey,
      );
    });
    return clientOpId;
  }

  Future<String> resend(String invitationId) async {
    final current = await _db.findOwnerInvitationById(invitationId);
    if (current == null) {
      throw StateError('OwnerInvitation $invitationId not found in cache');
    }
    final clientOpId = _idGen.next();
    final updated = current.copyWith(
      resendRequestedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _db.transaction(() async {
      await _db.upsertOwnerInvitation(updated);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: clientOpId,
          op: Upsert(payload: OwnerInvitationPayload(ownerInvitation: updated)),
        ),
        scopeKey: instanceOwnerScopeKey,
      );
    });
    return clientOpId;
  }
}
