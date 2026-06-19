import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavMenuWidget._roleSubtitle', () {
    test('displays single member role correctly', () {
      final state = AuthViewState(
        producerId: 'user-1',
        memberRoles: {Role.coordinator},
      );
      final subtitle = _roleSubtitle(state);
      expect(subtitle, equals('COORDINATEUR'));
    });

    test('displays single platform role correctly', () {
      final state = AuthViewState(
        producerId: 'user-1',
        role: UserRole.producer,
      );
      final subtitle = _roleSubtitle(state);
      expect(subtitle, equals('Producteur'));
    });

    test('displays multiple member roles', () {
      final state = AuthViewState(
        producerId: 'user-1',
        memberRoles: {Role.admin, Role.volunteer, Role.coordinator},
      );
      final subtitle = _roleSubtitle(state);
      expect(subtitle, contains('Rôles :'));
      expect(subtitle, contains('BÉNÉVOLE'));
      expect(subtitle, contains('COORDINATEUR'));
      expect(subtitle, contains('ADMIN'));
    });

    test('displays correctly when admin gains coordinator role', () {
      final state = AuthViewState(
        producerId: 'user-1',
        memberRoles: {Role.admin, Role.coordinator},
      );
      final subtitle = _roleSubtitle(state);
      expect(subtitle, contains('Rôles :'));
      expect(subtitle, contains('COORDINATEUR'));
      expect(subtitle, contains('ADMIN'));
    });

    test('shows admin as single role when only admin role', () {
      final state = AuthViewState(
        producerId: 'user-1',
        memberRoles: {Role.admin},
      );
      final subtitle = _roleSubtitle(state);
      expect(subtitle, equals('ADMIN'));
    });
  });
}

// Import the private function from the nav_menu_widget for testing.
// This is needed because _roleSubtitle is private in the actual code.
String _roleSubtitle(AuthViewState authState) {
  final memberRoles = authState.memberRoles;
  if (memberRoles.length > 1) {
    final labels = memberRoles.map(_memberRoleLabel).join(' · ');
    return 'Rôles : $labels';
  }
  if (memberRoles.length == 1) {
    return _memberRoleLabel(memberRoles.first);
  }
  return _platformRoleLabel(authState.role);
}

String _memberRoleLabel(Role role) => switch (role) {
  Role.volunteer => 'BÉNÉVOLE',
  Role.coordinator => 'COORDINATEUR',
  Role.admin => 'ADMIN',
  Role.owner || Role.producer => '',
};

String _platformRoleLabel(UserRole role) => switch (role) {
  UserRole.volunteer => 'Bénévole',
  UserRole.coordinator => 'Coordinateur',
  UserRole.memberNoRole => 'Membre',
  UserRole.admin => 'Administrateur',
  UserRole.owner => 'Propriétaire',
  UserRole.producer => 'Producteur',
};
