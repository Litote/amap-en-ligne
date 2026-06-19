import 'package:amap_en_ligne/domain/server/auth_provider.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';

/// Public per-instance bootstrap document intended to be served by each
/// federated server under a well-known URL.
///
/// The document contains only client-safe bootstrap data: sync API location,
/// auth provider kind + public parameters, protocol version, and capability
/// flags. No secret belongs here.
final class ServerDiscoveryDocument {
  const ServerDiscoveryDocument({
    required this.instanceId,
    required this.displayName,
    required this.backendUrl,
    required this.discoveryUrl,
    required this.protocolVersion,
    required this.capabilities,
    required this.auth,
    this.termsUrl,
  });

  static const wellKnownPath = '/.well-known/amap-en-ligne.json';

  final String instanceId;
  final String displayName;
  final String backendUrl;
  final String discoveryUrl;
  final int protocolVersion;
  final List<String> capabilities;
  final ServerDiscoveryAuth auth;

  /// Optional URL pointing to the instance's terms of service page.
  final String? termsUrl;

  factory ServerDiscoveryDocument.fromJson(Map<String, dynamic> json) =>
      ServerDiscoveryDocument(
        instanceId: _readString(json, 'instance_id'),
        displayName: _readString(json, 'display_name'),
        backendUrl: _readString(json, 'backend_url'),
        discoveryUrl: _readString(json, 'discovery_url'),
        protocolVersion: _readInt(json, 'protocol_version'),
        capabilities: _readStringList(json, 'capabilities'),
        auth: ServerDiscoveryAuth.fromJson(
          json['auth'] as Map<String, dynamic>? ??
              (throw const FormatException('Missing auth block.')),
        ),
        termsUrl: _readOptionalString(json, 'terms_url'),
      );

  Map<String, dynamic> toJson() => {
    'instance_id': instanceId,
    'display_name': displayName,
    'backend_url': backendUrl,
    'discovery_url': discoveryUrl,
    'protocol_version': protocolVersion,
    'capabilities': capabilities,
    'auth': auth.toJson(),
    if (termsUrl != null) 'terms_url': termsUrl,
  };

  ServerConfig toServerConfig() => switch (auth) {
    ServerDiscoveryGoTrueAuth(:final gotrueUrl) => GoTrueServerConfig(
      id: instanceId,
      name: displayName,
      backendUrl: backendUrl,
      gotrueUrl: gotrueUrl,
      discoveryUrl: discoveryUrl,
      termsUrl: termsUrl,
    ),
    ServerDiscoveryCognitoAuth(
      :final userPoolId,
      :final clientId,
      :final region,
    ) =>
      CognitoServerConfig(
        id: instanceId,
        name: displayName,
        backendUrl: backendUrl,
        userPoolId: userPoolId,
        clientId: clientId,
        region: region,
        discoveryUrl: discoveryUrl,
        termsUrl: termsUrl,
      ),
  };
}

sealed class ServerDiscoveryAuth {
  const ServerDiscoveryAuth();

  AuthProvider get provider;

  Map<String, dynamic> toJson();

  factory ServerDiscoveryAuth.fromJson(Map<String, dynamic> json) =>
      switch (_readString(json, 'provider')) {
        'gotrue' => ServerDiscoveryGoTrueAuth(
          gotrueUrl: _readString(json, 'gotrue_url'),
        ),
        'cognito' => ServerDiscoveryCognitoAuth(
          userPoolId: _readString(json, 'user_pool_id'),
          clientId: _readString(json, 'client_id'),
          region: _readString(json, 'region'),
        ),
        final provider => throw FormatException(
          'Unknown discovery auth provider: $provider',
        ),
      };
}

final class ServerDiscoveryGoTrueAuth extends ServerDiscoveryAuth {
  const ServerDiscoveryGoTrueAuth({required this.gotrueUrl});

  final String gotrueUrl;

  @override
  AuthProvider get provider => AuthProvider.gotrue;

  @override
  Map<String, dynamic> toJson() => {
    'provider': 'gotrue',
    'gotrue_url': gotrueUrl,
  };
}

final class ServerDiscoveryCognitoAuth extends ServerDiscoveryAuth {
  const ServerDiscoveryCognitoAuth({
    required this.userPoolId,
    required this.clientId,
    required this.region,
  });

  final String userPoolId;
  final String clientId;
  final String region;

  @override
  AuthProvider get provider => AuthProvider.cognito;

  @override
  Map<String, dynamic> toJson() => {
    'provider': 'cognito',
    'user_pool_id': userPoolId,
    'client_id': clientId,
    'region': region,
  };
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Invalid `$key`.');
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing or invalid `$key`.');
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw FormatException('Missing or invalid `$key`.');
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List<dynamic> && value.every((entry) => entry is String)) {
    return value.cast<String>();
  }
  throw FormatException('Missing or invalid `$key`.');
}
