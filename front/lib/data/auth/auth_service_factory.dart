import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/cognito_auth_service.dart';
import 'package:amap_en_ligne/data/auth/gotrue_auth_service.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';

/// Builds an [AuthService] for the active [ServerConfig]. The exhaustive
/// switch on the sealed `ServerConfig` makes the compiler force this
/// factory to be updated when a new provider variant is added.
AuthService buildAuthService({
  required ServerConfig config,
  required AuthTokenStorage storage,
}) {
  switch (config) {
    case GoTrueServerConfig():
      return GoTrueAuthService(
        dio: buildAuthDio(baseUrl: config.gotrueUrl),
        storage: storage,
      );
    case CognitoServerConfig():
      final pool = CognitoUserPool(config.userPoolId, config.clientId);
      return CognitoAuthService(
        gateway: CognitoUserPoolGateway(userPool: pool),
        storage: storage,
      );
  }
}
