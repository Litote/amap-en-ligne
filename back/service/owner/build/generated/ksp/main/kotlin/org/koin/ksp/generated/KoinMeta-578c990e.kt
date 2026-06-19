package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("owner.OwnerModule",id="uzjs4k", includes=["core.CoreModule"])
public class _KSP_OwnerOwnerModule
@MetaDefinition("owner.OwnerInvitationService",moduleTagId="uzjs4k:OwnerOwnerModule", dependencies=["ownerInvitationDAO:persistence.dao.OwnerInvitationSyncDAO","ownerDAO:persistence.dao.OwnerSyncDAO","activationTokenDAO:persistence.dao.ActivationTokenDAO","ownerActivationEmailPort:email.OwnerActivationEmailPort"], binds=["core.EntityTypeService"])
public class _KSP_OwnerOwnerInvitationService
@MetaDefinition("owner.OwnerInvitationService",moduleTagId="uzjs4k:OwnerOwnerModule", dependencies=["ownerInvitationDAO:persistence.dao.OwnerInvitationSyncDAO","ownerDAO:persistence.dao.OwnerSyncDAO","activationTokenDAO:persistence.dao.ActivationTokenDAO","ownerActivationEmailPort:email.OwnerActivationEmailPort"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit
@MetaDefinition("owner.OwnerService",moduleTagId="uzjs4k:OwnerOwnerModule", dependencies=["ownerDAO:persistence.dao.OwnerSyncDAO","roleService:core.RoleService","userProvisioningPort:core.UserProvisioningPort","accountLifecycleEmailPort:email.AccountLifecycleEmailPort","accountDeletionLogDAO:persistence.dao.AccountDeletionLogDAO"])
public class _KSP_OwnerOwnerService
@MetaDefinition("owner.OwnerTypeService",moduleTagId="uzjs4k:OwnerOwnerModule", dependencies=["ownerDAO:persistence.dao.OwnerSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","roleService:core.RoleService","ownerService:owner.OwnerService"], binds=["core.EntityTypeService"])
public class _KSP_OwnerOwnerTypeService