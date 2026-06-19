import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:dio/dio.dart';

/// Builds the `Dio` used to call the back's sync endpoint. The
/// `Authorization` header is injected per-request from [auth] so a token
/// rotation (refresh) is picked up without rebuilding the client.
///
/// [backendUrl] comes from the active `ServerConfig` — runtime-selected
/// from the preset list, no longer a build-time `--dart-define`.
Dio buildSyncDio({required String backendUrl, required AuthService auth}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: backendUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await auth.currentAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await auth.signOut();
        }
        handler.next(error);
      },
    ),
  );
  return dio;
}

/// Builds a `Dio` for the auth provider (GoTrue today). Separate from the
/// sync dio so the `Authorization` interceptor above doesn't apply — the
/// `/token` endpoint authenticates by request body, not header.
Dio buildAuthDio({required String baseUrl}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
}
