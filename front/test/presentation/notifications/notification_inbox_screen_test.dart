import 'dart:async';

import 'package:amap_en_ligne/data/repositories/member_join_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/notification_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/sync/sync_scope.dart';
import 'package:amap_en_ligne/presentation/notifications/notification_inbox_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

class _MockSyncRepository extends Mock implements SyncRepository {}

class _MockMemberJoinRequestRepository extends Mock
    implements MemberJoinRequestRepository {}

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

AppNotification _joinRequestNotification(String id, String requestId) =>
    AppNotification(
      notificationId: id,
      recipientScope: memberScopeKey(_memberId),
      type: NotificationType.info,
      category: NotificationCategory.memberJoinRequestSubmitted,
      title: "Nouvelle demande d'adhésion",
      body: 'Claude Cinq demande à rejoindre votre AMAP.',
      relatedEntityId: requestId,
      createdAt: '2026-09-27T12:09:00Z',
    );

AdminMemberJoinRequest _joinRequest(
  String id,
  MemberJoinRequestStatus status,
) => AdminMemberJoinRequest(
  requestId: id,
  organizationId: 'org-1',
  email: 'cinq@example.com',
  firstName: 'Claude',
  lastName: 'Cinq',
  status: status,
  submittedAt: '2026-09-27T12:09:00Z',
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    registerFallbackValue(_notification());
  });

  late _MockNotificationRepository repo;
  late StreamController<List<AppNotification>> stream;
  late SyncBloc syncBloc;
  late _MockMemberJoinRequestRepository joinRequestRepo;

  setUp(() {
    joinRequestRepo = _MockMemberJoinRequestRepository();
    when(
      () => joinRequestRepo.watchAll(),
    ).thenAnswer((_) => Stream.value(const []));
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

  Future<void> pump(WidgetTester tester, {GoRouter? router}) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<NotificationRepository>.value(value: repo),
          RepositoryProvider<MemberJoinRequestRepository>.value(
            value: joinRequestRepo,
          ),
        ],
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: router == null
              ? const MaterialApp(
                  home: NotificationInboxScreen(memberId: _memberId),
                )
              : MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'join request notifications show the current state of their request',
    (tester) async {
      when(() => joinRequestRepo.watchAll()).thenAnswer(
        (_) => Stream.value([
          _joinRequest('r-1', MemberJoinRequestStatus.approved),
          _joinRequest('r-2', MemberJoinRequestStatus.rejected),
          _joinRequest('r-3', MemberJoinRequestStatus.pending),
        ]),
      );
      await pump(tester);
      stream.add([
        _joinRequestNotification('n-1', 'r-1'),
        _joinRequestNotification('n-2', 'r-2'),
        _joinRequestNotification('n-3', 'r-3'),
        _joinRequestNotification('n-4', 'r-unknown'),
      ]);
      await tester.pump();
      // The request states stream is subscribed once the list is built.
      await tester.pump();

      expect(find.text('Demande approuvée'), findsOneWidget);
      expect(find.text('Demande rejetée'), findsOneWidget);
      expect(find.text('Demande en attente'), findsOneWidget);
      // A request no longer cached gets no state line.
      expect(find.textContaining('Demande '), findsNWidgets(3));
    },
  );

  testWidgets('tapping a join request notification opens the requests', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationInboxScreen(memberId: _memberId),
        ),
        GoRoute(
          path: '/admin/membership-requests',
          builder: (_, _) => const Text('membership-requests'),
        ),
      ],
    );
    await pump(tester, router: router);
    stream.add([_joinRequestNotification('n-1', 'r-1')]);
    await tester.pump();

    await tester.tap(find.text("Nouvelle demande d'adhésion"));
    await tester.pumpAndSettle();

    expect(find.text('membership-requests'), findsOneWidget);
  });

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

  testWidgets('shows when each notification was received', (tester) async {
    await pump(tester);
    stream.add([_notification()]);
    await tester.pump();

    expect(find.textContaining('Reçue le 29 mai 2026 à '), findsOneWidget);
  });

  testWidgets('the Archiver button archives without swiping', (tester) async {
    await pump(tester);
    stream.add([_notification()]);
    await tester.pump();

    await tester.tap(find.byTooltip('Archiver'));
    await tester.pumpAndSettle();

    verify(() => repo.archive(any())).called(1);
    verifyNever(() => repo.markRead(any(), readAtIso: any(named: 'readAtIso')));
  });
}
