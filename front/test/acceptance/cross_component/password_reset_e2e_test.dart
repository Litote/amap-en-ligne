@Tags(['acceptance'])
library;

import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/gotrue_auth_service.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _gotrueUrl = String.fromEnvironment('GOTRUE_URL');
const _backUrl = String.fromEnvironment('BACK_URL');
const _email = String.fromEnvironment('TEST_EMAIL');
const _newPassword = String.fromEnvironment('NEW_PASSWORD');
const _recoveryToken = String.fromEnvironment('RECOVERY_TOKEN');
const _producerAccountId = String.fromEnvironment('PRODUCER_ACCOUNT_ID');

void main() {
  final skip = _gotrueUrl.isEmpty || _recoveryToken.isEmpty || _email.isEmpty
      ? 'GOTRUE_URL / RECOVERY_TOKEN / TEST_EMAIL not set'
      : false;

  group('cross-component password reset', () {
    test(
      'reset password with admin token then sign in and sync',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = SharedPreferencesAuthTokenStorage(prefs: prefs);
        final authDio = buildAuthDio(baseUrl: _gotrueUrl);
        final authService = GoTrueAuthService(dio: authDio, storage: storage);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await authService.confirmPasswordReset(
          email: _email,
          token: _recoveryToken,
          newPassword: _newPassword,
        );

        await authService.signIn(email: _email, password: _newPassword);

        final state = authService.currentState;
        expect(state, isA<Authenticated>());
        final producerAccountId = (state as Authenticated).producerId;
        expect(producerAccountId, _producerAccountId);

        final syncDio = buildSyncDio(backendUrl: _backUrl, auth: authService);
        final syncRepo = SyncRepository(db: db, api: SyncApi(syncDio));
        final outcome = await syncRepo.sync(tenantId: producerAccountId);
        expect(outcome, isA<SyncSuccess>());
      },
      tags: ['cross-component'],
      skip: skip,
    );
  });
}
