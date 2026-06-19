import 'package:amap_en_ligne/data/server/server_catalog.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/domain/server/server_discovery_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GoTrue discovery document maps to GoTrueServerConfig', () {
    final document = ServerDiscoveryDocument.fromJson({
      'instance_id': 'amap-a',
      'display_name': 'AMAP A',
      'backend_url': 'https://a.example/v1',
      'discovery_url': 'https://a.example/.well-known/amap-en-ligne.json',
      'protocol_version': 1,
      'capabilities': ['sync-v1'],
      'auth': {'provider': 'gotrue', 'gotrue_url': 'https://a.example/auth'},
    });

    final config = document.toServerConfig();

    expect(config, isA<GoTrueServerConfig>());
    expect(config.id, 'amap-a');
    expect(config.discoveryUrl, contains('.well-known/amap-en-ligne.json'));
    expect((config as GoTrueServerConfig).gotrueUrl, 'https://a.example/auth');
  });

  test('Cognito discovery document maps to CognitoServerConfig', () {
    final document = ServerDiscoveryDocument.fromJson({
      'instance_id': 'amap-b',
      'display_name': 'AMAP B',
      'backend_url': 'https://b.example/v1',
      'discovery_url': 'https://b.example/.well-known/amap-en-ligne.json',
      'protocol_version': 1,
      'capabilities': ['sync-v1'],
      'auth': {
        'provider': 'cognito',
        'user_pool_id': 'pool',
        'client_id': 'client',
        'region': 'eu-west-3',
      },
    });

    final config = document.toServerConfig();

    expect(config, isA<CognitoServerConfig>());
    expect((config as CognitoServerConfig).clientId, 'client');
  });

  test('terms_url present in JSON is propagated to ServerConfig', () {
    final document = ServerDiscoveryDocument.fromJson({
      'instance_id': 'amap-c',
      'display_name': 'AMAP C',
      'backend_url': 'https://c.example/v1',
      'discovery_url': 'https://c.example/.well-known/amap-en-ligne.json',
      'protocol_version': 1,
      'capabilities': ['sync-v1'],
      'auth': {'provider': 'gotrue', 'gotrue_url': 'https://c.example/auth'},
      'terms_url': 'https://example.org/cgu',
    });

    final config = document.toServerConfig();

    expect(config.termsUrl, 'https://example.org/cgu');
  });

  test('terms_url absent from JSON produces null termsUrl', () {
    final document = ServerDiscoveryDocument.fromJson({
      'instance_id': 'amap-d',
      'display_name': 'AMAP D',
      'backend_url': 'https://d.example/v1',
      'discovery_url': 'https://d.example/.well-known/amap-en-ligne.json',
      'protocol_version': 1,
      'capabilities': ['sync-v1'],
      'auth': {'provider': 'gotrue', 'gotrue_url': 'https://d.example/auth'},
    });

    final config = document.toServerConfig();

    expect(config.termsUrl, isNull);
  });

  test('DiscoveryDocumentServerCatalog exposes discovery-backed configs', () {
    final catalog = DiscoveryDocumentServerCatalog(
      documents: [
        ServerDiscoveryDocument.fromJson({
          'instance_id': 'amap-a',
          'display_name': 'AMAP A',
          'backend_url': 'https://a.example/v1',
          'discovery_url': 'https://a.example/.well-known/amap-en-ligne.json',
          'protocol_version': 1,
          'capabilities': ['sync-v1'],
          'auth': {
            'provider': 'gotrue',
            'gotrue_url': 'https://a.example/auth',
          },
        }),
      ],
    );

    expect(catalog.listSelectionOptions().single.id, 'amap-a');
  });
}
