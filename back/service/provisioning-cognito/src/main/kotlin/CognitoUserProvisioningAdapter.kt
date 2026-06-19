package provisioning.cognito

import authentication.Role
import aws.sdk.kotlin.services.cognitoidentityprovider.CognitoIdentityProviderClient
import aws.sdk.kotlin.services.cognitoidentityprovider.adminAddUserToGroup
import aws.sdk.kotlin.services.cognitoidentityprovider.adminCreateUser
import aws.sdk.kotlin.services.cognitoidentityprovider.adminDeleteUser
import aws.sdk.kotlin.services.cognitoidentityprovider.adminDisableUser
import aws.sdk.kotlin.services.cognitoidentityprovider.adminEnableUser
import aws.sdk.kotlin.services.cognitoidentityprovider.adminGetUser
import aws.sdk.kotlin.services.cognitoidentityprovider.adminListGroupsForUser
import aws.sdk.kotlin.services.cognitoidentityprovider.adminSetUserPassword
import aws.sdk.kotlin.services.cognitoidentityprovider.listUsers
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminAddUserToGroupRequest
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminCreateUserRequest
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminDeleteUserRequest
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminDisableUserRequest
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminEnableUserRequest
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminGetUserRequest
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminListGroupsForUserRequest
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminSetUserPasswordRequest
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AttributeType
import aws.sdk.kotlin.services.cognitoidentityprovider.model.ListUsersRequest
import aws.sdk.kotlin.services.cognitoidentityprovider.model.MessageActionType
import aws.sdk.kotlin.services.cognitoidentityprovider.model.UserNotFoundException
import aws.sdk.kotlin.services.cognitoidentityprovider.model.UserType
import aws.sdk.kotlin.services.cognitoidentityprovider.model.UsernameExistsException
import core.UserProvisioningPort
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import properties.Properties

