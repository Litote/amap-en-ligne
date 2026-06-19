import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/model/device_token.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';

/// Read/write API for the current user's `DeviceToken` push registrations (ADR-005).
///
/// Device tokens are client-authored on the user's private scope (`member:{sub}` /
/// `owner:{sub}` / `producer-account:{id}`). Writes apply optimistically to the local
/// cache and enqueue a `ClientMutation` flushed on the next sync. The server
/// deduplicates by `(recipientScope, token)`, so re-registering a known token refreshes
/// the existing row (and its `tmp_*` id is remapped to the server id on the next sync).
class DeviceTokenRepository {
  DeviceTokenRepository({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGen = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGen;

  Stream<List<DeviceToken>> watch(String recipientScope) =>
      _db.watchDeviceTokens(recipientScope);

  /// Registers the push [token] for [recipientScope]. Idempotent: when the same
  /// token (and platform) is already cached for the scope it is a **no-op** — no
  /// write, no enqueue — so re-running on every sync does not spam the queue.
  /// Returns the registered (or already-present) row.
  Future<DeviceToken> register({
    required String recipientScope,
    required String token,
    required DevicePlatform platform,
    required String nowIso,
  }) async {
    final existing = await _db.getDeviceTokenByToken(recipientScope, token);
    if (existing != null && existing.platform == platform) {
      return existing;
    }
    final deviceToken =
        (existing ??
                DeviceToken(
                  deviceTokenId: _idGen.nextTmpId(),
                  recipientScope: recipientScope,
                  platform: platform,
                  token: token,
                  createdAt: nowIso,
                  lastSeenAt: nowIso,
                ))
            .copyWith(lastSeenAt: nowIso, platform: platform);
    await _db.transaction(() async {
      await _db.upsertDeviceToken(deviceToken);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Upsert(payload: DeviceTokenPayload(deviceToken: deviceToken)),
        ),
        scopeKey: recipientScope,
      );
    });
    return deviceToken;
  }

  /// Removes the push [token] from [recipientScope] (e.g. on logout). No-op if absent.
  Future<void> removeByToken({
    required String recipientScope,
    required String token,
  }) async {
    final existing = await _db.getDeviceTokenByToken(recipientScope, token);
    if (existing == null) return;
    await _db.transaction(() async {
      await _db.deleteDeviceToken(recipientScope, existing.deviceTokenId);
      await _db.enqueuePendingMutation(
        ClientMutation(
          clientOpId: _idGen.next(),
          op: Delete(
            entityType: EntityType.deviceToken,
            entityId: existing.deviceTokenId,
          ),
        ),
        scopeKey: recipientScope,
      );
    });
  }
}
