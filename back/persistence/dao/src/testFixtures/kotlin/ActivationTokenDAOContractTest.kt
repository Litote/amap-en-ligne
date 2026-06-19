@file:OptIn(ExperimentalTime::class)

package persistence.dao

import id.generateId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import persistence.model.ActivationKind
import persistence.model.ActivationToken
import persistence.model.MemberInvitation
import persistence.model.Organization
import persistence.model.OrganizationRequest
import persistence.model.OwnerInvitation
import persistence.model.ProducerAccount
import persistence.model.ProducerRequest
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.time.Clock
import kotlin.time.Duration.Companion.hours
import kotlin.time.ExperimentalTime

abstract class ActivationTokenDAOContractTest {
    protected abstract val dao: ActivationTokenDAO

    protected abstract fun insertOrganizationRequest(requestId: String)

    protected abstract fun insertProducerRequest(requestId: String)

    protected abstract fun insertOrganization(organizationId: String)

    protected abstract fun insertProducerAccount(producerAccountId: String)

    private fun buildOrganizationAdminToken(
        requestId: String = generateId<OrganizationRequest>().id,
        organizationId: String = generateId<Organization>().id,
    ): ActivationToken {
        val now = Clock.System.now()
        return ActivationToken(
            token = "tok-${java.util.UUID.randomUUID()}",
            kind = ActivationKind.ORGANIZATION_ADMIN,
            requestId = requestId.let { id.Id(it) },
            producerRequestId = null,
            adminEmail = "admin-${java.util.UUID.randomUUID()}@example.com",
            organizationId = organizationId.let { id.Id(it) },
            producerAccountId = null,
            ownerInvitationId = null,
            createdAt = now,
            expiresAt = now + 72.hours,
        )
    }

    private fun buildOwnerToken(invitationId: String = generateId<OwnerInvitation>().id): ActivationToken {
        val now = Clock.System.now()
        return ActivationToken(
            token = "tok-${java.util.UUID.randomUUID()}",
            kind = ActivationKind.OWNER,
            requestId = null,
            producerRequestId = null,
            adminEmail = "owner-${java.util.UUID.randomUUID()}@example.com",
            organizationId = null,
            producerAccountId = null,
            ownerInvitationId = invitationId.let { id.Id(it) },
            createdAt = now,
            expiresAt = now + 168.hours,
        )
    }

    private fun buildProducerToken(
        requestId: String = generateId<ProducerRequest>().id,
        producerAccountId: String = generateId<ProducerAccount>().id,
    ): ActivationToken {
        val now = Clock.System.now()
        return ActivationToken(
            token = "tok-${java.util.UUID.randomUUID()}",
            kind = ActivationKind.PRODUCER,
            requestId = null,
            producerRequestId = requestId.let { id.Id(it) },
            adminEmail = "producer-${java.util.UUID.randomUUID()}@example.com",
            organizationId = null,
            producerAccountId = producerAccountId.let { id.Id(it) },
            ownerInvitationId = null,
            createdAt = now,
            expiresAt = now + 72.hours,
        )
    }

    private fun buildMemberToken(invitationId: String = generateId<MemberInvitation>().id): ActivationToken {
        val now = Clock.System.now()
        return ActivationToken(
            token = "tok-${java.util.UUID.randomUUID()}",
            kind = ActivationKind.MEMBER,
            requestId = null,
            producerRequestId = null,
            adminEmail = "member-${java.util.UUID.randomUUID()}@example.com",
            organizationId = null,
            producerAccountId = null,
            ownerInvitationId = null,
            memberInvitationId = invitationId.let { id.Id(it) },
            createdAt = now,
            expiresAt = now + 168.hours,
        )
    }

    @Test
    fun `GIVEN ORGANIZATION_ADMIN token WHEN create then findByToken THEN returns it`() =
        runTest {
            val requestId = generateId<OrganizationRequest>().id
            val organizationId = generateId<Organization>().id
            insertOrganization(organizationId)
            insertOrganizationRequest(requestId)
            val token = buildOrganizationAdminToken(requestId, organizationId)

            dao.create(token)

            val found = dao.findByToken(token.token)
            assertNotNull(found)
            assertEquals(token.token, found.token)
            assertEquals(ActivationKind.ORGANIZATION_ADMIN, found.kind)
            assertEquals(token.requestId, found.requestId)
            assertEquals(token.adminEmail, found.adminEmail)
            assertEquals(token.organizationId, found.organizationId)
            assertNull(found.ownerInvitationId)
        }

    @Test
    fun `GIVEN OWNER token WHEN create then findByToken THEN returns it`() =
        runTest {
            val invitationId = generateId<OwnerInvitation>().id
            insertOwnerInvitation(invitationId)
            val token = buildOwnerToken(invitationId)

            dao.create(token)

            val found = dao.findByToken(token.token)
            assertNotNull(found)
            assertEquals(token.token, found.token)
            assertEquals(ActivationKind.OWNER, found.kind)
            assertNull(found.requestId)
            assertNull(found.organizationId)
            assertEquals(token.ownerInvitationId, found.ownerInvitationId)
            assertNull(found.memberInvitationId)
            assertEquals(token.adminEmail, found.adminEmail)
        }

