@Tags(['acceptance'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/server/server_presets.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  final story = _loadStory('organization-request-creation');

  group('${story.title} — login screen [${story.id}]', () {
    testWidgets(
      'GIVEN empty form WHEN submit tapped THEN validation errors appear',
      (tester) async {
        final service = _ScriptedAuthService();
        addTearDown(service.dispose);

        await _pumpLoginScreen(tester, service);

        await tester.tap(find.byKey(const Key('login_submit')));
        await tester.pump();

        expect(find.text('L\'email est requis.'), findsOneWidget);
        expect(find.text('Le mot de passe est requis.'), findsOneWidget);
      },
    );

    testWidgets(
      'GIVEN valid credentials WHEN submitted THEN user is authenticated',
      (tester) async {
        final service = _ScriptedAuthService();
        addTearDown(service.dispose);
        service.onSignIn = () async => service.emitAuthenticated(
          producerAccountId: 'new-admin-account-id',
        );

        await _pumpLoginScreen(tester, service);

        await tester.enterText(
          find.byKey(const Key('login_email')),
          'alice@collines.fr',
        );
        await tester.enterText(
          find.byKey(const Key('login_password')),
          'correct-password',
        );
        await tester.tap(find.byKey(const Key('login_submit')));
        await tester.pump();
        await tester.pump();

        expect(service.currentState, isA<Authenticated>());
        expect(
          (service.currentState as Authenticated).producerId,
          'new-admin-account-id',
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'GIVEN wrong credentials WHEN submitted THEN error message is shown',
      (tester) async {
        final service = _ScriptedAuthService();
        addTearDown(service.dispose);
        service.onSignIn = () async =>
            throw const AuthException(AuthError.invalidCredentials);

        await _pumpLoginScreen(tester, service);

        await tester.enterText(
          find.byKey(const Key('login_email')),
          'alice@collines.fr',
        );
        await tester.enterText(
          find.byKey(const Key('login_password')),
          'wrong-password',
        );
        await tester.tap(find.byKey(const Key('login_submit')));
        await tester.pump();
        await tester.pump();

        expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
        expect(service.currentState, isA<Unauthenticated>());
      },
    );

    testWidgets(
      'GIVEN submit in progress THEN button is disabled and spinner shown',
      (tester) async {
        final completer = Completer<void>();
        final service = _ScriptedAuthService();
        addTearDown(service.dispose);
        service.onSignIn = () => completer.future;

        await _pumpLoginScreen(tester, service);

        await tester.enterText(
          find.byKey(const Key('login_email')),
          'alice@collines.fr',
        );
        await tester.enterText(
          find.byKey(const Key('login_password')),
          'some-password',
        );
        await tester.tap(find.byKey(const Key('login_submit')));
        await tester.pump();

        final button = tester.widget<FilledButton>(
          find.byKey(const Key('login_submit')),
        );
        expect(button.onPressed, isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete();
        await tester.pumpAndSettle();
      },
    );
  });
}

// ── Scripted AuthService ──────────────────────────────────────────────────────

class _ScriptedAuthService implements AuthService {
  final _controller = StreamController<AuthState>.broadcast();
  AuthState _state = const AuthState.unauthenticated();

  Future<void> Function()? onSignIn;

  @override
  Stream<AuthState> get authState => _controller.stream;

  @override
  AuthState get currentState => _state;

  @override
  Future<void> bootstrap() async {
    _state = const AuthState.unauthenticated();
    _controller.add(_state);
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
    bool? rememberSession,
  }) async {
    final fn = onSignIn;
    if (fn != null) await fn();
  }

  void emitAuthenticated({
    required String producerAccountId,
    String accessToken = 'test-token',
  }) {
    _state = AuthState.authenticated(
      producerId: producerAccountId,
      accessToken: accessToken,
    );
    _controller.add(_state);
  }

  @override
  Future<void> signOut() async {
    _state = const AuthState.unauthenticated();
    _controller.add(_state);
  }

  @override
  Future<String?> currentAccessToken() async => switch (_state) {
    Authenticated(:final accessToken) => accessToken,
    Unauthenticated() => null,
  };

  @override
  Future<void> requestPasswordReset({
    required String email,
    String? redirectTo,
  }) async {}

  @override
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  }) async {}

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<void> signInWithSession({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
    bool? rememberSession,
  }) async {}

  @override
  Future<void> refreshSession() async {}

  Future<void> dispose() => _controller.close();
}

class _NoopRememberedUserContextStore implements RememberedUserContextStore {
  @override
  Future<void> clear() async {}

  @override
  Future<RememberedUserContext?> read({required String serverId}) async => null;

  @override
  Future<void> write(RememberedUserContext context) async {}
}

class _MockAppDatabase extends Mock implements AppDatabase {}

// ── Widget pump helper ────────────────────────────────────────────────────────

Future<void> _pumpLoginScreen(
  WidgetTester tester,
  _ScriptedAuthService service,
) async {
  final db = _MockAppDatabase();
  when(
    () => db.watchEffectiveOrganizationId(any()),
  ).thenAnswer((_) => Stream.value(null));
  final bloc = AuthBloc(service: service, db: db);
  await tester.pumpWidget(
    MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ServerConfig>.value(value: serverPresets.first),
          RepositoryProvider<RememberedUserContextStore>.value(
            value: _NoopRememberedUserContextStore(),
          ),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const LoginScreen(),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 30));
}

// ── Story loader ──────────────────────────────────────────────────────────────

class _AcceptanceStory {
  const _AcceptanceStory({required this.id, required this.title});

  final String id;
  final String title;
}

_AcceptanceStory _loadStory(String id) {
  final uri = Directory.current.uri.resolve('../acceptance/scenarios/$id.json');
  final content = File.fromUri(uri).readAsStringSync();
  final json = jsonDecode(content) as Map<String, Object?>;
  return _AcceptanceStory(
    id: json['id']! as String,
    title: json['title']! as String,
  );
}
