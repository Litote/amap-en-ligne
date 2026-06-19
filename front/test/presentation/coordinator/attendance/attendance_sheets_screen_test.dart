import 'package:amap_en_ligne/data/repositories/attendance_email_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/presentation/coordinator/attendance/attendance_sheets_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/organization_fixtures.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockBasketExchangeRepository extends Mock
    implements BasketExchangeRepository {}

class _MockAttendanceEmailRequestRepository extends Mock
    implements AttendanceEmailRequestRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

const _orgId = 'org-1';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr', null);
  });

  late _MockOrganizationRepository orgRepo;
  late _MockContractRepository contractRepo;
  late _MockMemberRepository memberRepo;
  late _MockBasketExchangeRepository exchangeRepo;
  late _MockAttendanceEmailRequestRepository attendanceRepo;
  late _MockSyncBloc syncBloc;

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    contractRepo = _MockContractRepository();
    memberRepo = _MockMemberRepository();
    exchangeRepo = _MockBasketExchangeRepository();
    attendanceRepo = _MockAttendanceEmailRequestRepository();
    syncBloc = _MockSyncBloc();

    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => contractRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Contract>[]));
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Member>[]));
    when(
      () => exchangeRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <BasketExchange>[]));
  });

  Future<void> pump(WidgetTester tester, {String tenantId = _orgId}) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
          RepositoryProvider<ContractRepository>.value(value: contractRepo),
          RepositoryProvider<MemberRepository>.value(value: memberRepo),
          RepositoryProvider<BasketExchangeRepository>.value(
            value: exchangeRepo,
          ),
          RepositoryProvider<AttendanceEmailRequestRepository>.value(
            value: attendanceRepo,
          ),
        ],
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: MaterialApp(home: AttendanceSheetsScreen(tenantId: tenantId)),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpAndSelectDelivery(WidgetTester tester) async {
    final delivery = buildDelivery(
      scheduledDate: '2030-01-15T18:00:00',
      contracts: [buildContract()],
    );
    when(
      () => orgRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

    await pump(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('janvier 2030').last);
    await tester.pumpAndSettle();
  }

  testWidgets('shows a spinner when the tenant is not resolved yet', (
    tester,
  ) async {
    await pump(tester, tenantId: '');

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('asks to select a delivery before showing anything', (
    tester,
  ) async {
    final delivery = buildDelivery(scheduledDate: '2030-01-15T18:00:00');
    when(
      () => orgRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

    await pump(tester);
    await tester.pump();

    expect(find.text('Sélectionnez une livraison.'), findsOneWidget);
    expect(find.text('Télécharger PDF'), findsNothing);
  });

  testWidgets('shows "Aucune livraison." when the org has no deliveries', (
    tester,
  ) async {
    when(
      () => orgRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [])));

    await pump(tester);
    await tester.pump();

    expect(find.text('Aucune livraison.'), findsOneWidget);
  });

  testWidgets('selecting a delivery reveals the PDF and email actions', (
    tester,
  ) async {
    await pumpAndSelectDelivery(tester);

    expect(find.text('Télécharger PDF'), findsOneWidget);
    expect(find.text('Envoyer email'), findsOneWidget);
  });

  testWidgets('cancelling the email dialog sends nothing', (tester) async {
    await pumpAndSelectDelivery(tester);

    await tester.tap(find.text('Envoyer email'));
    await tester.pumpAndSettle();
    expect(find.text('Envoyer par email'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    verifyNever(
      () => attendanceRepo.create(
        organizationId: any(named: 'organizationId'),
        deliveryId: any(named: 'deliveryId'),
        recipientEmail: any(named: 'recipientEmail'),
      ),
    );
  });

  testWidgets('sending the email creates the request and triggers a sync', (
    tester,
  ) async {
    when(
      () => attendanceRepo.create(
        organizationId: any(named: 'organizationId'),
        deliveryId: any(named: 'deliveryId'),
        recipientEmail: any(named: 'recipientEmail'),
      ),
    ).thenAnswer((_) async => 'op-1');

    await pumpAndSelectDelivery(tester);

    await tester.tap(find.text('Envoyer email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'coordo@amap.fr');
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    verify(
      () => attendanceRepo.create(
        organizationId: _orgId,
        deliveryId: any(named: 'deliveryId'),
        recipientEmail: 'coordo@amap.fr',
      ),
    ).called(1);
    verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
    expect(find.text('Envoi planifié pour coordo@amap.fr'), findsOneWidget);

    // Let the snackbar auto-dismiss so no timer is left pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
