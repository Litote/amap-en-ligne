package provisioning.gotrue

import authentication.Role
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.test.runTest
import properties.Properties
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.ByteBuffer
import java.nio.charset.StandardCharsets
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Flow
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

internal class GoTrueUserProvisioningAdapterTest {
    private val httpClient = mockk<HttpClient>()

    private val adapter =
        GoTrueUserProvisioningAdapter(
            properties =
                mockk<Properties> {
                    every { propertyOrNull("GOTRUE_ADMIN_API_URL") } returns null
                    every { propertyOrFail("GOTRUE_JWT_ISSUER") } returns "https://gotrue.test"
                    every { propertyOrFail("GOTRUE_SERVICE_ROLE_KEY") } returns "service-key"
                },
            dispatcher = Dispatchers.Unconfined,
            httpClient = httpClient,
        )

    private fun response(
        status: Int,
        body: String = "",
    ): HttpResponse<String> =
        mockk<HttpResponse<String>> {
            every { statusCode() } returns status
            every { this@mockk.body() } returns body
        }

    private fun stubSend(response: HttpResponse<String>) {
        every {
            httpClient.send(any(), any<HttpResponse.BodyHandler<String>>())
        } returns response
    }

    /** Reads the request body back from the (non-blocking) BodyPublisher synchronously. */
    private fun bodyOf(request: HttpRequest): String {
        val publisher = request.bodyPublisher().orElseThrow()
        val builder = StringBuilder()
        val latch = CountDownLatch(1)
        publisher.subscribe(
            object : Flow.Subscriber<ByteBuffer> {
                override fun onSubscribe(subscription: Flow.Subscription) = subscription.request(Long.MAX_VALUE)

                override fun onNext(item: ByteBuffer) {
                    builder.append(StandardCharsets.UTF_8.decode(item))
                }

                override fun onError(throwable: Throwable) = latch.countDown()

                override fun onComplete() = latch.countDown()
            },
        )
        latch.await()
        return builder.toString()
    }

    @Test
    fun `GIVEN a 201 response WHEN createAdminUser THEN returns the parsed id`() =
        runTest {
            stubSend(response(201, """{"id":"sub-admin"}"""))

            assertEquals("sub-admin", adapter.createAdminUser("admin@b.com", "pw"))
            verify {
                httpClient.send(any(), any<HttpResponse.BodyHandler<String>>())
            }
        }

    @Test
    fun `GIVEN GOTRUE_MAILER_AUTOCONFIRM false WHEN createAdminUser THEN forces email confirmation`() =
        runTest {
            // Regression guard: GoTrue only honours the `email_confirm` boolean to force-confirm
            // an admin-created user. Without it, the password grant returns 400 "Email not
            // confirmed" when GOTRUE_MAILER_AUTOCONFIRM is false (the production default).
            val requestSlot = slot<HttpRequest>()
            every {
                httpClient.send(capture(requestSlot), any<HttpResponse.BodyHandler<String>>())
            } returns response(201, """{"id":"sub-admin"}""")

            adapter.createAdminUser("admin@b.com", "pw")

            assertContains(bodyOf(requestSlot.captured), "\"email_confirm\":true")
        }

    @Test
    fun `GIVEN a member creation WHEN createMemberUser THEN forces email confirmation`() =
        runTest {
            val requestSlot = slot<HttpRequest>()
            every {
                httpClient.send(capture(requestSlot), any<HttpResponse.BodyHandler<String>>())
            } returns response(201, """{"id":"sub-member"}""")

            adapter.createMemberUser(
                email = "member@b.com",
                password = "pw",
                firstName = "Jane",
                lastName = "Doe",
                organizationId = "org-1",
                roles = setOf(Role.VOLUNTEER),
            )

            assertContains(bodyOf(requestSlot.captured), "\"email_confirm\":true")
        }

    @Test
    fun `GIVEN a non-2xx response WHEN createAdminUser THEN throws`() =
        runTest {
            stubSend(response(500, "boom"))

            assertFailsWith<IllegalStateException> {
                adapter.createAdminUser("admin@b.com", "pw")
            }
        }

    @Test
    fun `GIVEN a 200 response WHEN createOwnerUser THEN returns the parsed id`() =
        runTest {
            stubSend(response(200, """{"id":"sub-owner"}"""))

            assertEquals(
                "sub-owner",
                adapter.createOwnerUser("owner@b.com", "pw", "Jane", "Doe"),
            )
        }

