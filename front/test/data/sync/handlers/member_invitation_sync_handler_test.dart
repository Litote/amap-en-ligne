import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/sync/entity_sync_handler.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  const handler = MemberInvitationSyncHandler();

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  MemberInvitation invitation(String id) => MemberInvitation(
    invitationId: id,
    organizationId: 'org-1',
    email: '$id@example.com',
    firstName: 'Alice',
    lastName: 'Martin',
    roles: const {},
    status: InvitationStatus.pendingActivation,
    createdAt: '2026-09-01T00:00:00Z',
    expiresAt: '2026-09-08T00:00:00Z',
  );

  test(
    'a tombstone on the organization scope deletes the invitation',
    () async {
      await db.upsertMemberInvitation('org-1', invitation('i-1'));

      await handler.deleteEntity(
        db,
        entityId: 'i-1',
        scopeKey: 'organization:org-1',
      );

      expect(await db.watchAllMemberInvitations().first, isEmpty);
    },
  );

  test('a tombstone on the instance-owner scope deletes the invitation '
      'without an organization', () async {
    await db.upsertMemberInvitation('org-1', invitation('i-1'));

    await handler.deleteEntity(db, entityId: 'i-1', scopeKey: 'instance-owner');

    expect(await db.watchAllMemberInvitations().first, isEmpty);
  });
}
