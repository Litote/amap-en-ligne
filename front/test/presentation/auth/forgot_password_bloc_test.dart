import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_event.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_view_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late _MockAuthService service;

  setUp(() {
    service = _MockAuthService();
    when(
      () => service.authState,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => service.bootstrap()).thenAnswer((_) async {});
  });

  blocTest<ForgotPasswordBloc, ForgotPasswordViewState>(
    'resetRequested success → codeSent true and email captured',
    setUp: () => when(
      () => service.requestPasswordReset(email: any(named: 'email')),
    ).thenAnswer((_) async {}),
    build: () => ForgotPasswordBloc(service: service),
    act: (bloc) =>
        bloc.add(const ForgotPasswordEvent.resetRequested(email: 'a@b.c')),
    expect: () => [
      const ForgotPasswordViewState(submitting: true),
      const ForgotPasswordViewState(codeSent: true, email: 'a@b.c'),
    ],
  );

  blocTest<ForgotPasswordBloc, ForgotPasswordViewState>(
    'resetRequested network error → lastError network',
    setUp: () => when(
      () => service.requestPasswordReset(email: any(named: 'email')),
    ).thenThrow(const AuthException(AuthError.network)),
    build: () => ForgotPasswordBloc(service: service),
    act: (bloc) =>
        bloc.add(const ForgotPasswordEvent.resetRequested(email: 'a@b.c')),
    expect: () => [
      const ForgotPasswordViewState(submitting: true),
      const ForgotPasswordViewState(lastError: AuthError.network),
    ],
  );

  blocTest<ForgotPasswordBloc, ForgotPasswordViewState>(
    'confirmRequested success → success true',
    setUp: () => when(
      () => service.confirmPasswordReset(
        email: any(named: 'email'),
        token: any(named: 'token'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async {}),
    build: () =>
        ForgotPasswordBloc(service: service)
          ..emit(const ForgotPasswordViewState(codeSent: true, email: 'a@b.c')),
    act: (bloc) => bloc.add(
      const ForgotPasswordEvent.confirmRequested(
        email: 'a@b.c',
        token: '123456',
        newPassword: 'newpass123',
      ),
    ),
    expect: () => [
      const ForgotPasswordViewState(
        codeSent: true,
        email: 'a@b.c',
        submitting: true,
      ),
      const ForgotPasswordViewState(
        codeSent: true,
        email: 'a@b.c',
        success: true,
      ),
    ],
  );

  blocTest<ForgotPasswordBloc, ForgotPasswordViewState>(
    'confirmRequested invalidOrExpiredToken → lastError invalidOrExpiredToken',
    setUp: () => when(
      () => service.confirmPasswordReset(
        email: any(named: 'email'),
        token: any(named: 'token'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenThrow(const AuthException(AuthError.invalidOrExpiredToken)),
    build: () =>
        ForgotPasswordBloc(service: service)
          ..emit(const ForgotPasswordViewState(codeSent: true, email: 'a@b.c')),
    act: (bloc) => bloc.add(
      const ForgotPasswordEvent.confirmRequested(
        email: 'a@b.c',
        token: 'bad',
        newPassword: 'newpass123',
      ),
    ),
    expect: () => [
      const ForgotPasswordViewState(
        codeSent: true,
        email: 'a@b.c',
        submitting: true,
      ),
      const ForgotPasswordViewState(
        codeSent: true,
        email: 'a@b.c',
        lastError: AuthError.invalidOrExpiredToken,
      ),
    ],
  );

  blocTest<ForgotPasswordBloc, ForgotPasswordViewState>(
    'confirmRequested weakPassword → lastError weakPassword',
    setUp: () => when(
      () => service.confirmPasswordReset(
        email: any(named: 'email'),
        token: any(named: 'token'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenThrow(const AuthException(AuthError.weakPassword)),
    build: () =>
        ForgotPasswordBloc(service: service)
          ..emit(const ForgotPasswordViewState(codeSent: true, email: 'a@b.c')),
    act: (bloc) => bloc.add(
      const ForgotPasswordEvent.confirmRequested(
        email: 'a@b.c',
        token: '123456',
        newPassword: 'weak',
      ),
    ),
    expect: () => [
      const ForgotPasswordViewState(
        codeSent: true,
        email: 'a@b.c',
        submitting: true,
      ),
      const ForgotPasswordViewState(
        codeSent: true,
        email: 'a@b.c',
        lastError: AuthError.weakPassword,
      ),
    ],
  );
}
