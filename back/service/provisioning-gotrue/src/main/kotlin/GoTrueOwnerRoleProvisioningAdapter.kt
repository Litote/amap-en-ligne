package provisioning.gotrue

import authentication.Role
import core.OwnerRoleProvisioningPort
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import org.koin.core.annotation.Single
import properties.Properties
import serialization.json
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

@Single(createdAtStart = true, binds = [OwnerRoleProvisioningPort::class])
internal class GoTrueOwnerRoleProvisioningAdapter(
    private val properties: Properties,
) : OwnerRoleProvisioningPort {
    private val goTrueBaseUrl: String = properties.propertyOrFail("GOTRUE_JWT_ISSUER")
    private val serviceRoleKey: String = properties.propertyOrFail("GOTRUE_SERVICE_ROLE_KEY")
    private val httpClient: HttpClient = HttpClient.newHttpClient()

    override suspend fun updateOwnerRole(ownerId: String) {
        withContext(Dispatchers.IO) {
            val body =
                json.encodeToString(
                    mapOf(
                        "app_metadata" to
                            mapOf(
                                "roles" to listOf(Role.OWNER.name),
                            ),
                    ),
                )
            val request =
                HttpRequest
                    .newBuilder()
                    .uri(URI.create("$goTrueBaseUrl/admin/users/$ownerId"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer $serviceRoleKey")
                    .method("PUT", HttpRequest.BodyPublishers.ofString(body))
                    .build()
            val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            if (response.statusCode() !in 200..299) {
                error("GoTrue owner role update failed: ${response.statusCode()} ${response.body()}")
            }
            logger.info { "Owner role set in GoTrue for $ownerId" }
        }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}
