package core

import authentication.AuthenticatedInfo
import authentication.Role
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.EntityPayload
import persistence.changes.MutationErrorCode
import persistence.changes.MutationOutcome
import persistence.changes.MutationStatus
import persistence.changes.Upsert
import persistence.model.EntityType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * Unit tests for [EntityTypeService.requireAnyRole] — the centralised role-gate helper.
 *
 * Uses a minimal concrete stub so we can call the protected method.
 */
internal class EntityTypeServiceHelperTest {
    private val mutation =
        ClientMutation(
            clientOpId = "op-test",
            op = mockk<Upsert>(relaxed = true),
        )

    private val stub = StubEntityTypeService()

    @Test
    fun `GIVEN caller has one of the allowed roles WHEN requireAnyRole THEN returns null`() =
        runTest {
            val auth =
                AuthenticatedInfo(
                    memberId = "m-1",
                    firstName = "A",
                    lastName = "B",
                    email = "a@b.com",
                    roles = listOf(Role.ADMIN),
                )

            val outcome = stub.checkRole(auth, setOf(Role.OWNER, Role.ADMIN, Role.COORDINATOR), mutation)

            assertNull(outcome)
        }

    @Test
    fun `GIVEN caller has none of the allowed roles WHEN requireAnyRole THEN returns FORBIDDEN outcome`() =
        runTest {
            val auth =
                AuthenticatedInfo(
                    memberId = "m-2",
                    firstName = "V",
                    lastName = "O",
                    email = "v@o.com",
                    roles = listOf(Role.VOLUNTEER),
                )

            val outcome = stub.checkRole(auth, setOf(Role.OWNER, Role.ADMIN, Role.COORDINATOR), mutation)

            assertEquals(MutationStatus.REJECTED, outcome?.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome?.error?.code)
        }

    @Test
    fun `GIVEN caller has empty roles WHEN requireAnyRole THEN returns FORBIDDEN outcome`() =
        runTest {
            val auth =
                AuthenticatedInfo(
                    memberId = "m-3",
                    firstName = "N",
                    lastName = "R",
                    email = "n@r.com",
                    roles = emptyList(),
                )

            val outcome = stub.checkRole(auth, setOf(Role.OWNER), mutation)

            assertEquals(MutationStatus.REJECTED, outcome?.status)
            assertEquals(MutationErrorCode.FORBIDDEN, outcome?.error?.code)
        }
}

/** Minimal stub exposing [requireAnyRole] as a public method for testing. */
private class StubEntityTypeService : EntityTypeService<EntityPayload>(EntityType.ErrorReport) {
    fun checkRole(
        auth: AuthenticatedInfo,
        allowed: Set<Role>,
        mutation: ClientMutation,
    ): MutationOutcome? = requireAnyRole(auth, allowed, mutation)

    override suspend fun applyUpsert(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        payload: EntityPayload,
    ): MutationOutcome = applied(mutation, "stub-id")

    override suspend fun applyDelete(
        auth: AuthenticatedInfo,
        mutation: ClientMutation,
        op: Delete,
    ): MutationOutcome = applied(mutation, op.entityId)

    override suspend fun snapshot(auth: AuthenticatedInfo): List<EntityPayload> = emptyList()
}
