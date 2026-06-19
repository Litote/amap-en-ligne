import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_request.freezed.dart';
part 'sync_request.g.dart';

@freezed
abstract class SyncRequest with _$SyncRequest {
  const factory SyncRequest({
    @Default(<String, String?>{}) Map<String, String?> cursors,
    @Default(<ClientMutation>[]) List<ClientMutation> mutations,
  }) = _SyncRequest;

  factory SyncRequest.fromJson(Map<String, Object?> json) =>
      _$SyncRequestFromJson(json);
}
