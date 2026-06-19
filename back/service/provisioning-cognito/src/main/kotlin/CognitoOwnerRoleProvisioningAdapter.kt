package provisioning.cognito

import authentication.Role
import aws.sdk.kotlin.runtime.auth.credentials.EnvironmentCredentialsProvider
import aws.sdk.kotlin.services.cognitoidentityprovider.CognitoIdentityProviderClient
import aws.sdk.kotlin.services.cognitoidentityprovider.adminAddUserToGroup
import aws.sdk.kotlin.services.cognitoidentityprovider.model.AdminAddUserToGroupRequest
import aws.smithy.kotlin.runtime.http.engine.crt.CrtHttpEngine
import core.OwnerRoleProvisioningPort
import io.github.oshai.kotlinlogging.KotlinLogging
import org.koin.core.annotation.Single
import properties.Properties

@Single(createdAtStart = true, binds = [OwnerRoleProvisioningPort::class])
internal class CognitoOwnerRoleProvisioningAdapter(
    private val properties: Properties,
) : OwnerRoleProvisioningPort {
    private val userPoolId: String = properties.propertyOrFail("COGNITO_USER_POOL_ID")
    private val cognitoClient: CognitoIdentityProviderClient =
        CognitoIdentityProviderClient {
            region = properties.property("AWS_REGION", "eu-west-3")
            httpClient = CrtHttpEngine()
            credentialsProvider = EnvironmentCredentialsProvider()
        }

    override suspend fun updateOwnerRole(ownerId: String) {
        cognitoClient.adminAddUserToGroup(
            AdminAddUserToGroupRequest {
                this.userPoolId = this@CognitoOwnerRoleProvisioningAdapter.userPoolId
                username = ownerId
                groupName = Role.OWNER.name
            },
        )
        logger.info { "Owner role set in Cognito for $ownerId" }
    }

    private companion object {
        private val logger = KotlinLogging.logger {}
    }
}
