import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';

/// Repository for [MemberInvitation] entities.
class MemberInvitationRepository {
  MemberInvitationRepository({
    required AppDatabase db,
    IdGenerator? idGenerator,
  }) : _db = db,
       _idGen = idGenerator ?? IdGenerator();

  final AppDatabase _db;
  final IdGenerator _idGen;

  Stream<List<MemberInvitation>> watch(String organizationId) =>
      _db.watchMemberInvitations(organizationId);

  Future<String> create({
    required String organizationId,
    required String email,
    required String firstName,
    required String lastName,
    required Set<Role> roles,
  }) async {
    final clientOpId = _idGen.next();
    final now = DateTime.now().toUtc();

    // Check if invitation with same email already exists — if so, reuse it (just update roles)
    final existingInvitations = await _db.getMemberInvitationsForOrganization(
      organizationId,
    );
    MemberInvitation? existing;
    for (final inv in existingInvitations) {
      if (inv.email.toLowerCase() == email.toLowerCase()) {
        existing = inv;
        break;
      }
    }

    final invitationId = existing?.invitationId ?? _idGen.nextTmpId();
    final invitation = MemberInvitation(
      invitationId: invitationId,
      organizationId: organizationId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      roles: roles,
      status: InvitationStatus.pendingActivation,
      createdAt: existing?.createdAt ?? now.toIso8601String(),
      expiresAt: now.add(const Duration(days: 7)).toIso8601String(),
      resendRequestedAt: existing?.resendRequestedAt,
      activatedAt: existing?.activatedAt,
    );
    await _db.transaction(() async {
      await _db.upsertMemberInvitation(organizationId, invitation);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: clientOpId,
          op: Upsert(
            payload: MemberInvitationPayload(memberInvitation: invitation),
          ),
        ),
        scopeKey: organizationScopeKey(organizationId),
      );
    });
    return clientOpId;
  }

  Future<String> resend({
    required String organizationId,
    required String invitationId,
    String? customEmailSubject,
    String? customEmailBody,
  }) async {
    final current = await _db.getMemberInvitation(organizationId, invitationId);
    if (current == null) {
      throw StateError(
        'MemberInvitation $invitationId in organization $organizationId not found in cache',
      );
    }
    final clientOpId = _idGen.next();
    final updated = current.copyWith(
      resendRequestedAt: DateTime.now().toUtc().toIso8601String(),
      customEmailSubject: customEmailSubject,
      customEmailBody: customEmailBody,
    );
    await _db.transaction(() async {
      await _db.upsertMemberInvitation(organizationId, updated);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: clientOpId,
          op: Upsert(
            payload: MemberInvitationPayload(memberInvitation: updated),
          ),
        ),
        scopeKey: organizationScopeKey(organizationId),
      );
    });
    return clientOpId;
  }

  Future<String> delete({
    required String organizationId,
    required String invitationId,
  }) async {
    final current = await _db.getMemberInvitation(organizationId, invitationId);
    if (current == null) {
      throw StateError(
        'MemberInvitation $invitationId in organization $organizationId not found in cache',
      );
    }
    final clientOpId = _idGen.next();
    await _db.transaction(() async {
      await _db.deleteMemberInvitation(organizationId, invitationId);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: clientOpId,
          op: Delete(
            entityType: EntityType.memberInvitation,
            entityId: invitationId,
          ),
        ),
        scopeKey: organizationScopeKey(organizationId),
      );
    });
    return clientOpId;
  }
}
