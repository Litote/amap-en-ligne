package persistence.postgres

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.PostgreSQLContainer
import persistence.dao.ChangeDAO
import persistence.dao.ProductTypeSyncDAO
import persistence.dao.ProductTypeSyncDAOContractTest
import properties.Properties

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ProductTypeSyncPostgresDAOTest : ProductTypeSyncDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val productTypeDao: ProductTypeSyncDAO by lazy { ProductTypeSyncPostgresDAO(postgresClient) }
    override val changeDao: ChangeDAO by lazy { ChangePostgresDAO(postgresClient) }

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
}
