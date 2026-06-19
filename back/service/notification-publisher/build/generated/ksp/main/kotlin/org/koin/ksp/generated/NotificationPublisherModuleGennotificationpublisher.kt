package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val notificationpublisher_NotificationPublisherModule : Module get() = module {
	single(createdAtStart=true) { _ -> notificationpublisher.NotificationDispatcher(senders=getAll())} 
	single(createdAtStart=true) { _ -> notificationpublisher.NotificationPublisher(notificationSyncDAO=get(),deviceTokenSyncDAO=get(),dispatcher=get())} 
}
public val notificationpublisher.NotificationPublisherModule.module : org.koin.core.module.Module get() = notificationpublisher_NotificationPublisherModule
