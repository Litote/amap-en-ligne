import 'dart:convert';

import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:flutter_test/flutter_test.dart';

String _forge(Map<String, Object?> payload) {
  String b64(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${b64({'alg': 'none'})}.${b64(payload)}.sig';
}

void main() {
  test('decodes top-level string claim', () {
    final c = JwtClaims.decode(_forge({'sub': 'abc'}));
    expect(c.string('sub'), 'abc');
  });

  test('returns null for missing claim', () {
    final c = JwtClaims.decode(_forge({'sub': 'abc'}));
    expect(c.string('email'), isNull);
    expect(c.nestedString('app_metadata.organization_id'), isNull);
  });

  test('reads nested dotted path', () {
    final c = JwtClaims.decode(
      _forge({
        'app_metadata': {'organization_id': 'org-1'},
      }),
    );
    expect(c.nestedString('app_metadata.organization_id'), 'org-1');
  });

  test('non-map intermediate is treated as a miss, never throws', () {
    final c = JwtClaims.decode(_forge({'app_metadata': 'oops'}));
    expect(c.nestedString('app_metadata.organization_id'), isNull);
  });

  test('reads Cognito custom: prefixed claim as a top-level string', () {
    // Cognito flattens custom attributes onto the access token as
    // `custom:<name>` keys (no nesting), so `string()` is the right reader.
    final c = JwtClaims.decode(_forge({'custom:organization_id': 'org-2'}));
    expect(c.string('custom:organization_id'), 'org-2');
  });

  test('throws FormatException on malformed token', () {
    expect(
      () => JwtClaims.decode('not-a-jwt'),
      throwsA(isA<FormatException>()),
    );
  });
}
