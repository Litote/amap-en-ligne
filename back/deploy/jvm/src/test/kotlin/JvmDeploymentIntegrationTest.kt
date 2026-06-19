package deploy.jvm

import id.toId
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import persistence.changes.BootstrapScopeResult
import persistence.changes.ClientMutation
import persistence.changes.Delete
import persistence.changes.IncrementalScopeResult
import persistence.changes.MemberInvitationPayload
import persistence.changes.MemberJoinRequestPayload
import persistence.changes.OwnerPayload
import persistence.changes.ProducerAccountPayload
import persistence.changes.ProducerRequestPayload
import persistence.changes.ProductTypePayload
import persistence.changes.SyncRequest
import persistence.changes.SyncScope
import persistence.changes.Upsert
import persistence.model.AccountStatus
import persistence.model.BasketSize
import persistence.model.EntityType
import persistence.model.MemberInvitationStatus
import persistence.model.MemberJoinRequestStatus
import persistence.model.Owner
import persistence.model.ProducerRequestStatus
import persistence.model.ProductType
import serialization.json
import java.net.URI
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.sql.DriverManager
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@OptIn(ExperimentalTime::class)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
class JvmDeploymentIntegrationTest : JvmSyncTestSupport() {
    @Test
    fun `GIVEN empty cursors WHEN POST sync THEN bootstraps producer scope`() =
        runTest {
            val response = postSync(SyncRequest())

            val snapshot = response.results[SyncScope.ProducerAccount(tenantId).key]
            assertNotNull(snapshot)
            val bootstrap = snapshot as BootstrapScopeResult
            assertTrue(bootstrap.items.isEmpty())
            assertTrue(bootstrap.nextCursor.isNotEmpty())
        }

    @Test
    fun `GIVEN an UPSERT with tmp id WHEN POST sync THEN APPLIED with allocated server id`() =
        runTest {
            val tmp =
                ProductType(
                    productTypeId = "tmp_abc".toId(),
                    producerAccountId = tenantId.toId(),
                    supportedBasketSizes = listOf(BasketSize("small")),
                    name = "Vegetables",
                )

            val response =
                postSync(
                    SyncRequest(
                        mutations =
                            listOf(
                                ClientMutation(
                                    clientOpId = "op-1",
                                    op = Upsert(ProductTypePayload(tmp)),
                                ),
                            ),
                    ),
                )

            val outcome = response.mutations.single()
            assertEquals("op-1", outcome.clientOpId)
            assertEquals("APPLIED", outcome.status.name)
            assertNotNull(outcome.serverEntityId)
            assertNotEquals("tmp_abc", outcome.serverEntityId)
        }

    @Test
    fun `GIVEN OWNER caller WHEN promote then revoke round-trip THEN owner is applied then suspended`() =
        runTest {
            val ownerToken = mintGoTrueToken(subject = "owner-sub-1", roles = listOf("OWNER"), producerAccountId = null)
            val now = Clock.System.now()

            // 1. Promote: upsert with ownerId = target's sub (no tmp_* id after sub/id unification)
            // The server detects promotion when no Owner row exists for the given ownerId.
            val targetSub = "target-sub-1"
            val promotionOwner =
                Owner(
                    ownerId = targetSub.toId(),
                    firstName = "Target",
                    lastName = "User",
                    email = "target@example.com",
                    accountStatus = AccountStatus.ACTIVE,
                    registeredAt = now,
                    updatedAt = now,
                )
            val promoteResponse =
                postSyncAs(
                    token = ownerToken,
                    request =
                        SyncRequest(
                            mutations =
                                listOf(
                                    ClientMutation(
                                        clientOpId = "promote-1",
                                        op = Upsert(OwnerPayload(promotionOwner)),
                                    ),
                                ),
                        ),
                )

            val promoteOutcome = promoteResponse.mutations.single()
            assertEquals("promote-1", promoteOutcome.clientOpId)
            assertEquals("APPLIED", promoteOutcome.status.name)
            val realOwnerId = promoteOutcome.serverEntityId
            assertNotNull(realOwnerId)
            assertEquals(targetSub, realOwnerId) // ownerId == sub after unification

            // 2. Bootstrap sync as OWNER — Owner entity should appear
            val bootstrapResponse = postSyncAs(token = ownerToken, request = SyncRequest())
            val ownerSnapshot = bootstrapResponse.results[SyncScope.InstanceOwner.key]
            assertNotNull(ownerSnapshot)
            val ownerBootstrap = ownerSnapshot as BootstrapScopeResult
            assertTrue(ownerBootstrap.items.isNotEmpty())
            assertTrue(ownerBootstrap.items.filterIsInstance<OwnerPayload>().any { it.owner.ownerId.id == realOwnerId })

            // 3. Revoke: second owner needed to avoid LAST_OWNER rejection.
            // Insert a second owner via DB directly to allow revocation of the first.
            insertOwnerDirectly(
                ownerId = "owner-2",
                sub = "owner-sub-2",
                email = "owner2@example.com",
            )

            val revokeOwner =
                Owner(
                    ownerId = realOwnerId.toId(),
                    firstName = "Target",
                    lastName = "User",
                    email = "target@example.com",
                    accountStatus = AccountStatus.SUSPENDED,
                    registeredAt = now,
                    updatedAt = now,
                )
            val revokeResponse =
                postSyncAs(
                    token = ownerToken,
                    request =
                        SyncRequest(
                            mutations =
                                listOf(
                                    ClientMutation(
                                        clientOpId = "revoke-1",
                                        op = Upsert(OwnerPayload(revokeOwner)),
                                    ),
                                ),
                        ),
                )

            val revokeOutcome = revokeResponse.mutations.single()
            assertEquals("revoke-1", revokeOutcome.clientOpId)
            assertEquals("APPLIED", revokeOutcome.status.name)
        }

