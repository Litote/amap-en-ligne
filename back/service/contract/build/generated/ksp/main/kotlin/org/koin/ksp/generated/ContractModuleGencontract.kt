package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val contract_ContractModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> contract.ContractService(contractSyncDAO=get(),organizationSyncDAO=get())} bind(core.EntityTypeService::class)
}
public val contract.ContractModule.module : org.koin.core.module.Module get() = contract_ContractModule
