package provisioning.gotrue

import authentication.Role
import core.UserProvisioningPort
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

@Single(createdAtStart = true, binds = [UserProvisioningPort::class])
internal class GoTrueUserProvisioningAdapter(
    private val properties: Properties,
) : UserProvisioningPort {
    private val goTrueBaseUrl: String = properties.propertyOrFail("GOTRUE_JWT_ISSUER")
    private val serviceRoleKey: String = properties.propertyOrFail("GOTRUE_SERVICE_ROLE_KEY")
    private val httpClient: HttpClient = HttpClient.newHttpClient()

    override suspend fun createAdminUser(
        email: String,
        password: String,
    ): String =
        withContext(Dispatchers.IO) {
            val body =
                json.encodeToString(
                    mapOf(
                        "email" to email,
                        "password" to password,
                        "app_metadata" to
                            mapOf(
                                "role" to "admin",
                            ),
                    ),
                )
            val request =
                HttpRequest
                    .newBuilder()
                    .uri(URI.create("$goTrueBaseUrl/admin/users"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer $serviceRoleKey")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build()
            val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            if (response.statusCode() !in 200..299) {
                error("GoTrue admin user creation failed: ${response.statusCode()} ${response.body()}")
            }
            logger.info { "Admin user created in GoTrue for $email" }
            val responseBody = json.decodeFromString<Map<String, kotlinx.serialization.json.JsonElement>>(response.body())
            (responseBody["id"] as? kotlinx.serialization.json.JsonPrimitive)?.content
                ?: error("GoTrue response missing 'id' field")
        }

    override suspend fun createOwnerUser(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
    ): String =
        withContext(Dispatchers.IO) {
            val body =
                json.encodeToString(
                    mapOf(
                        "email" to email,
                        "password" to password,
                        "user_metadata" to
                            mapOf(
                                "given_name" to firstName,
                                "family_name" to lastName,
                            ),
                        "app_metadata" to
                            mapOf(
                                "roles" to listOf("OWNER"),
                            ),
                    ),
                )
            val request =
                HttpRequest
                    .newBuilder()
                    .uri(URI.create("$goTrueBaseUrl/admin/users"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer $serviceRoleKey")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build()
            val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            if (response.statusCode() !in 200..299) {
                error("GoTrue owner user creation failed: ${response.statusCode()} ${response.body()}")
            }
            logger.info { "Owner user created in GoTrue for $email" }
            // Parse the "id" field from the GoTrue response as the subject
            val responseBody = json.decodeFromString<Map<String, kotlinx.serialization.json.JsonElement>>(response.body())
            (responseBody["id"] as? kotlinx.serialization.json.JsonPrimitive)?.content
                ?: error("GoTrue response missing 'id' field")
        }

    override suspend fun createProducerUser(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
    ): String =
        withContext(Dispatchers.IO) {
            val body =
                json.encodeToString(
                    mapOf(
                        "email" to email,
                        "password" to password,
                        "user_metadata" to
                            mapOf(
                                "given_name" to firstName,
                                "family_name" to lastName,
                            ),
                        "app_metadata" to
                            mapOf(
                                "roles" to listOf(Role.PRODUCER.name),
                            ),
                    ),
                )
            val request =
                HttpRequest
                    .newBuilder()
                    .uri(URI.create("$goTrueBaseUrl/admin/users"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer $serviceRoleKey")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build()
            val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            if (response.statusCode() !in 200..299) {
                error("GoTrue producer user creation failed: ${response.statusCode()} ${response.body()}")
            }
            logger.info { "Producer user created in GoTrue for $email" }
            val responseBody = json.decodeFromString<Map<String, kotlinx.serialization.json.JsonElement>>(response.body())
            (responseBody["id"] as? kotlinx.serialization.json.JsonPrimitive)?.content
                ?: error("GoTrue response missing 'id' field")
        }

    override suspend fun createMemberUser(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        organizationId: String,
        roles: Set<Role>,
    ): String =
        withContext(Dispatchers.IO) {
            val body =
                json.encodeToString(
                    mapOf(
                        "email" to email,
                        "password" to password,
                        "user_metadata" to
                            mapOf(
                                "given_name" to firstName,
                                "family_name" to lastName,
                            ),
                        "app_metadata" to
                            mapOf(
                                "roles" to roles.map(Role::name),
                            ),
                    ),
                )
            val request =
                HttpRequest
                    .newBuilder()
                    .uri(URI.create("$goTrueBaseUrl/admin/users"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer $serviceRoleKey")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build()
            val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            if (response.statusCode() !in 200..299) {
                error("GoTrue member user creation failed: ${response.statusCode()} ${response.body()}")
            }
            logger.info { "Member user created in GoTrue for $email" }
            val responseBody = json.decodeFromString<Map<String, kotlinx.serialization.json.JsonElement>>(response.body())
            (responseBody["id"] as? kotlinx.serialization.json.JsonPrimitive)?.content
                ?: error("GoTrue response missing 'id' field")
        }

    override suspend fun banUser(sub: String) {
        // GoTrue ban_duration accepts a Go-style duration; "876000h" ≈ 100 years.
        updateBanDuration(sub, "876000h")
    }

    override suspend fun unbanUser(sub: String) {
        updateBanDuration(sub, "none")
    }

    override suspend fun deleteUser(sub: String) {
        withContext(Dispatchers.IO) {
            val request =
                HttpRequest
                    .newBuilder()
                    .uri(URI.create("$goTrueBaseUrl/admin/users/$sub"))
                    .header("Authorization", "Bearer $serviceRoleKey")
                    .DELETE()
                    .build()
            val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            // 404 is benign — the user was already removed (idempotent).
            if (response.statusCode() !in 200..299 && response.statusCode() != 404) {
                error("GoTrue admin user deletion failed: ${response.statusCode()} ${response.body()}")
            }
            logger.info { "User $sub deleted in GoTrue (status=${response.statusCode()})" }
        }
    }

    override suspend fun listAuthSubsByProducerAccount(producerAccountId: String): List<String> =
        withContext(Dispatchers.IO) {
            // sub == producerAccountId by invariant: direct lookup by sub (= GoTrue user id).
            val request =
                HttpRequest
                    .newBuilder()
                    .uri(URI.create("$goTrueBaseUrl/admin/users/$producerAccountId"))
                    .header("Authorization", "Bearer $serviceRoleKey")
                    .GET()
                    .build()
            val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            val result =
                when (response.statusCode()) {
                    404 -> emptyList()
                    in 200..299 -> listOf(producerAccountId)
                    else -> error("GoTrue admin user lookup failed: ${response.statusCode()} ${response.body()}")
                }
            logger.info { "GoTrue listAuthSubsByProducerAccount($producerAccountId) → ${result.size} user(s)" }
            result
        }

    override suspend fun findProducerAccountIdByEmail(email: String): String? =
        withContext(Dispatchers.IO) {
            // sub == producerAccountId by invariant: find the user by email, confirm PRODUCER role,
            // return their id (= sub = producerAccountId).
            var page = 1
            val perPage = 100
            while (true) {
                val request =
                    HttpRequest
                        .newBuilder()
                        .uri(URI.create("$goTrueBaseUrl/admin/users?per_page=$perPage&page=$page"))
                        .header("Authorization", "Bearer $serviceRoleKey")
                        .GET()
                        .build()
                val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
                if (response.statusCode() !in 200..299) {
                    error("GoTrue admin user list failed: ${response.statusCode()} ${response.body()}")
                }
                val body =
                    json.decodeFromString<kotlinx.serialization.json.JsonElement>(response.body())
                val users =
                    when (body) {
                        is kotlinx.serialization.json.JsonObject -> body["users"] as? kotlinx.serialization.json.JsonArray
                        is kotlinx.serialization.json.JsonArray -> body
                        else -> null
                    } ?: kotlinx.serialization.json.JsonArray(emptyList())
                if (users.isEmpty()) break
                for (user in users) {
                    val obj = user as? kotlinx.serialization.json.JsonObject ?: continue
                    val userEmail =
                        (obj["email"] as? kotlinx.serialization.json.JsonPrimitive)?.content
                    if (!userEmail.equals(email, ignoreCase = true)) continue
                    val appMetadata =
                        obj["app_metadata"] as? kotlinx.serialization.json.JsonObject ?: continue
                    val roles =
                        (appMetadata["roles"] as? kotlinx.serialization.json.JsonArray)
                            ?.mapNotNull { (it as? kotlinx.serialization.json.JsonPrimitive)?.content }
                            .orEmpty()
                    if (!roles.contains(Role.PRODUCER.name)) return@withContext null
                    return@withContext (obj["id"] as? kotlinx.serialization.json.JsonPrimitive)?.content
                }
                if (users.size < perPage) break
                page += 1
            }
            null
        }

    private suspend fun updateBanDuration(
        sub: String,
        banDuration: String,
    ) {
        withContext(Dispatchers.IO) {
            val body = json.encodeToString(mapOf("ban_duration" to banDuration))
            val request =
                HttpRequest
                    .newBuilder()
                    .uri(URI.create("$goTrueBaseUrl/admin/users/$sub"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer $serviceRoleKey")
                    .PUT(HttpRequest.BodyPublishers.ofString(body))
                    .build()
            val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
            if (response.statusCode() !in 200..299) {
                error(
                    "GoTrue admin user update (ban_duration=$banDuration) failed: ${response.statusCode()} ${response.body()}",
                )
            }
            logger.info { "User $sub ban_duration set to '$banDuration' in GoTrue" }
        }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}
