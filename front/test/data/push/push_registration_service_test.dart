import 'dart:async';
import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/push/push_registration_service.dart';
import 'package:amap_en_ligne/data/push/push_token_source.dart';
import 'package:amap_en_ligne/data/repositories/device_token_repository.dart';
import 'package:amap_en_ligne/domain/model/device_token.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePushTokenSource implements PushTokenSource {
  String? token;
  final _refresh = StreamController<String>.broadcast();

  @override
  DevicePlatform get platform => DevicePlatform.android;

  @override
  Future<String?> currentToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  void emitRefresh(String value) => _refresh.add(value);

  Future<void> dispose() => _refresh.close();
}

void main() {
  group('privateFeedScopeKeys', () {
    test('keeps only private recipient feeds', () {
      final feeds = privateFeedScopeKeys([
        'member:sub-1',
        'owner:sub-2',
        'producer-account:pa-1',
        'organization:org-1',
        'instance-owner',
      ]);
      expect(feeds, ['member:sub-1', 'owner:sub-2', 'producer-account:pa-1']);
    });
  });

  group('PushRegistrationService', () {
    late AppDatabase db;
    late DeviceTokenRepository repo;
    late _FakePushTokenSource source;
    List<String> feeds = const ['member:m-1'];

    PushRegistrationService build() => PushRegistrationService(
      source: source,
      repository: repo,
      resolvePrivateFeeds: () async => feeds,
      nowIso: () => '2026-05-29T10:00:00Z',
    );

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DeviceTokenRepository(db: db, idGenerator: IdGenerator(Random(0)));
      source = _FakePushTokenSource();
      feeds = const ['member:m-1'];
    });

    tearDown(() async {
      await source.dispose();
      await db.close();
    });

    test(
      'registerCurrentDevice registers on each authorized private feed',
      () async {
        source.token = 'fcm-1';
        feeds = const ['member:m-1', 'producer-account:pa-1'];

        await build().registerCurrentDevice();

        expect(
          (await db.watchDeviceTokens('member:m-1').first).single.token,
          'fcm-1',
        );
        expect(
          (await db.watchDeviceTokens('producer-account:pa-1').first)
              .single
              .token,
          'fcm-1',
        );
      },
    );

    test(
      'registerCurrentDevice is a no-op when no token is available',
      () async {
        source.token = null;
        await build().registerCurrentDevice();
        expect(await db.watchDeviceTokens('member:m-1').first, isEmpty);
      },
    );

    test(
      'registerCurrentDevice is a no-op when no private feed is authorized',
      () async {
        source.token = 'fcm-1';
        feeds = const [];
        await build().registerCurrentDevice();
        expect(await db.readPendingMutations(), isEmpty);
      },
    );

    test('bindTokenRefresh registers each rotated token', () async {
      source.token = 'fcm-old';
      final service = build();
      final sub = service.bindTokenRefresh();
      source.emitRefresh('fcm-rotated');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(
        (await db.watchDeviceTokens('member:m-1').first).single.token,
        'fcm-rotated',
      );
    });

    test(
      'unregisterCurrentDevice removes the token from authorized feeds',
      () async {
        source.token = 'fcm-1';
        final service = build();
        await service.registerCurrentDevice();

        await service.unregisterCurrentDevice();

        expect(await db.watchDeviceTokens('member:m-1').first, isEmpty);
      },
    );
  });
}
