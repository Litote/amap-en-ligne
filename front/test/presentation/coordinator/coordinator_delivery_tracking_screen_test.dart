import 'dart:async';

import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_delivery_tracking_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/organization_fixtures.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

Future<void> _pumpWith(
  WidgetTester tester, {
  required OrganizationRepository organizationRepository,
  required MemberRepository memberRepository,
  required SyncBloc syncBloc,
  ContractRepository? contractRepository,
  String tenantId = 'org-1',
  String deliveryId = 'd-1',
}) async {
  when(() => syncBloc.state).thenReturn(const SyncState.idle());
  when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
  // The tracking body watches contracts; default to an empty stream so
  // activeContractsForDelivery falls back to the delivery's own contract links.
  final contracts = contractRepository ?? _MockContractRepository();
  when(
    () => contracts.watch(any()),
  ).thenAnswer((_) => Stream.value(const <Contract>[]));
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(
          value: organizationRepository,
        ),
        RepositoryProvider<MemberRepository>.value(value: memberRepository),
        RepositoryProvider<ContractRepository>.value(value: contracts),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(
          home: CoordinatorDeliveryTrackingScreen(
            tenantId: tenantId,
            deliveryId: deliveryId,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Organization(
        organizationId: 'fallback',
        name: 'fallback',
        contactEmail: 'fallback@test.fr',
      ),
    );
    registerFallbackValue(RegistrationStatus.registered);
    registerFallbackValue(DeliveryContractStatus.pending);
    registerFallbackValue(const SyncEvent.mutationApplied());
  });

  group('CoordinatorDeliveryTrackingScreen — rendering', () {
    late _MockOrganizationRepository organizationRepository;
    late _MockMemberRepository memberRepository;
    late _MockSyncBloc syncBloc;
    late StreamController<Organization?> organizationStream;

    setUp(() {
      organizationRepository = _MockOrganizationRepository();
      memberRepository = _MockMemberRepository();
      syncBloc = _MockSyncBloc();
      organizationStream = StreamController<Organization?>.broadcast();
      when(
        () => organizationRepository.watch(any()),
      ).thenAnswer((_) => organizationStream.stream);
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value(const <Member>[]));
    });

    tearDown(() async {
      await organizationStream.close();
    });

    testWidgets('shows loading indicator when tenantId is empty', (
      tester,
    ) async {
      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
        tenantId: '',
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "Livraison introuvable." for unknown deliveryId', (
      tester,
    ) async {
      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
        deliveryId: 'unknown',
      );
      await tester.pump();

      organizationStream.add(buildOrg(deliveries: const []));
      await tester.pump();

      expect(find.text('Livraison introuvable.'), findsOneWidget);
    });

    testWidgets('shows volunteer section with no registrations', (
      tester,
    ) async {
      final slot = buildSlot(registrations: const []);
      final contract = buildContract(slots: [slot]);
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        contracts: [contract],
      );

      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.textContaining('Présence des bénévoles'), findsOneWidget);
      expect(find.text('Aucun bénévole inscrit.'), findsOneWidget);
    });

    testWidgets('shows volunteer displayName for registered volunteer', (
      tester,
    ) async {
      final registration = buildRegistration(
        displayName: 'Jean Dupont',
        status: RegistrationStatus.registered,
      );
      final slot = buildSlot(
        registrations: [registration],
        requiredVolunteers: 1,
        currentRegistrations: 1,
      );
      final contract = buildContract(slots: [slot]);
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        contracts: [contract],
      );

      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('Jean Dupont'), findsOneWidget);
      expect(find.text('À confirmer'), findsOneWidget);
    });

    testWidgets('confirmed volunteer shows simplified present absent toggles', (
      tester,
    ) async {
      final registration = buildRegistration(
        displayName: 'Jeanne Dupont',
        status: RegistrationStatus.confirmed,
      );
      final slot = buildSlot(registrations: [registration]);
      final contract = buildContract(slots: [slot]);
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        contracts: [contract],
      );

      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.text('Présent'), findsOneWidget);
      expect(find.text('PRÉSENT'), findsOneWidget);
      expect(find.text('ABSENT'), findsOneWidget);
      expect(find.text('SORTIE'), findsNothing);
    });

    testWidgets('shows contract pickup section', (tester) async {
      final contract = buildContract(
        deliveryDescription: 'Panier légumes',
        basketQuantity: 5,
      );
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        contracts: [contract],
      );

      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.textContaining('Récupération des paniers'), findsOneWidget);
      expect(find.text('Non collecté'), findsOneWidget);
    });

    testWidgets('shows progression section', (tester) async {
      final delivery = buildDelivery(status: DeliveryStatus.inProgress);

      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();

      expect(find.textContaining('Progression'), findsOneWidget);
    });
  });

  group('Coordinators section', () {
    late _MockOrganizationRepository organizationRepository;
    late _MockMemberRepository memberRepository;
    late _MockSyncBloc syncBloc;
    late StreamController<Organization?> organizationStream;

    Member buildCoord({
      String memberId = 'coord-1',
      String? firstName = 'Jean',
      String? lastName = 'Morel',
      String? phone,
    }) => Member(
      memberId: memberId,
      organizationId: 'org-1',
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );

    setUp(() {
      organizationRepository = _MockOrganizationRepository();
      memberRepository = _MockMemberRepository();
      syncBloc = _MockSyncBloc();
      organizationStream = StreamController<Organization?>.broadcast();
      when(
        () => organizationRepository.watch(any()),
      ).thenAnswer((_) => organizationStream.stream);
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value(const <Member>[]));
    });

    tearDown(() async {
      await organizationStream.close();
    });

    testWidgets('renders coordinators section grouped by contract', (
      tester,
    ) async {
      final coordinator = buildCoord();
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([coordinator]));

      final contract = buildContract(
        contractId: 'c-1',
        coordinators: ['coord-1'],
        deliveryDescription: 'Panier légumes',
      );
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        contracts: [contract],
      );

      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.textContaining('Coordinateurs de cette livraison'),
        findsOneWidget,
      );
      expect(find.textContaining('Jean Morel'), findsOneWidget);
    });

    testWidgets('shows phone link when coordinator has phone', (tester) async {
      final coordinator = buildCoord(phone: '06 12 34 56 78');
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([coordinator]));

      final contract = buildContract(
        contractId: 'c-1',
        coordinators: ['coord-1'],
        deliveryDescription: 'Légumes',
      );
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        contracts: [contract],
      );

      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrg(deliveries: [delivery]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('06 12 34 56 78'), findsOneWidget);
      // InkWell wrapping the phone link should be present.
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets(
      'shows "(téléphone non communiqué)" when coordinator phone is null',
      (tester) async {
        final coordinator = buildCoord(phone: null);
        when(
          () => memberRepository.watch(any()),
        ).thenAnswer((_) => Stream.value([coordinator]));

        final contract = buildContract(
          contractId: 'c-1',
          coordinators: ['coord-1'],
          deliveryDescription: 'Légumes',
        );
        final delivery = buildDelivery(
          status: DeliveryStatus.inProgress,
          contracts: [contract],
        );

        await _pumpWith(
          tester,
          organizationRepository: organizationRepository,
          memberRepository: memberRepository,
          syncBloc: syncBloc,
        );
        await tester.pump();

        organizationStream.add(buildOrg(deliveries: [delivery]));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.textContaining('téléphone non communiqué'), findsOneWidget);
      },
    );

    testWidgets(
      'shows "Coordinateur à confirmer" when contract has no coordinators',
      (tester) async {
        final contract = buildContract(
          contractId: 'c-1',
          coordinators: const [],
          deliveryDescription: 'Légumes',
        );
        final delivery = buildDelivery(
          status: DeliveryStatus.inProgress,
          contracts: [contract],
        );

        await _pumpWith(
          tester,
          organizationRepository: organizationRepository,
          memberRepository: memberRepository,
          syncBloc: syncBloc,
        );
        await tester.pump();

        organizationStream.add(buildOrg(deliveries: [delivery]));
        await tester.pump();

        expect(find.text('Coordinateur à confirmer'), findsOneWidget);
      },
    );
  });

  group('CoordinatorDeliveryTrackingScreen — mutations', () {
    late _MockOrganizationRepository organizationRepository;
    late _MockMemberRepository memberRepository;
    late _MockSyncBloc syncBloc;
    late StreamController<Organization?> organizationStream;

    setUp(() {
      organizationRepository = _MockOrganizationRepository();
      memberRepository = _MockMemberRepository();
      syncBloc = _MockSyncBloc();
      organizationStream = StreamController<Organization?>.broadcast();
      when(
        () => organizationRepository.watch(any()),
      ).thenAnswer((_) => organizationStream.stream);
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value(const <Member>[]));
      when(
        () => organizationRepository.updateRegistrationStatus(
          currentOrg: any(named: 'currentOrg'),
          deliveryId: any(named: 'deliveryId'),
          contractId: any(named: 'contractId'),
          memberId: any(named: 'memberId'),
          newStatus: any(named: 'newStatus'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => organizationRepository.updateDeliveryContractStatus(
          currentOrg: any(named: 'currentOrg'),
          deliveryId: any(named: 'deliveryId'),
          contractId: any(named: 'contractId'),
          newStatus: any(named: 'newStatus'),
        ),
      ).thenAnswer((_) async {});
      when(() => syncBloc.add(any())).thenReturn(null);
    });

    tearDown(() async {
      await organizationStream.close();
    });

    testWidgets('PRÉSENT button confirms volunteer and triggers sync', (
      tester,
    ) async {
      const memberId = 'member-1';
      final registration = buildRegistration(
        memberId: memberId,
        displayName: 'Jean Dupont',
        status: RegistrationStatus.registered,
      );
      final slot = buildSlot(
        registrations: [registration],
        requiredVolunteers: 1,
        currentRegistrations: 1,
      );
      final contract = buildContract(slots: [slot]);
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        contracts: [contract],
      );
      final organization = buildOrg(deliveries: [delivery]);

      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(organization);
      await tester.pump();

      await tester.tap(find.text('PRÉSENT'));
      await tester.pump();

      verify(
        () => organizationRepository.updateRegistrationStatus(
          currentOrg: organization,
          deliveryId: delivery.deliveryId,
          contractId: contract.contractId,
          memberId: memberId,
          newStatus: RegistrationStatus.confirmed,
        ),
      ).called(1);
      verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
    });

    testWidgets('ABSENT button cancels volunteer and triggers sync', (
      tester,
    ) async {
      const memberId = 'member-1';
      final registration = buildRegistration(
        memberId: memberId,
        status: RegistrationStatus.registered,
      );
      final slot = buildSlot(registrations: [registration]);
      final contract = buildContract(slots: [slot]);
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        contracts: [contract],
      );
      final organization = buildOrg(deliveries: [delivery]);

      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(organization);
      await tester.pump();

      await tester.tap(find.text('ABSENT'));
      await tester.pump();

      verify(
        () => organizationRepository.updateRegistrationStatus(
          currentOrg: organization,
          deliveryId: delivery.deliveryId,
          contractId: contract.contractId,
          memberId: memberId,
          newStatus: RegistrationStatus.cancelled,
        ),
      ).called(1);
      verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
    });

    testWidgets('COLLECTÉ button updates contract and triggers sync', (
      tester,
    ) async {
      final contract = buildContract(
        contractId: 'c-1',
        status: DeliveryContractStatus.pending,
      );
      final delivery = buildDelivery(
        status: DeliveryStatus.inProgress,
        contracts: [contract],
      );
      final organization = buildOrg(deliveries: [delivery]);

      await _pumpWith(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(organization);
      await tester.pump();

      await tester.tap(find.text('COLLECTÉ'));
      await tester.pump();

      verify(
        () => organizationRepository.updateDeliveryContractStatus(
          currentOrg: organization,
          deliveryId: delivery.deliveryId,
          contractId: contract.contractId,
          newStatus: DeliveryContractStatus.distributed,
        ),
      ).called(1);
      verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
    });
  });
}
