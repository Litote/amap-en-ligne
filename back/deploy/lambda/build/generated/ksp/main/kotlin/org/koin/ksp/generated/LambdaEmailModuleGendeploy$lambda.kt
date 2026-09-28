package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val deploy_lambda_LambdaEmailModule : Module get() = module {
	includes(instanceconfig.CognitoInstanceConfigModule().module,
		persistence.dynamo.DynamoModule().module,
		properties.PropertiesModule().module)
	single() { _ -> deploy.lambda.LambdaEmailGateway(properties=get(),instanceConfig=get())} bind(email.delivery.EmailGateway::class)
	single(createdAtStart=true) { _ -> deploy.lambda.SnsActivationEmailAdapter(gateway=get())} bind(email.ActivationEmailPort::class)
	single(createdAtStart=true) { _ -> deploy.lambda.SnsPushNotificationChannelSender(properties=get())} bind(notificationpublisher.NotificationChannelSender::class)
}
public val deploy.lambda.LambdaEmailModule.module : org.koin.core.module.Module get() = deploy_lambda_LambdaEmailModule
