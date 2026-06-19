package core

import notificationpublisher.NotificationPublisherModule
import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module

@Module(includes = [NotificationPublisherModule::class])
@ComponentScan
class CoreModule
