import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_event.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_view_state.dart';
import 'package:bloc/bloc.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordViewState> {
  ForgotPasswordBloc({required AuthService service})
    : _service = service,
      super(const ForgotPasswordViewState()) {
    on<ForgotPasswordResetRequested>(_onResetRequested);
    on<ForgotPasswordConfirmRequested>(_onConfirmRequested);
  }

  final AuthService _service;

  Future<void> _onResetRequested(
    ForgotPasswordResetRequested event,
    Emitter<ForgotPasswordViewState> emit,
  ) async {
    emit(state.copyWith(submitting: true, lastError: null));
    try {
      await _service.requestPasswordReset(
        email: event.email,
        redirectTo: event.redirectTo,
      );
      emit(
        state.copyWith(
          submitting: false,
          codeSent: true,
          email: event.email,
          lastError: null,
        ),
      );
    } on AuthException catch (e) {
      emit(state.copyWith(submitting: false, lastError: e.error));
    } catch (_) {
      emit(state.copyWith(submitting: false, lastError: AuthError.unknown));
    }
  }

  Future<void> _onConfirmRequested(
    ForgotPasswordConfirmRequested event,
    Emitter<ForgotPasswordViewState> emit,
  ) async {
    emit(state.copyWith(submitting: true, lastError: null));
    try {
      await _service.confirmPasswordReset(
        email: event.email,
        token: event.token,
        newPassword: event.newPassword,
      );
      emit(state.copyWith(submitting: false, success: true));
    } on AuthException catch (e) {
      emit(state.copyWith(submitting: false, lastError: e.error));
    } catch (_) {
      emit(state.copyWith(submitting: false, lastError: AuthError.unknown));
    }
  }
}
