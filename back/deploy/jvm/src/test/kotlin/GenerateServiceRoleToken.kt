package deploy.jvm

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import java.time.Instant
import java.util.Date

/**
 * Prints a service-role JWT suitable for use as GOTRUE_SERVICE_ROLE_KEY.
 * Run via: ./gradlew :deploy:jvm:generateServiceRoleToken
 *
 * The JWT is signed with the GOTRUE_JWT_SECRET system/env property.
 * Defaults to the dev secret in .env.example when not set.
 */
fun main() {
    val secret =
        System.getProperty("GOTRUE_JWT_SECRET")
            ?: System.getenv("GOTRUE_JWT_SECRET")
            ?: "dev-jwt-secret-change-me-dev-jwt-secret-change-me"
    val issuer =
        System.getProperty("GOTRUE_JWT_ISSUER")
            ?: System.getenv("GOTRUE_JWT_ISSUER")
            ?: "http://localhost:9999/auth/v1"
    val now = Instant.now()
    val token =
        JWT
            .create()
            .withIssuer(issuer)
            .withClaim("role", "service_role")
            .withIssuedAt(Date.from(now))
            .withExpiresAt(Date.from(now.plusSeconds(3650L * 24 * 3600)))
            .sign(Algorithm.HMAC256(secret))
    println("GOTRUE_SERVICE_ROLE_KEY=$token")
}
