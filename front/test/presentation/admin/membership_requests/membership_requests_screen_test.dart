import 'dart:async';

import 'package:amap_en_ligne/data/repositories/member_join_request_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_member_join_request.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMemberJoinRequestRepository extends Mock
    implements MemberJoinRequestRepository {}

class _MockSyncRepository extends Mock implements SyncRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

AdminMemberJoinRequest _request({
  String id = 'r1',
  String firstName = 'Alice',
  String lastName = 'Martin',
  String email = 'alice@example.com',
  MemberJoinRequestStatus status = MemberJoinRequestStatus.pending,
}) => AdminMemberJoinRequest(
  requestId: id,
  organizationId: 'org-1',
  email: email,
  firstName: firstName,
  lastName: lastName,
  status: status,
  submittedAt: '2026-01-01T10:00:00Z',
);

void main() {
  late _MockMemberJoinRequestRepository repo;
  late _MockSyncRepository syncRepo;
  late _MockSyncBloc syncBloc;

  setUpAll(() {
    registerFallbackValue(_request());
  });

  setUp(() {
    repo = _MockMemberJoinRequestRepository();
    syncRepo = _MockSyncRepository();
    syncBloc = _MockSyncBloc();
    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<MemberJoinRequestRepository>.value(value: repo),
          RepositoryProvider<SyncRepository>.value(value: syncRepo),
        ],
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: const MaterialApp(
            home: MembershipRequestsScreen(organizationId: 'org-1'),
          ),
        ),
      ),
    );
  }

  testWidgets('shows a spinner while the request stream is pending', (
    tester,
  ) async {
    final controller = StreamController<List<AdminMemberJoinRequest>>();
    when(() => repo.watch(any())).thenAnswer((_) => controller.stream);
    addTearDown(controller.close);

    await pump(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Demandes d\'adhésion'), findsOneWidget);
  });

  testWidgets('shows an error view with retry when the stream errors', (
    tester,
  ) async {
    when(
      () => repo.watch(any()),
    ).thenAnswer((_) => Stream.error(Exception('boom')));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('lists the membership requests with names and emails', (
    tester,
  ) async {
    when(() => repo.watch(any())).thenAnswer(
      (_) => Stream.value([
        _request(),
        _request(
          id: 'r2',
          firstName: 'Bob',
          lastName: 'Durand',
          email: 'bob@example.com',
          status: MemberJoinRequestStatus.approved,
        ),
      ]),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('Bob Durand'), findsOneWidget);
    expect(find.text('alice@example.com'), findsOneWidget);
    // Status badge for the approved request.
    expect(find.text('Approuvée'), findsOneWidget);
  });

  testWidgets(
    'tapping a pending request opens the detail with action buttons',
    (tester) async {
      when(
        () => repo.watch(any()),
      ).thenAnswer((_) => Stream.value([_request()]));

      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice Martin'));
      await tester.pumpAndSettle();

      expect(find.text('Approuver'), findsOneWidget);
      expect(find.text('Rejeter'), findsOneWidget);
    },
  );

  testWidgets('approving a request calls the repository and syncs', (
    tester,
  ) async {
    when(() => repo.watch(any())).thenAnswer((_) => Stream.value([_request()]));
    when(() => repo.approve(any())).thenAnswer((_) async => 'op-1');
    when(
      () => syncRepo.sync(tenantId: any(named: 'tenantId')),
    ).thenAnswer((_) async => const SyncOutcome.success());

    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice Martin'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approuver'));
    await tester.pumpAndSettle();

    verify(() => repo.approve(any())).called(1);
    verify(() => syncRepo.sync(tenantId: 'org-1')).called(1);
  });

  testWidgets('rejecting a request opens a dialog and calls reject', (
    tester,
  ) async {
    when(() => repo.watch(any())).thenAnswer((_) => Stream.value([_request()]));
    when(
      () => repo.reject(any(), reviewComment: any(named: 'reviewComment')),
    ).thenAnswer((_) async => 'op-2');
    when(
      () => syncRepo.sync(tenantId: any(named: 'tenantId')),
    ).thenAnswer((_) async => const SyncOutcome.success());

    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice Martin'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rejeter'));
    await tester.pumpAndSettle();
    expect(find.text('Rejeter la demande'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hors zone');
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    verify(() => repo.reject(any(), reviewComment: 'Hors zone')).called(1);
  });
}
