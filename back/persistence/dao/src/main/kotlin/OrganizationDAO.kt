package persistence.dao

import persistence.model.Organization
import persistence.model.PublicOrganizationSummary

interface OrganizationDAO {
    suspend fun listActive(): List<PublicOrganizationSummary>

    suspend fun create(organization: Organization)
}
