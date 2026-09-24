part of '../database.dart';

mixin _FeedQueries on _$AppDatabase {
  Stream<List<AppNotification>> watchNotifications(String recipientScope) =>
      (select(
        notifications,
      )..where((t) => t.recipientScope.equals(recipientScope))).watch().map(
        (rows) => rows
            .map(
              (r) => AppNotification.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<AppNotification?> getNotification(
    String recipientScope,
    String notificationId,
  ) async {
    final row =
        await (select(notifications)..where(
              (t) =>
                  t.recipientScope.equals(recipientScope) &
                  t.notificationId.equals(notificationId),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return AppNotification.fromJson(
      jsonDecode(row.dataJson) as Map<String, dynamic>,
    );
  }

  Future<void> upsertNotification(AppNotification notification) =>
      into(notifications).insertOnConflictUpdate(
        NotificationsCompanion.insert(
          recipientScope: notification.recipientScope,
          notificationId: notification.notificationId,
          dataJson: jsonEncode(notification.toJson()),
        ),
      );

  Future<void> deleteNotification(
    String recipientScope,
    String notificationId,
  ) =>
      (delete(notifications)..where(
            (t) =>
                t.recipientScope.equals(recipientScope) &
                t.notificationId.equals(notificationId),
          ))
          .go();

  Future<void> clearNotificationsForScope(String recipientScope) => (delete(
    notifications,
  )..where((t) => t.recipientScope.equals(recipientScope))).go();

  Stream<List<DeviceToken>> watchDeviceTokens(String recipientScope) =>
      (select(
        deviceTokens,
      )..where((t) => t.recipientScope.equals(recipientScope))).watch().map(
        (rows) => rows
            .map(
              (r) => DeviceToken.fromJson(
                jsonDecode(r.dataJson) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  Future<DeviceToken?> getDeviceTokenByToken(
    String recipientScope,
    String token,
  ) async {
    final rows = await (select(
      deviceTokens,
    )..where((t) => t.recipientScope.equals(recipientScope))).get();
    for (final row in rows) {
      final deviceToken = DeviceToken.fromJson(
        jsonDecode(row.dataJson) as Map<String, dynamic>,
      );
      if (deviceToken.token == token) return deviceToken;
    }
    return null;
  }

  Future<void> upsertDeviceToken(DeviceToken deviceToken) =>
      into(deviceTokens).insertOnConflictUpdate(
        DeviceTokensCompanion.insert(
          recipientScope: deviceToken.recipientScope,
          deviceTokenId: deviceToken.deviceTokenId,
          dataJson: jsonEncode(deviceToken.toJson()),
        ),
      );

  Future<void> deleteDeviceToken(String recipientScope, String deviceTokenId) =>
      (delete(deviceTokens)..where(
            (t) =>
                t.recipientScope.equals(recipientScope) &
                t.deviceTokenId.equals(deviceTokenId),
          ))
          .go();

  Future<void> clearDeviceTokensForScope(String recipientScope) => (delete(
    deviceTokens,
  )..where((t) => t.recipientScope.equals(recipientScope))).go();

  Future<void> remapDeviceTokenId({
    required String recipientScope,
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(deviceTokens)..where(
              (t) =>
                  t.recipientScope.equals(recipientScope) &
                  t.deviceTokenId.equals(oldId),
            ))
            .getSingleOrNull();
    if (existing == null) return;
    final remapped = DeviceToken.fromJson(
      jsonDecode(existing.dataJson) as Map<String, dynamic>,
    ).copyWith(deviceTokenId: newId);
    await deleteDeviceToken(recipientScope, oldId);
    await upsertDeviceToken(remapped);
  });

  /// Reactive stream of all [AttendanceEmailRequest] rows for the given organization.
  Stream<List<AttendanceEmailRequest>> watchAttendanceEmailRequestsByOrg(
    String organizationId,
  ) =>
      (select(attendanceEmailRequests)
            ..where((t) => t.organizationId.equals(organizationId)))
          .watch()
          .map((rows) => rows.map(_attendanceEmailRequestRowToDomain).toList());

  /// Inserts a new [AttendanceEmailRequest] row. Used for optimistic creation.
  Future<void> insertAttendanceEmailRequest(AttendanceEmailRequest request) =>
      into(
        attendanceEmailRequests,
      ).insert(_attendanceEmailRequestDomainToRow(request));

  /// Inserts or replaces a [AttendanceEmailRequest] row.
  Future<void> upsertAttendanceEmailRequest(AttendanceEmailRequest request) =>
      into(
        attendanceEmailRequests,
      ).insertOnConflictUpdate(_attendanceEmailRequestDomainToRow(request));

  /// Deletes the [AttendanceEmailRequest] row identified by [attendanceEmailRequestId].
  Future<void> deleteAttendanceEmailRequest(String attendanceEmailRequestId) =>
      (delete(attendanceEmailRequests)..where(
            (t) => t.attendanceEmailRequestId.equals(attendanceEmailRequestId),
          ))
          .go();

  /// Returns the [AttendanceEmailRequest] row identified by [attendanceEmailRequestId],
  /// or `null` if not cached locally.
  Future<AttendanceEmailRequest?> getAttendanceEmailRequestById(
    String attendanceEmailRequestId,
  ) async {
    final row =
        await (select(attendanceEmailRequests)..where(
              (t) =>
                  t.attendanceEmailRequestId.equals(attendanceEmailRequestId),
            ))
            .getSingleOrNull();
    return row == null ? null : _attendanceEmailRequestRowToDomain(row);
  }

  /// Clears all [AttendanceEmailRequest] rows for the given organization. Used when
  /// applying a bootstrap [ScopeSyncResult] for an `organization:{id}` scope.
  Future<void> clearAttendanceEmailRequestsForOrg(String organizationId) =>
      (delete(
        attendanceEmailRequests,
      )..where((t) => t.organizationId.equals(organizationId))).go();

  /// Remaps the primary key of a [AttendanceEmailRequest] row from a `tmp_*` id
  /// to the server-allocated real id. Done as a delete + insert in a transaction
  /// because [attendanceEmailRequestId] is the PK.
  Future<void> remapAttendanceEmailRequestId({
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing =
        await (select(attendanceEmailRequests)
              ..where((t) => t.attendanceEmailRequestId.equals(oldId)))
            .getSingleOrNull();
    if (existing == null) return;
    final request = _attendanceEmailRequestRowToDomain(existing);
    await (delete(
      attendanceEmailRequests,
    )..where((t) => t.attendanceEmailRequestId.equals(oldId))).go();
    await upsertAttendanceEmailRequest(
      request.copyWith(attendanceEmailRequestId: newId),
    );
  });

  /// Reactive stream of all [ErrorReport] rows in the local cache.
  Stream<List<ErrorReport>> watchAllErrorReports() => select(
    errorReports,
  ).watch().map((rows) => rows.map(_errorReportRowToDomain).toList());

  /// Inserts or replaces an [ErrorReport] row.
  Future<void> upsertErrorReport(ErrorReport report) => into(
    errorReports,
  ).insertOnConflictUpdate(_errorReportDomainToRow(report));

  /// Deletes the [ErrorReport] row identified by [errorReportId].
  Future<void> deleteErrorReport(String errorReportId) => (delete(
    errorReports,
  )..where((t) => t.errorReportId.equals(errorReportId))).go();

  /// Clears all [ErrorReport] rows. Used when applying a bootstrap result.
  Future<void> clearAllErrorReports() => delete(errorReports).go();

  /// Remaps the primary key of an [ErrorReport] row from a `tmp_*` id to the
  /// server-allocated real id. Done as delete + insert in a transaction because
  /// [errorReportId] is the PK.
  Future<void> remapErrorReportId({
    required String oldId,
    required String newId,
  }) => transaction(() async {
    final existing = await (select(
      errorReports,
    )..where((t) => t.errorReportId.equals(oldId))).getSingleOrNull();
    if (existing == null) return;
    final report = _errorReportRowToDomain(existing);
    await (delete(
      errorReports,
    )..where((t) => t.errorReportId.equals(oldId))).go();
    await upsertErrorReport(report.copyWith(errorReportId: newId));
  });
}

AttendanceEmailRequest _attendanceEmailRequestRowToDomain(
  AttendanceEmailRequestRow row,
) => AttendanceEmailRequest(
  attendanceEmailRequestId: row.attendanceEmailRequestId,
  organizationId: row.organizationId,
  deliveryId: row.deliveryId,
  recipientEmail: row.recipientEmail,
  requestedAt: row.requestedAt,
  sentAt: row.sentAt,
);

AttendanceEmailRequestsCompanion _attendanceEmailRequestDomainToRow(
  AttendanceEmailRequest request,
) => AttendanceEmailRequestsCompanion.insert(
  attendanceEmailRequestId: request.attendanceEmailRequestId,
  organizationId: request.organizationId,
  deliveryId: request.deliveryId,
  recipientEmail: request.recipientEmail,
  requestedAt: request.requestedAt,
  sentAt: Value(request.sentAt),
);

ErrorReport _errorReportRowToDomain(ErrorReportRow row) => ErrorReport(
  errorReportId: row.errorReportId,
  errorMessage: row.errorMessage,
  reportedAt: row.reportedAt,
);

ErrorReportsCompanion _errorReportDomainToRow(ErrorReport report) =>
    ErrorReportsCompanion.insert(
      errorReportId: report.errorReportId,
      errorMessage: report.errorMessage,
      reportedAt: report.reportedAt,
    );
