import 'package:amap_en_ligne/data/repositories/attendance_email_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/validation/input_rules.dart';
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

  testWidgets('preselects the next delivery, not the oldest one', (
    tester,
  ) async {
    final past = buildDelivery(
      deliveryId: 'd-past',
      scheduledDate: '2020-01-15T18:00:00',
    );
    final next = buildDelivery(
      deliveryId: 'd-next',
      scheduledDate: '2030-01-15T18:00:00',
    );
    final later = buildDelivery(
      deliveryId: 'd-later',
      scheduledDate: '2030-02-15T18:00:00',
    );
    when(() => orgRepo.watch(any())).thenAnswer(
      (_) => Stream.value(buildOrg(deliveries: [later, past, next])),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Sélectionnez une livraison.'), findsNothing);
    expect(find.text('15 janvier 2030 • 18h00'), findsOneWidget);
    expect(find.text('Télécharger PDF'), findsOneWidget);
  });

  testWidgets('preselects the most recent delivery when all are past', (
    tester,
  ) async {
    final older = buildDelivery(
      deliveryId: 'd-older',
      scheduledDate: '2020-01-15T18:00:00',
    );
    final recent = buildDelivery(
      deliveryId: 'd-recent',
      scheduledDate: '2020-02-12T18:00:00',
    );
    when(
      () => orgRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [older, recent])));

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('12 février 2020 • 18h00'), findsOneWidget);
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

  testWidgets('a malformed address is rejected before sending', (tester) async {
    await pumpAndSelectDelivery(tester);

    await tester.tap(find.text('Envoyer email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pas-un-email');
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(find.text(kInvalidEmailMessage), findsOneWidget);
    expect(find.text('Envoyer par email'), findsOneWidget);
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

  test('names the PDF after the delivery date, not its technical id', () {
    final delivery = buildDelivery(
      deliveryId: 'tmp_delivery_1',
      scheduledDate: '2026-10-01T18:00:00',
    );

    expect(attendanceSheetFilename(delivery), 'emargement-2026-10-01.pdf');
  });

  test('the volunteer PDF says so when nobody registered', () {
    expect(attendanceVolunteerSheetEmptyNote(0), 'Aucun bénévole inscrit.');
    expect(attendanceVolunteerSheetEmptyNote(2), isNull);
  });

  group('PDF titles', () {
    final delivery = buildDelivery(scheduledDate: '2026-10-01T18:00:00');

    test('volunteer sheet shows a French date, not the raw ISO instant', () {
      expect(
        attendanceVolunteerSheetTitle(delivery),
        'Émargement bénévoles - 1er octobre 2026',
      );
    });

    test('basket sheet avoids glyphs missing from the default PDF font', () {
      expect(
        attendanceBasketSheetTitle('Oeufs — Boîte de 12', delivery),
        'Récupération paniers - Oeufs - Boîte de 12 - 1er octobre 2026',
      );
    });
  });
}
