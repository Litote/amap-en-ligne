import 'dart:convert';

import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/cognito_auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryStorage implements AuthTokenStorage {
  StoredSession? _value;
  bool? lastDurable;

  @override
  Future<StoredSession?> read() async => _value;

  @override
  Future<void> write(StoredSession session, {bool? durable}) async {
    _value = session;
    lastDurable = durable;
  }

  @override
  Future<void> clear() async => _value = null;
}

class _StubGateway implements CognitoSessionGateway {
  CognitoSessionTokens? signInResult;
  CognitoSessionTokens? refreshResult;
  Object? error;
  Object? passwordResetError;
  int signInCalls = 0;
  int refreshCalls = 0;
  int requestPasswordResetCalls = 0;
  int confirmPasswordResetCalls = 0;

  @override
  Future<CognitoSessionTokens> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    if (error != null) throw error!;
    return signInResult!;
  }

  @override
  Future<CognitoSessionTokens> refresh(String refreshToken) async {
    refreshCalls++;
    if (error != null) throw error!;
    return refreshResult!;
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    requestPasswordResetCalls++;
    if (passwordResetError != null) throw passwordResetError!;
  }

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    confirmPasswordResetCalls++;
    if (passwordResetError != null) throw passwordResetError!;
  }
}

String _accessToken({required String sub, String? organizationId}) {
  String b64(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final payload = b64({
    'sub': sub,
    ...?organizationId == null
        ? null
        : {'custom:organization_id': organizationId},
  });
  return '${b64({'alg': 'none'})}.$payload.sig';
}

CognitoSessionTokens _tokens({
  String? sub,
  String? organizationId,
  String accessToken = '',
  String refreshToken = 'rt',
  Duration expiresIn = const Duration(hours: 1),
}) => CognitoSessionTokens(
  accessToken: accessToken.isNotEmpty
      ? accessToken
      : _accessToken(sub: sub ?? 'u', organizationId: organizationId),
  refreshToken: refreshToken,
  expiresAt: DateTime.now().toUtc().add(expiresIn),
);

void main() {
  late _StubGateway gateway;
  late _InMemoryStorage storage;
  late CognitoAuthService service;

  setUp(() {
    gateway = _StubGateway();
    storage = _InMemoryStorage();
    service = CognitoAuthService(gateway: gateway, storage: storage);
  });

  tearDown(() async => service.dispose());

  test('signIn success → state Authenticated and session persisted', () async {
    // producerAccountId == sub by invariant.
    gateway.signInResult = _tokens(sub: 'pa-1');

    await service.signIn(email: 'a@b.c', password: 'pw');

    expect((service.currentState as Authenticated).producerId, 'pa-1');
    expect((await storage.read())!.producerId, 'pa-1');
  });

  test('signIn forwards rememberSession to storage', () async {
    gateway.signInResult = _tokens(sub: 'pa-1');

    await service.signIn(
      email: 'a@b.c',
      password: 'pw',
      rememberSession: false,
    );

    expect(storage.lastDurable, isFalse);
  });

  test(
    'signIn uses sub as producerAccountId (producerAccountId == sub invariant)',
    () async {
      gateway.signInResult = _tokens(sub: 'u-1');

      await service.signIn(email: 'a@b.c', password: 'pw');

      expect((service.currentState as Authenticated).producerId, 'u-1');
    },
  );

  test(
    'signIn uses custom:organization_id as tenant key for admin/coordinator/volunteer',
    () async {
      // JWT for an ADMIN user: has organization_id (no producer_account_id claim exists).
      gateway.signInResult = _tokens(
        sub: 'admin-sub-uuid',
        accessToken: _accessToken(
          sub: 'admin-sub-uuid',
          organizationId: 'amap-dev',
        ),
      );

      await service.signIn(email: 'admin@example.com', password: 'pass1234');

      expect(
        (service.currentState as Authenticated).producerId,
        'amap-dev',
        reason:
            'custom:organization_id should be used as tenant key for admin '
            'users so that _requireTenant() returns the correct organizationId',
      );
    },
  );

  test('signIn maps NotAuthorizedException to invalidCredentials', () async {
    gateway.error = CognitoClientException(
      'wrong',
      code: 'NotAuthorizedException',
      statusCode: 400,
    );

    expect(
      () => service.signIn(email: 'a@b.c', password: 'wrong'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.error,
          'error',
          AuthError.invalidCredentials,
        ),
      ),
    );
    expect(service.currentState, const AuthState.unauthenticated());
  });

  test('signIn maps SDK transport error (no statusCode) to network', () async {
    gateway.error = CognitoClientException('boom');

    expect(
      () => service.signIn(email: 'a@b.c', password: 'pw'),
      throwsA(
        isA<AuthException>().having((e) => e.error, 'error', AuthError.network),
      ),
    );
  });

  test(
    'bootstrap with expired stored session triggers refresh and emits Authenticated',
    () async {
      await storage.write(
        StoredSession(
          producerId: 'pa-1',
          accessToken: 'old',
          refreshToken: 'old-rt',
          expiresAt: DateTime.now().toUtc().subtract(
            const Duration(seconds: 5),
          ),
        ),
      );
      gateway.refreshResult = _tokens(sub: 'pa-1');

      await service.bootstrap();

      expect(gateway.refreshCalls, 1);
      expect((service.currentState as Authenticated).producerId, 'pa-1');
    },
  );

  test(
    'bootstrap refresh failure → state Unauthenticated and storage cleared',
    () async {
      await storage.write(
        StoredSession(
          producerId: 'pa-1',
          accessToken: 'old',
          refreshToken: 'old-rt',
          expiresAt: DateTime.now().toUtc().subtract(
            const Duration(seconds: 5),
          ),
        ),
      );
      gateway.error = CognitoClientException(
        'expired',
        code: 'NotAuthorizedException',
        statusCode: 400,
      );

      await service.bootstrap();

      expect(service.currentState, const AuthState.unauthenticated());
      expect(await storage.read(), isNull);
    },
  );

  test('requestPasswordReset success → gateway called once', () async {
    await service.requestPasswordReset(email: 'a@b.c');

    expect(gateway.requestPasswordResetCalls, 1);
  });

  test(
    'requestPasswordReset UserNotFoundException → swallowed (no throw)',
    () async {
      gateway.passwordResetError = CognitoClientException(
        'user not found',
        code: 'UserNotFoundException',
        statusCode: 400,
      );

      await expectLater(
        service.requestPasswordReset(email: 'unknown@b.c'),
        completes,
      );
    },
  );

  test('requestPasswordReset network error → throws network', () async {
    gateway.passwordResetError = CognitoClientException('boom');

    expect(
      () => service.requestPasswordReset(email: 'a@b.c'),
      throwsA(
        isA<AuthException>().having((e) => e.error, 'error', AuthError.network),
      ),
    );
  });

  test('confirmPasswordReset success → gateway called once', () async {
    await service.confirmPasswordReset(
      email: 'a@b.c',
      token: '123456',
      newPassword: 'newpass123',
    );

    expect(gateway.confirmPasswordResetCalls, 1);
  });

  test(
    'confirmPasswordReset CodeMismatchException → throws invalidOrExpiredToken',
    () async {
      gateway.passwordResetError = CognitoClientException(
        'code mismatch',
        code: 'CodeMismatchException',
        statusCode: 400,
      );

      expect(
        () => service.confirmPasswordReset(
          email: 'a@b.c',
          token: 'wrong',
          newPassword: 'newpass123',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.error,
            'error',
            AuthError.invalidOrExpiredToken,
          ),
        ),
      );
    },
  );

  test(
    'confirmPasswordReset InvalidPasswordException → throws weakPassword',
    () async {
      gateway.passwordResetError = CognitoClientException(
        'weak password',
        code: 'InvalidPasswordException',
        statusCode: 400,
      );

      expect(
        () => service.confirmPasswordReset(
          email: 'a@b.c',
          token: '123456',
          newPassword: 'weak',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.error,
            'error',
            AuthError.weakPassword,
          ),
        ),
      );
    },
  );

  test('signOut clears local session', () async {
    gateway.signInResult = _tokens(sub: 'pa-1');
    await service.signIn(email: 'a@b.c', password: 'pw');

    await service.signOut();

    expect(service.currentState, const AuthState.unauthenticated());
    expect(await storage.read(), isNull);
  });
}
