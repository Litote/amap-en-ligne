import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:amap_en_ligne/data/local/database_constants.dart';

QueryExecutor openDatabaseExecutor() => DatabaseConnection.delayed(
  Future(() async {
    final probed = await probeAppDatabase();
    return probed.open(chooseAppDatabaseStorage(probed), appDatabaseName);
  }),
);

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
