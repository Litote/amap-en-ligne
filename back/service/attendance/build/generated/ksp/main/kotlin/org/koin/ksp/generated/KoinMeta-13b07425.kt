package org.koin.ksp.generated

import org.koin.meta.annotations.*
@MetaModule("attendance.AttendanceModule",id="3x8kw6", includes=["core.CoreModule"])
public class _KSP_AttendanceAttendanceModule
@MetaDefinition("attendance.AttendanceEmailRequestService",moduleTagId="3x8kw6:AttendanceAttendanceModule", dependencies=["attendanceEmailRequestSyncDAO:persistence.dao.AttendanceEmailRequestSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO","basketExchangeSyncDAO:persistence.dao.BasketExchangeSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","attendanceEmailPort:email.AttendanceEmailPort"], binds=["core.EntityTypeService"])
public class _KSP_AttendanceAttendanceEmailRequestService
@MetaDefinition("attendance.AttendanceEmailRequestService",moduleTagId="3x8kw6:AttendanceAttendanceModule", dependencies=["attendanceEmailRequestSyncDAO:persistence.dao.AttendanceEmailRequestSyncDAO","organizationSyncDAO:persistence.dao.OrganizationSyncDAO","basketExchangeSyncDAO:persistence.dao.BasketExchangeSyncDAO","memberSyncDAO:persistence.dao.MemberSyncDAO","attendanceEmailPort:email.AttendanceEmailPort"], binds=["core.EntityTypeService"])
public val _KSP_CoreEntityTypeService : Unit get() = Unit