import 'dart:async';

import 'package:amap_en_ligne/data/push/fcm_push_token_source.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

class _MockInstallations extends Mock implements FirebaseInstallations {}

class _MockSettings extends Mock implements NotificationSettings {}

void main() {
  late _MockMessaging messaging;
  late _MockInstallations installations;
  late _MockSettings settings;
  late FcmPushTokenSource source;

  setUp(() {
    messaging = _MockMessaging();
    installations = _MockInstallations();
    settings = _MockSettings();
    when(() => messaging.requestPermission()).thenAnswer((_) async => settings);
    when(
      () => settings.authorizationStatus,
    ).thenReturn(AuthorizationStatus.authorized);
    when(() => messaging.register()).thenAnswer((_) async {});
    when(() => installations.getId()).thenAnswer((_) async => 'fid-1');
    source = FcmPushTokenSource(
      messaging: () => messaging,
      installations: () => installations,
    );
  });

  group('currentToken', () {
    test('registers with FCM, then returns the installation FID', () async {
      expect(await source.currentToken(), 'fid-1');

      verifyInOrder([
        () => messaging.requestPermission(),
        () => messaging.register(),
        () => installations.getId(),
      ]);
    });

    test(
      'returns null without registering when permission is denied',
      () async {
        when(
          () => settings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.denied);

        expect(await source.currentToken(), isNull);

        verifyNever(() => messaging.register());
        verifyNever(() => installations.getId());
      },
    );

    test('returns null when the registration fails', () async {
      when(
        () => messaging.register(),
      ).thenThrow(FirebaseException(plugin: 'firebase_messaging'));

      expect(await source.currentToken(), isNull);

      verifyNever(() => installations.getId());
    });
  });

  group('onTokenRefresh', () {
    test('emits each FID FCM registers', () async {
      final registered = StreamController<String>();
      addTearDown(registered.close);
      when(() => messaging.onRegistered).thenAnswer((_) => registered.stream);

      final emitted = source.onTokenRefresh.take(2).toList();
      registered
        ..add('fid-1')
        ..add('fid-2');

      expect(await emitted, ['fid-1', 'fid-2']);
    });

    test('is empty when FCM is unavailable', () async {
      when(
        () => messaging.onRegistered,
      ).thenThrow(FirebaseException(plugin: 'firebase_messaging'));

      expect(await source.onTokenRefresh.isEmpty, isTrue);
    });
  });
}
