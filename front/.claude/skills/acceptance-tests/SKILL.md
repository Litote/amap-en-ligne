---
name: acceptance-tests
description: >
  Write Flutter acceptance tests for the amap-en-ligne front. Two tiers:
  @Tags(['acceptance']) for fast scripted tests (no real backend), and
  @Tags(['cross-component']) for E2E tests against a live backend.
  Covers _Scripted* fake pattern, BLoC stream assertions, widget tests,
  scenario linking, and cross-component skip guards.
triggers:
  - acceptance test
  - scripted api
  - _ScriptedSyncApi
  - _ScriptedAuthService
  - cross-component test
  - e2e flutter
  - testWidgets acceptance
  - BLoC acceptance
---

# Flutter Acceptance Tests

## Two-Tier Architecture

| Tier | Tag | Needs backend | Location |
|------|-----|---------------|----------|
| Scripted acceptance | `@Tags(['acceptance'])` | No — fakes only | `test/acceptance/` |
| Cross-component E2E | `@Tags(['cross-component'])` | Yes — real server | `test/acceptance/cross_component/` |

The `library;` directive must be the **first line after `@Tags([...])`**.

## Scenario Linking

Acceptance tests link to the shared JSON scenario files for their `id` and `title` only:

```dart
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
```

Use the story in test names: `test('${story.title} [${story.id}]', () async { ... })`.

## _Scripted* Pattern (Fake with Assertion Queue)

Every scripted fake holds a `Queue` of expected calls. Dequeue in the override and fail fast on mismatch. Always add `assertDrained()` in `tearDown`.

### Example: _ScriptedSyncApi

```dart
class _ScriptedSyncApi extends SyncApi {
  _ScriptedSyncApi(Iterable<_ExpectedSyncCall> calls)
    : _calls = Queue.of(calls),
      super(Dio()); // Dio() is never used — calls are intercepted

  final Queue<_ExpectedSyncCall> _calls;

  void enqueue(_ExpectedSyncCall call) => _calls.add(call);

  void assertDrained() {
    expect(_calls, isEmpty, reason: 'Unconsumed scripted sync calls remain.');
  }

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    expect(_calls, isNotEmpty, reason: 'Unexpected sync request: $request');
    final call = _calls.removeFirst();
    expect(request, call.request, reason: 'Unexpected sync request for ${call.label}');
    if (call.error != null) throw call.error!;
    return call.response!;
  }
}

class _ExpectedSyncCall {
  _ExpectedSyncCall.response({required this.label, required this.request, required this.response})
    : error = null;
  _ExpectedSyncCall.failure({required this.label, required this.request, required this.error})
    : response = null;

  final String label;
  final SyncRequest request;
  final SyncResponse? response;
  final Object? error;
}
```

### Example: _ScriptedAuthService

```dart
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
  Future<void> signIn({required String email, required String password}) async {
    final fn = onSignIn;
    if (fn != null) await fn();
  }

  void emitAuthenticated({required String producerAccountId, String accessToken = 'test-token'}) {
    _state = AuthState.authenticated(producerAccountId: producerAccountId, accessToken: accessToken);
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

  // requestPasswordReset / confirmPasswordReset → empty async stubs
  Future<void> dispose() => _controller.close();
}
```

Always call `addTearDown(service.dispose)` in `testWidgets`.

## BLoC-Only Acceptance Tests

Use `bloc.stream.where(...)` to await state transitions without rendering widgets:

```dart
final loadedFuture = adminBloc.stream
    .where((s) => s is AdminRequestsLoaded)
    .cast<AdminRequestsLoaded>()
    .first;

adminBloc.add(const AdminRequestsLoadRequested());
final loaded = await loadedFuture;
expect(loaded.requests, hasLength(1));

await adminBloc.close(); // always close blocs
```

For chained steps across multiple blocs (e.g., submit → review → authenticate), use sequential `await` + `close()` between steps. See `organization_request_acceptance_test.dart` for the full multi-step pattern.

## Widget Acceptance Tests

Pump the widget under test inside `testWidgets` with minimal BLoC wiring:

```dart
Future<void> _pumpLoginScreen(WidgetTester tester, _ScriptedAuthService service) async {
  final bloc = AuthBloc(service: service);
  await tester.pumpWidget(
    MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ServerConfig>.value(value: serverPresets.first),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const LoginScreen(),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 30)); // let bootstrap settle
}
```

Typical assertion flow:

```dart
await tester.tap(find.byKey(const Key('login_submit')));
await tester.pump();          // trigger rebuild
await tester.pump();          // let async state land

expect(find.text('Email is required'), findsOneWidget);
```

For in-progress states (spinner), call `completer.complete()` then `tester.pumpAndSettle()` to drain animations.

## AppDatabase in Tests

Always use in-memory database:

```dart
late AppDatabase db;

setUp(() {
  db = AppDatabase(NativeDatabase.memory());
});

tearDown(() async {
  api.assertDrained(); // before db.close()
  await db.close();
});
```

## Cross-Component Tests

Guard tests with `skip` when environment variables are missing:

```dart
const _backUrl = String.fromEnvironment('BACK_URL');
const _bearerToken = String.fromEnvironment('BEARER_TOKEN');

final skip = _backUrl.isEmpty || _bearerToken.isEmpty
    ? 'BACK_URL / BEARER_TOKEN not set'
    : false;

test('...', () async { ... }, tags: ['cross-component'], skip: skip);
```

Pass env vars at run time:

```bash
flutter test test/acceptance/cross_component/sync_e2e_test.dart \
  --dart-define=BACK_URL=http://localhost:8080 \
  --dart-define=BEARER_TOKEN=<token> \
  --dart-define=PRODUCER_ACCOUNT_ID=<id> \
  --tags cross-component
```

For auth E2E, also pass `GOTRUE_URL`, `TEST_EMAIL`, `TEST_PASSWORD`.

## Run Commands

```bash
# All scripted acceptance tests (no backend needed)
flutter test test/acceptance/ --tags acceptance

# Single acceptance test file
flutter test test/acceptance/sync_acceptance_test.dart

# All tests including acceptance (exclude cross-component)
flutter test --exclude-tags cross-component

# Full suite with golden update
flutter test test/golden/ --update-goldens --tags golden
```
