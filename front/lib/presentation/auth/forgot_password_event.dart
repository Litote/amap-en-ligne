import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_event.freezed.dart';

@freezed
sealed class ForgotPasswordEvent with _$ForgotPasswordEvent {
  const factory ForgotPasswordEvent.resetRequested({
    required String email,
    String? redirectTo,
  }) = ForgotPasswordResetRequested;

  const factory ForgotPasswordEvent.confirmRequested({
    required String email,
    required String token,
    required String newPassword,
  }) = ForgotPasswordConfirmRequested;
}