    @Test
    fun `GIVEN OWNER caller WHEN owner invitation mutation THEN returns allocated invitation_id`() =
        runTest {
            val ownerToken = mintGoTrueToken(subject = "owner-sub-invite", roles = listOf("OWNER"), producerAccountId = null)

            val response = postOwnerInvitationMutation(ownerToken, email = "invited-owner@example.com")
            val outcome = response.mutations.single()

            assertEquals("APPLIED", outcome.status.name)
            assertNotNull(outcome.serverEntityId)
        }

    @Test
    fun `GIVEN OWNER caller and duplicate email WHEN owner invitation mutation repeated THEN second is rejected`() =
        runTest {
            val ownerToken = mintGoTrueToken(subject = "owner-sub-dup", roles = listOf("OWNER"), producerAccountId = null)
            val email = "dup-owner@example.com"

            val first = postOwnerInvitationMutation(ownerToken, email = email)
            assertEquals(
                "APPLIED",
                first.mutations
                    .single()
                    .status.name,
            )

            val second = postOwnerInvitationMutation(ownerToken, email = email)
            assertEquals(
                "REJECTED",
                second.mutations
                    .single()
                    .status.name,
            )
            assertEquals(
                "UNIQUE_VIOLATION",
                second.mutations
                    .single()
                    .error
                    ?.code
                    ?.name,
            )
        }

    @Test
    fun `GIVEN non-OWNER caller WHEN owner invitation mutation THEN mutation is rejected`() =
        runTest {
            val adminToken = mintGoTrueToken(roles = listOf("ADMIN"), organizationId = "org-1", producerAccountId = null)

            val response = postOwnerInvitationMutation(adminToken, email = "test-403@example.com")

            assertEquals(
                "REJECTED",
                response.mutations
                    .single()
                    .status.name,
            )
            assertEquals(
                "FORBIDDEN",
                response.mutations
                    .single()
                    .error
                    ?.code
                    ?.name,
            )
        }

    @Test
    fun `GIVEN OWNER caller WHEN owner invitation resend mutation THEN applies`() =
        runTest {
            val ownerToken = mintGoTrueToken(subject = "owner-sub-resend", roles = listOf("OWNER"), producerAccountId = null)
            val email = "resend-owner@example.com"

            val createResponse = postOwnerInvitationMutation(ownerToken, email = email)
            val invitationId = createResponse.mutations.single().serverEntityId ?: error("missing serverEntityId")

            val resendResponse = resendOwnerInvitationMutation(ownerToken, invitationId)

            assertEquals(
                "APPLIED",
                resendResponse.mutations
                    .single()
                    .status.name,
            )
        }

    @Test
    fun `GIVEN OWNER caller WHEN POST sync with bootstrap THEN Owner entity type is present`() =
        runTest {
            val ownerToken = mintGoTrueToken(subject = "owner-sub-bootstrap", roles = listOf("OWNER"), producerAccountId = null)

            val response = postSyncAs(token = ownerToken, request = SyncRequest())

            val ownerSnapshot = response.results[SyncScope.InstanceOwner.key]
            assertNotNull(ownerSnapshot)
        }

