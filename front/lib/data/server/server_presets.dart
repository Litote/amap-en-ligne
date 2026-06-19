import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:flutter/foundation.dart';

/// Hardcoded list of servers a user can pick from on first launch. We do not
/// distribute discovery documents out-of-band today, so this list acts as the
/// current bootstrap catalog shipped with the app binary.
///
/// Once per-instance discovery is wired in, this file should remain only as a
/// minimal offline/bootstrap fallback.
final serverPresets = <ServerConfig>[
  GoTrueServerConfig(
    id: 'local-dev-gotrue',
    name: 'Local dev (Supabase / GoTrue)',
    backendUrl: kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080',
    gotrueUrl: kIsWeb ? 'http://localhost:9999' : 'http://10.0.2.2:9999',
  ),
  CognitoServerConfig(
    id: 'aws-prod-cognito',
    name: 'AWS prod (Cognito)',
    backendUrl: 'https://api.amap-en-ligne.example/v1',
    userPoolId: 'eu-west-1_PLACEHOLDER',
    clientId: 'placeholder-client-id',
    region: 'eu-west-1',
  ),
];
