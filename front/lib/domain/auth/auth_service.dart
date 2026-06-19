import 'package:amap_en_ligne/domain/auth/auth_state.dart';

/// Provider-agnostic authentication contract. Concrete implementations live
/// under `data/auth/` (currently GoTrue; Cognito to follow). The dio
/// interceptor calls `currentAccessToken()` on every request, so any
/// implementation must keep this fast and synchronous-feeling (cached value).
///
/// Throwing [AuthException] from `signIn` is the only failure channel — the
/// stream re-emits `Unauthenticated` for any post-bootstrap failure (e.g.
/// refresh failed) and stays silent on transient errors.
abstract class AuthService {
  /// Reactive session state. Always emits the current value to new
  /// subscribers (broadcast + replay-last semantics expected).
  Stream<AuthState> get authState;

  /// Snapshot of the latest emitted state. Useful for synchronous reads
  /// (e.g. router redirect, dio interceptor).
  AuthState get currentState;

  /// Restores the persisted session if any, otherwise emits
  /// `Unauthenticated`. Idempotent.
  Future<void> bootstrap();

  /// Authenticates against the provider. Updates `authState` to
  /// `Authenticated` on success, throws [AuthException] on failure (state
  /// stays `Unauthenticated`).
  Future<void> signIn({
    required String email,
    required String password,
    bool? rememberSession,
  });

  /// Clears the session locally (and best-effort remotely). Always emits
  /// `Unauthenticated` afterwards.
  Future<void> signOut();

  /// Latest access token, or `null` if no active session. Implementations
  /// may transparently refresh an expired token here.
  Future<String?> currentAccessToken();

  /// Sends a password-reset email to [email]. Returns normally whether or not
  /// the address is registered (prevents user enumeration). Throws
  /// [AuthException] only on network or provider errors.
  ///
  /// [redirectTo] is the URL GoTrue should redirect to after token
  /// verification. Cognito ignores this parameter.
  Future<void> requestPasswordReset({
    required String email,
    String? redirectTo,
  });

  /// Sets a new password using an access token obtained from a GoTrue
  /// recovery redirect. [accessToken] comes from the URL fragment
  /// (`#access_token=...&type=recovery`) after GoTrue's verification redirect.
  /// Throws [AuthException(AuthError.invalidOrExpiredToken)] if the token is
  /// invalid, [AuthException(AuthError.weakPassword)] if the password is weak.
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  });

  /// Exchanges the [token] from the recovery email and sets [newPassword].
  /// [email] is required by Cognito; GoTrue ignores it.
  /// Throws [AuthException(AuthError.invalidOrExpiredToken)] if the token is
  /// expired or invalid, [AuthException(AuthError.weakPassword)] if the new
  /// password does not meet the provider's strength requirements.
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  });

  /// Persists an already-verified session (access + refresh token) and emits
  /// [AuthState.authenticated]. Used after a password-reset flow that returns
  /// tokens directly (GoTrue recovery redirect, POST /verify response).
  /// Cognito throws [AuthException(AuthError.unknown)] — use [signIn] instead.
  Future<void> signInWithSession({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
    bool? rememberSession,
  });

  /// Forces an immediate token refresh and emits a new [AuthState.authenticated]
  /// with the latest claims (including updated roles). No-ops when unauthenticated.
  ///
  /// Used by [SyncBloc] after a sync detects that the current user's Member or
  /// Owner row was updated — roles may have changed server-side and a new access
  /// token is needed so menus and guarded routes reflect the new reality without
  /// requiring a logout/login cycle.
  Future<void> refreshSession();
}
