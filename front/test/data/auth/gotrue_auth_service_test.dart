import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/gotrue_auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

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

/// Forges a GoTrue-shaped access token. The front decodes the payload
/// without verifying the signature, so the header/signature segments can
/// be anything — only the payload matters.
String _accessToken({
  required String sub,
  String? organizationId,
  List<String>? roles,
}) {
  String b64(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final header = b64({'alg': 'HS256', 'typ': 'JWT'});
  final appMetadata = <String, Object?>{
    'organization_id': ?organizationId,
    'roles': ?roles,
  };
  final payload = b64({
    'sub': sub,
    if (appMetadata.isNotEmpty) 'app_metadata': appMetadata,
  });
  return '$header.$payload.sig';
}

Map<String, Object?> _tokenResponse({
  String sub = 'user-1',
  String? organizationId,
  List<String>? roles,
  String? accessToken,
  String refreshToken = 'refresh-1',
  int expiresIn = 3600,
}) => {
  'access_token':
      accessToken ??
      _accessToken(sub: sub, organizationId: organizationId, roles: roles),
  'refresh_token': refreshToken,
  'expires_in': expiresIn,
};

Response<Map<String, Object?>> _ok(Map<String, Object?> data) => Response(
  requestOptions: RequestOptions(path: '/token'),
  statusCode: 200,
  data: data,
);

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  late _MockDio dio;
  late _InMemoryStorage storage;
  late GoTrueAuthService service;

  setUp(() {
    dio = _MockDio();
    storage = _InMemoryStorage();
    service = GoTrueAuthService(dio: dio, storage: storage);
  });

  tearDown(() async {
    await service.dispose();
  });

  test('signIn success → state Authenticated and session persisted', () async {
    // producerAccountId == sub by invariant; sub defaults to 'user-1'.
    when(
      () => dio.post<Map<String, Object?>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => _ok(_tokenResponse(sub: 'producer-7')));

    await service.signIn(email: 'a@b.c', password: 'secret-pw');

    final state = service.currentState as Authenticated;
    expect(state.producerId, 'producer-7');
    final stored = await storage.read();
    expect(stored, isNotNull);
    expect(stored!.producerId, 'producer-7');
    expect(stored.refreshToken, 'refresh-1');
  });

  test('signIn forwards rememberSession to storage', () async {
    when(
      () => dio.post<Map<String, Object?>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => _ok(_tokenResponse()));

    await service.signIn(
      email: 'a@b.c',
      password: 'secret-pw',
      rememberSession: false,
    );

    expect(storage.lastDurable, isFalse);
  });

  test(
    'signIn uses sub as producerAccountId (producerAccountId == sub invariant)',
    () async {
      when(
        () => dio.post<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => _ok(_tokenResponse(sub: 'sub-1')));

      await service.signIn(email: 'a@b.c', password: 'pw');

      expect((service.currentState as Authenticated).producerId, 'sub-1');
    },
  );

  test(
    'signIn uses organization_id as tenant key for admin/coordinator/volunteer',
    () async {
      // JWT for an ADMIN user: has organization_id (no producer_account_id claim exists).
      final adminToken = _accessToken(
        sub: 'admin-sub-uuid',
        organizationId: 'amap-dev',
        roles: ['ADMIN'],
      );
      when(
        () => dio.post<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async =>
            _ok(_tokenResponse(sub: 'admin-sub-uuid', accessToken: adminToken)),
      );

      await service.signIn(email: 'admin@example.com', password: 'pass1234');

      expect(
        (service.currentState as Authenticated).producerId,
        'amap-dev',
        reason:
            'organization_id should be used as tenant key for admin users '
            'so that _requireTenant() returns the correct organizationId '
            'for /admin/* screens',
      );
    },
  );

  test(
    'signIn 400 → throws invalidCredentials, state stays Unauthenticated',
    () async {
      when(
        () => dio.post<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/token'),
          response: Response(
            requestOptions: RequestOptions(path: '/token'),
            statusCode: 400,
          ),
          type: DioExceptionType.badResponse,
        ),
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
    },
  );

  test('signIn connection error → throws network', () async {
    when(
      () => dio.post<Map<String, Object?>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/token'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(
      () => service.signIn(email: 'a@b.c', password: 'pw'),
      throwsA(
        isA<AuthException>().having((e) => e.error, 'error', AuthError.network),
      ),
    );
  });

  test('bootstrap with stored fresh session → emits Authenticated', () async {
    await storage.write(
      StoredSession(
        producerId: 'u1',
        accessToken: 'at',
        refreshToken: 'rt',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
    );

    await service.bootstrap();

    expect(
      service.currentState,
      const AuthState.authenticated(producerId: 'u1', accessToken: 'at'),
    );
  });

  test(
    'bootstrap with expired stored session → refreshes and emits Authenticated',
    () async {
      await storage.write(
        StoredSession(
          producerId: 'u1',
          accessToken: 'old-at',
          refreshToken: 'old-rt',
          expiresAt: DateTime.now().toUtc().subtract(
            const Duration(seconds: 5),
          ),
        ),
      );
      final freshAt = _accessToken(sub: 'u1');
      when(
        () => dio.post<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _ok(
          _tokenResponse(
            sub: 'u1',
            accessToken: freshAt,
            refreshToken: 'fresh-rt',
          ),
        ),
      );

      await service.bootstrap();

      expect(
        service.currentState,
        AuthState.authenticated(producerId: 'u1', accessToken: freshAt),
      );
      final stored = await storage.read();
      expect(stored!.accessToken, freshAt);
      expect(stored.refreshToken, 'fresh-rt');
    },
  );

  test(
    'bootstrap refresh failure → state Unauthenticated and storage cleared',
    () async {
      await storage.write(
        StoredSession(
          producerId: 'u1',
          accessToken: 'old-at',
          refreshToken: 'old-rt',
          expiresAt: DateTime.now().toUtc().subtract(
            const Duration(seconds: 5),
          ),
        ),
      );
      when(
        () => dio.post<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/token'),
          type: DioExceptionType.connectionError,
        ),
      );

      await service.bootstrap();

      expect(service.currentState, const AuthState.unauthenticated());
      expect(await storage.read(), isNull);
    },
  );

  test(
    'two concurrent currentAccessToken calls share one refresh and both return the fresh token',
    () async {
      // Sign in with an immediately-expired session so both callers detect
      // _isExpiringSoon and join the in-flight refresh.
      when(
        () => dio.post<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => _ok(_tokenResponse(expiresIn: 0)));
      await service.signIn(email: 'a@b.c', password: 'pw');

      // Block the next network call with a Completer so both concurrent
      // currentAccessToken() calls pile up on the same in-flight future.
      final refreshCompleter = Completer<Response<Map<String, Object?>>>();
      final freshAt = _accessToken(sub: 'u1');
      when(
        () => dio.post<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) => refreshCompleter.future);

      final token1Future = service.currentAccessToken();
      final token2Future = service.currentAccessToken();

      refreshCompleter.complete(
        _ok(
          _tokenResponse(
            sub: 'u1',
            accessToken: freshAt,
            refreshToken: 'new-rt',
          ),
        ),
      );

      expect(await token1Future, freshAt);
      expect(await token2Future, freshAt);
    },
  );

  test(
    'signIn with roles in app_metadata → roles in Authenticated state',
    () async {
      when(
        () => dio.post<Map<String, Object?>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _ok(_tokenResponse(sub: 'owner-sub', roles: ['OWNER'])),
      );

      await service.signIn(email: 'a@b.c', password: 'secret-pw');

      final state = service.currentState as Authenticated;
      expect(state.roles, ['OWNER']);
    },
  );

  test('signIn with no roles → empty roles in Authenticated state', () async {
    when(
      () => dio.post<Map<String, Object?>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => _ok(_tokenResponse()));

    await service.signIn(email: 'a@b.c', password: 'secret-pw');

    final state = service.currentState as Authenticated;
    expect(state.roles, isEmpty);
  });

  test('requestPasswordReset → calls POST /recover', () async {
    when(() => dio.post<void>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/recover'),
        statusCode: 200,
      ),
    );

    await service.requestPasswordReset(email: 'a@b.c');

    verify(
      () => dio.post<void>('/recover', data: any(named: 'data')),
    ).called(1);
  });

  test('requestPasswordReset network error → throws network', () async {
    when(() => dio.post<void>(any(), data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/recover'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(
      () => service.requestPasswordReset(email: 'a@b.c'),
      throwsA(
        isA<AuthException>().having((e) => e.error, 'error', AuthError.network),
      ),
    );
  });

  test(
    'confirmPasswordReset success → calls /verify then PUT /user, emits Authenticated',
    () async {
      final recoveryAt = _accessToken(sub: 'u1');

      when(
        () =>
            dio.post<Map<String, Object?>>('/verify', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/verify'),
          statusCode: 200,
          data: {
            'access_token': recoveryAt,
            'refresh_token': 'recovery-rt',
            'expires_in': 3600,
          },
        ),
      );
      when(
        () => dio.put<void>(
          '/user',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/user'),
          statusCode: 200,
        ),
      );

      await service.confirmPasswordReset(
        email: 'a@b.c',
        token: 'otp-token',
        newPassword: 'newpass123',
      );

      verify(
        () =>
            dio.post<Map<String, Object?>>('/verify', data: any(named: 'data')),
      ).called(1);
      verify(
        () => dio.put<void>(
          '/user',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);

      // Auto-login: after successful reset the user is now Authenticated.
      final state = service.currentState as Authenticated;
      expect(state.producerId, 'u1');
      final stored = await storage.read();
      expect(stored, isNotNull);
      expect(stored!.refreshToken, 'recovery-rt');
    },
  );

  test(
    'signInWithSession success → persists session and emits Authenticated',
    () async {
      // producerAccountId == sub by invariant.
      final at = _accessToken(sub: 'u2');

      await service.signInWithSession(
        accessToken: at,
        refreshToken: 'rt-2',
        expiresIn: 3600,
      );

      final state = service.currentState as Authenticated;
      expect(state.producerId, 'u2');
      expect(state.accessToken, at);
      final stored = await storage.read();
      expect(stored, isNotNull);
      expect(stored!.refreshToken, 'rt-2');
    },
  );

  test(
    'signInWithSession updates currentState and persists to storage',
    () async {
      // producerAccountId == sub by invariant.
      final at = _accessToken(sub: 'u3');

      await service.signInWithSession(accessToken: at, refreshToken: 'rt-3');

      // currentState reflects the new session immediately.
      final state = service.currentState as Authenticated;
      expect(state.producerId, 'u3');

      // Storage is updated.
      final stored = await storage.read();
      expect(stored, isNotNull);
      expect(stored!.accessToken, at);
      expect(stored.refreshToken, 'rt-3');
    },
  );

  test(
    'confirmPasswordReset 422 on /verify → throws invalidOrExpiredToken',
    () async {
      when(
        () =>
            dio.post<Map<String, Object?>>('/verify', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/verify'),
          response: Response(
            requestOptions: RequestOptions(path: '/verify'),
            statusCode: 422,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => service.confirmPasswordReset(
          email: 'a@b.c',
          token: 'bad-token',
          newPassword: 'newpass',
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

  test('confirmPasswordReset 422 on PUT /user → throws weakPassword', () async {
    final recoveryAt = _accessToken(sub: 'u1');

    when(
      () => dio.post<Map<String, Object?>>('/verify', data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/verify'),
        statusCode: 200,
        data: {
          'access_token': recoveryAt,
          'refresh_token': 'rt',
          'expires_in': 3600,
        },
      ),
    );
    when(
      () => dio.put<void>(
        '/user',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/user'),
        response: Response(
          requestOptions: RequestOptions(path: '/user'),
          statusCode: 422,
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => service.confirmPasswordReset(
        email: 'a@b.c',
        token: 'valid-token',
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
  });

  test('signOut clears state and calls /logout', () async {
    when(
      () => dio.post<Map<String, Object?>>(
        '/token',
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => _ok(_tokenResponse()));
    await service.signIn(email: 'a@b.c', password: 'pw');

    when(
      () => dio.post<void>('/logout', options: any(named: 'options')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/logout'),
        statusCode: 204,
      ),
    );

    await service.signOut();

    expect(service.currentState, const AuthState.unauthenticated());
    expect(await storage.read(), isNull);
    verify(
      () => dio.post<void>('/logout', options: any(named: 'options')),
    ).called(1);
  });
}
