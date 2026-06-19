import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/producer/producer_deliveries_screen.dart';
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

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

_MockSyncBloc _makeSyncBloc() {
  final bloc = _MockSyncBloc();
  when(() => bloc.state).thenReturn(const SyncState.idle());
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

const _orgId = 'org-1';
const _producerAccountId = 'producer-sub-1';
const _contractId = 'contract-1';

const _contract = Contract(
  contractId: _contractId,
  name: 'Légumes',
  organizationId: _orgId,
  producerAccountId: _producerAccountId,
  minDeliveryDate: '2025-01-01T00:00:00',
  maxDeliveryDate: '2025-12-31T00:00:00',
  deliveryCount: 12,
  seasonYear: 2025,
);

Delivery _delivery({
  String deliveryId = 'd-1',
  String scheduledDate = '2025-06-14T18:00:00',
  DeliveryStatus status = DeliveryStatus.planned,
  List<DeliveryContract> contracts = const [],
}) => Delivery(
  deliveryId: deliveryId,
  organizationId: _orgId,
  scheduledDate: scheduledDate,
  status: status,
  minVolunteersRequired: 3,
  contracts: contracts,
);

Organization _org({List<Delivery> deliveries = const []}) => Organization(
  organizationId: _orgId,
  name: 'AMAP Test',
  contactEmail: 'test@amap.fr',
  deliveries: deliveries,
);

DeliveryContract _dc({
  String contractId = _contractId,
}) => DeliveryContract(
  contractId: contractId,
  basketQuantity: 1,
  deliveryDescription: '',
  status: DeliveryContractStatus.pending,
);

Future<void> _pump(
  WidgetTester tester, {
  required _MockOrganizationRepository orgRepo,
  required _MockContractRepository contractRepo,
  String tenantId = _producerAccountId,
  String producerAccountId = _producerAccountId,
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
        RepositoryProvider<ContractRepository>.value(value: contractRepo),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: _makeSyncBloc(),
        child: MaterialApp(
          home: ProducerDeliveriesScreen(
            tenantId: tenantId,
            producerAccountId: producerAccountId,
          ),
        ),
      ),
    ),
  );
  // Two pumps needed: first lets the outer StreamBuilder receive the org, the
  // second lets the inner StreamBuilder receive the contracts.
  await tester.pump();
  await tester.pump();
}

void main() {
  late _MockOrganizationRepository orgRepo;
  late _MockContractRepository contractRepo;

  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    contractRepo = _MockContractRepository();
  });

  group('ProducerDeliveriesScreen', () {
    testWidgets('shows loading spinner while org is not yet available', (
      tester,
    ) async {
      when(
        () => orgRepo.watch(_producerAccountId),
      ).thenAnswer((_) => const Stream.empty());

      await _pump(tester, orgRepo: orgRepo, contractRepo: contractRepo);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when org has no relevant deliveries', (
      tester,
    ) async {
      // Org with one delivery but no linked contracts for this producer.
      const otherContractId = 'contract-other';
      final org = _org(
        deliveries: [
          _delivery(contracts: [_dc(contractId: otherContractId)]),
        ],
      );
      when(
        () => orgRepo.watch(_producerAccountId),
      ).thenAnswer((_) => Stream.value(org));
      when(
        () => contractRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([_contract])); // contract-1 ≠ contract-other

      await _pump(tester, orgRepo: orgRepo, contractRepo: contractRepo);

      expect(
        find.text('Aucune livraison pour vos produits.'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when org has no deliveries at all', (
      tester,
    ) async {
      when(
        () => orgRepo.watch(_producerAccountId),
      ).thenAnswer((_) => Stream.value(_org()));
      when(
        () => contractRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([_contract]));

      await _pump(tester, orgRepo: orgRepo, contractRepo: contractRepo);

      expect(
        find.text('Aucune livraison pour vos produits.'),
        findsOneWidget,
      );
    });

    testWidgets('renders relevant deliveries', (tester) async {
      final org = _org(
        deliveries: [
          _delivery(
            deliveryId: 'd-1',
            scheduledDate: '2025-06-14T18:00:00',
            contracts: [_dc()], // links to contract-1 → this producer
          ),
          _delivery(
            deliveryId: 'd-2',
            scheduledDate: '2025-07-12T18:00:00',
            contracts: [_dc()],
          ),
        ],
      );
      when(
        () => orgRepo.watch(_producerAccountId),
      ).thenAnswer((_) => Stream.value(org));
      when(
        () => contractRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([_contract]));

      await _pump(tester, orgRepo: orgRepo, contractRepo: contractRepo);

      // Two delivery tiles.
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('does not show deliveries from other producers', (
      tester,
    ) async {
      const otherContract = Contract(
        contractId: 'contract-other',
        name: 'Fruits',
        organizationId: _orgId,
        producerAccountId: 'other-producer',
        minDeliveryDate: '2025-01-01T00:00:00',
        maxDeliveryDate: '2025-12-31T00:00:00',
        deliveryCount: 12,
        seasonYear: 2025,
      );
      final org = _org(
        deliveries: [
          _delivery(
            deliveryId: 'd-mine',
            scheduledDate: '2025-06-14T18:00:00',
            contracts: [_dc()], // contract-1 → this producer
          ),
          _delivery(
            deliveryId: 'd-other',
            scheduledDate: '2025-07-12T18:00:00',
            contracts: [_dc(contractId: 'contract-other')], // other producer
          ),
        ],
      );
      when(
        () => orgRepo.watch(_producerAccountId),
      ).thenAnswer((_) => Stream.value(org));
      when(
        () => contractRepo.watch(_orgId),
      ).thenAnswer(
        (_) => Stream.value([_contract, otherContract]),
      );

      await _pump(tester, orgRepo: orgRepo, contractRepo: contractRepo);

      // Only the tile for this producer's delivery.
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('renders screen title', (tester) async {
      when(
        () => orgRepo.watch(_producerAccountId),
      ).thenAnswer((_) => Stream.value(_org()));
      when(
        () => contractRepo.watch(_orgId),
      ).thenAnswer((_) => Stream.value([]));

      await _pump(tester, orgRepo: orgRepo, contractRepo: contractRepo);

      expect(find.text('Mes livraisons'), findsOneWidget);
    });
  });
}
