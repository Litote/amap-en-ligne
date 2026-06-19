/// Orchestrates opening the local cache with corruption recovery, independently
/// of any platform (web/wasm, native) so the control flow can be unit-tested.
///
/// If [isHealthy] reports the stored database is intact, it is opened directly.
/// Otherwise [onCorruption] runs first (report + drop the corrupt copy) and the
/// database is then re-opened from a clean state. The local cache is
/// server-authoritative, so recreating it is safe — the next sync rebuilds it.
Future<T> openDatabaseWithRecovery<T>({
  required Future<bool> Function() isHealthy,
  required Future<T> Function() open,
  required Future<void> Function() onCorruption,
}) async {
  if (await isHealthy()) {
    return open();
  }
  await onCorruption();
  return open();
}
