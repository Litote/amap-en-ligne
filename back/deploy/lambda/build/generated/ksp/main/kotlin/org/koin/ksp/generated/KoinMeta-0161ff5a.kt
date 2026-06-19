package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("deploy.lambda.LambdaEmailModule",id="argwov", includes=["properties.PropertiesModule","instanceconfig.CognitoInstanceConfigModule","persistence.dynamo.DynamoModule"])
public class _KSP_DeployLambdaLambdaEmailModule
@MetaDefinition("deploy.lambda.SnsPushNotificationChannelSender",moduleTagId="argwov:DeployLambdaLambdaEmailModule", dependencies=["properties:properties.Properties"], binds=["notificationpublisher.NotificationChannelSender"])
public class _KSP_DeployLambdaSnsPushNotificationChannelSender
@MetaDefinition("deploy.lambda.SnsActivationEmailAdapter",moduleTagId="argwov:DeployLambdaLambdaEmailModule", dependencies=["gateway:deploy.lambda.LambdaEmailGateway"], binds=["email.ActivationEmailPort"])
public class _KSP_DeployLambdaSnsActivationEmailAdapter
@MetaDefinition("deploy.lambda.SnsActivationEmailAdapter",moduleTagId="argwov:DeployLambdaLambdaEmailModule", dependencies=["gateway:deploy.lambda.LambdaEmailGateway"], binds=["email.ActivationEmailPort"])
public val _KSP_EmailActivationEmailPort : Unit get() = Unit
@MetaDefinition("deploy.lambda.LambdaEmailGateway",moduleTagId="argwov:DeployLambdaLambdaEmailModule", dependencies=["properties:properties.Properties","instanceConfig:instanceconfig.InstanceConfig"], binds=["email.delivery.EmailGateway"])
public class _KSP_DeployLambdaLambdaEmailGateway
@MetaDefinition("deploy.lambda.LambdaEmailGateway",moduleTagId="argwov:DeployLambdaLambdaEmailModule", dependencies=["properties:properties.Properties","instanceConfig:instanceconfig.InstanceConfig"], binds=["email.delivery.EmailGateway"])
public val _KSP_EmailDeliveryEmailGateway : Unit get() = Unit