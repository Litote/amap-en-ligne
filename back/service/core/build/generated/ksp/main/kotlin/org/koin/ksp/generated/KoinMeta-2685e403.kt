package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("core.CoreModule",id="u6eudi", includes=["notificationpublisher.NotificationPublisherModule"])
public class _KSP_CoreCoreModule
@MetaDefinition("core.RoleService",moduleTagId="u6eudi:CoreCoreModule", dependencies=["ownerDAO:persistence.dao.OwnerSyncDAO","userProvisioningPort:core.UserProvisioningPort","memberInvitationSyncDAO:persistence.dao.MemberInvitationSyncDAO"])
public class _KSP_CoreRoleService
@MetaDefinition("core.AuthorizedScopeResolver",moduleTagId="u6eudi:CoreCoreModule", dependencies=["memberSyncDAO:persistence.dao.MemberSyncDAO","producerSyncDAO:persistence.dao.ProducerSyncDAO"])
public class _KSP_CoreAuthorizedScopeResolver