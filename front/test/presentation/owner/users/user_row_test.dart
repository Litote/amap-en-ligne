import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/invitation_status.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/member_invitation.dart';
import 'package:amap_en_ligne/domain/model/owner.dart';
import 'package:amap_en_ligne/domain/model/owner_invitation.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('userRowFromProducerAccount', () {
    test('an approved producer that has not activated yet is pending', () {
      const producer = ProducerAccount(
        producerAccountId: 'pa-1',
        name: 'Ferme Test',
        pendingActivation: true,
      );

      expect(
        userRowFromProducerAccount(producer).displayStatus,
        UserDisplayStatus.pendingInvitation,
      );
    });

    test('an activated producer is active, a suspended one suspended', () {
      const producer = ProducerAccount(
        producerAccountId: 'pa-1',
        name: 'Ferme Test',
      );

      expect(
        userRowFromProducerAccount(producer).displayStatus,
        UserDisplayStatus.active,
      );
      expect(
        userRowFromProducerAccount(
          producer.copyWith(activeStatus: false),
        ).displayStatus,
        UserDisplayStatus.suspended,
      );
    });
  });

  group('UserRow equality', () {
    test('two rows of the same user with different content are not equal, '
        'so a late organization name or a role change reaches the screen', () {
      const member = Member(
        memberId: 'm-1',
        organizationId: 'org-1',
        roles: {Role.volunteer},
      );
      final withId = userRowFromMembers([member], const {})!;
      final withName = userRowFromMembers(
        [member],
        const {'org-1': 'AMAP des Pins'},
      )!;
      final withRole = userRowFromMembers(
        [
          member.copyWith(roles: {Role.coordinator}),
        ],
        const {'org-1': 'AMAP des Pins'},
      )!;

      expect(withId, isNot(withName));
      expect(withName, isNot(withRole));
      expect(
        withName,
        userRowFromMembers([member], const {'org-1': 'AMAP des Pins'}),
      );
    });
  });

  group('userRowFromOwner', () {
    const owner = Owner(
      ownerId: 'o-1',
      firstName: '',
      lastName: '',
      email: 'owner@example.com',
      registeredAt: '1970-01-01T00:00:00Z',
      updatedAt: '1970-01-01T00:00:00Z',
    );

    test('an epoch registration date (seeded owner) is unknown', () {
      expect(userRowFromOwner(owner).registeredAt, isNull);
    });

    test('a real registration date is kept', () {
      expect(
        userRowFromOwner(
          owner.copyWith(registeredAt: '2026-09-25T10:19:55.842Z'),
        ).registeredAt,
        '2026-09-25T10:19:55.842Z',
      );
    });
  });

  group('userRowFromMembers registration date', () {
    test('uses the earliest known registration date of the memberships', () {
      const first = Member(
        memberId: 'm-1',
        organizationId: 'org-1',
        registeredAt: '2026-09-25T10:00:00Z',
      );
      final second = first.copyWith(
        organizationId: 'org-2',
        registeredAt: '2026-01-02T10:00:00Z',
      );
      final legacy = first.copyWith(
        organizationId: 'org-3',
        registeredAt: null,
      );

      expect(
        userRowFromMembers([first, second, legacy], const {})!.registeredAt,
        '2026-01-02T10:00:00Z',
      );
      expect(userRowFromMembers([legacy], const {})!.registeredAt, isNull);
    });
  });

  group('invitation rows', () {
    test('a pending owner invitation is an invited owner', () {
      const invitation = OwnerInvitation(
        invitationId: 'oi-1',
        firstName: 'Zoé',
        lastName: 'Zed',
        email: 'zoe@example.com',
        status: InvitationStatus.pendingActivation,
        submittedAt: '2026-09-25T10:00:00Z',
      );

      final row = userRowFromOwnerInvitation(invitation);

      expect(row.isOwner, isTrue);
      expect(row.isInvitation, isTrue);
      expect(row.displayStatus, UserDisplayStatus.pendingInvitation);
      expect(row.displayName, 'Zoé Zed');
      expect(row.email, 'zoe@example.com');
    });

    test('a pending member invitation is an invited member of its AMAP', () {
      const invitation = MemberInvitation(
        invitationId: 'mi-1',
        organizationId: 'org-1',
        email: 'julie@example.com',
        firstName: 'Julie',
        lastName: 'Legrand',
        roles: {Role.volunteer},
        status: InvitationStatus.pendingActivation,
        createdAt: '2026-09-25T10:00:00Z',
        expiresAt: '2026-10-02T10:00:00Z',
      );

      final row = userRowFromMemberInvitation(invitation, const {
        'org-1': 'AMAP des Pins',
      });

      expect(row.isOwner, isFalse);
      expect(row.isProducer, isFalse);
      expect(row.isInvitation, isTrue);
      expect(row.displayStatus, UserDisplayStatus.pendingInvitation);
      expect(row.memberships.single.organizationName, 'AMAP des Pins');
      expect(row.memberships.single.roles, {Role.volunteer});
    });
  });
}
