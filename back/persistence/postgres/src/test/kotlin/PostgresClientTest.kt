package persistence.postgres

import org.junit.jupiter.api.Test
import properties.Properties
import kotlin.test.assertContains
import kotlin.test.assertFailsWith

class PostgresClientTest {
    @Test
    fun `GIVEN no POSTGRES_PASSWORD WHEN creating PostgresClient THEN fails with explicit error`() {
        val properties =
            object : Properties {
                override fun propertyOrNull(name: String): String? = null
            }

        val exception = assertFailsWith<IllegalStateException> { PostgresClient(properties) }

        assertContains(exception.message.orEmpty(), "POSTGRES_PASSWORD")
    }
}
