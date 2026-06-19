import 'dart:async';

import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';

/// Tokens we hold after a successful sign-in / refresh against Cognito. We
/// intentionally do not carry the SDK's `CognitoUserSession` past this
/// boundary so the rest of the app stays decoupled from
/// `amazon_cognito_identity_dart_2`.
class CognitoSessionTokens {
  const CognitoSessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
}

/// Thin wrapper around Cognito SDK calls. Lets `CognitoAuthService` stay
/// SDK-agnostic and lets tests inject a fake without instantiating a real
/// `CognitoUserPool`.
abstract class CognitoSessionGateway {
  Future<CognitoSessionTokens> signIn({
    required String email,
    required String password,
  });

  Future<CognitoSessionTokens> refresh(String refreshToken);

  Future<void> requestPasswordReset({required String email});

  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  });
}

/// Production gateway driving the real Cognito SDK. Uses
/// `USER_PASSWORD_AUTH` (plain username/password) — the user pool must
/// allow `ALLOW_USER_PASSWORD_AUTH` on its app client. SRP is harder to
/// run on web and brings nothing here since the connection is HTTPS.
class CognitoUserPoolGateway implements CognitoSessionGateway {
  CognitoUserPoolGateway({required this.userPool});

  final CognitoUserPool userPool;

  @override
  Future<CognitoSessionTokens> signIn({
    required String email,
    required String password,
  }) async {
    final user = CognitoUser(email, userPool, storage: userPool.storage)
      ..authenticationFlowType = 'USER_PASSWORD_AUTH';
    final session = await user.authenticateUser(
      AuthenticationDetails(username: email, password: password),
    );
    return _toTokens(session);
  }

  @override
  Future<CognitoSessionTokens> refresh(String refreshToken) async {
    // Cognito's REFRESH_TOKEN_AUTH flow does not require the original
    // username — it only takes the refresh token + client id. We still
    // need a `CognitoUser` instance to call `refreshSession()` though.
    final user = CognitoUser('refresh', userPool, storage: userPool.storage);
    final session = await user.refreshSession(
      CognitoRefreshToken(refreshToken),
    );
    return _toTokens(session);
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    final user = CognitoUser(email, userPool, storage: userPool.storage);
    await user.forgotPassword();
  }

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final user = CognitoUser(email, userPool, storage: userPool.storage);
    await user.confirmPassword(token, newPassword);
  }

  CognitoSessionTokens _toTokens(CognitoUserSession? session) {
    if (session == null) {
      throw const AuthException(AuthError.unknown, 'null session');
    }
    final accessToken = session.getAccessToken().getJwtToken();
    final refreshToken = session.getRefreshToken()?.getToken();
    if (accessToken == null || refreshToken == null) {
      throw const AuthException(AuthError.unknown, 'missing tokens');
    }
    final expSeconds = session.getAccessToken().getExpiration();
    return CognitoSessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        expSeconds * 1000,
        isUtc: true,
      ),
    );
  }
}

/// `AuthService` backed by AWS Cognito.
///
/// Sends the **access token** on `Authorization: Bearer …` — Cognito's
/// `CognitoAuthenticationService.kt:91` rejects any token whose
/// `token_use` claim is not `"access"`, so we never use the idToken even
/// though the SDK exposes it.
///
/// `producerId == sub` by invariant — the JWT `sub` is the stable user
/// identifier. The real `organizationId` for non-producer users is
/// resolved from the database by `AuthBloc` after bootstrap.
class CognitoAuthService implements AuthService {
  CognitoAuthService({required this.gateway, required this.storage});

  static const _refreshSkew = Duration(seconds: 30);

  final CognitoSessionGateway gateway;
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
    final CognitoSessionTokens tokens;
    try {
      tokens = await gateway.signIn(email: email, password: password);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw _mapSdkError(e);
    }
    final session = _toStoredSession(tokens);
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
    // We do not call Cognito's GlobalSignOut today — local clear is enough
    // for this app's threat model. Adding remote revoke means storing the
    // username and is best done together with refresh-token rotation.
    await _signOutLocal();
  }

  @override
  Future<String?> currentAccessToken() async {
    final session = _session;
    if (session == null) return null;
    if (_isExpiringSoon(session)) {
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
    final CognitoSessionTokens tokens;
    try {
      tokens = await gateway.refresh(session.refreshToken);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw _mapSdkError(e);
    }
    final refreshed = _toStoredSession(tokens);
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
      return JwtClaims.decode(accessToken).stringList('cognito:groups');
    } catch (_) {
      return [];
    }
  }

  StoredSession _toStoredSession(CognitoSessionTokens tokens) {
    final claims = JwtClaims.decode(tokens.accessToken);

    // For admin/coordinator/volunteer users, custom:organization_id is the tenant key.
    // For producer users, custom:organization_id is absent and sub is the producerId.
    final organizationId =
        claims.nestedString('custom:organization_id') ??
        claims.string('organization_id');
    final producerId = organizationId ?? claims.string('sub');
    if (producerId == null) {
      throw const AuthException(
        AuthError.unknown,
        'access token has no sub or organization_id claim',
      );
    }
    return StoredSession(
      producerId: producerId,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
    );
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    String? redirectTo,
  }) async {
    try {
      await gateway.requestPasswordReset(email: email);
    } on AuthException {
      rethrow;
    } catch (e) {
      // UserNotFoundException: swallow silently to prevent user enumeration.
      if (e is CognitoClientException && e.code == 'UserNotFoundException') {
        return;
      }
      throw _mapSdkError(e);
    }
  }

  @override
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  }) {
    throw const AuthException(
      AuthError.unknown,
      'updatePassword not supported for Cognito',
    );
  }

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await gateway.confirmPasswordReset(
        email: email,
        token: token,
        newPassword: newPassword,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw _mapPasswordResetError(e);
    }
  }

  @override
  Future<void> signInWithSession({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
    bool? rememberSession,
  }) {
    throw const AuthException(
      AuthError.unknown,
      'signInWithSession not supported for Cognito — use signIn',
    );
  }

  AuthException _mapPasswordResetError(Object error) {
    if (error is CognitoClientException) {
      switch (error.code) {
        case 'CodeMismatchException':
        case 'ExpiredCodeException':
          return const AuthException(AuthError.invalidOrExpiredToken);
        case 'InvalidPasswordException':
          return const AuthException(AuthError.weakPassword);
      }
      if (error.statusCode == null) {
        return const AuthException(AuthError.network);
      }
    }
    return AuthException(AuthError.unknown, error.toString());
  }

  AuthException _mapSdkError(Object error) {
    if (error is CognitoClientException) {
      switch (error.code) {
        case 'NotAuthorizedException':
        case 'UserNotFoundException':
        case 'UserNotConfirmedException':
          return const AuthException(AuthError.invalidCredentials);
      }
      // Cognito uses statusCode null for transport-level errors (DNS,
      // timeout). The SDK maps them to its own client exceptions.
      if (error.statusCode == null) {
        return const AuthException(AuthError.network);
      }
    }
    return AuthException(AuthError.unknown, error.toString());
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
