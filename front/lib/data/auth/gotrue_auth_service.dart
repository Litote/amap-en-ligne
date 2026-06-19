import 'dart:async';

import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:dio/dio.dart';

/// `AuthService` backed by self-hosted Supabase GoTrue.
///
/// Talks directly to GoTrue's REST API rather than pulling the full
/// `supabase_flutter` package — we only need email/password sign-in,
/// refresh-token rotation, and logout. The dio instance is provider-scoped
/// (different baseUrl from the back's sync API) and must not carry the
/// `Authorization` header set by the sync interceptor.
///
/// Token refresh is best-effort: `currentAccessToken()` refreshes when the
/// access token is within [_refreshSkew] of expiry. A failed refresh emits
/// `Unauthenticated` and clears storage — the user is bounced to /login.
class GoTrueAuthService implements AuthService {
  GoTrueAuthService({required this.dio, required this.storage});

  static const _refreshSkew = Duration(seconds: 30);

  final Dio dio;
  final AuthTokenStorage storage;

  final _controller = StreamController<AuthState>.broadcast();
  AuthState _current = const AuthState.unauthenticated();
  StoredSession? _session;
  Future<void>? _refreshInFlight;

  @override
  Stream<AuthState> get authState async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  AuthState get currentState => _current;

  @override
  Future<void> bootstrap() async {
    final stored = await storage.read();
    if (stored == null) {
      _emit(const AuthState.unauthenticated());
      return;
    }
    _session = stored;
    if (_isExpiringSoon(stored)) {
      try {
        await _refresh();
      } on AuthException {
        await _signOutLocal();
        return;
      }
    } else {
      _emit(
        AuthState.authenticated(
          producerId: stored.producerId,
          accessToken: stored.accessToken,
          roles: _extractRoles(stored.accessToken),
        ),
      );
    }
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
    bool? rememberSession,
  }) async {
    final Response<Map<String, Object?>> response;
    try {
      response = await dio.post<Map<String, Object?>>(
        '/token',
        queryParameters: {'grant_type': 'password'},
        data: {'email': email, 'password': password},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
    final data = response.data;
    if (data == null) {
      throw const AuthException(AuthError.unknown, 'empty response');
    }
    final session = _sessionFromJson(data);
    await storage.write(session, durable: rememberSession);
    _session = session;
    _emit(
      AuthState.authenticated(
        producerId: session.producerId,
        accessToken: session.accessToken,
        roles: _extractRoles(session.accessToken),
      ),
    );
  }

  @override
  Future<void> signOut() async {
    final token = _session?.accessToken;
    if (token != null) {
      try {
        await dio.post<void>(
          '/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } on DioException {
        // Best-effort — we always clear the local session below.
      }
    }
    await _signOutLocal();
  }

  @override
  Future<String?> currentAccessToken() async {
    final session = _session;
    if (session == null) return null;
    if (_isExpiringSoon(session) || _refreshInFlight != null) {
      try {
        await _refresh();
      } on AuthException {
        await _signOutLocal();
        return null;
      }
    }
    return _session?.accessToken;
  }

  Future<void> _refresh() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<void> _doRefresh() async {
    final session = _session;
    if (session == null) {
      throw const AuthException(AuthError.unknown, 'no session to refresh');
    }
    final Response<Map<String, Object?>> response;
    try {
      response = await dio.post<Map<String, Object?>>(
        '/token',
        queryParameters: {'grant_type': 'refresh_token'},
        data: {'refresh_token': session.refreshToken},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
    final data = response.data;
    if (data == null) {
      throw const AuthException(AuthError.unknown, 'empty refresh response');
    }
    final refreshed = _sessionFromJson(data);
    await storage.write(refreshed);
    _session = refreshed;
    _emit(
      AuthState.authenticated(
        producerId: refreshed.producerId,
        accessToken: refreshed.accessToken,
        roles: _extractRoles(refreshed.accessToken),
      ),
    );
  }

  Future<void> _signOutLocal() async {
    _session = null;
    await storage.clear();
    _emit(const AuthState.unauthenticated());
  }

  void _emit(AuthState state) {
    _current = state;
    _controller.add(state);
  }

  bool _isExpiringSoon(StoredSession session) {
    final now = DateTime.now().toUtc();
    return session.expiresAt.toUtc().isBefore(now.add(_refreshSkew));
  }

  List<String> _extractRoles(String accessToken) {
    try {
      return JwtClaims.decode(
        accessToken,
      ).nestedStringList('app_metadata.roles');
    } catch (_) {
      return [];
    }
  }

  /// Decodes GoTrace's `/token` response shape:
  /// `{ access_token, refresh_token, expires_in, expires_at, user: { id, ... } }`.
  ///
  /// For non-producer users (admin/coordinator/volunteer), the JWT carries
  /// `app_metadata.organization_id` as the tenant key. When present, it is used
  /// as the `producerId`. Otherwise, `producerId == sub` by invariant.
  StoredSession _sessionFromJson(Map<String, Object?> json) {
    final accessToken = json['access_token'] as String?;
    final refreshToken = json['refresh_token'] as String?;
    if (accessToken == null || refreshToken == null) {
      throw const AuthException(AuthError.unknown, 'malformed token response');
    }
    final claims = JwtClaims.decode(accessToken);

    // For admin/coordinator/volunteer users, organization_id is the tenant key.
    // For producer users, organization_id is absent and sub is the producerId.
    final organizationId = claims.nestedString('app_metadata.organization_id');
    final producerId = organizationId ?? claims.string('sub');
    if (producerId == null) {
      throw const AuthException(
        AuthError.unknown,
        'access token has no sub or organization_id claim',
      );
    }
    final expiresAt = _decodeExpiry(json);
    return StoredSession(
      producerId: producerId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  DateTime _decodeExpiry(Map<String, Object?> json) {
    final expiresAt = json['expires_at'];
    if (expiresAt is int) {
      return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true);
    }
    final expiresIn = json['expires_in'];
    if (expiresIn is int) {
      return DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    }
    // Conservative fallback — treat as already expired so we refresh ASAP.
    return DateTime.now().toUtc();
  }

  AuthException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 400 || status == 401) {
      return const AuthException(AuthError.invalidCredentials);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const AuthException(AuthError.network);
    }
    return AuthException(AuthError.unknown, e.message);
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    String? redirectTo,
  }) async {
    try {
      await dio.post<void>(
        redirectTo != null
            ? '/recover?redirect_to=${Uri.encodeQueryComponent(redirectTo)}'
            : '/recover',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  }) async {
    try {
      await dio.put<Object?>(
        '/user',
        data: {'password': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final body = e.response?.data;
        final msg = body is Map ? (body['msg'] as String? ?? '') : '';
        if (msg.toLowerCase().contains('different')) {
          throw const AuthException(AuthError.samePassword);
        }
        throw const AuthException(AuthError.weakPassword);
      }
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    // Step 1 — exchange the recovery token for a short-lived access token.
    final Response<Map<String, Object?>> verifyResponse;
    try {
      verifyResponse = await dio.post<Map<String, Object?>>(
        '/verify',
        data: {'type': 'recovery', 'token': token, 'email': email},
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 422) {
        throw const AuthException(AuthError.invalidOrExpiredToken);
      }
      throw _mapDioError(e);
    }
    final verifyData = verifyResponse.data;
    final recoveryAccessToken = verifyData?['access_token'] as String?;
    if (recoveryAccessToken == null) {
      throw const AuthException(AuthError.unknown, 'no recovery access token');
    }

    // Step 2 — set the new password with the recovery access token.
    try {
      await dio.put<void>(
        '/user',
        data: {'password': newPassword},
        options: Options(
          headers: {'Authorization': 'Bearer $recoveryAccessToken'},
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw const AuthException(AuthError.weakPassword);
      }
      throw _mapDioError(e);
    }

    // Step 3 — persist the session returned by POST /verify so the user is
    // automatically signed in after the password change.
    final refreshToken = verifyData?['refresh_token'] as String?;
    final expiresIn = verifyData?['expires_in'] as int?;
    if (refreshToken != null) {
      await signInWithSession(
        accessToken: recoveryAccessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
      );
    }
  }

  @override
  Future<void> signInWithSession({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
    bool? rememberSession,
  }) async {
    final session = _sessionFromJson({
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': ?expiresIn,
    });
    await storage.write(session, durable: rememberSession);
    _session = session;
    _emit(
      AuthState.authenticated(
        producerId: session.producerId,
        accessToken: session.accessToken,
        roles: _extractRoles(session.accessToken),
      ),
    );
  }

  @override
  Future<void> refreshSession() async {
    if (_session == null) return;
    try {
      await _refresh();
    } on AuthException {
      // Best-effort: if the refresh fails (e.g. network error), leave the
      // current session intact — the next scheduled refresh will retry.
    }
  }

  /// Tests can call this to release the broadcast controller.
  Future<void> dispose() async {
    await _controller.close();
  }
}
