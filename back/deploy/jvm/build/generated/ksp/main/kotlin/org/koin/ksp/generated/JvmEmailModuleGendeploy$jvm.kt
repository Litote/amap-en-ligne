package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val deploy_jvm_JvmEmailModule : Module get() = module {
	includes(persistence.postgres.PostgresModule().module,
		properties.PropertiesModule().module)
	single() { _ -> deploy.jvm.ActivationEmailCronJob(dataSource=get(),gateway=get())} 
	single(createdAtStart=true) { _ -> deploy.jvm.FcmPushNotificationChannelSender(properties=get())} bind(notificationpublisher.NotificationChannelSender::class)
	single() { _ -> deploy.jvm.JvmEmailGateway(emailSender=get(),properties=get())} bind(email.delivery.EmailGateway::class)
	single(createdAtStart=true) { _ -> deploy.jvm.PostgresActivationEmailAdapter()} bind(email.ActivationEmailPort::class)
	single(createdAtStart=true) { _ -> deploy.jvm.SmtpEmailSender(properties=get())} bind(deploy.jvm.EmailSender::class)
}
public val deploy.jvm.JvmEmailModule.module : org.koin.core.module.Module get() = deploy_jvm_JvmEmailModule
