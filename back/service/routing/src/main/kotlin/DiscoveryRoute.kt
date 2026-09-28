package routing

import instanceconfig.InstanceConfig
import io.ktor.http.CacheControl
import io.ktor.server.response.cacheControl
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get

/**
 * Public discovery endpoint — no authentication required.
 *
 * GET /.well-known/amap-en-ligne.json
 *
 * Returns the instance's public metadata so that clients can bootstrap
 * their configuration from a server URL alone, without hardcoded presets.
 * Response is safe to cache for 1 hour (non-secret data only).
 */
internal fun Route.discoveryRoute(instanceConfig: InstanceConfig) {
    get("/.well-known/amap-en-ligne.json") {
        call.response.cacheControl(CacheControl.MaxAge(maxAgeSeconds = 3600))
        call.respond(instanceConfig)
    }
}
