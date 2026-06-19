import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/domain/sync/sync_response.dart';
import 'package:dio/dio.dart';

/// Thin wrapper around `POST /v1/sync` — the back's only endpoint.
class SyncApi {
  SyncApi(this._dio);

  final Dio _dio;

  Future<SyncResponse> sync(SyncRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/sync',
      data: request.toJson(),
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('Empty body for /v1/sync');
    }
    return SyncResponse.fromJson(body);
  }
}
