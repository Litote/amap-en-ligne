import 'package:amap_en_ligne/data/repositories/attendance_email_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
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
const _deliveryId = 'd1';
const _contractId = 'c1';
const _scheduledDate = '2030-01-15T18:00:00';

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

    when(() => orgRepo.watch(any())).thenAnswer((_) => Stream.value(_org()));
    when(
      () => contractRepo.watch(any()),
    ).thenAnswer((_) => Stream.value([_contract()]));
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(_members()));
    when(
      () => exchangeRepo.watch(any()),
    ).thenAnswer((_) => Stream.value([_confirmedExchange()]));
  });

  Future<void> pump(WidgetTester tester) async {
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
          child: const MaterialApp(
            home: AttendanceSheetsScreen(tenantId: _orgId),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'Paniers tab shows the exchange pickup annotation for the owner basket',
    (tester) async {
      await pump(tester);

      // Select the delivery in the dropdown.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('janvier 2030').last);
      await tester.pumpAndSettle();

      // Switch to the "Paniers" tab.
      await tester.tap(find.text('Paniers'));
      await tester.pumpAndSettle();

      // Owner Alice's basket is annotated as collected by Bob.
      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.textContaining('à remettre à Bob Durand'), findsOneWidget);
    },
  );

  testWidgets('Paniers tab groups members by basket type (product + size)', (
    tester,
  ) async {
    when(
      () => contractRepo.watch(any()),
    ).thenAnswer((_) => Stream.value([_contractWithSubscriptions()]));
    when(() => exchangeRepo.watch(any())).thenAnswer((_) => Stream.value([]));

    await pump(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('janvier 2030').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paniers'));
    await tester.pumpAndSettle();

    // One section header per distinct subscription (product type + basket size).
    expect(find.text('Légumes — Panier 3kg'), findsOneWidget);
    expect(find.text('Légumes — Panier 5kg'), findsOneWidget);

    // Alice (3kg) and Bob (5kg) each land under their own basket type.
    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('Bob Durand'), findsOneWidget);
  });
}

Contract _contractWithSubscriptions() => const Contract(
  contractId: _contractId,
  name: 'Contrat légumes',
  organizationId: _orgId,
  producerAccountId: 'pa-1',
  minDeliveryDate: '2030-01-01T00:00:00',
  maxDeliveryDate: '2030-12-31T00:00:00',
  deliveryCount: 1,
  seasonYear: 2030,
  members: [
    ContractMember(
      memberId: 'A',
      subscriptionInstant: '2030-01-01T00:00:00Z',
      status: ContractMemberStatus.active,
      subscriptions: [
        MemberSubscription(
          productTypeId: 'pt-1',
          basketSize: BasketSize(name: 'Panier 3kg'),
        ),
      ],
    ),
    ContractMember(
      memberId: 'B',
      subscriptionInstant: '2030-01-01T00:00:00Z',
      status: ContractMemberStatus.active,
      subscriptions: [
        MemberSubscription(
          productTypeId: 'pt-1',
          basketSize: BasketSize(name: 'Panier 5kg'),
        ),
      ],
    ),
  ],
);

Organization _org() => const Organization(
  organizationId: _orgId,
  name: 'AMAP Test',
  contactEmail: 'amap@test.fr',
  products: [
    OrgProduct(
      name: 'Légumes',
      productTypeId: 'pt-1',
      producerAccountId: 'pa-1',
    ),
  ],
  deliveries: [
    Delivery(
      deliveryId: _deliveryId,
      organizationId: _orgId,
      scheduledDate: _scheduledDate,
      status: DeliveryStatus.planned,
      minVolunteersRequired: 1,
      contracts: [
        DeliveryContract(
          contractId: _contractId,
          basketQuantity: 10,
          deliveryDescription: 'Panier légumes',
          status: DeliveryContractStatus.pending,
        ),
      ],
    ),
  ],
);

Contract _contract() => const Contract(
  contractId: _contractId,
  name: 'Contrat légumes',
  organizationId: _orgId,
  producerAccountId: 'pa-1',
  minDeliveryDate: '2030-01-01T00:00:00',
  maxDeliveryDate: '2030-12-31T00:00:00',
  deliveryCount: 1,
  seasonYear: 2030,
  members: [
    ContractMember(
      memberId: 'A',
      subscriptionInstant: '2030-01-01T00:00:00Z',
      status: ContractMemberStatus.active,
    ),
  ],
);

List<Member> _members() => const [
  Member(
    memberId: 'A',
    organizationId: _orgId,
    firstName: 'Alice',
    lastName: 'Martin',
  ),
  Member(
    memberId: 'B',
    organizationId: _orgId,
    firstName: 'Bob',
    lastName: 'Durand',
  ),
];

BasketExchange _confirmedExchange() => const BasketExchange(
  basketExchangeId: 'be-1',
  organizationId: _orgId,
  deliveryId: _deliveryId,
  contractId: _contractId,
  offeringMemberId: 'A',
  status: BasketExchangeStatus.accepted,
  createdAt: '2030-01-01T10:00:00Z',
  acceptedRequestId: 'r-1',
  requests: [
    BasketExchangeRequest(
      requestId: 'r-1',
      requesterMemberId: 'B',
      createdAt: '2030-01-02T10:00:00Z',
      status: BasketExchangeRequestStatus.accepted,
      proposedDeliveryId: 'd2',
    ),
  ],
);
