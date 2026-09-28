import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_event.freezed.dart';

@freezed
sealed class SyncEvent with _$SyncEvent {
  /// User-initiated sync (pull-to-refresh, refresh button).
  const factory SyncEvent.requested() = SyncRequested;

  /// Bloc creation hook — runs an initial sync at app start.
  const factory SyncEvent.started() = SyncStarted;

  /// Network came back online — flush any pending mutations.
  const factory SyncEvent.connectivityRestored() = ConnectivityRestored;

  /// A local mutation was just enqueued — try to flush it eagerly.
  const factory SyncEvent.mutationApplied() = MutationApplied;

  /// User-initiated full (non-incremental) sync: resets all scope cursors so
  /// the next sync triggers a bootstrap for every authorized scope.
  const factory SyncEvent.fullSyncRequested() = FullSyncRequested;
}
