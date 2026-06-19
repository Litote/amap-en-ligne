import 'dart:convert';

/// Decodes the **payload** of a JWT without verifying the signature.
///
/// Verification is the back's responsibility — both `CognitoAuthenticationService`
/// (RS256 against JWKS) and `GoTrueAuthenticationService` (HS256 with shared
/// secret) reject malformed or unsigned tokens. The front only ever decodes
/// claims it can trust transitively: any token that reaches us came from a
/// successful sign-in or refresh call against the configured provider.
///
/// After the `producerAccountId == sub` invariant was established on the back,
/// the auth services derive the tenant id directly from `sub`. Other claims
/// (roles, organization_id) are still read from the token payload.
class JwtClaims {
  const JwtClaims(this._claims);

  final Map<String, Object?> _claims;

  /// Decodes the payload segment of [token]. Throws [FormatException] if
  /// the token is structurally invalid; signature is **not** checked.
  factory JwtClaims.decode(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      throw const FormatException('JWT must have at least 2 segments');
    }
    final payload = parts[1];
    final padded = payload.padRight((payload.length + 3) & ~3, '=');
    final bytes = base64Url.decode(padded);
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('JWT payload must be a JSON object');
    }
    return JwtClaims(decoded);
  }

  String? string(String key) => _claims[key] as String?;

  /// Reads a nested string at `dotted.path`. Treats anything that isn't a
  /// `Map<String, Object?>` along the way as a miss — never throws.
  /// Reads a nested string at `dotted.path`. Treats anything that isn't a
  /// `Map<String, Object?>` along the way as a miss — never throws.
  String? nestedString(String dottedPath) {
    final segments = dottedPath.split('.');
    Object? cursor = _claims;
    for (final segment in segments) {
      if (cursor is! Map<String, Object?>) return null;
      cursor = cursor[segment];
    }
    return cursor is String ? cursor : null;
  }

  /// Reads a top-level `List<String>` at [key]. Returns an empty list on any
  /// miss or type mismatch — never throws.
  List<String> stringList(String key) {
    final value = _claims[key];
    if (value is List) return value.whereType<String>().toList();
    return [];
  }

  /// Reads a nested `List<String>` at `dotted.path`. Returns an empty list on
  /// any miss or type mismatch — never throws.
  List<String> nestedStringList(String dottedPath) {
    final segments = dottedPath.split('.');
    Object? cursor = _claims;
    for (final segment in segments) {
      if (cursor is! Map<String, Object?>) return [];
      cursor = cursor[segment];
    }
    if (cursor is List) return cursor.whereType<String>().toList();
    return [];
  }
}
