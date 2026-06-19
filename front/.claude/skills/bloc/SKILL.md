---
name: bloc
description: >
  Write BLoC classes and their unit tests in amap-en-ligne/front.
  Covers bloc_test/blocTest<>, mocktail _MockX pattern, StreamController
  lifecycle, skip/wait, and the project's sealed Event+State conventions.
triggers:
  - BLoC
  - bloc_test
  - blocTest
  - Cubit
  - event state
  - mocktail
  - Mock service
  - StreamController
  - authBloc
  - syncBloc
---

# BLoC Pattern

## Class Conventions

```
presentation/<feature>/
  <feature>_bloc.dart       — extends Bloc<Event, State>
  <feature>_event.dart      — sealed class via Freezed
  <feature>_state.dart      — Freezed union or copyWith class
  <feature>_view_state.dart — if UI state is separate from domain state
```

Events and states use `@freezed` (with `part` directives for `.freezed.dart` and optionally `.g.dart`).

### Registering handlers

```dart
class FooBloc extends Bloc<FooEvent, FooState> {
  FooBloc({required FooService service})
    : _service = service,
      super(const FooState.idle()) {
    on<FooStarted>(_onStarted);
    on<FooRequested>(_onRequested);
    // Subscribe to external streams in constructor:
    _sub = service.stream.listen((data) => add(FooEvent.changed(data)));
    add(const FooEvent.started());
  }

  final FooService _service;
  late final StreamSubscription<FooData> _sub;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
```

`close()` must cancel every `StreamSubscription` before `super.close()`.

## Unit Tests with bloc_test

### Setup skeleton

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFooService extends Mock implements FooService {}

void main() {
  late _MockFooService service;
  late StreamController<FooData> events;   // only when the bloc subscribes to a stream

  setUp(() {
    service = _MockFooService();
    events = StreamController<FooData>.broadcast();
    when(() => service.stream).thenAnswer((_) => events.stream);
    when(() => service.bootstrap()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await events.close();   // close before the test framework disposes the bloc
  });
```

### blocTest anatomy

```dart
blocTest<FooBloc, FooState>(
  'description of expected behaviour',
  // Optional mock setup for this specific test only:
  setUp: () => when(() => service.doWork()).thenAnswer((_) async => 'result'),
  // BLoC factory — called once per test:
  build: () => FooBloc(service: service),
  // Actions after build completes:
  act: (bloc) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(const FooEvent.requested());
  },
  // How long to wait for async events after act finishes:
  wait: const Duration(milliseconds: 50),
  // Skip N leading states (e.g. the bootstrap cycle):
  skip: 1,
  // Ordered list of expected state emissions:
  expect: () => [
    const FooState.loading(),
    const FooState.success(data: 'result'),
  ],
  // Assert side-effects after all emissions:
  verify: (_) => verify(() => service.doWork()).called(1),
);
```

**Key rules:**
- Use `skip:` to ignore the initial auto-fired bootstrap states. Count carefully: each emission counts as 1.
- Use `wait:` (not `act` delays) when the BLoC fires async work automatically on construction (e.g. `add(const FooEvent.started())` in constructor). Typical value: `Duration(milliseconds: 50)`.
- Do NOT use `any()` for named parameters in `when()` — use `any(named: 'paramName')`.

### Testing stream-triggered transitions

When a BLoC subscribes to an injected `Stream` (connectivity, auth state, etc.), inject a `StreamController` and push events in `act`:

```dart
blocTest<SyncBloc, SyncState>(
  'connectivity none → wifi triggers a sync',
  setUp: () => when(() => repo.sync(tenantId: tenant))
      .thenAnswer((_) async => const SyncOutcome.success()),
  build: () => SyncBloc(
    repository: repo,
    tenantId: tenant,
    connectivityStream: connectivity.stream,   // injected, not platform plugin
  ),
  act: (_) async {
    await Future<void>.delayed(const Duration(milliseconds: 30)); // drain auto-Started
    connectivity.add([ConnectivityResult.none]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    connectivity.add([ConnectivityResult.wifi]);
  },
  wait: const Duration(milliseconds: 50),
  skip: 2, // auto-Started: syncing + success
  expect: () => [const SyncState.syncing(), const SyncState.success()],
);
```

Always make stream-dependent constructor parameters injectable (`Stream<T>? connectivityStream`) so tests don't touch platform plugins.

### Testing error paths

```dart
blocTest<FooBloc, FooState>(
  'service throws → emits failure',
  setUp: () => when(() => service.doWork()).thenThrow(Exception('boom')),
  build: () => FooBloc(service: service),
  act: (bloc) => bloc.add(const FooEvent.requested()),
  wait: const Duration(milliseconds: 50),
  skip: 1,
  expect: () => [
    const FooState.loading(),
    const FooState.failure('boom'),
  ],
);
```

### Testing BLoCs that update state via `copyWith`

For BLoCs using a single state class with `copyWith` (like `AuthBloc`):

```dart
expect: () => [
  const AuthViewState(initializing: false),                   // bootstrap done
  const AuthViewState(initializing: false, submitting: true), // login started
  const AuthViewState(initializing: false, submitting: false, producerAccountId: 'u-1'),
],
```

Freezed `copyWith` preserves all other fields — only list the fields that differ from the initial state.

## Fixtures / Helpers

Place shared test fixtures in `test/support/`:

```dart
// test/support/product_type_fixtures.dart
const testTenantId = 'producer-1';

ProductType buildProductType({
  String productTypeId = 'pt-1',
  String name = 'Vegetables',
  ...
}) => ProductType(...);
```

Prefer builders with named defaults over `const` instances when tests need variations.

## Run Commands

```bash
# All unit tests (no emulator needed)
flutter test test/presentation/

# Single bloc test file
flutter test test/presentation/auth/auth_bloc_test.dart

# With verbose output for debugging
flutter test test/presentation/auth/auth_bloc_test.dart --reporter expanded
```
