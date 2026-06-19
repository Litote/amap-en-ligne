import 'dart:async';

import 'package:amap_en_ligne/data/repositories/notification_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:amap_en_ligne/presentation/notifications/notification_inbox_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

class _MockSyncRepository extends Mock implements SyncRepository {}

const _memberId = 'm-1';

AppNotification _notification({String id = 'notif-1', String? readAt}) =>
    AppNotification(
      notificationId: id,
      recipientScope: memberScopeKey(_memberId),
      type: NotificationType.info,
      category: NotificationCategory.basketExchangeAccepted,
      title: 'Demande acceptée',
      body: 'Votre demande a été acceptée.',
      createdAt: '2026-05-29T10:00:00Z',
      readAt: readAt,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_notification());
  });

  late _MockNotificationRepository repo;
  late StreamController<List<AppNotification>> stream;
  late SyncBloc syncBloc;

  setUp(() {
    repo = _MockNotificationRepository();
    stream = StreamController<List<AppNotification>>.broadcast();
    when(() => repo.watch(any())).thenAnswer((_) => stream.stream);
    when(
      () => repo.markRead(any(), readAtIso: any(named: 'readAtIso')),
    ).thenAnswer((_) async {});
    when(() => repo.archive(any())).thenAnswer((_) async {});
    syncBloc = SyncBloc(
      repository: _MockSyncRepository(),
      tenantId: 'tenant',
      enabled: false,
    );
  });

  tearDown(() async {
    await stream.close();
    await syncBloc.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<NotificationRepository>.value(
        value: repo,
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: const MaterialApp(
            home: NotificationInboxScreen(memberId: _memberId),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows empty state when there are no notifications', (
    tester,
  ) async {
    await pump(tester);
    stream.add(const []);
    await tester.pump();

    expect(find.text('Aucune notification'), findsOneWidget);
  });

  testWidgets('renders a notification and marks it read on tap', (
    tester,
  ) async {
    await pump(tester);
    stream.add([_notification()]);
    await tester.pump();

    expect(find.text('Demande acceptée'), findsOneWidget);

    await tester.tap(find.text('Demande acceptée'));
    await tester.pump();

    verify(
      () => repo.markRead(any(), readAtIso: any(named: 'readAtIso')),
    ).called(1);
  });

  testWidgets('swiping a notification archives it', (tester) async {
    await pump(tester);
    stream.add([_notification()]);
    await tester.pump();

    await tester.fling(
      find.text('Demande acceptée'),
      const Offset(-500, 0),
      1000,
    );
    await tester.pumpAndSettle();

    verify(() => repo.archive(any())).called(1);
  });
}
