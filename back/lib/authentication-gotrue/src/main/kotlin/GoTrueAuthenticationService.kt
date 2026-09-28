package authentication

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.auth0.jwt.exceptions.JWTDecodeException
import com.auth0.jwt.exceptions.TokenExpiredException
import com.auth0.jwt.interfaces.DecodedJWT
import i18n.DEFAULT_LANGUAGE
import i18n.DEFAULT_TIMEZONE
import i18n.toTimeZone
import io.github.oshai.kotlinlogging.KotlinLogging
import properties.Properties

/**
 * Validates JWTs issued by Supabase Auth (GoTrue).
 *
 * GoTrue signs tokens with HS256 using a shared secret (`GOTRUE_JWT_SECRET`). The same secret
 * lives on the GoTrue container and on this back, so we verify symmetrically — no JWKS round-trip.
 *
 * Claim mapping (GoTrue → AuthenticatedInfo):
 *   sub                                  → memberId
 *   email / email_verified               → email / emailVerified
 *   user_metadata.given_name             → firstName
 *   user_metadata.family_name            → lastName
 *   user_metadata.locale                 → language
 *   user_metadata.zoneinfo               → timezone
 *   app_metadata.roles  (List<String>)   → roles  (mapped via Role.fromString)
 *   app_metadata.scopes (List<String>)   → scopes (mapped via Scope.fromString, OAuth "verb:resource" form)
 *
 * `app_metadata` is admin-controlled (only writeable via service-role / SQL), so it is the safe
 * place for security-sensitive claims like roles and scopes. `user_metadata` is user-controlled
 * and is only used here for cosmetic profile fields.
 */
class GoTrueAuthenticationService : AuthenticationService {
    private val secret: String = Properties.Instance.propertyOrFail("GOTRUE_JWT_SECRET")
    private val issuer: String = Properties.Instance.propertyOrFail("GOTRUE_JWT_ISSUER")
    private val audience: String = Properties.Instance.property("GOTRUE_JWT_AUDIENCE", DEFAULT_AUDIENCE)

    private val verifier =
        JWT
            .require(Algorithm.HMAC256(secret))
            .withIssuer(issuer)
            .withAudience(audience)
            .acceptLeeway(60) // Clock skew tolerance (±60s)
            .build()

    override fun getAuthentication(token: String?): Authentication {
        if (token == null) {
            logger.debug { "Token is null" }
            return Authentication.InvalidToken
        }

        val cleanToken =
            if (token.startsWith("Bearer ")) {
                token.substring(7)
            } else {
                token
            }

        // Decode without verification first to detect cross-server tokens early.
        val tokenIssuer =
            try {
                JWT.decode(cleanToken).issuer
            } catch (e: JWTDecodeException) {
                logger.debug(e) { "JWT token is malformed" }
                return Authentication.InvalidToken
            }
        if (tokenIssuer != issuer) {
            logger.debug { "Token issuer '$tokenIssuer' does not match expected '$issuer'" }
            return Authentication.WrongServer(tokenIssuer = tokenIssuer)
        }

        return try {
            val info = verifyAndExtractAuthenticatedInfo(cleanToken)
            if (info == null) {
                logger.debug { "Failed to extract authenticated member from GoTrue token" }
                Authentication.InvalidToken
            } else {
                Authentication.Success(info)
            }
        } catch (e: TokenExpiredException) {
            logger.debug(e) { "JWT token has expired" }
            Authentication.ExpiredToken
        } catch (e: JWTDecodeException) {
            logger.debug(e) { "JWT token is malformed" }
            Authentication.InvalidToken
        } catch (e: Exception) {
            logger.error(e) { "Unexpected error during JWT token processing" }
            Authentication.InvalidToken
        }
    }

    private fun verifyAndExtractAuthenticatedInfo(token: String): AuthenticatedInfo? {
        val jwt: DecodedJWT = verifier.verify(token)

        val memberId = jwt.subject ?: return null
        val email: String =
            jwt.getClaim("email").asString().takeUnless { it.isNullOrBlank() }
                ?: error("empty email")
        val emailVerified: Boolean = jwt.getClaim("email_verified").asBoolean() ?: false

        val appMetadata: Map<String, Any?> = jwt.getClaim("app_metadata").asMap() ?: emptyMap()
        val userMetadata: Map<String, Any?> = jwt.getClaim("user_metadata").asMap() ?: emptyMap()

        val roles =
            (appMetadata["roles"] as? List<*>)
                ?.filterIsInstance<String>()
                ?.mapNotNull { Role.fromString(it) }
                ?: emptyList()

        val scopes =
            (appMetadata["scopes"] as? List<*>)
                ?.filterIsInstance<String>()
                ?.mapNotNull { Scope.fromString(it) }
                ?: emptyList()

        val firstName = userMetadata["given_name"] as? String
        val lastName = userMetadata["family_name"] as? String
        val locale = userMetadata["locale"] as? String
        val timezone = userMetadata["zoneinfo"] as? String

        return AuthenticatedInfo(
            memberId = memberId,
            firstName = firstName ?: "",
            lastName = lastName ?: "",
            email = email,
            emailVerified = emailVerified,
            language = locale ?: DEFAULT_LANGUAGE,
            timezone = (timezone ?: DEFAULT_TIMEZONE).toTimeZone(),
            roles = roles,
            scopes = scopes,
        )
    }

    companion object {
        // GoTrue's default `aud` claim for end-user tokens.
        private const val DEFAULT_AUDIENCE = "authenticated"
    }
}

private val logger = KotlinLogging.logger {}
