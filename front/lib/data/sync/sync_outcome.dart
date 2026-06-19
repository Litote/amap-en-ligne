import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_outcome.freezed.dart';

/// Result of a single sync round-trip.
///
/// `hasMore` is retained for presentation compatibility; the scope-based sync
/// contract no longer paginates so it is always `false` in production.
/// `rejectedMutations` carries the back's REJECTED outcomes so the UI can
/// surface them; APPLIED mutations have already been drained from the local
/// pending queue.
/// `memberOrOwnerUpdated` is `true` when the sync applied at least one Member
/// or Owner upsert — used by [SyncBloc] to trigger a token refresh so that
/// role changes made by an admin are reflected immediately without a
/// logout/login cycle.
@freezed
sealed class SyncOutcome with _$SyncOutcome {
  const factory SyncOutcome.success({
    @Default(false) bool hasMore,
    @Default(<MutationOutcome>[]) List<MutationOutcome> rejectedMutations,
    @Default(false) bool memberOrOwnerUpdated,
  }) = SyncSuccess;

  const factory SyncOutcome.failure(String message) = SyncFailure;

  /// The server could not be reached (no connectivity, DNS failure, timeout).
  /// Pending mutations stay queued locally and are flushed by the next sync,
  /// which is triggered automatically when connectivity returns.
  const factory SyncOutcome.networkFailure() = SyncNetworkFailure;
}
