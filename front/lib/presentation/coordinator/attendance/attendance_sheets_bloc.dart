import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_sheets_bloc.freezed.dart';

@freezed
sealed class AttendanceSheetsEvent with _$AttendanceSheetsEvent {
  /// User selects a delivery from the list.
  const factory AttendanceSheetsEvent.deliverySelected({
    required String deliveryId,
  }) = AttendanceSheetsDeliverySelected;
}

@freezed
sealed class AttendanceSheetsState with _$AttendanceSheetsState {
  /// No delivery selected yet.
  const factory AttendanceSheetsState.idle() = AttendanceSheetsIdle;

  /// A delivery is currently selected and its detail is shown.
  const factory AttendanceSheetsState.deliverySelected({
    required String deliveryId,
    required Delivery delivery,
  }) = AttendanceSheetsDeliveryShown;
}
