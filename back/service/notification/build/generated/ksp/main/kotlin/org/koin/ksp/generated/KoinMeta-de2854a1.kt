package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("notification.NotificationModule",id="n55ps6", includes=["core.CoreModule"])
public class _KSP_NotificationNotificationModule
@MetaDefinition("notification.NotificationService",moduleTagId="n55ps6:NotificationNotificationModule", dependencies=["notificationSyncDAO:persistence.dao.NotificationSyncDAO","authorizedScopeResolver:core.AuthorizedScopeResolver"], binds=["core.EntityTypeService"])
public class _KSP_NotificationNotificationService
@MetaDefinition("notification.NotificationService",moduleTagId="n55ps6:NotificationNotificationModule", dependencies=["notificationSyncDAO:persistence.dao.NotificationSyncDAO","authorizedScopeResolver:core.AuthorizedScopeResolver"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit
@MetaDefinition("notification.DeviceTokenService",moduleTagId="n55ps6:NotificationNotificationModule", dependencies=["deviceTokenSyncDAO:persistence.dao.DeviceTokenSyncDAO","authorizedScopeResolver:core.AuthorizedScopeResolver"], binds=["core.EntityTypeService"])
public class _KSP_NotificationDeviceTokenService