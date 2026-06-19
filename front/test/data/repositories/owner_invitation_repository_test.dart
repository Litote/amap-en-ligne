import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/repositories/owner_invitation_repository.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/owner_invitation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late OwnerInvitationRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = OwnerInvitationRepository(
      db: db,
      idGenerator: IdGenerator(Random(0)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('create writes local pending invitation and enqueues Upsert', () async {
    final clientOpId = await repo.create(
      firstName: 'Jean',
      lastName: 'Dupont',
      email: 'jean@example.fr',
    );

    final invitations = await repo.watchAll().first;
    expect(invitations, hasLength(1));
    final invitation = invitations.single;
    expect(invitation.invitationId, startsWith('tmp_'));
    expect(invitation.status, InvitationStatus.pendingActivation);

    final entries = await db.readPendingMutationEntries();
    expect(entries.single.clientOpId, clientOpId);
    expect(entries.single.scopeKey, instanceOwnerScopeKey);

    final payload =
        ((await db.readPendingMutations()).single.op as Upsert).payload
            as OwnerInvitationPayload;
    expect(payload.ownerInvitation.email, 'jean@example.fr');
  });

  test('resend updates resendRequestedAt and enqueues Upsert', () async {
    await db.upsertOwnerInvitation(
      const OwnerInvitation(
        invitationId: 'inv-1',
        firstName: 'Jean',
        lastName: 'Dupont',
        email: 'jean@example.fr',
        status: InvitationStatus.pendingActivation,
        submittedAt: '2026-01-01T00:00:00Z',
      ),
    );

    await repo.resend('inv-1');

    final updated = (await repo.watchAll().first).single;
    expect(updated.resendRequestedAt, isNotNull);

    final payload =
        ((await db.readPendingMutations()).single.op as Upsert).payload
            as OwnerInvitationPayload;
    expect(payload.ownerInvitation.resendRequestedAt, isNotNull);
  });
}
