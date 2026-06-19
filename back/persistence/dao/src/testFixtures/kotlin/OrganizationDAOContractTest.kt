@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.generateId
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.TimeZone
import org.junit.jupiter.api.Test
import persistence.model.Organization
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

abstract class OrganizationDAOContractTest {
    protected abstract val dao: OrganizationDAO

    protected abstract fun insertOrganization(
        id: String,
        name: String,
        email: String,
        active: Boolean,
    )

    @Test
    fun `GIVEN active organization WHEN listActive THEN includes it`() =
        runTest {
            val id = "org-active-${UUID.randomUUID()}"
            insertOrganization(id, "AMAP des Collines", "collines-${UUID.randomUUID()}@example.com", true)

            val result = dao.listActive()

            assertTrue(result.any { it.organizationId.id == id })
        }

    @Test
    fun `GIVEN inactive organization WHEN listActive THEN excludes it`() =
        runTest {
            val id = "org-inactive-${UUID.randomUUID()}"
            insertOrganization(id, "AMAP inactive-${UUID.randomUUID()}", "inactive-${UUID.randomUUID()}@example.com", false)

            val result = dao.listActive()

            assertFalse(result.any { it.organizationId.id == id })
        }

    @Test
    fun `GIVEN active organization WHEN listActive THEN returns correct fields`() =
        runTest {
            val id = "org-fields-${UUID.randomUUID()}"
            val email = "jardins-${UUID.randomUUID()}@example.com"
            insertOrganization(id, "AMAP Les Jardins", email, true)

            val result = dao.listActive()

            val org = result.first { it.organizationId.id == id }
            assertEquals("AMAP Les Jardins", org.name)
            assertEquals(email, org.contactEmail)
            assertTrue(org.activeStatus)
        }

    @Test
    fun `GIVEN organization WHEN create THEN appears in listActive`() =
        runTest {
            val now = Clock.System.now()
            val org =
                Organization(
                    organizationId = generateId(),
                    name = "AMAP Nouvelle-${UUID.randomUUID()}",
                    contactEmail = "new-${UUID.randomUUID()}@example.com",
                    activeStatus = true,
                    timezone = TimeZone.of("Europe/Paris"),
                    defaultLanguage = "fr",
                    createdInstant = now,
                    lastUpdatedInstant = now,
                )

            dao.create(org)

            val result = dao.listActive()
            assertTrue(result.any { it.organizationId == org.organizationId })
            val found = result.first { it.organizationId == org.organizationId }
            assertEquals(org.name, found.name)
            assertEquals(org.contactEmail, found.contactEmail)
            assertTrue(found.activeStatus)
        }
}
