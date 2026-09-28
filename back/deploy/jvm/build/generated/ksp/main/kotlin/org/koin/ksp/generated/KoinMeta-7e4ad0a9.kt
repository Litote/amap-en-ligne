package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("deploy.jvm.JvmEmailModule",id="fxm6gr", includes=["properties.PropertiesModule","persistence.postgres.PostgresModule"])
public class _KSP_DeployJvmJvmEmailModule
@MetaDefinition("deploy.jvm.PostgresActivationEmailAdapter",moduleTagId="fxm6gr:DeployJvmJvmEmailModule", binds=["email.ActivationEmailPort"])
public class _KSP_DeployJvmPostgresActivationEmailAdapter
@MetaDefinition("deploy.jvm.PostgresActivationEmailAdapter",moduleTagId="fxm6gr:DeployJvmJvmEmailModule", binds=["email.ActivationEmailPort"])
public val _KSP_EmailActivationEmailPort : Unit get() = Unit
@MetaDefinition("deploy.jvm.FcmPushNotificationChannelSender",moduleTagId="fxm6gr:DeployJvmJvmEmailModule", dependencies=["properties:properties.Properties"], binds=["notificationpublisher.NotificationChannelSender"])
public class _KSP_DeployJvmFcmPushNotificationChannelSender
@MetaDefinition("deploy.jvm.ActivationEmailCronJob",moduleTagId="fxm6gr:DeployJvmJvmEmailModule", dependencies=["dataSource:javax.sql.DataSource","gateway:deploy.jvm.JvmEmailGateway"])
public class _KSP_DeployJvmActivationEmailCronJob
@MetaDefinition("deploy.jvm.JvmEmailGateway",moduleTagId="fxm6gr:DeployJvmJvmEmailModule", dependencies=["emailSender:deploy.jvm.EmailSender","properties:properties.Properties"], binds=["email.delivery.EmailGateway"])
public class _KSP_DeployJvmJvmEmailGateway
@MetaDefinition("deploy.jvm.JvmEmailGateway",moduleTagId="fxm6gr:DeployJvmJvmEmailModule", dependencies=["emailSender:deploy.jvm.EmailSender","properties:properties.Properties"], binds=["email.delivery.EmailGateway"])
public val _KSP_EmailDeliveryEmailGateway : Unit get() = Unit
@MetaDefinition("deploy.jvm.SmtpEmailSender",moduleTagId="fxm6gr:DeployJvmJvmEmailModule", dependencies=["properties:properties.Properties"], binds=["deploy.jvm.EmailSender"])
public class _KSP_DeployJvmSmtpEmailSender
@MetaDefinition("deploy.jvm.SmtpEmailSender",moduleTagId="fxm6gr:DeployJvmJvmEmailModule", dependencies=["properties:properties.Properties"], binds=["deploy.jvm.EmailSender"])
public val _KSP_DeployJvmEmailSender : Unit get() = Unit