import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_view_state.freezed.dart';

/// UI state for the forgot-password flow.
///
/// - [codeSent] false → show the email-request form (step 1).
/// - [codeSent] true  → show the token+new-password confirmation form (step 2).
/// - [success] true   → password reset confirmed; the screen should navigate
///   back to login.
@freezed
abstract class ForgotPasswordViewState with _$ForgotPasswordViewState {
  const factory ForgotPasswordViewState({
    @Default(false) bool codeSent,
    @Default(false) bool submitting,
    @Default(false) bool success,
    String? email,
    AuthError? lastError,
  }) = _ForgotPasswordViewState;
}
