import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MemberInvitationRepository repo;

  const organizationId = 'org-1';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MemberInvitationRepository(
      db: db,
      idGenerator: IdGenerator(Random(0)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('create writes local pending invitation and enqueues Upsert', () async {
    final clientOpId = await repo.create(
      organizationId: organizationId,
      email: 'alice@example.org',
      firstName: 'Alice',
      lastName: 'Martin',
      roles: const {Role.admin},
    );

    final invitations = await repo.watch(organizationId).first;
    expect(invitations, hasLength(1));
    final invitation = invitations.single;
    expect(invitation.invitationId, startsWith('tmp_'));
    expect(invitation.email, 'alice@example.org');
    expect(invitation.status, InvitationStatus.pendingActivation);

    final entries = await db.readPendingMutationEntries();
    expect(entries.single.clientOpId, clientOpId);
    expect(entries.single.scopeKey, organizationScopeKey(organizationId));

    final pending = await db.readPendingMutations();
    final upsert = pending.single.op as Upsert;
    final payload = upsert.payload as MemberInvitationPayload;
    expect(payload.memberInvitation.email, 'alice@example.org');
  });

  test('resend updates resendRequestedAt and enqueues Upsert', () async {
    await db.writeCursor('organization:$organizationId', 'cursor-0');
    await db.upsertMemberInvitation(
      organizationId,
      const MemberInvitation(
        invitationId: 'inv-1',
        organizationId: organizationId,
        email: 'alice@example.org',
        firstName: 'Alice',
        lastName: 'Martin',
        roles: {Role.volunteer},
        status: InvitationStatus.pendingActivation,
        createdAt: '2026-01-01T00:00:00Z',
        expiresAt: '2026-01-08T00:00:00Z',
      ),
    );

    await repo.resend(organizationId: organizationId, invitationId: 'inv-1');

    final updated = (await repo.watch(organizationId).first).single;
    expect(updated.resendRequestedAt, isNotNull);

    final pending = await db.readPendingMutations();
    final payload =
        ((pending.single.op as Upsert).payload as MemberInvitationPayload);
    expect(payload.memberInvitation.resendRequestedAt, isNotNull);
  });

  test(
    'resend carries custom email subject/body into the enqueued Upsert',
    () async {
      await db.writeCursor('organization:$organizationId', 'cursor-0');
      await db.upsertMemberInvitation(
        organizationId,
        const MemberInvitation(
          invitationId: 'inv-1',
          organizationId: organizationId,
          email: 'alice@example.org',
          firstName: 'Alice',
          lastName: 'Martin',
          roles: {Role.volunteer},
          status: InvitationStatus.pendingActivation,
          createdAt: '2026-01-01T00:00:00Z',
          expiresAt: '2026-01-08T00:00:00Z',
        ),
      );

      await repo.resend(
        organizationId: organizationId,
        invitationId: 'inv-1',
        customEmailSubject: 'Connecte-toi',
        customEmailBody: 'Merci de finaliser ton inscription.',
      );

      final pending = await db.readPendingMutations();
      final payload =
          ((pending.single.op as Upsert).payload as MemberInvitationPayload);
      expect(payload.memberInvitation.customEmailSubject, 'Connecte-toi');
      expect(
        payload.memberInvitation.customEmailBody,
        'Merci de finaliser ton inscription.',
      );
    },
  );

  test(
    'create with same email overwrites existing invitation (case-insensitive)',
    () async {
      await db.writeCursor('organization:$organizationId', 'cursor-0');
      // Create first invitation
      await db.upsertMemberInvitation(
        organizationId,
        const MemberInvitation(
          invitationId: 'inv-1',
          organizationId: organizationId,
          email: 'alice@example.org',
          firstName: 'Alice',
          lastName: 'Martin',
          roles: {Role.volunteer},
          status: InvitationStatus.pendingActivation,
          createdAt: '2026-01-01T00:00:00Z',
          expiresAt: '2026-01-08T00:00:00Z',
        ),
      );

      // Create new invitation with same email (different case) and different roles
      final clientOpId = await repo.create(
        organizationId: organizationId,
        email: 'ALICE@EXAMPLE.ORG',
        firstName: 'Alice',
        lastName: 'Martin',
        roles: const {Role.admin, Role.coordinator},
      );

      final invitations = await repo.watch(organizationId).first;
      expect(invitations, hasLength(1));
      final invitation = invitations.single;
      // Should reuse the existing invitationId, not create a new one
      expect(invitation.invitationId, 'inv-1');
      expect(invitation.roles, const {Role.admin, Role.coordinator});

      final entries = await db.readPendingMutationEntries();
      expect(entries, hasLength(1));
      expect(entries.single.clientOpId, clientOpId);

      final pending = await db.readPendingMutations();
      final payload =
          ((pending.single.op as Upsert).payload as MemberInvitationPayload);
      expect(payload.memberInvitation.invitationId, 'inv-1');
      expect(payload.memberInvitation.roles, const {
        Role.admin,
        Role.coordinator,
      });
    },
  );
}
