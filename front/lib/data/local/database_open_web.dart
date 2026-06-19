import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:amap_en_ligne/data/local/database_constants.dart';
import 'package:amap_en_ligne/data/local/database_integrity.dart';
import 'package:amap_en_ligne/data/local/database_recovery.dart';

QueryExecutor openDatabaseExecutor() => DatabaseConnection.delayed(
  openDatabaseWithRecovery<DatabaseConnection>(
    isHealthy: _appDatabaseIsHealthy,
    open: _openAppDatabase,
    onCorruption: _recoverCorruptDatabase,
  ),
);

/// Probes the browser, then opens the persistent cache with the best available
/// storage. Used for both the initial open and the post-recovery re-open.
Future<DatabaseConnection> _openAppDatabase() async {
  final probed = await probeAppDatabase();
  return probed.open(chooseAppDatabaseStorage(probed), appDatabaseName);
}

/// Reports the corruption for tracing, then drops the malformed copy so the
/// re-open starts from a clean, empty cache. The cache is server-authoritative,
/// so the next sync rebuilds it.
Future<void> _recoverCorruptDatabase() async {
  final probed = await probeAppDatabase();
  final storage = chooseAppDatabaseStorage(probed);
  await _reportCorruptDatabase(probed, storage);
  await _deleteAppDatabases(probed);
}

/// Emits a stable, groupable Sentry event each time a corrupt local cache is
/// detected and recreated, so the occurrence count is traceable. Reporting must
/// never block recovery, so any failure here is swallowed.
Future<void> _reportCorruptDatabase(
  WasmProbeResult probed,
  WasmStorageImplementation storage,
) async {
  try {
    await Sentry.captureMessage(
      'Local cache corrupt — recreated',
      level: SentryLevel.warning,
      withScope: (scope) {
        scope.setContexts('local_cache', {
          'storage': storage.name,
          'existing_databases': probed.existingDatabases
              .map((db) => {'name': db.$2, 'storage': db.$1.name})
              .toList(),
        });
      },
    );
  } on Object {
    // Sentry not initialised / offline — recovery proceeds regardless.
  }
}

/// Opens a throwaway connection (migrations disabled, so it never touches the
/// schema) purely to run an integrity check, then closes it before the real
/// connection is opened. Any failure to probe or open is treated as corruption.
Future<bool> _appDatabaseIsHealthy() async {
  final probed = await probeAppDatabase();
  final storage = chooseAppDatabaseStorage(probed);
  DatabaseConnection? probe;
  try {
    probe = await probed.open(
      storage,
      appDatabaseName,
      enableMigrations: false,
    );
    return await isDatabaseHealthy(probe.executor);
  } on Object {
    return false;
  } finally {
    await probe?.executor.close();
  }
}

/// Deletes every stored database named [appDatabaseName] across the storage
/// implementations the probe found. Must run with no open connection.
Future<void> _deleteAppDatabases(WasmProbeResult probed) async {
  for (final existing in probed.existingDatabases) {
    if (existing.$2 == appDatabaseName) {
      await probed.deleteDatabase(existing);
    }
  }
}

Future<WasmProbeResult> probeAppDatabase() => WasmDatabase.probe(
  sqlite3Uri: Uri.parse(appDatabaseSqlite3WasmPath),
  driftWorkerUri: Uri.parse(appDatabaseDriftWorkerPath),
  databaseName: appDatabaseName,
);

WasmStorageImplementation chooseAppDatabaseStorage(WasmProbeResult probed) {
  // opfsShared is available exclusively on Firefox: it relies on nested
  // dedicated workers spawned from a shared worker, a capability Chrome and
  // Safari do not support. Use its presence as a Firefox indicator.
  //
  // On Firefox, both opfsShared and sharedIndexedDb route through the shared
  // worker's DriftServerController._servers registry (putIfAbsent keyed by
  // database name). If the shared worker survives a page reload with a broken
  // opfs server for 'amap_en_ligne' — which happens after
  // FileSystemSyncAccessHandle throws NoModificationAllowedError on bfcache
  // restore — sharedIndexedDb reuses that broken server and hangs forever.
  //
  // opfsLocks and unsafeIndexedDb are routed to the dedicated worker directly
  // (dedicatedWorker.send), bypassing the shared worker's server registry.
  // unsafeIndexedDb uses IndexedDB with no OPFS dependency, making it the
  // most robust choice for Firefox. The "unsafe" label only refers to
  // multi-tab write races, which are acceptable for this server-authoritative
  // offline-first app.
  //
  // On Chrome and Safari, opfsShared is absent so this branch is never taken
  // and the default selection (opfsLocks → best available) is preserved.
  if (probed.availableStorages.contains(WasmStorageImplementation.opfsShared)) {
    for (final candidate in const [
      WasmStorageImplementation.unsafeIndexedDb,
      WasmStorageImplementation.inMemory,
    ]) {
      if (probed.availableStorages.contains(candidate) ||
          candidate == WasmStorageImplementation.inMemory) {
        return candidate;
      }
    }
  }

  final available = probed.availableStorages.toList()
    ..sort((a, b) => a.index.compareTo(b.index));
  return available.firstOrNull ?? WasmStorageImplementation.inMemory;
}