    @Test
    fun `GIVEN an applied write WHEN POST sync with returned cursor THEN returns the change`() =
        runTest {
            val pt1 =
                ProductType(
                    productTypeId = "pt-1".toId(),
                    producerAccountId = tenantId.toId(),
                    supportedBasketSizes = listOf(BasketSize("small")),
                    name = "Vegetables",
                )
            val pt2 = pt1.copy(productTypeId = "pt-2".toId(), name = "Fruits")

            // 1. apply pt-1 + bootstrap → grab the snapshot cursor.
            val first =
                postSync(
                    SyncRequest(
                        mutations =
                            listOf(
                                ClientMutation(clientOpId = "op-1", op = Upsert(ProductTypePayload(pt1))),
                            ),
                    ),
                )
            val cursor = (first.results.getValue(SyncScope.ProducerAccount(tenantId).key) as BootstrapScopeResult).nextCursor

            // 2. apply pt-2 + incremental sync from that cursor → only pt-2's change.
            val second =
                postSync(
                    SyncRequest(
                        cursors = mapOf(SyncScope.ProducerAccount(tenantId).key to cursor),
                        mutations =
                            listOf(
                                ClientMutation(clientOpId = "op-2", op = Upsert(ProductTypePayload(pt2))),
                            ),
                    ),
                )

            val page = second.results.getValue(SyncScope.ProducerAccount(tenantId).key) as IncrementalScopeResult
            assertEquals(1, page.changes.size)
            assertEquals("pt-2", page.changes.single().entityId)
        }

    @Test
    fun `GIVEN producer request public submission WHEN owner approves via sync THEN producer account is created`() =
        runTest {
            val submitResponse =
                httpClient.send(
                    HttpRequest
                        .newBuilder()
                        .uri(URI("http://127.0.0.1:$port/v1/producer-requests"))
                        .header("Content-Type", "application/json")
                        .POST(
                            HttpRequest.BodyPublishers.ofString(
                                """
                                {
                                  "producer_name": "Ferme des Collines",
                                  "admin_first_name": "Jean",
                                  "admin_last_name": "Dupont",
                                  "admin_email": "producer@example.com"
                                }
                                """.trimIndent(),
                            ),
                        ).build(),
                    HttpResponse.BodyHandlers.ofString(),
                )
            assertEquals(201, submitResponse.statusCode())

            val ownerToken = mintGoTrueToken(subject = "owner-sub-producer", roles = listOf("OWNER"), producerAccountId = null)
            val bootstrap = postSyncAs(ownerToken, SyncRequest())
            val ownerResult = bootstrap.results.getValue(SyncScope.InstanceOwner.key) as BootstrapScopeResult
            val request =
                ownerResult.items
                    .filterIsInstance<ProducerRequestPayload>()
                    .single()
                    .producerRequest

            val approveResponse =
                postSyncAs(
                    ownerToken,
                    SyncRequest(
                        mutations =
                            listOf(
                                ClientMutation(
                                    clientOpId = "approve-producer",
                                    op =
                                        Upsert(
                                            ProducerRequestPayload(
                                                request.copy(status = ProducerRequestStatus.APPROVED),
                                            ),
                                        ),
                                ),
                            ),
                    ),
                )
            assertEquals(
                "APPLIED",
                approveResponse.mutations
                    .single()
                    .status.name,
            )

            val afterApproval = postSyncAs(ownerToken, SyncRequest())
            val snapshot = afterApproval.results.getValue(SyncScope.InstanceOwner.key) as BootstrapScopeResult
            assertTrue(snapshot.items.filterIsInstance<ProducerAccountPayload>().isNotEmpty())
            assertTrue(
                snapshot.items.filterIsInstance<ProducerRequestPayload>().any {
                    it.producerRequest.status ==
                        ProducerRequestStatus.APPROVED
                },
            )
            assertEquals("PRODUCER", readLatestActivationKind("producer@example.com"))
        }

