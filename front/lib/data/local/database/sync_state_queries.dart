part of '../database.dart';

mixin _SyncStateQueries on _$AppDatabase {
  final _mutationEnqueuedController = StreamController<void>.broadcast();

  /// Emits whenever a pending mutation is enqueued. `SyncBloc` subscribes to
  /// this stream to flush the queue immediately without requiring every screen
  /// to manually dispatch `SyncEvent.mutationApplied()`.
  Stream<void> get onMutationEnqueued => _mutationEnqueuedController.stream;

  Future<Map<String, String?>> readAllScopeCursors() async {
    final rows = await select(syncCursors).get();
    return {for (final row in rows) row.scopeKey: row.cursor};
  }

  Future<String?> readCursor(String scopeKey) async {
    final row = await (select(
      syncCursors,
    )..where((t) => t.scopeKey.equals(scopeKey))).getSingleOrNull();
    return row?.cursor;
  }

  Future<void> writeCursor(String scopeKey, String? cursor) =>
      into(syncCursors).insertOnConflictUpdate(
        SyncCursorsCompanion.insert(scopeKey: scopeKey, cursor: Value(cursor)),
      );

  Future<void> deleteCursor(String scopeKey) =>
      (delete(syncCursors)..where((t) => t.scopeKey.equals(scopeKey))).go();

  /// Resets every known scope cursor to null, signalling a full bootstrap on
  /// the next sync round-trip.
  Future<void> resetAllCursors() => update(
    syncCursors,
  ).write(const SyncCursorsCompanion(cursor: Value(null)));

  Future<void> enqueuePendingMutation(
    ClientMutation mutation, {
    required String scopeKey,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(pendingMutations).insertOnConflictUpdate(
      PendingMutationsCompanion.insert(
        clientOpId: mutation.clientOpId,
        scopeKey: scopeKey,
        payloadJson: jsonEncode(mutation),
        createdAt: now,
      ),
    );
    _mutationEnqueuedController.add(null);
  }

  Future<List<PendingClientMutation>> readPendingMutationEntries() async {
    final rows = await (select(
      pendingMutations,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    return rows.map(_pendingMutationFromRow).toList();
  }

  Future<List<ClientMutation>> readPendingMutations() async {
    final rows = await readPendingMutationEntries();
    return rows.map((row) => row.mutation).toList();
  }

  Future<void> drainPendingMutations(Iterable<String> clientOpIds) {
    final ids = clientOpIds.toList();
    if (ids.isEmpty) return Future.value();
    return (delete(
      pendingMutations,
    )..where((t) => t.clientOpId.isIn(ids))).go();
  }

  Future<void> dropPendingMutationsForScopes(Iterable<String> scopeKeys) {
    final keys = scopeKeys.toList();
    if (keys.isEmpty) return Future.value();
    return (delete(pendingMutations)..where((t) => t.scopeKey.isIn(keys))).go();
  }

  Future<void> replacePendingMutation(
    PendingClientMutation entry, {
    required ClientMutation mutation,
    String? scopeKey,
  }) => into(pendingMutations).insertOnConflictUpdate(
    PendingMutationsCompanion.insert(
      clientOpId: entry.clientOpId,
      scopeKey: scopeKey ?? entry.scopeKey,
      payloadJson: jsonEncode(mutation),
      createdAt: entry.createdAt,
    ),
  );

}

PendingClientMutation _pendingMutationFromRow(PendingMutation row) {
  final mutation = ClientMutation.fromJson(
    jsonDecode(row.payloadJson) as Map<String, dynamic>,
  );
  return PendingClientMutation(
    clientOpId: row.clientOpId,
    scopeKey: row.scopeKey,
    mutation: mutation,
    createdAt: row.createdAt,
  );
}

class PendingClientMutation {
  const PendingClientMutation({
    required this.clientOpId,
    required this.scopeKey,
    required this.mutation,
    required this.createdAt,
  });

  final String clientOpId;
  final String scopeKey;
  final ClientMutation mutation;
  final int createdAt;

  PendingClientMutation copyWith({
    String? scopeKey,
    ClientMutation? mutation,
    int? createdAt,
  }) => PendingClientMutation(
    clientOpId: clientOpId,
    scopeKey: scopeKey ?? this.scopeKey,
    mutation: mutation ?? this.mutation,
    createdAt: createdAt ?? this.createdAt,
  );
}