    @Test
    fun `GIVEN PRODUCER token WHEN create then findByToken THEN returns it`() =
        runTest {
            val requestId = generateId<ProducerRequest>().id
            val producerAccountId = generateId<ProducerAccount>().id
            insertProducerRequest(requestId)
            insertProducerAccount(producerAccountId)
            val token = buildProducerToken(requestId, producerAccountId)

            dao.create(token)

            val found = dao.findByToken(token.token)
            assertNotNull(found)
            assertEquals(token.token, found.token)
            assertEquals(ActivationKind.PRODUCER, found.kind)
            assertEquals(token.producerRequestId, found.producerRequestId)
            assertEquals(token.producerAccountId, found.producerAccountId)
            assertNull(found.requestId)
            assertNull(found.organizationId)
        }

    @Test
    fun `GIVEN MEMBER token WHEN create then findByToken THEN returns it`() =
        runTest {
            val invitationId = generateId<MemberInvitation>().id
            insertMemberInvitation(invitationId)
            val token = buildMemberToken(invitationId)

            dao.create(token)

            val found = dao.findByToken(token.token)
            assertNotNull(found)
            assertEquals(token.token, found.token)
            assertEquals(ActivationKind.MEMBER, found.kind)
            assertEquals(token.memberInvitationId, found.memberInvitationId)
            assertNull(found.ownerInvitationId)
        }

    @Test
    fun `GIVEN no token WHEN findByToken THEN returns null`() =
        runTest {
            val found = dao.findByToken("nonexistent-token")

            assertNull(found)
        }

    @Test
    fun `GIVEN token WHEN findByToken THEN expiresAt is preserved`() =
        runTest {
            val requestId = generateId<OrganizationRequest>().id
            val organizationId = generateId<Organization>().id
            insertOrganization(organizationId)
            insertOrganizationRequest(requestId)
            val token = buildOrganizationAdminToken(requestId, organizationId)

            dao.create(token)

            val found = dao.findByToken(token.token)
            assertNotNull(found)
            assertEquals(token.expiresAt.toEpochMilliseconds(), found.expiresAt.toEpochMilliseconds())
        }

    @Test
    fun `GIVEN token WHEN findByToken THEN activatedAt is null initially`() =
        runTest {
            val requestId = generateId<OrganizationRequest>().id
            val organizationId = generateId<Organization>().id
            insertOrganization(organizationId)
            insertOrganizationRequest(requestId)
            val token = buildOrganizationAdminToken(requestId, organizationId)

            dao.create(token)

            val found = dao.findByToken(token.token)
            assertNotNull(found)
            assertNull(found.activatedAt)
        }

    @Test
    fun `GIVEN existing token WHEN markActivated THEN activatedAt is set`() =
        runTest {
            val requestId = generateId<OrganizationRequest>().id
            val organizationId = generateId<Organization>().id
            insertOrganization(organizationId)
            insertOrganizationRequest(requestId)
            val token = buildOrganizationAdminToken(requestId, organizationId)
            dao.create(token)

            val activatedAt = Clock.System.now()
            dao.markActivated(token.token, activatedAt)

            val found = dao.findByToken(token.token)
            assertNotNull(found)
            assertNotNull(found.activatedAt)
            assertEquals(activatedAt.toEpochMilliseconds(), found.activatedAt!!.toEpochMilliseconds())
        }

    @Test
    fun `GIVEN owner invitation tokens WHEN invalidateByOwnerInvitationId THEN invalidatedAt is set`() =
        runTest {
            val invitationId = generateId<OwnerInvitation>().id
            insertOwnerInvitation(invitationId)
            val token = buildOwnerToken(invitationId)
            dao.create(token)

            val invalidatedAt = Clock.System.now()
            dao.invalidateByOwnerInvitationId(token.ownerInvitationId!!, invalidatedAt)

            val found = dao.findByToken(token.token)
            assertNotNull(found)
            assertEquals(invalidatedAt.toEpochMilliseconds(), found.invalidatedAt?.toEpochMilliseconds())
        }

    @Test
    fun `GIVEN member invitation tokens WHEN invalidateByMemberInvitationId THEN invalidatedAt is set`() =
        runTest {
            val invitationId = generateId<MemberInvitation>().id
            insertMemberInvitation(invitationId)
            val token = buildMemberToken(invitationId)
            dao.create(token)

            val invalidatedAt = Clock.System.now()
            dao.invalidateByMemberInvitationId(token.memberInvitationId!!, invalidatedAt)

            val found = dao.findByToken(token.token)
            assertNotNull(found)
            assertEquals(invalidatedAt.toEpochMilliseconds(), found.invalidatedAt?.toEpochMilliseconds())
        }

    /** Override to pre-insert an owner_invitation row if backend has FK constraints. */
    protected open fun insertOwnerInvitation(invitationId: String) {
        // No-op by default (Dynamo has no FK constraints)
    }

    protected open fun insertMemberInvitation(invitationId: String) {
        // No-op by default (Dynamo has no FK constraints)
    }
}
