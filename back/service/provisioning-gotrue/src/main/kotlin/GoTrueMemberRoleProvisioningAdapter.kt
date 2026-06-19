package provisioning.gotrue

import authentication.Role
import core.MemberRoleProvisioningPort
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.CoroutineDispatcher
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

@Single(createdAtStart = true, binds = [MemberRoleProvisioningPort::class])
internal class GoTrueMemberRoleProvisioningAdapter(
    private val properties: Properties,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO,
) : MemberRoleProvisioningPort {
    private val goTrueBaseUrl: String = properties.propertyOrFail("GOTRUE_JWT_ISSUER")
    private val serviceRoleKey: String = properties.propertyOrFail("GOTRUE_SERVICE_ROLE_KEY")
    private val httpClient: HttpClient = HttpClient.newHttpClient()

    override suspend fun updateRoles(
        memberId: String,
        oldRoles: Set<Role>,
        newRoles: Set<Role>,
    ) {
        withContext(dispatcher) {
            val body =
                json.encodeToString(
                    mapOf(
                        "app_metadata" to
                            mapOf(
                                "roles" to newRoles.map { it.name },
                            ),
                    ),
                )
            val request =
                HttpRequest
                    .newBuilder()
                    .uri(URI.create("$goTrueBaseUrl/admin/users/$memberId"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer $serviceRoleKey")
                    .method("PUT", HttpRequest.BodyPublishers.ofString(body))
                    .build()
            val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            if (response.statusCode() !in 200..299) {
                error("GoTrue role update failed: ${response.statusCode()} ${response.body()}")
            }
            logger.info { "Roles updated in GoTrue for $memberId: $newRoles" }
        }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}