    @Test
    fun `GIVEN a 201 response WHEN createProducerUser THEN returns the parsed id`() =
        runTest {
            stubSend(response(201, """{"id":"sub-prod"}"""))

            assertEquals(
                "sub-prod",
                adapter.createProducerUser("prod@b.com", "pw", "Jane", "Doe"),
            )
        }

    @Test
    fun `GIVEN a response missing the id field WHEN createMemberUser THEN throws`() =
        runTest {
            stubSend(response(201, """{"email":"member@b.com"}"""))

            assertFailsWith<IllegalStateException> {
                adapter.createMemberUser(
                    email = "member@b.com",
                    password = "pw",
                    firstName = "Jane",
                    lastName = "Doe",
                    organizationId = "org-1",
                    roles = setOf(Role.VOLUNTEER),
                )
            }
        }

    @Test
    fun `GIVEN a 201 response WHEN createMemberUser THEN returns the parsed id`() =
        runTest {
            stubSend(response(201, """{"id":"sub-member"}"""))

            assertEquals(
                "sub-member",
                adapter.createMemberUser(
                    email = "member@b.com",
                    password = "pw",
                    firstName = "Jane",
                    lastName = "Doe",
                    organizationId = "org-1",
                    roles = setOf(Role.VOLUNTEER, Role.COORDINATOR),
                ),
            )
        }

    @Test
    fun `GIVEN a 200 response WHEN banUser THEN sends the ban update`() =
        runTest {
            stubSend(response(200))

            adapter.banUser("sub-1")

            verify {
                httpClient.send(any(), any<HttpResponse.BodyHandler<String>>())
            }
        }

    @Test
    fun `GIVEN a failing response WHEN banUser THEN throws`() =
        runTest {
            stubSend(response(403, "forbidden"))

            assertFailsWith<IllegalStateException> { adapter.banUser("sub-1") }
        }

    @Test
    fun `GIVEN a 200 response WHEN unbanUser THEN sends the update without throwing`() =
        runTest {
            stubSend(response(200))
            adapter.unbanUser("sub-1")
        }

    @Test
    fun `GIVEN a 404 response WHEN deleteUser THEN treats it as success`() =
        runTest {
            stubSend(response(404, "not found"))
            // 404 is benign — must not throw.
            adapter.deleteUser("sub-missing")
        }

    @Test
    fun `GIVEN a 500 response WHEN deleteUser THEN throws`() =
        runTest {
            stubSend(response(500, "boom"))

            assertFailsWith<IllegalStateException> { adapter.deleteUser("sub-1") }
        }

    @Test
    fun `GIVEN a 200 lookup WHEN listAuthSubsByProducerAccount THEN returns the id`() =
        runTest {
            stubSend(response(200, """{"id":"pa-1"}"""))

            assertEquals(listOf("pa-1"), adapter.listAuthSubsByProducerAccount("pa-1"))
        }

    @Test
    fun `GIVEN a 404 lookup WHEN listAuthSubsByProducerAccount THEN returns empty`() =
        runTest {
            stubSend(response(404))

            assertEquals(emptyList(), adapter.listAuthSubsByProducerAccount("pa-1"))
        }

    @Test
    fun `GIVEN a producer-role user on the page WHEN findProducerAccountIdByEmail THEN returns the id`() =
        runTest {
            stubSend(
                response(
                    200,
                    """[{"id":"pa-1","email":"prod@b.com","app_metadata":{"roles":["PRODUCER"]}}]""",
                ),
            )

            assertEquals("pa-1", adapter.findProducerAccountIdByEmail("prod@b.com"))
        }

    @Test
    fun `GIVEN a non-producer user WHEN findProducerAccountIdByEmail THEN returns null`() =
        runTest {
            stubSend(
                response(
                    200,
                    """[{"id":"m-1","email":"member@b.com","app_metadata":{"roles":["VOLUNTEER"]}}]""",
                ),
            )

            assertNull(adapter.findProducerAccountIdByEmail("member@b.com"))
        }

    @Test
    fun `GIVEN an empty page WHEN findProducerAccountIdByEmail THEN returns null`() =
        runTest {
            stubSend(response(200, """{"users":[]}"""))

            assertNull(adapter.findProducerAccountIdByEmail("nobody@b.com"))
        }
}
