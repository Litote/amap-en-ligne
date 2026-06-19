import 'package:drift/drift.dart';

/// The single value `PRAGMA quick_check` returns when the SQLite image is intact.
const _quickCheckOk = 'ok';

/// Runs `PRAGMA quick_check` on [executor] to detect a structurally corrupt
/// SQLite image (e.g. the `database disk image is malformed` / `SQLITE_CORRUPT`
/// errors that can occur on the web cache after a multi-tab write race).
///
/// The local database is a server-authoritative cache, so a corrupt image can
/// safely be discarded and rebuilt from a fresh sync. Returns `false` on any
/// failure — corruption reported by `quick_check`, or the open/query itself
/// throwing — so callers can recover by deleting and recreating the database.
///
/// Open [executor] with migrations disabled before calling this: the probe must
/// never write `user_version` or create tables, otherwise it would interfere
/// with the real database's migration on the next open.
Future<bool> isDatabaseHealthy(QueryExecutor executor) async {
  try {
    await executor.ensureOpen(_IntegrityProbeUser());
    final rows = await executor.runSelect('PRAGMA quick_check(1);', const []);
    if (rows.isEmpty) return false;
    final values = rows.first.values;
    final first = values.isEmpty ? null : values.first;
    return first is String && first.toLowerCase() == _quickCheckOk;
  } on Object {
    return false;
  }
}

/// Minimal [QueryExecutorUser] used only to open a connection for the integrity
/// probe. It runs no migration: the probe connection is opened with
/// `enableMigrations: false`, so [beforeOpen] is a no-op and [schemaVersion] is
/// never written to the database.
class _IntegrityProbeUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}
