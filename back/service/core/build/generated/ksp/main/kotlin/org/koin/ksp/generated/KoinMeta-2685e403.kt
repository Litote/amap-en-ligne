package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("core.CoreModule",id="u6eudi", includes=["notificationpublisher.NotificationPublisherModule"])
public class _KSP_CoreCoreModule
@MetaDefinition("core.AuthorizedScopeResolver",moduleTagId="u6eudi:CoreCoreModule", dependencies=["memberSyncDAO:persistence.dao.MemberSyncDAO","producerSyncDAO:persistence.dao.ProducerSyncDAO"])
public class _KSP_CoreAuthorizedScopeResolver
@MetaDefinition("core.RoleService",moduleTagId="u6eudi:CoreCoreModule", dependencies=["ownerDAO:persistence.dao.OwnerSyncDAO","userProvisioningPort:core.UserProvisioningPort"])
public class _KSP_CoreRoleService