    @Test
    fun `GIVEN a rejected member join request WHEN the same email resubmits THEN HTTP 201 is returned`() =
        runTest {
            val orgId = "resubmit-test-org"
            val adminSub = "admin-resubmit-sub"
            val email = "resubmit@example.com"

            // Set up: create organization and an ADMIN member so the admin token resolves a scope.
            insertOrganizationDirectly(orgId)
            insertMemberDirectly(memberId = adminSub, organizationId = orgId, roles = listOf("ADMIN"))

            val adminToken =
                mintGoTrueToken(subject = adminSub, email = "admin-resubmit@example.com", roles = listOf("ADMIN"), producerAccountId = null)

            // Step 1: submit the first join request.
            val firstSubmit =
                httpClient.send(
                    HttpRequest
                        .newBuilder()
                        .uri(URI("http://127.0.0.1:$port/v1/public/member-join-requests"))
                        .header("Content-Type", "application/json")
                        .POST(
                            HttpRequest.BodyPublishers.ofString(
                                """{"organization_id":"$orgId","email":"$email","first_name":"Alice","last_name":"Resubmit"}""",
                            ),
                        ).build(),
                    HttpResponse.BodyHandlers.ofString(),
                )
            assertEquals(201, firstSubmit.statusCode(), "First submission should succeed with 201")

            // Step 2: admin rejects the request via sync.
            val orgBootstrap = postSyncAs(adminToken, SyncRequest())
            val orgResult = orgBootstrap.results.getValue(SyncScope.Organization(orgId).key) as BootstrapScopeResult
            val joinRequest =
                orgResult.items
                    .filterIsInstance<MemberJoinRequestPayload>()
                    .single { it.memberJoinRequest.email == email }
                    .memberJoinRequest

            val rejectResponse =
                postSyncAs(
                    adminToken,
                    SyncRequest(
                        mutations =
                            listOf(
                                ClientMutation(
                                    clientOpId = "reject-resubmit",
                                    op =
                                        Upsert(
                                            MemberJoinRequestPayload(
                                                joinRequest.copy(
                                                    status = MemberJoinRequestStatus.REJECTED,
                                                    reviewComment = "Not eligible at this time.",
                                                ),
                                            ),
                                        ),
                                ),
                            ),
                    ),
                )
            assertEquals(
                "APPLIED",
                rejectResponse.mutations
                    .single()
                    .status.name,
                "Rejection mutation should be APPLIED",
            )

            // Step 3: same email resubmits — must not be blocked by the now-REJECTED previous request.
            val secondSubmit =
                httpClient.send(
                    HttpRequest
                        .newBuilder()
                        .uri(URI("http://127.0.0.1:$port/v1/public/member-join-requests"))
                        .header("Content-Type", "application/json")
                        .POST(
                            HttpRequest.BodyPublishers.ofString(
                                """{"organization_id":"$orgId","email":"$email","first_name":"Alice","last_name":"Resubmit"}""",
                            ),
                        ).build(),
                    HttpResponse.BodyHandlers.ofString(),
                )
            assertEquals(
                201,
                secondSubmit.statusCode(),
                "Re-submission after rejection should return 201, not ${secondSubmit.statusCode()}. Body: ${secondSubmit.body()}",
            )
        }

