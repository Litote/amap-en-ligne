package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("provisioning.cognito.ProvisioningCognitoModule",id="m0srw2")
public class _KSP_ProvisioningCognitoProvisioningCognitoModule
@MetaDefinition("provisioning.cognito.cognitoIdentityProviderClient",moduleTagId="m0srw2:ProvisioningCognitoProvisioningCognitoModule", dependencies=["properties:properties.Properties"], binds=["aws.sdk.kotlin.services.cognitoidentityprovider.CognitoIdentityProviderClient"])
public class _KSP_ProvisioningCognitoCognitoIdentityProviderClient
@MetaDefinition("provisioning.cognito.cognitoIdentityProviderClient",moduleTagId="m0srw2:ProvisioningCognitoProvisioningCognitoModule", dependencies=["properties:properties.Properties"], binds=["aws.sdk.kotlin.services.cognitoidentityprovider.CognitoIdentityProviderClient"])
public val _KSP_AwsSdkKotlinServicesCognitoidentityproviderCognitoIdentityProviderClient : Unit get() = Unit
@MetaDefinition("provisioning.cognito.CognitoMemberRoleProvisioningAdapter",moduleTagId="m0srw2:ProvisioningCognitoProvisioningCognitoModule", dependencies=["properties:properties.Properties"], binds=["core.MemberRoleProvisioningPort"])
public class _KSP_ProvisioningCognitoCognitoMemberRoleProvisioningAdapter
@MetaDefinition("provisioning.cognito.CognitoMemberRoleProvisioningAdapter",moduleTagId="m0srw2:ProvisioningCognitoProvisioningCognitoModule", dependencies=["properties:properties.Properties"], binds=["core.MemberRoleProvisioningPort"])
public val _KSP_CoreMemberRoleProvisioningPort : Unit get() = Unit
@MetaDefinition("provisioning.cognito.CognitoOwnerRoleProvisioningAdapter",moduleTagId="m0srw2:ProvisioningCognitoProvisioningCognitoModule", dependencies=["properties:properties.Properties"], binds=["core.OwnerRoleProvisioningPort"])
public class _KSP_ProvisioningCognitoCognitoOwnerRoleProvisioningAdapter
@MetaDefinition("provisioning.cognito.CognitoOwnerRoleProvisioningAdapter",moduleTagId="m0srw2:ProvisioningCognitoProvisioningCognitoModule", dependencies=["properties:properties.Properties"], binds=["core.OwnerRoleProvisioningPort"])
public val _KSP_CoreOwnerRoleProvisioningPort : Unit get() = Unit
@MetaDefinition("provisioning.cognito.CognitoUserProvisioningAdapter",moduleTagId="m0srw2:ProvisioningCognitoProvisioningCognitoModule", dependencies=["properties:properties.Properties","cognitoClient:aws.sdk.kotlin.services.cognitoidentityprovider.CognitoIdentityProviderClient"], binds=["core.UserProvisioningPort"])
public class _KSP_ProvisioningCognitoCognitoUserProvisioningAdapter
@MetaDefinition("provisioning.cognito.CognitoUserProvisioningAdapter",moduleTagId="m0srw2:ProvisioningCognitoProvisioningCognitoModule", dependencies=["properties:properties.Properties","cognitoClient:aws.sdk.kotlin.services.cognitoidentityprovider.CognitoIdentityProviderClient"], binds=["core.UserProvisioningPort"])
public val _KSP_CoreUserProvisioningPort : Unit get() = Unit