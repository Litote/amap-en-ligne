package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.DeliveryTemplate
import persistence.model.Organization

interface DeliveryTemplateSyncDAO {
    suspend fun getByOrganizationId(organizationId: Id<Organization>): List<DeliveryTemplate>

    /** Atomically writes the delivery template and its change record. */
    suspend fun put(
        deliveryTemplate: DeliveryTemplate,
        change: Change,
    )

    /** Atomically deletes the delivery template and records the corresponding tombstone. */
    suspend fun delete(
        deliveryTemplateId: Id<DeliveryTemplate>,
        organizationId: Id<Organization>,
        change: Change,
    )
}