    @Test
    fun `GIVEN an approved-then-cancelled invitation WHEN second join request is approved THEN APPLIED`() =
        runTest {
            val orgId = "resubmit-approve-org"
            val adminSub = "admin-resubmit-approve-sub"
            val email = "resubmit-approve@example.com"

            insertOrganizationDirectly(orgId)
            insertMemberDirectly(memberId = adminSub, organizationId = orgId, roles = listOf("ADMIN"))

            val adminToken =
                mintGoTrueToken(
                    subject = adminSub,
                    email = "admin-resubmit-approve@example.com",
                    roles = listOf("ADMIN"),
                    producerAccountId = null,
                )

            // Step 1: submit the first join request.
            val firstSubmit =
                httpClient.send(
                    HttpRequest
                        .newBuilder()
                        .uri(URI("http://127.0.0.1:$port/v1/public/member-join-requests"))
                        .header("Content-Type", "application/json")
                        .POST(
                            HttpRequest.BodyPublishers.ofString(
                                """{"organization_id":"$orgId","email":"$email","first_name":"Alice","last_name":"Approve"}""",
                            ),
                        ).build(),
                    HttpResponse.BodyHandlers.ofString(),
                )
            assertEquals(201, firstSubmit.statusCode(), "First submission should succeed with 201")

            // Step 2: admin approves the first request via sync.
            val orgBootstrap1 = postSyncAs(adminToken, SyncRequest())
            val orgResult1 = orgBootstrap1.results.getValue(SyncScope.Organization(orgId).key) as BootstrapScopeResult
            val firstJoinRequest =
                orgResult1.items
                    .filterIsInstance<MemberJoinRequestPayload>()
                    .single { it.memberJoinRequest.email == email }
                    .memberJoinRequest

            val approveResponse =
                postSyncAs(
                    adminToken,
                    SyncRequest(
                        mutations =
                            listOf(
                                ClientMutation(
                                    clientOpId = "approve-first",
                                    op = Upsert(MemberJoinRequestPayload(firstJoinRequest.copy(status = MemberJoinRequestStatus.APPROVED))),
                                ),
                            ),
                    ),
                )
            assertEquals(
                "APPLIED",
                approveResponse.mutations
                    .single()
                    .status.name,
                "First approval should be APPLIED",
            )

            // Step 3: find the invitation created by the approval and cancel it.
            val orgBootstrap2 = postSyncAs(adminToken, SyncRequest())
            val orgResult2 = orgBootstrap2.results.getValue(SyncScope.Organization(orgId).key) as BootstrapScopeResult
            val invitation =
                orgResult2.items
                    .filterIsInstance<MemberInvitationPayload>()
                    .single {
                        it.memberInvitation.email == email && it.memberInvitation.status == MemberInvitationStatus.PENDING_ACTIVATION
                    }.memberInvitation

            val cancelResponse =
                postSyncAs(
                    adminToken,
                    SyncRequest(
                        mutations =
                            listOf(
                                ClientMutation(
                                    clientOpId = "cancel-invitation",
                                    op = Delete(EntityType.MemberInvitation, invitation.invitationId),
                                ),
                            ),
                    ),
                )
            assertEquals(
                "APPLIED",
                cancelResponse.mutations
                    .single()
                    .status.name,
                "Cancellation should be APPLIED",
            )

            // Step 4: submit a second join request for the same email.
            val secondSubmit =
                httpClient.send(
                    HttpRequest
                        .newBuilder()
                        .uri(URI("http://127.0.0.1:$port/v1/public/member-join-requests"))
                        .header("Content-Type", "application/json")
                        .POST(
                            HttpRequest.BodyPublishers.ofString(
                                """{"organization_id":"$orgId","email":"$email","first_name":"Alice","last_name":"Approve"}""",
                            ),
                        ).build(),
                    HttpResponse.BodyHandlers.ofString(),
                )
            assertEquals(
                201,
                secondSubmit.statusCode(),
                "Second submission after cancellation should return 201. Body: ${secondSubmit.body()}",
            )

            // Step 5: admin approves the second request — must not be blocked by the cancelled invitation.
            val orgBootstrap3 = postSyncAs(adminToken, SyncRequest())
            val orgResult3 = orgBootstrap3.results.getValue(SyncScope.Organization(orgId).key) as BootstrapScopeResult
            val secondJoinRequest =
                orgResult3.items
                    .filterIsInstance<MemberJoinRequestPayload>()
                    .filter { it.memberJoinRequest.email == email && it.memberJoinRequest.status == MemberJoinRequestStatus.PENDING }
                    .single()
                    .memberJoinRequest

            val approveSecondResponse =
                postSyncAs(
                    adminToken,
                    SyncRequest(
                        mutations =
                            listOf(
                                ClientMutation(
                                    clientOpId = "approve-second",
                                    op =
                                        Upsert(
                                            MemberJoinRequestPayload(secondJoinRequest.copy(status = MemberJoinRequestStatus.APPROVED)),
                                        ),
                                ),
                            ),
                    ),
                )
            assertEquals(
                "APPLIED",
                approveSecondResponse.mutations
                    .single()
                    .status.name,
                "Second approval after cancelled invitation should be APPLIED, not CONFLICT",
            )
        }

    private fun readLatestActivationKind(email: String): String? =
        DriverManager
            .getConnection(container.jdbcUrl, container.username, container.password)
            .use { conn ->
                conn
                    .prepareStatement(
                        "SELECT kind FROM activation_token WHERE admin_email = ? ORDER BY created_at DESC LIMIT 1",
                    ).use { stmt ->
                        stmt.setString(1, email)
                        stmt.executeQuery().use { rs ->
                            if (rs.next()) rs.getString("kind") else null
                        }
                    }
            }
}
