import 'dart:async';

import 'package:amap_en_ligne/data/push/push_token_source.dart';
import 'package:amap_en_ligne/data/repositories/device_token_repository.dart';

/// Filters a set of authorized scope keys down to the private per-recipient feeds
/// that carry device tokens (ADR-005): `member:{sub}` / `owner:{sub}` /
/// `producer-account:{id}`. Server-authoritative — derived from the persisted
/// `authorized_scopes`, never guessed from JWT claims, so we never register on a
/// feed the server would reject with FORBIDDEN.
List<String> privateFeedScopeKeys(Iterable<String> scopeKeys) => scopeKeys
    .where(
      (k) =>
          k.startsWith('member:') ||
          k.startsWith('owner:') ||
          k.startsWith('producer-account:'),
    )
    .toList();

/// Orchestrates push-token registration for the current user (ADR-005).
///
/// Bridges the platform [PushTokenSource] to the offline-first
/// [DeviceTokenRepository]: registers the current token on the user's authorized
/// private feed(s), keeps it fresh on rotation, and can remove it on logout. All
/// writes are optimistic and flushed by the next sync. [resolvePrivateFeeds]
/// returns the authorized private feed scope keys (typically read from persisted
/// sync cursors).
class PushRegistrationService {
  PushRegistrationService({
    required PushTokenSource source,
    required DeviceTokenRepository repository,
    required Future<List<String>> Function() resolvePrivateFeeds,
    String Function()? nowIso,
  }) : _source = source,
       _repository = repository,
       _resolvePrivateFeeds = resolvePrivateFeeds,
       _nowIso = nowIso ?? (() => DateTime.now().toUtc().toIso8601String());

  final PushTokenSource _source;
  final DeviceTokenRepository _repository;
  final Future<List<String>> Function() _resolvePrivateFeeds;
  final String Function() _nowIso;

  /// Registers the device's current push token on every authorized private feed.
  /// No-op when no token is available or no private feed is authorized yet.
  Future<void> registerCurrentDevice() async {
    final token = await _source.currentToken();
    if (token == null || token.isEmpty) return;
    await _registerOnFeeds(token);
  }

  /// Subscribes to token rotations and re-registers each new token. Caller owns
  /// the returned subscription's lifecycle (cancel on dispose / scope change).
  StreamSubscription<String> bindTokenRefresh() =>
      _source.onTokenRefresh.listen((token) {
        if (token.isEmpty) return;
        _registerOnFeeds(token);
      });

  /// Removes the device's current push token from every authorized private feed
  /// (best-effort, on logout). Must run while the session is still active for the
  /// Delete to flush.
  Future<void> unregisterCurrentDevice() async {
    final token = await _source.currentToken();
    if (token == null || token.isEmpty) return;
    for (final feed in await _resolvePrivateFeeds()) {
      await _repository.removeByToken(recipientScope: feed, token: token);
    }
  }

  Future<void> _registerOnFeeds(String token) async {
    final now = _nowIso();
    for (final feed in await _resolvePrivateFeeds()) {
      await _repository.register(
        recipientScope: feed,
        token: token,
        platform: _source.platform,
        nowIso: now,
      );
    }
  }
}
