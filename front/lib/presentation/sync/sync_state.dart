import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_state.freezed.dart';

@freezed
sealed class SyncState with _$SyncState {
  const factory SyncState.idle() = SyncIdle;
  const factory SyncState.syncing() = SyncRunning;
  const factory SyncState.success({
    @Default(false) bool hasMore,
    @Default(<MutationOutcome>[]) List<MutationOutcome> rejectedMutations,
  }) = SyncSucceeded;
  const factory SyncState.failure(String message) = SyncFailed;

  /// The last sync attempt could not reach the server. Local changes are
  /// saved on the device and will sync once connectivity returns.
  const factory SyncState.offline() = SyncOffline;
}
