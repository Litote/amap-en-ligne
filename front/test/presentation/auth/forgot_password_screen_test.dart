import 'package:amap_en_ligne/data/server/server_presets.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockRememberedUserContextStore extends Mock
    implements RememberedUserContextStore {}

void main() {
  late _MockAuthService authService;
  late _MockRememberedUserContextStore store;

  setUpAll(() {
    registerFallbackValue(
      const RememberedUserContext(email: 'x', serverId: 'x', rememberMe: false),
    );
  });

  setUp(() {
    authService = _MockAuthService();
    store = _MockRememberedUserContextStore();
    when(
      () => store.read(serverId: any(named: 'serverId')),
    ).thenAnswer((_) async => null);
    when(() => store.write(any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, {String? initialEmail}) async {
    final router = GoRouter(
      initialLocation: '/forgot',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('LOGIN PAGE')),
        ),
        GoRoute(
          path: '/forgot',
          builder: (_, _) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AuthService>.value(value: authService),
              RepositoryProvider<RememberedUserContextStore>.value(
                value: store,
              ),
              RepositoryProvider<ServerConfig>.value(
                value: serverPresets.first,
              ),
            ],
            child: ForgotPasswordScreen(initialEmail: initialEmail),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the request form initially', (tester) async {
    await pump(tester);
    expect(find.text('Mot de passe oublié'), findsOneWidget);
    expect(find.byKey(const Key('forgot_email')), findsOneWidget);
    expect(find.text('ENVOYER LE CODE'), findsOneWidget);
  });

  testWidgets('empty email submission shows a validation error', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('forgot_submit')));
    await tester.pumpAndSettle();

    expect(find.text("L'email est requis."), findsOneWidget);
    verifyNever(
      () => authService.requestPasswordReset(
        email: any(named: 'email'),
        redirectTo: any(named: 'redirectTo'),
      ),
    );
  });

  testWidgets('successful reset request switches to the confirm form', (
    tester,
  ) async {
    when(
      () => authService.requestPasswordReset(
        email: any(named: 'email'),
        redirectTo: any(named: 'redirectTo'),
      ),
    ).thenAnswer((_) async {});

    await pump(tester, initialEmail: 'alice@example.com');
    await tester.tap(find.byKey(const Key('forgot_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Réinitialisation'), findsOneWidget);
    expect(find.byKey(const Key('forgot_token')), findsOneWidget);
    expect(find.byKey(const Key('forgot_new_password')), findsOneWidget);
    expect(find.text('RÉINITIALISER'), findsOneWidget);
  });

  testWidgets('reset request network error shows an error message', (
    tester,
  ) async {
    when(
      () => authService.requestPasswordReset(
        email: any(named: 'email'),
        redirectTo: any(named: 'redirectTo'),
      ),
    ).thenThrow(const AuthException(AuthError.network));

    await pump(tester, initialEmail: 'alice@example.com');
    await tester.tap(find.byKey(const Key('forgot_submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Erreur réseau'), findsOneWidget);
    // Still on the request form.
    expect(find.text('ENVOYER LE CODE'), findsOneWidget);
  });

  testWidgets('confirm form rejects mismatched passwords', (tester) async {
    when(
      () => authService.requestPasswordReset(
        email: any(named: 'email'),
        redirectTo: any(named: 'redirectTo'),
      ),
    ).thenAnswer((_) async {});

    await pump(tester, initialEmail: 'alice@example.com');
    await tester.tap(find.byKey(const Key('forgot_submit')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('forgot_token')), '123456');
    await tester.enterText(
      find.byKey(const Key('forgot_new_password')),
      'newpass123',
    );
    await tester.enterText(
      find.byKey(const Key('forgot_confirm_password')),
      'different',
    );
    await tester.tap(find.byKey(const Key('forgot_confirm_submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('Les mots de passe ne correspondent pas.'),
      findsOneWidget,
    );
    verifyNever(
      () => authService.confirmPasswordReset(
        email: any(named: 'email'),
        token: any(named: 'token'),
        newPassword: any(named: 'newPassword'),
      ),
    );
  });

  testWidgets(
    'successful confirmation remembers the user and navigates to /login',
    (tester) async {
      when(
        () => authService.requestPasswordReset(
          email: any(named: 'email'),
          redirectTo: any(named: 'redirectTo'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => authService.confirmPasswordReset(
          email: any(named: 'email'),
          token: any(named: 'token'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async {});

      await pump(tester, initialEmail: 'alice@example.com');
      await tester.tap(find.byKey(const Key('forgot_submit')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('forgot_token')), '123456');
      await tester.enterText(
        find.byKey(const Key('forgot_new_password')),
        'newpass123',
      );
      await tester.enterText(
        find.byKey(const Key('forgot_confirm_password')),
        'newpass123',
      );
      await tester.tap(find.byKey(const Key('forgot_confirm_submit')));
      await tester.pumpAndSettle();

      verify(() => store.write(any())).called(1);
      expect(find.text('LOGIN PAGE'), findsOneWidget);
    },
  );
}
