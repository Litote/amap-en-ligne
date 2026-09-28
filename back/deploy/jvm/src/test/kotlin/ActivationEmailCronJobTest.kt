package deploy.jvm

import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import org.koin.core.context.stopKoin
import org.testcontainers.containers.PostgreSQLContainer
import java.sql.Connection
import java.sql.DriverManager
import java.util.logging.Logger
import javax.sql.DataSource
import kotlin.test.assertFalse
import kotlin.test.assertTrue

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class ActivationEmailCronJobTest {
    private val container = PostgreSQLContainer<Nothing>("postgres:16")
    private lateinit var cronJob: ActivationEmailCronJob

    private val capturedEmails = mutableListOf<String>()
    private val fakeEmailSender =
        object : EmailSender {
            override suspend fun sendNotificationEmail(
                to: String,
                subject: String,
                body: String,
            ) {
                capturedEmails.add(to)
            }
        }

    @BeforeAll
    fun setUpAll() {
        // Defensively clear any Koin context leaked by a previous test class in this JVM
        // (no-op when nothing is started) so bootstrap()'s startKoin cannot fail with
        // KoinApplicationAlreadyStartedException.
        stopKoin()
        container.start()
        // Use bootstrap to run Flyway migrations via PostgresClient.
        System.setProperty("POSTGRES_URL", container.jdbcUrl)
        System.setProperty("POSTGRES_USER", container.username)
        System.setProperty("POSTGRES_PASSWORD", container.password)
        System.setProperty("GOTRUE_JWT_SECRET", "test-secret-test-secret-test-secret-test-secret")
        System.setProperty("GOTRUE_JWT_ISSUER", "http://localhost:9999/auth/v1")
        System.setProperty("GOTRUE_JWT_AUDIENCE", "authenticated")
        System.setProperty("INSTANCE_NAME", "Test Instance")
        System.setProperty("INSTANCE_API_URL", "http://localhost:8080/")
        System.setProperty("GOTRUE_SERVICE_ROLE_KEY", "test-service-role-key")
        val server = bootstrap(0)
        server.stop(0, 500)
        stopKoin()

        val dataSource = DriverManagerDataSource(container.jdbcUrl, container.username, container.password)
        val gateway = JvmEmailGateway(fakeEmailSender, properties.Properties.Instance)
        cronJob = ActivationEmailCronJob(dataSource, gateway)
    }

    @AfterAll
    fun tearDownAll() {
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

    @BeforeEach
    fun resetState() {
        capturedEmails.clear()
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn.createStatement().use { stmt ->
                    stmt.execute("TRUNCATE activation_token, organization_request, basket_exchange, organization CASCADE")
                }
            }
    }

    @Test
    fun `GIVEN pending token WHEN processPending THEN email sent and token marked email_sent=true`() =
        runTest {
            insertOrganizationRequest("req-1", "AMAP des Collines", "alice@collines.fr")
            insertPendingToken("tok-1", "req-1", "alice@collines.fr")

            cronJob.processPending()

            assertTrue(capturedEmails.contains("alice@collines.fr"))
            assertTrue(isEmailSent("tok-1"))
        }

    @Test
    fun `GIVEN no pending tokens WHEN processPending THEN no email sent`() =
        runTest {
            cronJob.processPending()

            assertTrue(capturedEmails.isEmpty())
        }

    @Test
    fun `GIVEN already sent token WHEN processPending THEN no email sent again`() =
        runTest {
            insertOrganizationRequest("req-2", "AMAP des Champs", "bob@champs.fr")
            insertPendingToken("tok-2", "req-2", "bob@champs.fr", emailSent = true)

            cronJob.processPending()

            assertFalse(capturedEmails.contains("bob@champs.fr"))
        }

    private fun insertOrganization(organizationId: String) {
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO organization(organization_id, name, contact_email, active_status)
                        VALUES (?, 'Test Org', 'test@example.com', true)
                        ON CONFLICT (organization_id) DO NOTHING
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, organizationId)
                        stmt.executeUpdate()
                    }
            }
    }

    private fun insertOrganizationRequest(
        requestId: String,
        orgName: String,
        email: String,
    ) {
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
                        stmt.setString(2, orgName)
                        stmt.setString(3, "AMAP")
                        stmt.setString(4, "Europe/Paris")
                        stmt.setString(5, "fr")
                        stmt.setString(6, "Admin")
                        stmt.setString(7, "User")
                        stmt.setString(8, email)
                        stmt.setString(9, "APPROVED")
                        stmt.setLong(10, System.currentTimeMillis())
                        stmt.executeUpdate()
                    }
            }
    }

    private fun insertPendingToken(
        token: String,
        requestId: String,
        adminEmail: String,
        organizationId: String = "org-$requestId",
        emailSent: Boolean = false,
    ) {
        insertOrganization(organizationId)
        val now = System.currentTimeMillis()
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        """
                        INSERT INTO activation_token(token, request_id, admin_email, organization_id, created_at, expires_at, email_sent)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                        """.trimIndent(),
                    ).use { stmt ->
                        stmt.setString(1, token)
                        stmt.setString(2, requestId)
                        stmt.setString(3, adminEmail)
                        stmt.setString(4, organizationId)
                        stmt.setLong(5, now)
                        stmt.setLong(6, now + 72 * 3_600_000L)
                        stmt.setBoolean(7, emailSent)
                        stmt.executeUpdate()
                    }
            }
    }

    private fun isEmailSent(token: String): Boolean =
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement("SELECT email_sent FROM activation_token WHERE token = ?")
                    .use { stmt ->
                        stmt.setString(1, token)
                        stmt.executeQuery().use { rs ->
                            rs.next() && rs.getBoolean("email_sent")
                        }
                    }
            }
}

/**
 * Minimal [DataSource] backed by [DriverManager] for use in tests.
 * Does not pool connections — each call to [getConnection] opens a new one.
 */
private class DriverManagerDataSource(
    private val url: String,
    private val username: String,
    private val password: String,
) : DataSource {
    override fun getConnection(): Connection = DriverManager.getConnection(url, username, password)

    override fun getConnection(
        username: String,
        password: String,
    ): Connection = DriverManager.getConnection(url, username, password)

    override fun getLogWriter(): java.io.PrintWriter? = null

    override fun setLogWriter(out: java.io.PrintWriter?) = Unit

    override fun setLoginTimeout(seconds: Int) = Unit

    override fun getLoginTimeout(): Int = 0

    override fun getParentLogger(): Logger = Logger.getLogger(DriverManagerDataSource::class.java.name)

    override fun <T : Any?> unwrap(iface: Class<T>): T = throw java.sql.SQLFeatureNotSupportedException()

    override fun isWrapperFor(iface: Class<*>): Boolean = false
}
