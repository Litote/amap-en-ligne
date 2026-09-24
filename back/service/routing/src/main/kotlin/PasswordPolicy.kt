package routing

private const val MIN_PASSWORD_LENGTH = 12

/**
 * Instance-wide password policy applied at activation, aligned on the strictest
 * provider (Cognito pool: 12 chars, lowercase, uppercase, digit) so both
 * deployments behave identically and the provider never rejects a password
 * mid-activation. Mirrored by the front activation form (`password_policy.dart`).
 *
 * Returns the first violated rule, or `null` when the password is compliant.
 */
internal fun passwordPolicyViolation(password: String): String? =
    when {
        password.length < MIN_PASSWORD_LENGTH -> "password must be at least $MIN_PASSWORD_LENGTH characters long"
        password.none { it.isLowerCase() } -> "password must contain a lowercase letter"
        password.none { it.isUpperCase() } -> "password must contain an uppercase letter"
        password.none { it.isDigit() } -> "password must contain a digit"
        else -> null
    }
