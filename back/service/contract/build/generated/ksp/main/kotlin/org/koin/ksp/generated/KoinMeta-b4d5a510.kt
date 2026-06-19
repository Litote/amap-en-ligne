package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("contract.ContractModule",id="30kokm", includes=["core.CoreModule"])
public class _KSP_ContractContractModule
@MetaDefinition("contract.ContractService",moduleTagId="30kokm:ContractContractModule", dependencies=["contractSyncDAO:persistence.dao.ContractSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO"], binds=["core.EntityTypeService"])
public class _KSP_ContractContractService
@MetaDefinition("contract.ContractService",moduleTagId="30kokm:ContractContractModule", dependencies=["contractSyncDAO:persistence.dao.ContractSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit