@file:OptIn(ExperimentalTime::class)

package deploy.jvm

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import core.UserProvisioningPort
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import org.koin.core.context.stopKoin
import serialization.json
import java.net.ServerSocket
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.sql.DriverManager
import java.time.Instant
import java.util.Date
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.time.ExperimentalTime

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class ActivationEndpointTest {
    private val container = org.testcontainers.containers.PostgreSQLContainer<Nothing>("postgres:16")
    private val httpClient: HttpClient = HttpClient.newHttpClient()
    private var port: Int = 0
    private lateinit var server: io.ktor.server.engine.EmbeddedServer<*, *>

    private val jwtSecret = "test-jwt-secret-test-jwt-secret-test-jwt-secret"
    private val jwtIssuer = "http://localhost:9999/auth/v1"

    private val stubUserProvisioningPort =
        object : UserProvisioningPort {
            override suspend fun createAdminUser(
                email: String,
                password: String,
            ) = UUID.randomUUID().toString()

            override suspend fun createOwnerUser(
                email: String,
                password: String,
                firstName: String,
                lastName: String,
            ): String = UUID.randomUUID().toString()

            override suspend fun createProducerUser(
                email: String,
                password: String,
                firstName: String,
                lastName: String,
            ): String = UUID.randomUUID().toString()

            override suspend fun createMemberUser(
                email: String,
                password: String,
                firstName: String,
                lastName: String,
                organizationId: String,
                roles: Set<authentication.Role>,
            ): String = UUID.randomUUID().toString()

            override suspend fun banUser(sub: String) = Unit

            override suspend fun unbanUser(sub: String) = Unit

            override suspend fun deleteUser(sub: String) = Unit

            override suspend fun findProducerAccountIdByEmail(email: String): String? = null

            override suspend fun listAuthSubsByProducerAccount(producerAccountId: String): List<String> = emptyList()
        }

    @BeforeAll
    fun setUp() {
        // Defensively clear any Koin context leaked by a previous test class in this JVM
        // (no-op when nothing is started) so bootstrap()'s startKoin cannot fail with
        // KoinApplicationAlreadyStartedException.
        stopKoin()
        container.start()
        System.setProperty("POSTGRES_URL", container.jdbcUrl)
        System.setProperty("POSTGRES_USER", container.username)
        System.setProperty("POSTGRES_PASSWORD", container.password)
        System.setProperty("GOTRUE_JWT_SECRET", jwtSecret)
        System.setProperty("GOTRUE_JWT_ISSUER", jwtIssuer)
        System.setProperty("GOTRUE_JWT_AUDIENCE", "authenticated")
        System.setProperty("INSTANCE_NAME", "Test Instance")
        val now = Instant.now()
        val serviceRoleToken =
            JWT
                .create()
                .withIssuer(jwtIssuer)
                .withClaim("role", "service_role")
                .withIssuedAt(Date.from(now))
                .withExpiresAt(Date.from(now.plusSeconds(3600)))
                .sign(Algorithm.HMAC256(jwtSecret))
        System.setProperty("GOTRUE_SERVICE_ROLE_KEY", serviceRoleToken)
        port = ServerSocket(0).use { it.localPort }
        System.setProperty("INSTANCE_API_URL", "http://127.0.0.1:$port/")

        val stubModule =
            org.koin.dsl.module {
                single<UserProvisioningPort> { stubUserProvisioningPort }
            }
        server =
            bootstrap(
                port,
                stubModule,
            )
        server.start(wait = false)
        insertServer()
    }

    @AfterAll
    fun tearDown() {
        // stopKoin() must always run so a failure here cannot leak the global Koin context
        // into the next test class.
        try {
            if (::server.isInitialized) server.stop(0, 1_000)
        } finally {
            stopKoin()
        }
        container.stop()
        System.clearProperty("POSTGRES_URL")
        System.clearProperty("POSTGRES_USER")
        System.clearProperty("POSTGRES_PASSWORD")
        System.clearProperty("GOTRUE_JWT_SECRET")
        System.clearProperty("GOTRUE_JWT_ISSUER")
        System.clearProperty("GOTRUE_JWT_AUDIENCE")
        System.clearProperty("INSTANCE_NAME")
        System.clearProperty("INSTANCE_API_URL")
        System.clearProperty("GOTRUE_SERVICE_ROLE_KEY")
    }

    @AfterEach
    fun resetDb() {
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn.createStatement().use {
                    it.execute(
                        "TRUNCATE activation_token, organization_request, basket_exchange, organization, producer_account, organization_producer CASCADE",
                    )
                }
            }
    }

    @Test
    fun `GIVEN valid approval flow WHEN POST activate THEN 200 with organization info`() =
        runTest {
            val requestId = insertApprovedRequest()
            val orgId = insertOrganization()
            val token = insertActivationToken(requestId, orgId)

            val response = postActivate(token, "newpassword123")

            assertEquals(200, response.statusCode())
            val body = json.parseToJsonElement(response.body())
            val obj = body as kotlinx.serialization.json.JsonObject
            assertEquals("AMAP Test", obj["organization_name"]?.let { (it as kotlinx.serialization.json.JsonPrimitive).content })
        }

    @Test
    fun `GIVEN unknown token WHEN POST activate THEN 404`() =
        runTest {
            val response = postActivate("nonexistent-token", "password")
            assertEquals(404, response.statusCode())
        }

    @Test
    fun `GIVEN token activated twice WHEN POST activate THEN 409`() =
        runTest {
            val requestId = insertApprovedRequest()
            val orgId = insertOrganization()
            val token = insertActivationToken(requestId, orgId)

            postActivate(token, "newpassword123")
            val second = postActivate(token, "newpassword123")

            assertEquals(409, second.statusCode())
        }

    @Test
    fun `GIVEN approved producer request WHEN POST activate THEN 200 with producer info`() =
        runTest {
            val requestId = insertApprovedProducerRequest()
            val producerAccountId = insertProducerAccount()
            val token = insertProducerActivationToken(requestId, producerAccountId)

            val response = postActivate(token, "newpassword123")

            assertEquals(200, response.statusCode())
            val body = json.parseToJsonElement(response.body()) as kotlinx.serialization.json.JsonObject
            assertEquals("PRODUCER", body["kind"]?.let { (it as kotlinx.serialization.json.JsonPrimitive).content })
            assertEquals("Producer Test", body["organization_name"]?.let { (it as kotlinx.serialization.json.JsonPrimitive).content })
        }

    private fun postActivate(
        token: String,
        password: String,
    ): HttpResponse<String> {
        val body = """{"token":"$token","password":"$password"}"""
        val request =
            HttpRequest
                .newBuilder()
                .uri(URI("http://127.0.0.1:$port/v1/activate"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build()
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString())
    }

    private fun insertApprovedRequest(): String {
        val requestId = UUID.randomUUID().toString()
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO organization_request(request_id, organization_name, organization_type, timezone, default_language,
                            admin_first_name, admin_last_name, admin_email, status, submitted_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, requestId)
                        stmt.setString(2, "AMAP Test")
                        stmt.setString(3, "AMAP")
                        stmt.setString(4, "Europe/Paris")
                        stmt.setString(5, "fr")
                        stmt.setString(6, "Alice")
                        stmt.setString(7, "Martin")
                        stmt.setString(8, "admin@example.com")
                        stmt.setString(9, "APPROVED")
                        stmt.setLong(10, System.currentTimeMillis())
                        stmt.executeUpdate()
                    }
            }
        return requestId
    }

    private fun insertOrganization(): String {
        val orgId = UUID.randomUUID().toString()
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO organization(organization_id, name, contact_email, active_status)
                        VALUES (?, 'AMAP Test', 'admin@example.com', true)
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, orgId)
                        stmt.executeUpdate()
                    }
            }
        return orgId
    }

    private fun insertActivationToken(
        requestId: String,
        organizationId: String,
    ): String {
        val token = UUID.randomUUID().toString()
        val now = System.currentTimeMillis()
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO activation_token(token, kind, request_id, admin_email, organization_id, created_at, expires_at, email_sent)
                        VALUES (?, 'ORGANIZATION_ADMIN', ?, ?, ?, ?, ?, false)
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, token)
                        stmt.setString(2, requestId)
                        stmt.setString(3, "admin@example.com")
                        stmt.setString(4, organizationId)
                        stmt.setLong(5, now)
                        stmt.setLong(6, now + 72 * 3_600_000L)
                        stmt.executeUpdate()
                    }
            }
        return token
    }

    private fun insertApprovedProducerRequest(): String {
        val requestId = UUID.randomUUID().toString()
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO producer_request(request_id, producer_name, admin_first_name, admin_last_name, admin_email, status, submitted_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, requestId)
                        stmt.setString(2, "Producer Test")
                        stmt.setString(3, "Alice")
                        stmt.setString(4, "Martin")
                        stmt.setString(5, "producer@example.com")
                        stmt.setString(6, "APPROVED")
                        stmt.setLong(7, System.currentTimeMillis())
                        stmt.executeUpdate()
                    }
            }
        return requestId
    }

    private fun insertProducerAccount(): String {
        val producerAccountId = UUID.randomUUID().toString()
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO producer_account(producer_account_id, name, contact_email, active_status, created_instant, last_updated_instant)
                        VALUES (?, 'Producer Test', 'producer@example.com', true, ?, ?)
                        """.trimIndent(),
                    ).use { stmt ->
                        val now = System.currentTimeMillis()
                        stmt.setString(1, producerAccountId)
                        stmt.setLong(2, now)
                        stmt.setLong(3, now)
                        stmt.executeUpdate()
                    }
            }
        return producerAccountId
    }

    private fun insertProducerActivationToken(
        requestId: String,
        producerAccountId: String,
    ): String {
        val token = UUID.randomUUID().toString()
        val now = System.currentTimeMillis()
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO activation_token(
                            token, kind, producer_request_id, admin_email, producer_account_id, created_at, expires_at, email_sent
                        )
                        VALUES (?, 'PRODUCER', ?, ?, ?, ?, ?, false)
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, token)
                        stmt.setString(2, requestId)
                        stmt.setString(3, "producer@example.com")
                        stmt.setString(4, producerAccountId)
                        stmt.setLong(5, now)
                        stmt.setLong(6, now + 72 * 3_600_000L)
                        stmt.executeUpdate()
                    }
            }
        return token
    }

    private fun insertServer() {
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        "INSERT INTO server(server_id, name, url) VALUES (?, ?, ?) ON CONFLICT DO NOTHING",
                    ).use { stmt ->
                        stmt.setString(1, "test-server-id")
                        stmt.setString(2, "Test Server")
                        stmt.setString(3, "https://test.example.com")
                        stmt.executeUpdate()
                    }
            }
    }
}
