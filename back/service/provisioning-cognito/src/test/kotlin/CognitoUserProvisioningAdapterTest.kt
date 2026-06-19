package provisioning.cognito

import authentication.Role
import aws.sdk.kotlin.services.cognitoidentityprovider.CognitoIdentityProviderClient
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminCreateUserResponse
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminGetUserResponse
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminListGroupsForUserResponse
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AttributeType
import aws.sdk.kotlin.services.cognitoidentityprovider.model.GroupType
import aws.sdk.kotlin.services.cognitoidentityprovider.model.ListUsersResponse
import aws.sdk.kotlin.services.cognitoidentityprovider.model.UserNotFoundException
import aws.sdk.kotlin.services.cognitoidentityprovider.model.UserType
import aws.sdk.kotlin.services.cognitoidentityprovider.model.UsernameExistsException
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import properties.Properties
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class CognitoUserProvisioningAdapterTest {
    private fun user(vararg attributes: Pair<String, String>): UserType =
        UserType {
            this.attributes =
                attributes.map { (name, value) ->
                    AttributeType {
                        this.name = name
                        this.value = value
                    }
                }
        }

    @Test
    fun `GIVEN a non-empty user list WHEN extractSubFromUserList THEN returns the sub of the first user`() {
        val result = extractSubFromUserList(listOf(user("sub" to "sub-existing", "email" to "a@b.com")))

        assertEquals("sub-existing", result)
    }

    @Test
    fun `GIVEN an empty user list WHEN extractSubFromUserList THEN returns null`() {
        val result = extractSubFromUserList(emptyList())

        assertNull(result)
    }

    @Test
    fun `GIVEN a user without a sub attribute WHEN extractSubFromUserList THEN returns null`() {
        val result = extractSubFromUserList(listOf(user("email" to "a@b.com")))

        assertNull(result)
    }

    // -------------------------------------------------------------------------
    // Adapter behaviour (mocked Cognito client)
    // -------------------------------------------------------------------------

    private val client = mockk<CognitoIdentityProviderClient>(relaxed = true)

    private val adapter =
        CognitoUserProvisioningAdapter(
            properties =
                mockk<Properties> {
                    every { propertyOrFail("COGNITO_USER_POOL_ID") } returns "pool-1"
                },
            cognitoClient = client,
        )

    private fun createResponseWithSub(sub: String) =
        AdminCreateUserResponse {
            this.user = user("sub" to sub, "email" to "a@b.com")
        }

    @Test
    fun `GIVEN a new email WHEN createAdminUser THEN returns the created sub and adds the ADMIN group`() =
        runTest {
            coEvery { client.adminCreateUser(any()) } returns createResponseWithSub("sub-new")

            val sub = adapter.createAdminUser("admin@b.com", "pw")

            assertEquals("sub-new", sub)
            coVerify(exactly = 1) { client.adminSetUserPassword(any()) }
            coVerify(exactly = 1) { client.adminAddUserToGroup(any()) }
        }

    @Test
    fun `GIVEN an existing email WHEN createAdminUser THEN falls back to fetching the existing sub`() =
        runTest {
            coEvery { client.adminCreateUser(any()) } throws UsernameExistsException { message = "exists" }
            coEvery { client.adminGetUser(any()) } returns
                AdminGetUserResponse {
                    username = "admin@b.com"
                    userAttributes =
                        listOf(
                            AttributeType {
                                name = "sub"
                                value = "sub-existing"
                            },
                        )
                }

            val sub = adapter.createAdminUser("admin@b.com", "pw")

            assertEquals("sub-existing", sub)
        }

    @Test
    fun `GIVEN names WHEN createOwnerUser THEN returns sub even if the owners group is missing`() =
        runTest {
            coEvery { client.adminCreateUser(any()) } returns createResponseWithSub("sub-owner")
            // The owners group add is wrapped in runCatching — a failure must not propagate.
            coEvery { client.adminAddUserToGroup(any()) } throws RuntimeException("no such group")

            val sub = adapter.createOwnerUser("owner@b.com", "pw", "Jane", "Doe")

            assertEquals("sub-owner", sub)
        }

    @Test
    fun `GIVEN names WHEN createProducerUser THEN returns the created sub`() =
        runTest {
            coEvery { client.adminCreateUser(any()) } returns createResponseWithSub("sub-prod")

            val sub = adapter.createProducerUser("prod@b.com", "pw", "Jane", "Doe")

            assertEquals("sub-prod", sub)
            coVerify(exactly = 1) { client.adminAddUserToGroup(any()) }
        }

    @Test
    fun `GIVEN multiple roles WHEN createMemberUser THEN adds the user to one group per role`() =
        runTest {
            coEvery { client.adminCreateUser(any()) } returns createResponseWithSub("sub-member")

            val sub =
                adapter.createMemberUser(
                    email = "member@b.com",
                    password = "pw",
                    firstName = "Jane",
                    lastName = "Doe",
                    organizationId = "org-1",
                    roles = setOf(Role.COORDINATOR, Role.VOLUNTEER),
                )

            assertEquals("sub-member", sub)
            coVerify(exactly = 2) { client.adminAddUserToGroup(any()) }
        }

    @Test
    fun `GIVEN a known user WHEN banUser THEN disables it in Cognito`() =
        runTest {
            adapter.banUser("sub-1")
            coVerify(exactly = 1) { client.adminDisableUser(any()) }
        }

    @Test
    fun `GIVEN an unknown user WHEN banUser THEN swallows UserNotFoundException`() =
        runTest {
            coEvery { client.adminDisableUser(any()) } throws UserNotFoundException { }
            // Must not throw.
            adapter.banUser("sub-missing")
        }

    @Test
    fun `GIVEN a known user WHEN unbanUser THEN enables it in Cognito`() =
        runTest {
            adapter.unbanUser("sub-1")
            coVerify(exactly = 1) { client.adminEnableUser(any()) }
        }

    @Test
    fun `GIVEN a known user WHEN deleteUser THEN deletes it in Cognito`() =
        runTest {
            adapter.deleteUser("sub-1")
            coVerify(exactly = 1) { client.adminDeleteUser(any()) }
        }

    @Test
    fun `GIVEN an unknown user WHEN deleteUser THEN swallows UserNotFoundException`() =
        runTest {
            coEvery { client.adminDeleteUser(any()) } throws UserNotFoundException { }
            adapter.deleteUser("sub-missing")
        }

    @Test
    fun `GIVEN a matching user WHEN listAuthSubsByProducerAccount THEN returns the id`() =
        runTest {
            coEvery { client.listUsers(any()) } returns ListUsersResponse { users = listOf(user("sub" to "pa-1")) }

            assertEquals(listOf("pa-1"), adapter.listAuthSubsByProducerAccount("pa-1"))
        }

    @Test
    fun `GIVEN no matching user WHEN listAuthSubsByProducerAccount THEN returns empty`() =
        runTest {
            coEvery { client.listUsers(any()) } returns ListUsersResponse { users = emptyList() }

            assertEquals(emptyList(), adapter.listAuthSubsByProducerAccount("pa-1"))
        }

    @Test
    fun `GIVEN a producer-group user WHEN findProducerAccountIdByEmail THEN returns the sub`() =
        runTest {
            coEvery { client.listUsers(any()) } returns
                ListUsersResponse {
                    users =
                        listOf(
                            UserType {
                                username = "u1"
                                attributes =
                                    listOf(
                                        AttributeType {
                                            name = "sub"
                                            value = "pa-1"
                                        },
                                    )
                            },
                        )
                }
            coEvery { client.adminListGroupsForUser(any()) } returns
                AdminListGroupsForUserResponse {
                    groups = listOf(GroupType { groupName = Role.PRODUCER.name })
                }

            assertEquals("pa-1", adapter.findProducerAccountIdByEmail("prod@b.com"))
        }

    @Test
    fun `GIVEN a non-producer user WHEN findProducerAccountIdByEmail THEN returns null`() =
        runTest {
            coEvery { client.listUsers(any()) } returns
                ListUsersResponse {
                    users =
                        listOf(
                            UserType {
                                username = "u1"
                                attributes =
                                    listOf(
                                        AttributeType {
                                            name = "sub"
                                            value = "pa-1"
                                        },
                                    )
                            },
                        )
                }
            coEvery { client.adminListGroupsForUser(any()) } returns
                AdminListGroupsForUserResponse { groups = emptyList() }

            assertNull(adapter.findProducerAccountIdByEmail("prod@b.com"))
        }

    @Test
    fun `GIVEN no user for the email WHEN findProducerAccountIdByEmail THEN returns null`() =
        runTest {
            coEvery { client.listUsers(any()) } returns ListUsersResponse { users = emptyList() }

            assertNull(adapter.findProducerAccountIdByEmail("nobody@b.com"))
        }
}
