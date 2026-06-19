package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val errorreport_ErrorReportModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> errorreport.ErrorReportService(errorReportSyncDAO=get())} bind(core.EntityTypeService::class)
}
public val errorreport.ErrorReportModule.module : org.koin.core.module.Module get() = errorreport_ErrorReportModule
