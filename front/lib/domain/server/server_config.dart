import 'package:amap_en_ligne/domain/server/auth_provider.dart';

/// Connection target — backend URL + auth provider configuration.
///
/// Sealed so adding a new variant (e.g. another OIDC IdP) forces a
/// compile-time update of the auth factory and `ServerConfigStorage`
/// serialization. The [id] is the persistence key and should stay stable for
/// a given instance whether the config came from a static bootstrap catalog or
/// a federated discovery document.
sealed class ServerConfig {
  const ServerConfig({
    required this.id,
    required this.name,
    required this.backendUrl,
    this.discoveryUrl,
    this.termsUrl,
  });

  final String id;
  final String name;
  final String backendUrl;
  final String? discoveryUrl;

  /// Optional URL pointing to the instance's terms of service page.
  final String? termsUrl;

  AuthProvider get provider;

  Map<String, dynamic> toJson();

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    final provider = switch (json['provider']) {
      'gotrue' => AuthProvider.gotrue,
      'cognito' => AuthProvider.cognito,
      final value => throw FormatException('Unknown server provider: $value'),
    };

    return switch (provider) {
      AuthProvider.gotrue => GoTrueServerConfig(
        id: _readRequiredString(json, 'id'),
        name: _readRequiredString(json, 'name'),
        backendUrl: _readRequiredString(json, 'backend_url'),
        gotrueUrl: _readRequiredString(json, 'gotrue_url'),
        discoveryUrl: _readOptionalString(json, 'discovery_url'),
        termsUrl: _readOptionalString(json, 'terms_url'),
      ),
      AuthProvider.cognito => CognitoServerConfig(
        id: _readRequiredString(json, 'id'),
        name: _readRequiredString(json, 'name'),
        backendUrl: _readRequiredString(json, 'backend_url'),
        userPoolId: _readRequiredString(json, 'user_pool_id'),
        clientId: _readRequiredString(json, 'client_id'),
        region: _readRequiredString(json, 'region'),
        discoveryUrl: _readOptionalString(json, 'discovery_url'),
        termsUrl: _readOptionalString(json, 'terms_url'),
      ),
    };
  }
}

class CognitoServerConfig extends ServerConfig {
  const CognitoServerConfig({
    required super.id,
    required super.name,
    required super.backendUrl,
    super.discoveryUrl,
    super.termsUrl,
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
    'id': id,
    'name': name,
    'backend_url': backendUrl,
    if (discoveryUrl != null) 'discovery_url': discoveryUrl,
    if (termsUrl != null) 'terms_url': termsUrl,
    'user_pool_id': userPoolId,
    'client_id': clientId,
    'region': region,
  };
}

class GoTrueServerConfig extends ServerConfig {
  const GoTrueServerConfig({
    required super.id,
    required super.name,
    required super.backendUrl,
    super.discoveryUrl,
    super.termsUrl,
    required this.gotrueUrl,
  });

  final String gotrueUrl;

  @override
  AuthProvider get provider => AuthProvider.gotrue;

  @override
  Map<String, dynamic> toJson() => {
    'provider': 'gotrue',
    'id': id,
    'name': name,
    'backend_url': backendUrl,
    if (discoveryUrl != null) 'discovery_url': discoveryUrl,
    if (termsUrl != null) 'terms_url': termsUrl,
    'gotrue_url': gotrueUrl,
  };
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing or invalid `$key`.');
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Invalid `$key`.');
}
