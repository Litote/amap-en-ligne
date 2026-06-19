package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("member.MemberModule",id="rdnk9y", includes=["core.CoreModule"])
public class _KSP_MemberMemberModule
@MetaDefinition("member.MemberService",moduleTagId="rdnk9y:MemberMemberModule", dependencies=["memberSyncDAO:persistence.dao.MemberSyncDAO","roleService:core.RoleService","userProvisioningPort:core.UserProvisioningPort","accountLifecycleEmailPort:email.AccountLifecycleEmailPort","accountDeletionLogDAO:persistence.dao.AccountDeletionLogDAO","contractSyncDAO:persistence.dao.ContractSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO"], binds=["core.EntityTypeService"])
public class _KSP_MemberMemberService
@MetaDefinition("member.MemberService",moduleTagId="rdnk9y:MemberMemberModule", dependencies=["memberSyncDAO:persistence.dao.MemberSyncDAO","roleService:core.RoleService","userProvisioningPort:core.UserProvisioningPort","accountLifecycleEmailPort:email.AccountLifecycleEmailPort","accountDeletionLogDAO:persistence.dao.AccountDeletionLogDAO","contractSyncDAO:persistence.dao.ContractSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit