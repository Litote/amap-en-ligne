import 'dart:async';

import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncRepository extends Mock implements SyncRepository {
  _MockSyncRepository() {
    when(() => resetAllCursors()).thenAnswer((_) async {});
  }
}

class _MockAuthService extends Mock implements AuthService {}

void main() {
  const tenant = 'producer-1';
  late _MockSyncRepository repo;
  late StreamController<List<ConnectivityResult>> connectivity;

  setUp(() {
    repo = _MockSyncRepository();
    connectivity = StreamController<List<ConnectivityResult>>.broadcast();
  });

  tearDown(() async {
    await connectivity.close();
  });

  SyncBloc buildBloc() => SyncBloc(
    repository: repo,
    tenantId: tenant,
    connectivityStream: connectivity.stream,
  );

  blocTest<SyncBloc, SyncState>(
    'auto-fires Started at construction → syncing → success',
    setUp: () => when(
      () => repo.sync(tenantId: tenant),
    ).thenAnswer((_) async => const SyncOutcome.success()),
    build: buildBloc,
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => repo.sync(tenantId: tenant)).called(1),
    expect: () => [const SyncState.syncing(), const SyncState.success()],
  );

  blocTest<SyncBloc, SyncState>(
    'manual Requested triggers a sync',
    setUp: () => when(
      () => repo.sync(tenantId: tenant),
    ).thenAnswer((_) async => const SyncOutcome.success(hasMore: true)),
    build: buildBloc,
    act: (bloc) async {
      // Let the auto-Started cycle drain first.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(const SyncEvent.requested());
    },
    wait: const Duration(milliseconds: 50),
    skip: 2, // skip the auto-Started cycle
    expect: () => [
      const SyncState.syncing(),
      const SyncState.success(hasMore: true),
    ],
  );

  blocTest<SyncBloc, SyncState>(
    'connectivity none → wifi triggers a sync',
    setUp: () => when(
      () => repo.sync(tenantId: tenant),
    ).thenAnswer((_) async => const SyncOutcome.success()),
    build: buildBloc,
    act: (_) async {
      // Let auto-Started cycle drain.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      // Then go offline → online to trigger the reconnection event.
      connectivity.add([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      connectivity.add([ConnectivityResult.wifi]);
    },
    wait: const Duration(milliseconds: 50),
    skip: 2, // skip auto-Started cycle
    expect: () => [const SyncState.syncing(), const SyncState.success()],
  );

  blocTest<SyncBloc, SyncState>(
    'staying offline does not trigger a sync',
    setUp: () => when(
      () => repo.sync(tenantId: tenant),
    ).thenAnswer((_) async => const SyncOutcome.success()),
    build: buildBloc,
    act: (_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      connectivity.add([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      connectivity.add([ConnectivityResult.none]);
    },
    wait: const Duration(milliseconds: 50),
    skip: 2,
    expect: () => <SyncState>[],
    verify: (_) => verify(() => repo.sync(tenantId: tenant)).called(1),
  );

  blocTest<SyncBloc, SyncState>(
    'maps SyncFailure to SyncState.failure',
    setUp: () => when(
      () => repo.sync(tenantId: tenant),
    ).thenAnswer((_) async => const SyncOutcome.failure('boom')),
    build: buildBloc,
    wait: const Duration(milliseconds: 50),
    expect: () => [const SyncState.syncing(), const SyncState.failure('boom')],
  );

  blocTest<SyncBloc, SyncState>(
    'maps SyncNetworkFailure to SyncState.offline',
    setUp: () => when(
      () => repo.sync(tenantId: tenant),
    ).thenAnswer((_) async => const SyncOutcome.networkFailure()),
    build: buildBloc,
    wait: const Duration(milliseconds: 50),
    expect: () => [const SyncState.syncing(), const SyncState.offline()],
  );

  blocTest<SyncBloc, SyncState>(
    'fullSyncRequested resets cursors then syncs',
    setUp: () => when(
      () => repo.sync(tenantId: tenant),
    ).thenAnswer((_) async => const SyncOutcome.success()),
    build: buildBloc,
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(const SyncEvent.fullSyncRequested());
    },
    wait: const Duration(milliseconds: 50),
    skip: 2,
    expect: () => [const SyncState.syncing(), const SyncState.success()],
    verify: (_) => verify(() => repo.resetAllCursors()).called(1),
  );

  group('role refresh on Member/Owner changes', () {
    late _MockAuthService authService;

    setUp(() {
      authService = _MockAuthService();
      when(() => authService.refreshSession()).thenAnswer((_) async {});
    });

    SyncBloc buildBlocWithAuth() => SyncBloc(
      repository: repo,
      tenantId: tenant,
      connectivityStream: connectivity.stream,
      authService: authService,
    );

    blocTest<SyncBloc, SyncState>(
      'calls refreshSession when sync returns memberOrOwnerUpdated=true and session is authenticated',
      setUp: () {
        when(() => authService.currentState).thenReturn(
          const AuthState.authenticated(
            producerId: tenant,
            accessToken: 'token',
          ),
        );
        when(() => repo.sync(tenantId: tenant)).thenAnswer(
          (_) async => const SyncOutcome.success(memberOrOwnerUpdated: true),
        );
      },
      build: buildBlocWithAuth,
      wait: const Duration(milliseconds: 50),
      verify: (_) =>
          verify(() => authService.refreshSession()).called(greaterThan(0)),
      expect: () => [const SyncState.syncing(), const SyncState.success()],
    );

    blocTest<SyncBloc, SyncState>(
      'does not call refreshSession when sync returns memberOrOwnerUpdated=false',
      setUp: () {
        when(() => repo.sync(tenantId: tenant)).thenAnswer(
          (_) async => const SyncOutcome.success(memberOrOwnerUpdated: false),
        );
      },
      build: buildBlocWithAuth,
      wait: const Duration(milliseconds: 50),
      verify: (_) => verifyNever(() => authService.refreshSession()),
      expect: () => [const SyncState.syncing(), const SyncState.success()],
    );

    blocTest<SyncBloc, SyncState>(
      'does not call refreshSession when session is unauthenticated',
      setUp: () {
        when(
          () => authService.currentState,
        ).thenReturn(const AuthState.unauthenticated());
        when(() => repo.sync(tenantId: tenant)).thenAnswer(
          (_) async => const SyncOutcome.success(memberOrOwnerUpdated: true),
        );
      },
      build: buildBlocWithAuth,
      wait: const Duration(milliseconds: 50),
      verify: (_) => verifyNever(() => authService.refreshSession()),
      expect: () => [const SyncState.syncing(), const SyncState.success()],
    );
  });
}
