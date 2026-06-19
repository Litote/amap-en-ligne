import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/domain/sync/scope_sync_result.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_response.freezed.dart';
part 'sync_response.g.dart';

@freezed
abstract class SyncResponse with _$SyncResponse {
  const factory SyncResponse({
    @JsonKey(name: 'authorized_scopes')
    @Default(<String>[])
    List<String> authorizedScopes,
    @Default(<String, ScopeSyncResult>{}) Map<String, ScopeSyncResult> results,
    @Default(<MutationOutcome>[]) List<MutationOutcome> mutations,
  }) = _SyncResponse;

  factory SyncResponse.fromJson(Map<String, Object?> json) =>
      _$SyncResponseFromJson(json);
}
