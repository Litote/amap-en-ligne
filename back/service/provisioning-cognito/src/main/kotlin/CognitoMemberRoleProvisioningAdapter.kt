package provisioning.cognito

import authentication.Role
import aws.sdk.kotlin.runtime.auth.credentials.EnvironmentCredentialsProvider
import aws.sdk.kotlin.services.cognitoidentityprovider.CognitoIdentityProviderClient
import aws.sdk.kotlin.services.cognitoidentityprovider.adminAddUserToGroup
import aws.sdk.kotlin.services.cognitoidentityprovider.adminRemoveUserFromGroup
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminAddUserToGroupRequest
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminRemoveUserFromGroupRequest
import aws.smithy.kotlin.runtime.http.engine.crt.CrtHttpEngine
import core.MemberRoleProvisioningPort
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import properties.Properties

@Single(createdAtStart = true, binds = [MemberRoleProvisioningPort::class])
internal class CognitoMemberRoleProvisioningAdapter(
    private val properties: Properties,
) : MemberRoleProvisioningPort {
    private val userPoolId: String = properties.propertyOrFail("COGNITO_USER_POOL_ID")
    private val cognitoClient: CognitoIdentityProviderClient =
        CognitoIdentityProviderClient {
            region = properties.property("AWS_REGION", "eu-west-3")
            httpClient = CrtHttpEngine()
            credentialsProvider = EnvironmentCredentialsProvider()
        }

    override suspend fun updateRoles(
        memberId: String,
        oldRoles: Set<Role>,
        newRoles: Set<Role>,
    ) {
        val toAdd = newRoles - oldRoles.toSet()
        val toRemove = oldRoles - newRoles.toSet()
        for (role in toAdd) {
            cognitoClient.adminAddUserToGroup(
                AdminAddUserToGroupRequest {
                    this.userPoolId = this@CognitoMemberRoleProvisioningAdapter.userPoolId
                    username = memberId
                    groupName = role.name
                },
            )
        }
        for (role in toRemove) {
            cognitoClient.adminRemoveUserFromGroup(
                AdminRemoveUserFromGroupRequest {
                    this.userPoolId = this@CognitoMemberRoleProvisioningAdapter.userPoolId
                    username = memberId
                    groupName = role.name
                },
            )
        }
        logger.info { "Roles updated in Cognito for $memberId: $newRoles" }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}
