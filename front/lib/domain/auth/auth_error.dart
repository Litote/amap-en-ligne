/// Provider-agnostic error code surfaced by `AuthService`. Implementations
/// (GoTrue, Cognito, …) are responsible for mapping their native error shapes
/// to one of these values so the UI layer never branches on the underlying
/// provider.
enum AuthError {
  invalidCredentials,
  network,
  unknown,
  userNotFound,
  invalidOrExpiredToken,
  weakPassword,
  samePassword,
}

class AuthException implements Exception {
  const AuthException(this.error, [this.message]);

  final AuthError error;
  final String? message;

  @override
  String toString() => 'AuthException($error, $message)';
}
