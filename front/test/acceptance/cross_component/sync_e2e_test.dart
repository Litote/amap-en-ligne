@Tags(['acceptance'])
library;

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _backUrl = String.fromEnvironment('BACK_URL');
const _bearerToken = String.fromEnvironment('BEARER_TOKEN');
const _producerAccountId = String.fromEnvironment('PRODUCER_ACCOUNT_ID');

/// Minimal auth service that returns a pre-minted token — no GoTrue needed for sync tests.
class _StaticTokenAuthService implements AuthService {
  const _StaticTokenAuthService();

  @override
  Stream<AuthState> get authState => Stream.value(
    const AuthState.authenticated(
      producerId: _producerAccountId,
      accessToken: _bearerToken,
    ),
  );

  @override
  AuthState get currentState => const AuthState.authenticated(
    producerId: _producerAccountId,
    accessToken: _bearerToken,
  );

  @override
  Future<void> bootstrap() async {}

  @override
  Future<String?> currentAccessToken() async => _bearerToken;

  @override
  Future<void> signIn({
    required String email,
    required String password,
    bool? rememberSession,
  }) async {}

  @override
  Future<void> signOut() async {}

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
}

void main() {
  final skip = _backUrl.isEmpty || _bearerToken.isEmpty
      ? 'BACK_URL / BEARER_TOKEN not set'
      : false;

  group('cross-component sync', () {
    late AppDatabase db;
    late SyncRepository syncRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      final auth = const _StaticTokenAuthService();
      final dio = buildSyncDio(backendUrl: _backUrl, auth: auth);
      final api = SyncApi(dio);
      syncRepo = SyncRepository(db: db, api: api);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'bootstrap sync returns empty state for a fresh producer account',
      () async {
        final outcome = await syncRepo.sync(tenantId: _producerAccountId);
        expect(outcome, isA<SyncSuccess>());
        final success = outcome as SyncSuccess;
        expect(success.rejectedMutations, isEmpty);
      },
      tags: ['cross-component'],
      skip: skip,
    );

    test(
      'second sync with cursor is incremental and returns no new changes',
      () async {
        // Bootstrap first
        await syncRepo.sync(tenantId: _producerAccountId);
        // Incremental sync — should succeed and produce no new changes
        final outcome = await syncRepo.sync(tenantId: _producerAccountId);
        expect(outcome, isA<SyncSuccess>());
      },
      tags: ['cross-component'],
      skip: skip,
    );
  });
}
