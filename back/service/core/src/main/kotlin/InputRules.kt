package core

/**
 * Server-side input rules shared by routes and entity services. Each rule mirrors
 * a front form check (`front/lib/domain/validation/input_rules.dart`): the front
 * check is UX, this one is authoritative (see root `AGENTS.md` → "Validation on
 * both sides"). `require*` / `optional*` helpers return a human-readable reason
 * naming the field, or `null` when the value is valid.
 */
object InputRules {
    const val MAX_NAME_LENGTH = 200
    const val MAX_EMAIL_LENGTH = 254
    const val MAX_COMMENT_LENGTH = 2000
    const val MAX_PHONE_LENGTH = 30
    private const val MIN_PHONE_DIGITS = 6

    // Pragmatic shape check (local@domain.tld, no whitespace): deliverability is
    // proven by the emails the platform sends.
    private val EMAIL_REGEX = Regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")

    // Digits with the usual separators, an optional leading `+` (international prefix).
    private val PHONE_REGEX = Regex("^\\+?[0-9 .()\\-]+$")
    private val HH_MM_REGEX = Regex("^([01]\\d|2[0-3]):([0-5]\\d)$")

    fun isValidEmail(value: String): Boolean {
        val trimmed = value.trim()
        return trimmed.length <= MAX_EMAIL_LENGTH && EMAIL_REGEX.matches(trimmed)
    }

    fun isValidHttpUrl(value: String): Boolean {
        val trimmed = value.trim()
        val schemeEnd = trimmed.indexOf("://")
        if (schemeEnd < 0) return false
        val scheme = trimmed.substring(0, schemeEnd).lowercase()
        val host =
            trimmed
                .substring(schemeEnd + 3)
                .substringBefore('/')
                .substringBefore('?')
                .substringBefore('#')
        return (scheme == "http" || scheme == "https") && host.isNotBlank() && host.none { it.isWhitespace() }
    }

    fun isValidPhone(value: String): Boolean {
        val trimmed = value.trim()
        return trimmed.length <= MAX_PHONE_LENGTH &&
            PHONE_REGEX.matches(trimmed) &&
            trimmed.count { it.isDigit() } >= MIN_PHONE_DIGITS
    }

    /** Minutes since midnight for a strict `HH:MM` value, or `null` when malformed. */
    fun minutesOf(hhmm: String): Int? = HH_MM_REGEX.matchEntire(hhmm)?.destructured?.let { (h, m) -> h.toInt() * 60 + m.toInt() }

    fun requireName(
        field: String,
        value: String,
    ): String? =
        when {
            value.isBlank() -> "$field must not be blank"
            value.length > MAX_NAME_LENGTH -> "$field must not exceed $MAX_NAME_LENGTH characters"
            else -> null
        }

    fun requireEmail(
        field: String,
        value: String,
    ): String? = if (isValidEmail(value)) null else "$field is not a valid email address"

    fun optionalEmail(
        field: String,
        value: String?,
    ): String? = if (value.isNullOrBlank()) null else requireEmail(field, value)

    fun optionalHttpUrl(
        field: String,
        value: String?,
    ): String? = if (value.isNullOrBlank() || isValidHttpUrl(value)) null else "$field is not a valid http(s) URL"

    fun optionalPhone(
        field: String,
        value: String?,
    ): String? = if (value.isNullOrBlank() || isValidPhone(value)) null else "$field is not a valid phone number"

    /**
     * Basket sizes are identified by their name (contract prices, subscriptions and
     * basket compositions reference it): each must be a valid name and names must be
     * unique, ignoring case and surrounding whitespace.
     */
    fun basketSizesError(
        field: String,
        names: List<String>,
    ): String? {
        names.forEach { name -> requireName(field, name)?.let { return it } }
        val seen = mutableSetOf<String>()
        names.map { it.trim().lowercase() }.forEach { key ->
            if (!seen.add(key)) return "$field must not contain the same name twice: $key"
        }
        return null
    }

    fun optionalComment(
        field: String,
        value: String?,
    ): String? =
        if (value != null && value.length > MAX_COMMENT_LENGTH) {
            "$field must not exceed $MAX_COMMENT_LENGTH characters"
        } else {
            null
        }

    fun requireAtLeast(
        field: String,
        value: Int,
        min: Int,
    ): String? = if (value >= min) null else "$field must be at least $min"
}
