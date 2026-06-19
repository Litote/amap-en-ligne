package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("memberinvitation.MemberInvitationModule",id="c71zh6", includes=["core.CoreModule"])
public class _KSP_MemberinvitationMemberInvitationModule
@MetaDefinition("memberinvitation.MemberInvitationService",moduleTagId="c71zh6:MemberinvitationMemberInvitationModule", dependencies=["memberInvitationDAO:persistence.dao.MemberInvitationSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","activationTokenDAO:persistence.dao.ActivationTokenDAO","memberInvitationEmailPort:email.MemberInvitationEmailPort","organizationSyncDAO:persistence.dao.OrganizationSyncDAO"], binds=["core.EntityTypeService"])
public class _KSP_MemberinvitationMemberInvitationService
@MetaDefinition("memberinvitation.MemberInvitationService",moduleTagId="c71zh6:MemberinvitationMemberInvitationModule", dependencies=["memberInvitationDAO:persistence.dao.MemberInvitationSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","activationTokenDAO:persistence.dao.ActivationTokenDAO","memberInvitationEmailPort:email.MemberInvitationEmailPort","organizationSyncDAO:persistence.dao.OrganizationSyncDAO"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit