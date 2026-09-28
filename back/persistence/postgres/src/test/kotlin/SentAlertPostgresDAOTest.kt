@file:OptIn(ExperimentalTime::class)

package persistence.postgres

import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.SentAlertDAO
import persistence.dao.SentAlertDAOContractTest
import properties.Properties
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.ExperimentalTime

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class SentAlertPostgresDAOTest : SentAlertDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val sentAlertDAO: SentAlertDAO by lazy {
        SentAlertPostgresDAO(postgresClient)
    }

    @BeforeAll
    fun setUp() {
        container.start()
        val properties =
            object : Properties {
                override fun propertyOrNull(name: String): String? =
                    when (name) {
                        "POSTGRES_URL" -> container.jdbcUrl
                        "POSTGRES_USER" -> container.username
                        "POSTGRES_PASSWORD" -> container.password
                        else -> null
                    }
            }
        postgresClient = PostgresClient(properties)
    }

    @AfterAll
    fun tearDown() {
        container.stop()
    }

    @Test
    fun `GIVEN keys recorded before and after the purge instant WHEN purgeBefore THEN only the older ones are forgotten`() =
        runTest {
            val oldKey = newKey()
            val recentKey = newKey()
            sentAlertDAO.markIfAbsent(oldKey, sentAt)
            sentAlertDAO.markIfAbsent(recentKey, sentAt + 2.milliseconds)

            sentAlertDAO.purgeBefore(sentAt + 1.milliseconds)

            assertTrue(sentAlertDAO.markIfAbsent(oldKey, sentAt))
            assertFalse(sentAlertDAO.markIfAbsent(recentKey, sentAt))
        }
}
