import 'package:amap_en_ligne/domain/auth/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('passwordPolicyViolation', () {
    test('accepts a compliant password', () {
      expect(passwordPolicyViolation('Str0ngPassword'), isNull);
    });

    test('reports the first violated rule', () {
      expect(
        passwordPolicyViolation('Sh0rt'),
        'Le mot de passe doit contenir au moins 12 caractères.',
      );
      expect(
        passwordPolicyViolation('ABCDEFGHIJK1'),
        'Le mot de passe doit contenir au moins une minuscule.',
      );
      expect(
        passwordPolicyViolation('abcdefghijk1'),
        'Le mot de passe doit contenir au moins une majuscule.',
      );
      expect(
        passwordPolicyViolation('Abcdefghijkl'),
        'Le mot de passe doit contenir au moins un chiffre.',
      );
    });
  });
}
