package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val deliverytemplate_DeliveryTemplateModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> deliverytemplate.DeliveryTemplateService(deliveryTemplateSyncDAO=get())} bind(core.EntityTypeService::class)
}
public val deliverytemplate.DeliveryTemplateModule.module : org.koin.core.module.Module get() = deliverytemplate_DeliveryTemplateModule
