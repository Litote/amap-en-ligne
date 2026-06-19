package deploy.jvm

import io.github.oshai.kotlinlogging.KotlinLogging
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.plugins.cors.routing.CORS
import properties.Properties

/**
 * Installs the standard Ktor CORS plugin when [Properties.Instance] exposes
 * a non-empty `CORS_ALLOW_ORIGINS` variable.
 *
 * Accepted values:
 *  - unset / empty   → plugin not installed at all (production default for
 *                      a same-origin deploy)
 *  - `*`             → `anyHost()` — convenient for dev; do not use in prod
 *  - csv of origins  → `allowHost(...)` for each (e.g.
 *                      `https://app.example.com,https://catalog.example.org`)
 *
 * In the Lambda deployment, CORS is handled by API Gateway's `cors_configuration`
 * (see `infra/modules/api_gateway/main.tf`) and this code is not part of the
 * classpath at all.
 */
internal fun Application.installCorsIfConfigured() {
    val raw =
        Properties.Instance
            .propertyOrNull("CORS_ALLOW_ORIGINS")
            ?.trim()
            .orEmpty()
    if (raw.isEmpty()) {
        logger.debug { "CORS_ALLOW_ORIGINS not set; Ktor CORS plugin not installed" }
        return
    }

    install(CORS) {
        if (raw == "*") {
            anyHost()
        } else {
            raw
                .split(",")
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .forEach { origin ->
                    val (scheme, host) = parseOrigin(origin)
                    allowHost(host, schemes = listOf(scheme))
                }
        }
        allowMethod(HttpMethod.Get)
        allowMethod(HttpMethod.Post)
        allowMethod(HttpMethod.Patch)
        allowMethod(HttpMethod.Delete)
        allowMethod(HttpMethod.Options)
        allowHeader(HttpHeaders.Authorization)
        allowHeader(HttpHeaders.ContentType)
    }
    logger.info { "Ktor CORS plugin installed with allow-origins='$raw'" }
}

private fun parseOrigin(origin: String): Pair<String, String> {
    val idx = origin.indexOf("://")
    if (idx <= 0) error("CORS_ALLOW_ORIGINS entry '$origin' must include a scheme (https:// or http://)")
    val scheme = origin.substring(0, idx)
    val host = origin.substring(idx + 3).trimEnd('/')
    return scheme to host
}

private val logger = KotlinLogging.logger {}
