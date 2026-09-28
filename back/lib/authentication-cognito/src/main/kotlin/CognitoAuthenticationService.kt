package authentication

import com.auth0.jwk.JwkProviderBuilder
import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.auth0.jwt.exceptions.JWTDecodeException
import com.auth0.jwt.exceptions.TokenExpiredException
import com.auth0.jwt.interfaces.DecodedJWT
import i18n.DEFAULT_LANGUAGE
import i18n.DEFAULT_TIMEZONE
import i18n.toTimeZone
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import properties.Properties
import java.net.URI
import java.security.interfaces.RSAPublicKey
import java.util.Base64
import java.util.concurrent.TimeUnit

class CognitoAuthenticationService : AuthenticationService {
    private val issuer: String = Properties.Instance.propertyOrFail("COGNITO_ISSUER_URL")

    @Suppress("unused")
    private val audience: String = Properties.Instance.propertyOrFail("COGNITO_CLIENT_ID")

    private val jwkProvider =
        JwkProviderBuilder(URI("$issuer/.well-known/jwks.json").toURL())
            .cached(10, 24, TimeUnit.HOURS) // Cache 10 keys, 24h
            .rateLimited(10, 1, TimeUnit.MINUTES) // Limit calls
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
            val member = verifyAndExtractAuthenticatedInfo(cleanToken)
            if (member == null) {
                logger.debug { "Failed to verify and extract authenticated member from token" }
                Authentication.InvalidToken
            } else {
                Authentication.Success(member)
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
        return try {
            // 1) Decode header only to get kid (DO NOT trust content yet)
            val decodedHeader = JWT.decode(token).header
            val kid = JWTHeader(decodedHeader).kid ?: return null

            // 2) Get public key from JWKS
            val jwk = jwkProvider.get(kid)
            val algorithm = Algorithm.RSA256(jwk.publicKey as RSAPublicKey, null)

            // 3) Build verifier with all security constraints
            val verifier =
                JWT
                    .require(algorithm)
                    .withIssuer(issuer)
                    // Cognito access tokens carry `client_id` rather than `aud`. The API Gateway JWT
                    // authorizer matches `client_id` against the configured audience for us; we keep
                    // local audience verification off here to avoid duplicating that contract.
                    .acceptLeeway(60) // Clock skew tolerance (±60s)
                    .build()

            val jwt: DecodedJWT = verifier.verify(token)

            val tokenUse = jwt.getClaim("token_use").asString()
            if (tokenUse != "access") {
                logger.debug { "Rejecting non-access token: token_use='$tokenUse'" }
                return null
            }

            val memberId = jwt.subject ?: return null
            val firstName: String? = jwt.getClaim("given_name").asString()
            val lastName: String? = jwt.getClaim("family_name").asString()
            // `email` is absent from Cognito access tokens (present only in ID tokens).
            // Fall back to `username` (= the email used at sign-up when username_attributes = ["email"]).
            val email: String =
                jwt.getClaim("email").asString()?.takeUnless { it.isBlank() }
                    ?: jwt.getClaim("username").asString()?.takeUnless { it.isBlank() }
                    ?: ""
            val emailVerified: Boolean = jwt.getClaim("email_verified").asBoolean() ?: false
            // Standard OIDC claims (Cognito forbids ":" in custom-attribute names, so we map
            // language/timezone onto the standard `locale` / `zoneinfo` attributes of the User Pool).
            val locale: String? = jwt.getClaim("locale").asString()
            val timezone: String? = jwt.getClaim("zoneinfo").asString()

            val roleStrings = jwt.getClaim("cognito:groups")?.asList(String::class.java) ?: emptyList()
            val roles = roleStrings.mapNotNull { Role.fromString(it) }

            // Cognito emits scopes as "<resource_server>/<scope>" (e.g. "api/read:profile") for
            // custom resource-server scopes, alongside reserved scopes ("openid", "email", …).
            // Strip the resource-server prefix before mapping to the Scope enum.
            val scopeString: String? = jwt.getClaim("scope").asString()
            val scopes =
                scopeString
                    ?.split(" ")
                    ?.filter { it.isNotBlank() }
                    ?.map { it.substringAfterLast('/') }
                    ?.mapNotNull { Scope.fromString(it) }
                    ?: emptyList()

            AuthenticatedInfo(
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
        } catch (e: Exception) {
            logger.error(e) { "Token verification/extraction failed" }
            null
        }
    }
}

private data class JWTHeader(
    val raw: String,
) {
    val kid: String? =
        runCatching {
            val decodedBytes = Base64.getUrlDecoder().decode(raw)
            val jsonString = String(decodedBytes, Charsets.UTF_8)
            val jsonElement = Json.parseToJsonElement(jsonString)
            jsonElement.jsonObject["kid"]?.jsonPrimitive?.content
        }.getOrNull()
}

private val logger = KotlinLogging.logger {}
