/// Instance password policy applied at account activation.
///
/// Mirrors the back `PasswordPolicy.kt` (routing) which is aligned on the
/// Cognito pool policy, so the server never rejects a password the form
/// accepted.
const int kPasswordMinLength = 12;

/// User-facing summary of the rules, shown under the password field.
const String kPasswordPolicyHint =
    'Au moins $kPasswordMinLength caractères, dont une minuscule, '
    'une majuscule et un chiffre.';

/// Returns the first violated rule as a French message, or `null` when
/// [password] complies with the policy.
String? passwordPolicyViolation(String password) {
  if (password.length < kPasswordMinLength) {
    return 'Le mot de passe doit contenir au moins $kPasswordMinLength caractères.';
  }
  if (!password.contains(RegExp('[a-z]'))) {
    return 'Le mot de passe doit contenir au moins une minuscule.';
  }
  if (!password.contains(RegExp('[A-Z]'))) {
    return 'Le mot de passe doit contenir au moins une majuscule.';
  }
  if (!password.contains(RegExp('[0-9]'))) {
    return 'Le mot de passe doit contenir au moins un chiffre.';
  }
  return null;
}
