@Tags(['acceptance'])
library;

import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/gotrue_auth_service.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _gotrueUrl = String.fromEnvironment('GOTRUE_URL');
const _backUrl = String.fromEnvironment('BACK_URL');
const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');
const _producerAccountId = String.fromEnvironment('PRODUCER_ACCOUNT_ID');

void main() {
  final skip = _gotrueUrl.isEmpty || _backUrl.isEmpty || _email.isEmpty
      ? 'GOTRUE_URL / BACK_URL / TEST_EMAIL not set'
      : false;

  group('cross-component auth + sync', () {
    late GoTrueAuthService authService;
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SharedPreferencesAuthTokenStorage(prefs: prefs);
      final authDio = buildAuthDio(baseUrl: _gotrueUrl);
      authService = GoTrueAuthService(dio: authDio, storage: storage);
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'sign in via real GoTrue yields authenticated state with correct producerAccountId',
      () async {
        await authService.signIn(email: _email, password: _password);

        final state = authService.currentState;
        expect(state, isA<Authenticated>());
        final auth = state as Authenticated;
        expect(auth.producerId, _producerAccountId);
        expect(auth.accessToken, isNotEmpty);
      },
      tags: ['cross-component'],
      skip: skip,
    );

    test(
      'authenticated token is accepted by back for sync',
      () async {
        await authService.signIn(email: _email, password: _password);
        final producerAccountId =
            (authService.currentState as Authenticated).producerId;

        final syncDio = buildSyncDio(backendUrl: _backUrl, auth: authService);
        final syncRepo = SyncRepository(db: db, api: SyncApi(syncDio));

        final outcome = await syncRepo.sync(tenantId: producerAccountId);
        expect(outcome, isA<SyncSuccess>());
      },
      tags: ['cross-component'],
      skip: skip,
    );

    test(
      'wrong password throws AuthException with invalidCredentials',
      () async {
        expect(
          () => authService.signIn(email: _email, password: 'wrong-password'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.error,
              'error',
              AuthError.invalidCredentials,
            ),
          ),
        );
      },
      tags: ['cross-component'],
      skip: skip,
    );
  });
}
