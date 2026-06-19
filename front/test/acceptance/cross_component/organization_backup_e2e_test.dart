@Tags(['acceptance'])
library;

import 'package:amap_en_ligne/data/network/admin_api.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _backUrl = String.fromEnvironment('BACK_URL');
const _ownerToken = String.fromEnvironment('OWNER_TOKEN');
const _sourceOrgId = String.fromEnvironment('SOURCE_ORG_ID');
const _targetOrgId = String.fromEnvironment('TARGET_ORG_ID');

/// Minimal AuthService that always presents the configured OWNER bearer token,
/// so the sync Dio's auth interceptor attaches it to the admin REST calls.
class _StaticTokenAuthService implements AuthService {
  const _StaticTokenAuthService();

  @override
  Stream<AuthState> get authState => Stream.value(
    const AuthState.authenticated(producerId: '', accessToken: _ownerToken),
  );

  @override
  AuthState get currentState =>
      const AuthState.authenticated(producerId: '', accessToken: _ownerToken);

  @override
  Future<void> bootstrap() async {}

  @override
  Future<String?> currentAccessToken() async => _ownerToken;

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
  final shouldSkip =
      _backUrl.isEmpty ||
          _ownerToken.isEmpty ||
          _sourceOrgId.isEmpty ||
          _targetOrgId.isEmpty
      ? 'BACK_URL / OWNER_TOKEN / SOURCE_ORG_ID / TARGET_ORG_ID not set'
      : false;

  test(
    'exports an organization and imports it into an empty target',
    () async {
      final auth = const _StaticTokenAuthService();
      final adminApi = AdminApi(buildSyncDio(backendUrl: _backUrl, auth: auth));

      // Export the source organization.
      final archive = await adminApi.exportOrganization(_sourceOrgId);
      expect(archive, isNotEmpty);
      expect(archive, contains('"format_version":1'));

      // Restore it into the (empty) target organization.
      final result = await adminApi.importOrganization(_targetOrgId, archive);
      expect(result['organization_id'], _targetOrgId);
    },
    tags: ['cross-component'],
    skip: shouldSkip,
  );
}
