package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val producttype_ProductTypeModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> producttype.ProductTypeService(productTypeDAO=get())} bind(core.EntityTypeService::class)
}
public val producttype.ProductTypeModule.module : org.koin.core.module.Module get() = producttype_ProductTypeModule
