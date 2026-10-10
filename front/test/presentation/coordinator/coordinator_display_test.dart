import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MemberRegistration registration(String displayName) => MemberRegistration(
    memberId: 'member-1',
    displayName: displayName,
    memberEmail: '',
    registrationInstant: '2026-10-01T10:00:00Z',
    status: RegistrationStatus.confirmed,
  );

  group('registrationDisplayName', () {
    test('GIVEN a registration with its copied name THEN shows it', () {
      expect(
        registrationDisplayName(registration('Ada Lovelace')),
        'Ada Lovelace',
      );
    });

    test('GIVEN the registration of a deleted member (name blanked) '
        'THEN reads « Membre supprimé »', () {
      expect(registrationDisplayName(registration('')), 'Membre supprimé');
      expect(registrationDisplayName(registration('  ')), 'Membre supprimé');
    });
  });
}
