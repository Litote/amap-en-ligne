import 'dart:convert';

import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Parses the `auth` block of the back's discovery document.
///
/// The back emits:
/// ```json
/// // GoTrue:
/// { "kind": "gotrue", "base_url": "https://..." }
/// // Cognito:
/// { "kind": "cognito", "issuer_url": "https://...", "client_id": "..." }
/// ```
///
/// This differs from `ServerDiscoveryDocument` (which uses a richer schema
/// designed for the federated multi-server catalog). This file parses the
/// actual back wire format directly.
ServerConfig? _parseDiscoveryResponse(
  String origin,
  Map<String, dynamic> json,
) {
  final name = json['name'] as String? ?? origin;
  final apiUrl = json['api_url'] as String?;
  if (apiUrl == null || apiUrl.isEmpty) {
    return null;
  }
  final auth = json['auth'] as Map<String, dynamic>?;
  if (auth == null) {
    return null;
  }
  final kind = auth['kind'] as String?;
  switch (kind) {
    case 'gotrue':
      final gotrueUrl = auth['base_url'] as String?;
      if (gotrueUrl == null || gotrueUrl.isEmpty) {
        return null;
      }
      return GoTrueServerConfig(
        id: origin,
        name: name,
        backendUrl: apiUrl,
        gotrueUrl: gotrueUrl,
        discoveryUrl: '$origin/.well-known/amap-en-ligne.json',
      );
    case 'cognito':
      final issuerUrl = auth['issuer_url'] as String?;
      final clientId = auth['client_id'] as String?;
      if (issuerUrl == null ||
          issuerUrl.isEmpty ||
          clientId == null ||
          clientId.isEmpty) {
        return null;
      }
      // Derive region from Cognito issuer URL:
      // https://cognito-idp.<region>.amazonaws.com/<pool-id>
      // Extract pool id as-is; region and pool id are both needed.
      final issuerUri = Uri.tryParse(issuerUrl);
      final pathSegments =
          issuerUri?.pathSegments.where((s) => s.isNotEmpty).toList() ?? [];
      final userPoolId = pathSegments.isNotEmpty ? pathSegments.last : '';
      // Region is the second label of the Cognito IdP hostname.
      final hostParts = issuerUri?.host.split('.') ?? [];
      // cognito-idp.<region>.amazonaws.com → index 1
      final region = hostParts.length >= 3 ? hostParts[1] : 'us-east-1';
      if (userPoolId.isEmpty) {
        return null;
      }
      return CognitoServerConfig(
        id: origin,
        name: name,
        backendUrl: apiUrl,
        userPoolId: userPoolId,
        clientId: clientId,
        region: region,
        discoveryUrl: '$origin/.well-known/amap-en-ligne.json',
      );
    default:
      return null;
  }
}

/// On web, fetches `{origin}/.well-known/amap-en-ligne.json` and parses it
/// into a [ServerConfig]. Returns `null` on any failure (network error, parse
/// error, unknown auth kind, …) so the caller can fall back to the preset list.
///
/// This function is a no-op (returns `null`) on non-web platforms.
Future<ServerConfig?> tryWebDiscovery() async {
  if (!kIsWeb) {
    return null;
  }
  final origin = Uri.base.origin;
  final discoveryUrl = '$origin/.well-known/amap-en-ligne.json';
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    final response = await dio.get<dynamic>(discoveryUrl);
    final data = response.data;
    final Map<String, dynamic> json;
    if (data is Map<String, dynamic>) {
      json = data;
    } else if (data is String) {
      json = jsonDecode(data) as Map<String, dynamic>;
    } else {
      return null;
    }
    return _parseDiscoveryResponse(origin, json);
  } on DioException {
    // Network failure or missing document (404) — degrade gracefully, no noise.
    return null;
  } catch (e, s) {
    // Unexpected parse or type error — the discovery document has an unknown
    // format; the server is unaware of this client-side failure.
    await Sentry.captureException(e, stackTrace: s);
    return null;
  }
}
