package org.koin.ksp.generated

import org.koin.core.module.Module
import org.koin.dsl.*


public val attendance_AttendanceModule : Module get() = module {
	includes(core.CoreModule().module)
	single(createdAtStart=true) { _ -> attendance.AttendanceEmailRequestService(attendanceEmailRequestSyncDAO=get(),organizationSyncDAO=get(),basketExchangeSyncDAO=get(),memberSyncDAO=get(),attendanceEmailPort=get())} bind(core.EntityTypeService::class)
}
public val attendance.AttendanceModule.module : org.koin.core.module.Module get() = attendance_AttendanceModule
