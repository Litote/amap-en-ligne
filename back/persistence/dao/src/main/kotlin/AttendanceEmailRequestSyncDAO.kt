package persistence.dao

import id.Id
import persistence.changes.Change
import persistence.model.AttendanceEmailRequest
import persistence.model.Organization

interface AttendanceEmailRequestSyncDAO {
    /** Atomically writes the attendance email request and its change record. */
    suspend fun put(
        request: AttendanceEmailRequest,
        change: Change,
    )

    /** Returns all attendance email requests for the given organization. */
    suspend fun getByOrganizationId(organizationId: Id<Organization>): List<AttendanceEmailRequest>

    /** Returns a single attendance email request by id, or null if absent. */
    suspend fun findById(id: Id<AttendanceEmailRequest>): AttendanceEmailRequest?
}
