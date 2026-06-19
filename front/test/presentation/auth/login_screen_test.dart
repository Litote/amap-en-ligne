import 'dart:async';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/server/server_presets.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/login_screen.dart';
import 'package:amap_en_ligne/presentation/server/server_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockRememberedUserContextStore extends Mock
    implements RememberedUserContextStore {}

Future<void> _pumpLogin(
  WidgetTester tester,
  AuthService service, {
  ValueChanged<ServerConfig>? onServerSelected,
  RememberedUserContextStore? rememberedUserContextStore,
}) async {
  final db = _MockAppDatabase();
  when(
    () => db.watchEffectiveOrganizationId(any()),
  ).thenAnswer((_) => Stream.value(null));
  final bloc = AuthBloc(service: service, db: db);
  await tester.pumpWidget(
    MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RememberedUserContextStore>.value(
            value:
                rememberedUserContextStore ?? _MockRememberedUserContextStore(),
          ),
          RepositoryProvider<ServerConfig>.value(value: serverPresets.first),
          RepositoryProvider<ValueChanged<ServerConfig>>.value(
            value: onServerSelected ?? (_) {},
          ),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const LoginScreen(),
        ),
      ),
    ),
  );
  // Drain bootstrap.
  await tester.pump(const Duration(milliseconds: 30));
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const RememberedUserContext(
        email: 'fallback@example.com',
        serverId: 'local-dev-gotrue',
        rememberMe: true,
      ),
    );
  });

  late _MockAuthService service;
  late _MockRememberedUserContextStore rememberedUserContextStore;
  late StreamController<AuthState> sessions;

  setUp(() {
    service = _MockAuthService();
    rememberedUserContextStore = _MockRememberedUserContextStore();
    sessions = StreamController<AuthState>.broadcast();
    when(() => service.authState).thenAnswer((_) => sessions.stream);
    when(() => service.bootstrap()).thenAnswer((_) async {});
    when(
      () => rememberedUserContextStore.read(serverId: any(named: 'serverId')),
    ).thenAnswer((_) async => null);
    when(
      () => rememberedUserContextStore.write(any()),
    ).thenAnswer((_) async {});
    when(() => rememberedUserContextStore.clear()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await sessions.close();
  });

  testWidgets('shows email/password validation errors on empty submit', (
    tester,
  ) async {
    await _pumpLogin(
      tester,
      service,
      rememberedUserContextStore: rememberedUserContextStore,
    );

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('L\'email est requis.'), findsOneWidget);
    expect(find.text('Le mot de passe est requis.'), findsOneWidget);
    verifyNever(
      () => service.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('valid form calls AuthService.signIn', (tester) async {
    when(
      () => service.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
        rememberSession: any(named: 'rememberSession'),
      ),
    ).thenAnswer((_) async {});

    await _pumpLogin(
      tester,
      service,
      rememberedUserContextStore: rememberedUserContextStore,
    );

    await tester.enterText(find.byKey(const Key('login_email')), 'a@b.c');
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'secret-pw',
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    verify(
      () => service.signIn(
        email: 'a@b.c',
        password: 'secret-pw',
        rememberSession: true,
      ),
    ).called(1);
  });

  testWidgets('tapping server field opens ServerSelectionScreen', (
    tester,
  ) async {
    await _pumpLogin(
      tester,
      service,
      rememberedUserContextStore: rememberedUserContextStore,
    );

    await tester.tap(find.byKey(const Key('login_server')));
    await tester.pumpAndSettle();

    expect(find.byType(ServerSelectionScreen), findsOneWidget);
  });

  testWidgets('shows error message on invalid credentials', (tester) async {
    when(
      () => service.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
        rememberSession: any(named: 'rememberSession'),
      ),
    ).thenThrow(const AuthException(AuthError.invalidCredentials));

    await _pumpLogin(
      tester,
      service,
      rememberedUserContextStore: rememberedUserContextStore,
    );

    await tester.enterText(find.byKey(const Key('login_email')), 'a@b.c');
    await tester.enterText(find.byKey(const Key('login_password')), 'badpass');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
  });

  testWidgets(
    'loads remembered email and checkbox state for the current server',
    (tester) async {
      when(
        () => rememberedUserContextStore.read(serverId: any(named: 'serverId')),
      ).thenAnswer(
        (_) async => const RememberedUserContext(
          email: 'remembered@example.com',
          serverId: 'local-dev-gotrue',
          rememberMe: false,
        ),
      );

      await _pumpLogin(
        tester,
        service,
        rememberedUserContextStore: rememberedUserContextStore,
      );
      await tester.pump();

      expect(find.text('remembered@example.com'), findsOneWidget);
      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('login_remember_me')),
      );
      expect(checkbox.value, isFalse);
    },
  );

  testWidgets('unchecked remember me forwards rememberSession false', (
    tester,
  ) async {
    when(
      () => service.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
        rememberSession: any(named: 'rememberSession'),
      ),
    ).thenAnswer((_) async {});

    await _pumpLogin(
      tester,
      service,
      rememberedUserContextStore: rememberedUserContextStore,
    );

    await tester.enterText(find.byKey(const Key('login_email')), 'a@b.c');
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'secret-pw',
    );
    await tester.tap(find.byKey(const Key('login_remember_me')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    verify(
      () => service.signIn(
        email: 'a@b.c',
        password: 'secret-pw',
        rememberSession: false,
      ),
    ).called(1);
  });
}
