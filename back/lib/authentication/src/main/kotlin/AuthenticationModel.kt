package authentication

import i18n.DEFAULT_LANGUAGE
import i18n.DEFAULT_TIMEZONE
import i18n.Language
import i18n.toTimeZone
import id.Id
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.datetime.TimeZone
import kotlinx.serialization.Serializable
import kotlinx.serialization.Transient

enum class MemberType {
    PRODUCER,
    MEMBER,
}

@Serializable
enum class Role {
    OWNER,
    ADMIN,
    PRODUCER,
    COORDINATOR,
    VOLUNTEER,
    ;

    companion object {
        fun fromString(value: String): Role? =
            try {
                valueOf(value.uppercase())
            } catch (_: IllegalArgumentException) {
                logger.error { "Unknown role: '$value'" }
                null
            }
    }
}

enum class Scope {
    READ_PROFILE,
    WRITE_PROFILE,
    READ_DELIVERIES,
    WRITE_DELIVERIES,
    MANAGE_DELIVERIES,
    ;

    companion object {
        fun fromString(value: String): Scope? =
            try {
                // Convert from OAuth 2.0 scope format (read:profile) to enum format (READ_PROFILE)
                val enumName = value.replace(":", "_").uppercase()
                valueOf(enumName)
            } catch (_: IllegalArgumentException) {
                logger.debug { "Unknown scope: '$value'" }
                null
            }
    }
}

@Serializable
data class AuthenticatedInfo(
    val memberId: String,
    val firstName: String,
    val lastName: String,
    val email: String,
    val emailVerified: Boolean = false,
    val organizationId: String? = null,
    val producerAccountId: String? = null,
    val language: Language = DEFAULT_LANGUAGE,
    val timezone: TimeZone = DEFAULT_TIMEZONE.toTimeZone(),
    val roles: List<Role> = emptyList(),
    val scopes: List<Scope> = emptyList(),
) {
    val memberType: MemberType
        get() =
            when {
                producerAccountId != null -> MemberType.PRODUCER
                else -> MemberType.MEMBER
            }
}

private val logger = KotlinLogging.logger {}
