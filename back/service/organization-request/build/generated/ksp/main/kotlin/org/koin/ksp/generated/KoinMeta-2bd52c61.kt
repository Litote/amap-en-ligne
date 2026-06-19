package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("organizationrequest.OrganizationRequestModule",id="vxxh62", includes=["core.CoreModule"])
public class _KSP_OrganizationrequestOrganizationRequestModule
@MetaDefinition("organizationrequest.OrganizationRequestService",moduleTagId="vxxh62:OrganizationrequestOrganizationRequestModule", dependencies=["organizationRequestSyncDAO:persistence.dao.OrganizationRequestSyncDAO","organizationRequestDAO:persistence.dao.OrganizationRequestDAO","organizationDAO:persistence.dao.OrganizationDAO","activationTokenDAO:persistence.dao.ActivationTokenDAO","activationEmailPort:email.ActivationEmailPort","rejectionEmailPort:email.RejectionEmailPort"], binds=["core.EntityTypeService"])
public class _KSP_OrganizationrequestOrganizationRequestService
@MetaDefinition("organizationrequest.OrganizationRequestService",moduleTagId="vxxh62:OrganizationrequestOrganizationRequestModule", dependencies=["organizationRequestSyncDAO:persistence.dao.OrganizationRequestSyncDAO","organizationRequestDAO:persistence.dao.OrganizationRequestDAO","organizationDAO:persistence.dao.OrganizationDAO","activationTokenDAO:persistence.dao.ActivationTokenDAO","activationEmailPort:email.ActivationEmailPort","rejectionEmailPort:email.RejectionEmailPort"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit