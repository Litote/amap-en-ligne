import 'dart:async';

import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_member_contracts_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

class _FakeContract extends Fake implements Contract {}

Future<void> _pump(
  WidgetTester tester, {
  required OrganizationRepository organizationRepository,
  required MemberRepository memberRepository,
  required ContractRepository contractRepository,
  required SyncBloc syncBloc,
}) async {
  when(() => syncBloc.state).thenReturn(const SyncState.idle());
  when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(
          value: organizationRepository,
        ),
        RepositoryProvider<MemberRepository>.value(value: memberRepository),
        RepositoryProvider<ContractRepository>.value(value: contractRepository),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: const MaterialApp(
          home: CoordinatorMemberContractsScreen(tenantId: 'org-1'),
        ),
      ),
    ),
  );
}

void main() {
  late _MockOrganizationRepository organizationRepository;
  late _MockMemberRepository memberRepository;
  late _MockContractRepository contractRepository;
  late _MockSyncBloc syncBloc;
  late StreamController<Organization?> organizationStream;
  late StreamController<List<Member>> memberStream;
  late StreamController<List<Contract>> contractStream;

  Organization buildOrganization() => const Organization(
    organizationId: 'org-1',
    name: 'AMAP Test',
    contactEmail: 'contact@amap.fr',
    products: [
      OrgProduct(
        name: 'Tomates',
        productTypeId: 'pt-1',
        producerAccountId: 'p-1',
      ),
      OrgProduct(
        name: 'Oeufs',
        productTypeId: 'pt-2',
        producerAccountId: 'p-2',
      ),
    ],
  );

  Member buildMember({required String memberId, required String firstName}) =>
      Member(memberId: memberId, organizationId: 'org-1', firstName: firstName);

  Contract buildContract({
    required String contractId,
    String producerAccountId = 'pa-1',
    List<ContractMember> members = const [],
    List<ProductPrice> productPrices = const [
      ProductPrice(productTypeId: 'pt-1'),
    ],
    ContractStatus status = ContractStatus.active,
  }) => Contract(
    contractId: contractId,
    name: 'Contrat test',
    organizationId: 'org-1',
    producerAccountId: producerAccountId,
    // Active season: starts before today (2026-06-10) and ends after.
    minDeliveryDate: '2026-01-01',
    maxDeliveryDate: '2026-12-31',
    deliveryCount: 10,
    seasonYear: 2026,
    productPrices: productPrices,
    members: members,
    status: status,
  );

  /// Builds a contract whose season has already ended (maxDeliveryDate < today).
  Contract buildEndedContract({
    required String contractId,
    String producerAccountId = 'pa-1',
    List<ContractMember> members = const [],
  }) => Contract(
    contractId: contractId,
    name: 'Contrat test',
    organizationId: 'org-1',
    producerAccountId: producerAccountId,
    // Ended season: both dates are in the past relative to 2026-06-10.
    minDeliveryDate: '2025-01-01',
    maxDeliveryDate: '2025-12-31',
    deliveryCount: 10,
    seasonYear: 2025,
    members: members,
  );

  setUpAll(() {
    registerFallbackValue(_FakeContract());
  });

  setUp(() {
    organizationRepository = _MockOrganizationRepository();
    memberRepository = _MockMemberRepository();
    contractRepository = _MockContractRepository();
    syncBloc = _MockSyncBloc();
    organizationStream = StreamController<Organization?>.broadcast();
    memberStream = StreamController<List<Member>>.broadcast();
    contractStream = StreamController<List<Contract>>.broadcast();

    when(
      () => organizationRepository.watch(any()),
    ).thenAnswer((_) => organizationStream.stream);
    when(
      () => memberRepository.watch(any()),
    ).thenAnswer((_) => memberStream.stream);
    when(
      () => contractRepository.watch(any()),
    ).thenAnswer((_) => contractStream.stream);
    when(() => contractRepository.update(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await organizationStream.close();
    await memberStream.close();
    await contractStream.close();
  });

  testWidgets('assigns a contract to a member with subscription', (
    tester,
  ) async {
    await _pump(
      tester,
      organizationRepository: organizationRepository,
      memberRepository: memberRepository,
      contractRepository: contractRepository,
      syncBloc: syncBloc,
    );
    await tester.pump();

    organizationStream.add(buildOrganization());
    await tester.pump();
    memberStream.add([buildMember(memberId: 'm-1', firstName: 'Alice')]);
    await tester.pump();
    // Single product price → auto-pre-check will fire
    contractStream.add([
      buildContract(contractId: 'c-active', producerAccountId: 'p-1'),
    ]);
    await tester.pumpAndSettle();

    // Check the contract: with a single subscription option, it is auto-pre-checked
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();

    // Assign (subscription was auto-pre-checked)
    await tester.tap(find.text('AFFECTER LA SÉLECTION'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final captured =
        verify(() => contractRepository.update(captureAny())).captured.single
            as Contract;
    expect(captured.members, hasLength(1));
    expect(captured.members.single.memberId, 'm-1');
    expect(captured.members.single.subscriptions, isNotEmpty);
  });

  testWidgets(
    'assignment is blocked when no subscription selected for a contract',
    (tester) async {
      await _pump(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        contractRepository: contractRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrganization());
      await tester.pump();
      memberStream.add([buildMember(memberId: 'm-1', firstName: 'Alice')]);
      await tester.pump();
      // Two product prices → no auto-pre-check
      contractStream.add([
        buildContract(
          contractId: 'c-multi',
          producerAccountId: 'p-1',
          productPrices: const [
            ProductPrice(productTypeId: 'pt-1'),
            ProductPrice(productTypeId: 'pt-2'),
          ],
        ),
      ]);
      await tester.pumpAndSettle();

      // Check the contract but do NOT check any subscription option
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('AFFECTER LA SÉLECTION'));
      await tester.pump();

      expect(
        find.textContaining('Sélectionnez au moins un produit'),
        findsOneWidget,
      );
      verifyNever(() => contractRepository.update(any()));
    },
  );

  testWidgets('assigned contract card shows subscription label', (
    tester,
  ) async {
    await _pump(
      tester,
      organizationRepository: organizationRepository,
      memberRepository: memberRepository,
      contractRepository: contractRepository,
      syncBloc: syncBloc,
    );
    await tester.pump();

    organizationStream.add(buildOrganization());
    await tester.pump();
    memberStream.add([buildMember(memberId: 'm-1', firstName: 'Alice')]);
    await tester.pump();
    contractStream.add([
      buildContract(
        contractId: 'c-active',
        producerAccountId: 'p-1',
        members: const [
          ContractMember(
            memberId: 'm-1',
            subscriptionInstant: '2026-01-01T00:00:00Z',
            status: ContractMemberStatus.active,
            subscriptions: [MemberSubscription(productTypeId: 'pt-1')],
          ),
        ],
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.textContaining('📦'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'MODIFIER'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'RETIRER'), findsOneWidget);
  });

  testWidgets(
    'MODIFIER flow updates subscriptions preserving status and instant',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await _pump(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        contractRepository: contractRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrganization());
      await tester.pump();
      memberStream.add([buildMember(memberId: 'm-1', firstName: 'Alice')]);
      await tester.pump();
      contractStream.add([
        buildContract(
          contractId: 'c-active',
          producerAccountId: 'p-1',
          productPrices: const [
            ProductPrice(productTypeId: 'pt-1'),
            ProductPrice(productTypeId: 'pt-2'),
          ],
          members: const [
            ContractMember(
              memberId: 'm-1',
              subscriptionInstant: '2026-01-01T00:00:00Z',
              status: ContractMemberStatus.suspended,
              subscriptions: [MemberSubscription(productTypeId: 'pt-1')],
            ),
          ],
        ),
      ]);
      await tester.pumpAndSettle();

      // Open inline editor
      await tester.tap(find.widgetWithText(TextButton, 'MODIFIER'));
      await tester.pumpAndSettle();

      expect(find.text('ENREGISTRER'), findsOneWidget);
      expect(find.text('ANNULER'), findsOneWidget);

      // Toggle a subscription option (check the second one)
      final checkboxes = find.byType(CheckboxListTile);
      await tester.tap(checkboxes.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('ENREGISTRER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final captured =
          verify(() => contractRepository.update(captureAny())).captured.single
              as Contract;
      final updatedEntry = captured.members.single;
      expect(updatedEntry.memberId, 'm-1');
      expect(updatedEntry.status, ContractMemberStatus.suspended);
      expect(updatedEntry.subscriptionInstant, '2026-01-01T00:00:00Z');
      expect(updatedEntry.subscriptions, isNotEmpty);
    },
  );

  testWidgets(
    'ended contract does not appear in the available-for-assignment section',
    (tester) async {
      await _pump(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        contractRepository: contractRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrganization());
      await tester.pump();
      memberStream.add([buildMember(memberId: 'm-1', firstName: 'Alice')]);
      await tester.pump();
      contractStream.add([
        // Active contract — should appear in available section.
        buildContract(contractId: 'c-active', producerAccountId: 'p-1'),
        // Ended contract — must NOT appear in available section.
        buildEndedContract(contractId: 'c-ended', producerAccountId: 'p-2'),
      ]);
      await tester.pumpAndSettle();

      // The active contract's product is available for assignment.
      expect(find.text('Tomates'), findsOneWidget);
      // The ended contract's product must not be in the available list.
      expect(find.text('Oeufs'), findsNothing);
    },
  );

  testWidgets(
    'ended contract already assigned to a member is still listed with its Terminé label',
    (tester) async {
      await _pump(
        tester,
        organizationRepository: organizationRepository,
        memberRepository: memberRepository,
        contractRepository: contractRepository,
        syncBloc: syncBloc,
      );
      await tester.pump();

      organizationStream.add(buildOrganization());
      await tester.pump();
      memberStream.add([buildMember(memberId: 'm-1', firstName: 'Alice')]);
      await tester.pump();
      contractStream.add([
        // Ended contract already assigned to Alice.
        buildEndedContract(
          contractId: 'c-ended-assigned',
          producerAccountId: 'p-2',
          members: const [
            ContractMember(
              memberId: 'm-1',
              subscriptionInstant: '2025-01-01T00:00:00Z',
              status: ContractMemberStatus.active,
            ),
          ],
        ),
      ]);
      await tester.pumpAndSettle();

      // Assigned section must show the contract with "Terminé" status label.
      expect(find.textContaining('Terminé'), findsOneWidget);
      // The RETIRER button must be present for already-assigned contracts.
      expect(find.widgetWithText(TextButton, 'RETIRER'), findsOneWidget);
    },
  );

  testWidgets('shows snackbar when sync returns a CONTRACT_ENDED rejection', (
    tester,
  ) async {
    // Set up a live stream controller BEFORE pumping so BlocListener
    // subscribes to the real stream from the start.
    final syncStateController = StreamController<SyncState>.broadcast();
    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => syncStateController.stream);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OrganizationRepository>.value(
            value: organizationRepository,
          ),
          RepositoryProvider<MemberRepository>.value(value: memberRepository),
          RepositoryProvider<ContractRepository>.value(
            value: contractRepository,
          ),
        ],
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: const MaterialApp(
            home: CoordinatorMemberContractsScreen(tenantId: 'org-1'),
          ),
        ),
      ),
    );
    await tester.pump();

    organizationStream.add(buildOrganization());
    await tester.pump();
    memberStream.add([buildMember(memberId: 'm-1', firstName: 'Alice')]);
    await tester.pump();
    contractStream.add([]);
    // Extra pump to ensure ContractEndedListener is fully mounted and has
    // subscribed to syncBloc.stream before we push the rejection state.
    await tester.pump();
    await tester.pump();

    // Simulate a SyncSucceeded state carrying a CONTRACT_ENDED rejection.
    syncStateController.add(
      SyncState.success(
        rejectedMutations: [
          const MutationOutcome(
            clientOpId: 'op-1',
            status: MutationStatus.rejected,
            error: MutationError(
              code: MutationErrorCode.contractEnded,
              message: 'contract season has ended',
            ),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('Opération refusée : ce contrat est terminé.'),
      findsOneWidget,
    );

    await syncStateController.close();
  });
}
