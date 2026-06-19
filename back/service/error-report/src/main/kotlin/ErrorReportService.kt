@file:OptIn(kotlin.time.ExperimentalTime::class)

package errorreport

import authentication.AuthenticatedInfo
import core.EntityTypeService
import id.generateId
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.changes.ChangeOp
import persistence.changes.ClientMutation
import persistence.changes.Cursor
import persistence.changes.Delete
import persistence.changes.ErrorReportPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.SyncScope
import persistence.dao.ErrorReportSyncDAO
import persistence.model.EntityType
import persistence.model.ErrorReport

/**
 * EntityTypeService for [ErrorReport].
 *
 * Any authenticated caller may create a report (upsert with a tmp_* id).
 * Reports are immutable: upsert with an existing real id is FORBIDDEN.
 * Delete is always FORBIDDEN.
 * Snapshot returns all reports on the instance-owner scope; empty for all other scopes.
 */
@Single(createdAtStart = true, binds = [EntityTypeService::class])
class ErrorReportService(
    private val errorReportSyncDAO: ErrorReportSyncDAO,
) : EntityTypeService<ErrorReportPayload>(EntityType.ErrorReport) {
    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: ErrorReportPayload,
    ): MutationOutcome {
        if (!payload.errorReport.errorReportId.id
                .startsWith(ClientMutation.TMP_ID_PREFIX)
        ) {
            return rejected(mutation, MutationErrorCode.FORBIDDEN, "error reports are immutable")
        }

        val realId = generateId<ErrorReport>()

        val report =
            ErrorReport(
                errorReportId = realId,
                errorMessage = payload.errorReport.errorMessage,
                reportedAt = payload.errorReport.reportedAt,
            )

        val change =
            Change(
                cursor = Cursor.next(),
                entityType = EntityType.ErrorReport,
                entityId = realId.id,
                scopeKey = SyncScope.InstanceOwner.key,
                op = ChangeOp.UPSERT,
                payload = ErrorReportPayload(errorReport = report),
                producedAt = System.currentTimeMillis(),
            )

        errorReportSyncDAO.put(report, change)

        return applied(mutation, realId.id)
    }

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome = rejected(mutation, MutationErrorCode.FORBIDDEN, "error reports cannot be deleted")

    override suspend fun snapshot(auth: AuthenticatedInfo): List<ErrorReportPayload> = emptyList()

    override suspend fun snapshot(
        auth: AuthenticatedInfo,
        scope: SyncScope,
    ): List<ErrorReportPayload> =
        when (scope) {
            SyncScope.InstanceOwner -> {
                errorReportSyncDAO.listAll().map { ErrorReportPayload(errorReport = it) }
            }

            else -> {
                emptyList()
            }
        }
}
