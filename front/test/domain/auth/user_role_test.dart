import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRoleResolver.resolveRole', () {
    test('empty list → memberNoRole', () {
      expect(<String>[].resolveRole(), UserRole.memberNoRole);
    });

    test('OWNER → owner', () {
      expect(['OWNER'].resolveRole(), UserRole.owner);
    });

    test('ADMIN → admin', () {
      expect(['ADMIN'].resolveRole(), UserRole.admin);
    });

    test('COORDINATOR → coordinator', () {
      expect(['COORDINATOR'].resolveRole(), UserRole.coordinator);
    });

    test('VOLUNTEER → volunteer', () {
      expect(['VOLUNTEER'].resolveRole(), UserRole.volunteer);
    });

    test('PRODUCER → producer', () {
      expect(['PRODUCER'].resolveRole(), UserRole.producer);
    });

    test('OWNER beats ADMIN (priority)', () {
      expect(['ADMIN', 'OWNER'].resolveRole(), UserRole.owner);
    });

    test('OWNER beats COORDINATOR', () {
      expect(['COORDINATOR', 'OWNER'].resolveRole(), UserRole.owner);
    });

    test('ADMIN beats COORDINATOR', () {
      expect(['COORDINATOR', 'ADMIN'].resolveRole(), UserRole.admin);
    });

    test('ADMIN beats VOLUNTEER', () {
      expect(['VOLUNTEER', 'ADMIN'].resolveRole(), UserRole.admin);
    });

    test('COORDINATOR beats VOLUNTEER', () {
      expect(['VOLUNTEER', 'COORDINATOR'].resolveRole(), UserRole.coordinator);
    });

    test('VOLUNTEER beats PRODUCER', () {
      expect(['PRODUCER', 'VOLUNTEER'].resolveRole(), UserRole.volunteer);
    });

    test('unknown roles → memberNoRole', () {
      expect(['UNKNOWN', 'MEMBER'].resolveRole(), UserRole.memberNoRole);
    });
  });

  group('MemberRoleResolver.resolveMemberRoles', () {
    test('empty list → empty set', () {
      expect(<String>[].resolveMemberRoles(), isEmpty);
    });

    test('VOLUNTEER → {volunteer}', () {
      expect(['VOLUNTEER'].resolveMemberRoles(), {Role.volunteer});
    });

    test('COORDINATOR → {coordinator}', () {
      expect(['COORDINATOR'].resolveMemberRoles(), {Role.coordinator});
    });

    test('ADMIN → {admin}', () {
      expect(['ADMIN'].resolveMemberRoles(), {Role.admin});
    });

    test('VOLUNTEER + COORDINATOR → both in set', () {
      expect(
        ['COORDINATOR', 'VOLUNTEER'].resolveMemberRoles(),
        containsAll([Role.volunteer, Role.coordinator]),
      );
    });

    test('COORDINATOR + ADMIN → both in set', () {
      expect(
        ['ADMIN', 'COORDINATOR'].resolveMemberRoles(),
        containsAll([Role.coordinator, Role.admin]),
      );
    });

    test('all three → all in set', () {
      expect(
        ['ADMIN', 'VOLUNTEER', 'COORDINATOR'].resolveMemberRoles(),
        containsAll([Role.volunteer, Role.coordinator, Role.admin]),
      );
    });

    test('OWNER and PRODUCER are ignored', () {
      expect(['OWNER', 'PRODUCER'].resolveMemberRoles(), isEmpty);
    });

    test('VOLUNTEER + OWNER → only volunteer', () {
      expect(['VOLUNTEER', 'OWNER'].resolveMemberRoles(), {Role.volunteer});
    });

    test('unknown strings → empty set', () {
      expect(['UNKNOWN', 'MEMBER'].resolveMemberRoles(), isEmpty);
    });
  });
}
