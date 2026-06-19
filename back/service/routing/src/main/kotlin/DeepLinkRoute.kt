package routing

import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.server.response.respondText
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import properties.Properties

internal fun Route.deepLinkRoute(properties: Properties) {
    get("/.well-known/apple-app-site-association") {
        val teamId = properties.propertyOrNull("IOS_TEAM_ID")
        val bundleId = properties.propertyOrNull("IOS_BUNDLE_ID")
        if (teamId == null || bundleId == null) {
            call.respondText("", status = HttpStatusCode.NotFound)
            return@get
        }
        val json =
            """{"applinks":{"apps":[],"details":[{"appID":"$teamId.$bundleId","paths":["/activate"]}]}}"""
        call.respondText(json, ContentType.Application.Json)
    }

    get("/.well-known/assetlinks.json") {
        val packageName = properties.propertyOrNull("ANDROID_PACKAGE_NAME")
        val certFingerprint = properties.propertyOrNull("ANDROID_CERT_FINGERPRINT")
        if (packageName == null || certFingerprint == null) {
            call.respondText("", status = HttpStatusCode.NotFound)
            return@get
        }
        val json =
            """[{"relation":["delegate_permission/common.handle_all_urls"],"target":{"namespace":"android_app","package_name":"$packageName","sha256_cert_fingerprints":["$certFingerprint"]}}]"""
        call.respondText(json, ContentType.Application.Json)
    }
}