@Single(createdAtStart = true, binds = [UserProvisioningPort::class])
internal class CognitoUserProvisioningAdapter(
    properties: Properties,
    private val cognitoClient: CognitoIdentityProviderClient,
) : UserProvisioningPort {
    private val userPoolId: String = properties.propertyOrFail("COGNITO_USER_POOL_ID")

    override suspend fun createAdminUser(
        email: String,
        password: String,
    ): String {
        val sub =
            try {
                val createResponse =
                    cognitoClient.adminCreateUser(
                        AdminCreateUserRequest {
                            this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                            username = email
                            temporaryPassword = password
                            messageAction = MessageActionType.Suppress
                        },
                    )
                createResponse.user
                    ?.attributes
                    ?.firstOrNull { it.name == "sub" }
                    ?.value
                    ?: error("Cognito adminCreateUser response missing 'sub' attribute for $email")
            } catch (_: UsernameExistsException) {
                logger.warn { "createAdminUser($email) — user already exists; fetching existing sub" }
                fetchSubByEmail(email)
            }
        cognitoClient.adminSetUserPassword(
            AdminSetUserPasswordRequest {
                this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                username = email
                this.password = password
                permanent = true
            },
        )
        cognitoClient.adminAddUserToGroup(
            AdminAddUserToGroupRequest {
                this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                username = email
                groupName = "ADMIN"
            },
        )
        logger.info { "Admin user created in Cognito for $email" }
        return sub
    }

    override suspend fun createOwnerUser(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
    ): String {
        val sub =
            try {
                val createResponse =
                    cognitoClient.adminCreateUser(
                        AdminCreateUserRequest {
                            this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                            username = email
                            temporaryPassword = password
                            messageAction = MessageActionType.Suppress
                            userAttributes =
                                listOf(
                                    AttributeType {
                                        name = "given_name"
                                        value = firstName
                                    },
                                    AttributeType {
                                        name = "family_name"
                                        value = lastName
                                    },
                                )
                        },
                    )
                createResponse.user
                    ?.attributes
                    ?.firstOrNull { it.name == "sub" }
                    ?.value
                    ?: error("Cognito adminCreateUser response missing 'sub' attribute for $email")
            } catch (_: UsernameExistsException) {
                logger.warn { "createOwnerUser($email) — user already exists; fetching existing sub" }
                fetchSubByEmail(email)
            }
        cognitoClient.adminSetUserPassword(
            AdminSetUserPasswordRequest {
                this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                username = email
                this.password = password
                permanent = true
            },
        )
        runCatching {
            cognitoClient.adminAddUserToGroup(
                AdminAddUserToGroupRequest {
                    this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                    username = email
                    groupName = "owners"
                },
            )
        }.onFailure { e ->
            logger.warn { "Could not add owner user $email to 'owners' group — group may not exist: ${e.message}" }
        }
        logger.info { "Owner user created in Cognito for $email" }
        return sub
    }

    override suspend fun createProducerUser(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
    ): String {
        val sub =
            try {
                val createResponse =
                    cognitoClient.adminCreateUser(
                        AdminCreateUserRequest {
                            this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                            username = email
                            temporaryPassword = password
                            messageAction = MessageActionType.Suppress
                            userAttributes =
                                listOf(
                                    AttributeType {
                                        name = "given_name"
                                        value = firstName
                                    },
                                    AttributeType {
                                        name = "family_name"
                                        value = lastName
                                    },
                                )
                        },
                    )
                createResponse.user
                    ?.attributes
                    ?.firstOrNull { it.name == "sub" }
                    ?.value
                    ?: error("Cognito adminCreateUser response missing 'sub' attribute for $email")
            } catch (_: UsernameExistsException) {
                logger.warn { "createProducerUser($email) — user already exists; fetching existing sub" }
                fetchSubByEmail(email)
            }
        cognitoClient.adminSetUserPassword(
            AdminSetUserPasswordRequest {
                this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                username = email
                this.password = password
                permanent = true
            },
        )
        cognitoClient.adminAddUserToGroup(
            AdminAddUserToGroupRequest {
                this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                username = email
                groupName = Role.PRODUCER.name
            },
        )
        logger.info { "Producer user created in Cognito for $email" }
        return sub
    }

    override suspend fun createMemberUser(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        organizationId: String,
        roles: Set<Role>,
    ): String {
        val sub =
            try {
                val createResponse =
                    cognitoClient.adminCreateUser(
                        AdminCreateUserRequest {
                            this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                            username = email
                            temporaryPassword = password
                            messageAction = MessageActionType.Suppress
                            userAttributes =
                                listOf(
                                    AttributeType {
                                        name = "given_name"
                                        value = firstName
                                    },
                                    AttributeType {
                                        name = "family_name"
                                        value = lastName
                                    },
                                )
                        },
                    )
                createResponse.user
                    ?.attributes
                    ?.firstOrNull { it.name == "sub" }
                    ?.value
                    ?: error("Cognito adminCreateUser response missing 'sub' attribute for $email")
            } catch (_: UsernameExistsException) {
                logger.warn { "createMemberUser($email) — user already exists; fetching existing sub" }
                fetchSubByEmail(email)
            }
        cognitoClient.adminSetUserPassword(
            AdminSetUserPasswordRequest {
                this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                username = email
                this.password = password
                permanent = true
            },
        )
        roles.forEach { role ->
            cognitoClient.adminAddUserToGroup(
                AdminAddUserToGroupRequest {
                    this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                    username = email
                    groupName = role.name
                },
            )
        }
        logger.info { "Member user created in Cognito for $email" }
        return sub
    }

    override suspend fun banUser(sub: String) {
        try {
            cognitoClient.adminDisableUser(
                AdminDisableUserRequest {
                    this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                    username = sub
                },
            )
            logger.info { "User $sub disabled in Cognito" }
        } catch (_: UserNotFoundException) {
            logger.warn { "banUser($sub) — user not found in Cognito; ignoring" }
        }
    }

    override suspend fun unbanUser(sub: String) {
        try {
            cognitoClient.adminEnableUser(
                AdminEnableUserRequest {
                    this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                    username = sub
                },
            )
            logger.info { "User $sub enabled in Cognito" }
        } catch (_: UserNotFoundException) {
            logger.warn { "unbanUser($sub) — user not found in Cognito; ignoring" }
        }
    }

    override suspend fun deleteUser(sub: String) {
        try {
            cognitoClient.adminDeleteUser(
                AdminDeleteUserRequest {
                    this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                    username = sub
                },
            )
            logger.info { "User $sub deleted in Cognito" }
        } catch (_: UserNotFoundException) {
            logger.warn { "deleteUser($sub) — user not found in Cognito; treating as success" }
        }
    }

    override suspend fun listAuthSubsByProducerAccount(producerAccountId: String): List<String> {
        // sub == producerAccountId by invariant: direct lookup via the sub filter.
        val response =
            cognitoClient.listUsers(
                ListUsersRequest {
                    this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                    filter = "sub = \"$producerAccountId\""
                    limit = 1
                },
            )
        val found = response.users.orEmpty().isNotEmpty()
        val result = if (found) listOf(producerAccountId) else emptyList()
        logger.info { "Cognito listAuthSubsByProducerAccount($producerAccountId) → ${result.size} user(s)" }
        return result
    }

    override suspend fun findProducerAccountIdByEmail(email: String): String? {
        // sub == producerAccountId by invariant: find user by email, confirm PRODUCER group, return sub.
        val user =
            cognitoClient
                .listUsers(
                    ListUsersRequest {
                        this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                        filter = "email = \"$email\""
                        limit = 1
                    },
                ).users
                ?.firstOrNull()
                ?: return null
        val username = user.username ?: return null
        val groups =
            cognitoClient
                .adminListGroupsForUser(
                    AdminListGroupsForUserRequest {
                        this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                        this.username = username
                    },
                ).groups
                .orEmpty()
        val isProducer = groups.any { it.groupName == Role.PRODUCER.name }
        return if (isProducer) {
            user.attributes?.firstOrNull { it.name == "sub" }?.value
        } else {
            null
        }
    }

    private suspend fun fetchSubByEmail(email: String): String {
        val response =
            cognitoClient.adminGetUser(
                AdminGetUserRequest {
                    this.userPoolId = this@CognitoUserProvisioningAdapter.userPoolId
                    username = email
                },
            )
        return response.userAttributes
            ?.firstOrNull { it.name == "sub" }
            ?.value
            ?: error("Cognito user exists but sub not found for $email")
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}

/**
 * Returns the `sub` attribute of the first user in [users], or null when the list is empty
 * or the user has no `sub`. Used for the idempotent-create fallback when `AdminCreateUser`
 * throws `UsernameExistsException`.
 */
internal fun extractSubFromUserList(users: List<UserType>): String? =
    users
        .firstOrNull()
        ?.attributes
        ?.firstOrNull { it.name == "sub" }
        ?.value
