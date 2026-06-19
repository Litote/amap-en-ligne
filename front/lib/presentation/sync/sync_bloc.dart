import 'dart:async';

import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Drives the sync lifecycle. Triggers come from:
///  - manual user action (`SyncEvent.requested`),
///  - app start (`SyncEvent.started`, dispatched at construction),
///  - reconnection (subscribes to `connectivity_plus`),
///  - post-mutation flushes (`SyncEvent.mutationApplied`, dispatched by repos).
///
/// `connectivityStream` is injectable so tests can drive transitions
/// deterministically without touching the platform plugin.
///
/// When [authService] is provided, the bloc triggers [AuthService.refreshSession]
/// after a successful sync that contains Member or Owner upserts — role changes
/// made by an admin are then reflected immediately without a logout/login cycle.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    required SyncRepository repository,
    required String tenantId,
    bool enabled = true,
    Stream<List<ConnectivityResult>>? connectivityStream,
    Stream<void>? mutationStream,
    AuthService? authService,
  }) : _repository = repository,
       _tenantId = tenantId,
       _enabled = enabled,
       _authService = authService,
       super(const SyncState.idle()) {
    on<SyncRequested>(_onSync);
    on<SyncStarted>(_onSync);
    on<ConnectivityRestored>(_onSync);
    on<MutationApplied>(_onSync);
    on<FullSyncRequested>(_onFullSync);

    if (_enabled) {
      final stream = connectivityStream ?? Connectivity().onConnectivityChanged;
      _connectivitySub = stream.listen(_handleConnectivity);
      _mutationSub = mutationStream?.listen(
        (_) => add(const SyncEvent.mutationApplied()),
      );
      add(const SyncEvent.started());
    }
  }

  final SyncRepository _repository;
  final String _tenantId;
  final bool _enabled;
  final AuthService? _authService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<void>? _mutationSub;
  bool _wasOffline = false;

  void _handleConnectivity(List<ConnectivityResult> results) {
    final isOffline = results.every((r) => r == ConnectivityResult.none);
    if (_wasOffline && !isOffline) {
      add(const SyncEvent.connectivityRestored());
    }
    _wasOffline = isOffline;
  }

  Future<void> _onFullSync(
    FullSyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (!_enabled) return;
    await _repository.resetAllCursors();
    await _onSync(event, emit);
  }

  Future<void> _onSync(SyncEvent event, Emitter<SyncState> emit) async {
    if (!_enabled) return;
    emit(const SyncState.syncing());
    final outcome = await _repository.sync(tenantId: _tenantId);
    if (isClosed) return;
    switch (outcome) {
      case SyncSuccess(
        :final hasMore,
        :final rejectedMutations,
        :final memberOrOwnerUpdated,
      ):
        if (memberOrOwnerUpdated) {
          await _maybeRefreshSession();
        }
        if (isClosed) return;
        emit(
          SyncState.success(
            hasMore: hasMore,
            rejectedMutations: rejectedMutations,
          ),
        );
      case SyncFailure(:final message):
        emit(SyncState.failure(message));
      case SyncNetworkFailure():
        emit(const SyncState.offline());
    }
  }

  /// Triggers [AuthService.refreshSession] when the current state is
  /// authenticated. The session refresh emits a new [AuthState.authenticated]
  /// with updated claims (roles), which flows through [AuthBloc] and updates
  /// the menus/guards without requiring a logout/login cycle.
  Future<void> _maybeRefreshSession() async {
    final service = _authService;
    if (service == null) return;
    if (service.currentState is! Authenticated) return;
    await service.refreshSession();
  }

  @override
  Future<void> close() async {
    await _connectivitySub?.cancel();
    await _mutationSub?.cancel();
    return super.close();
  }
}
