import 'dart:async';
import 'dart:convert';

import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/common/error_feedback.dart';
import 'package:amap_en_ligne/presentation/coordinator/time_slots/time_slot_form_screen.dart';
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

class _MockDeliveryTemplateRepository extends Mock
    implements DeliveryTemplateRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockProducerAccountRepository extends Mock
    implements ProducerAccountRepository {}

class _MockAuthService extends Mock implements AuthService {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

Finder _minVolunteersField() => find.byType(TextFormField).first;
Finder _saveButton() => find.widgetWithText(FilledButton, 'Enregistrer');

Future<void> _tapSaveButton(WidgetTester tester) async {
  await tester.ensureVisible(_saveButton());
  await tester.tap(_saveButton());
}

const _delivery = Delivery(
  deliveryId: 'd-1',
  organizationId: 'org-1',
  scheduledDate: '2025-06-14T18:00:00Z',
  status: DeliveryStatus.planned,
  minVolunteersRequired: 2,
  basketDescriptions: [
    BasketDeliveryDescription(productTypeId: 'pt-1', basketSizeName: 'Petit'),
  ],
);

const _organization = Organization(
  organizationId: 'org-1',
  name: 'AMAP Test',
  contactEmail: 'test@amap.fr',
  defaultDeliveryTemplateId: 'dt-1',
  products: [
    OrgProduct(
      name: 'Tomates',
      productTypeId: 'pt-1',
      producerAccountId: 'producer-1',
      supportedBasketSizes: [BasketSize(name: 'Petit')],
    ),
    OrgProduct(
      name: 'Oeufs',
      productTypeId: 'pt-2',
      producerAccountId: 'producer-2',
      supportedBasketSizes: [BasketSize(name: 'Petit')],
    ),
  ],
  deliveries: [_delivery],
);

const _templates = [
  DeliveryTemplate(
    deliveryTemplateId: 'dt-1',
    organizationId: 'org-1',
    name: 'Marché du soir',
    standardStartTime: '18:00',
    standardEndTime: '20:00',
    desiredVolunteerCount: 2,
  ),
  DeliveryTemplate(
    deliveryTemplateId: 'dt-2',
    organizationId: 'org-1',
    name: 'Marché du samedi',
    standardStartTime: '09:00',
    standardEndTime: '11:00',
    desiredVolunteerCount: 5,
  ),
];

// Season contracts used by the contract-first selection tests. Both span
// far into the future so they are active whatever the test clock says.
// _contractVegs declares its products through productPrices while
// _contractEggs is a legacy contract without any price entry (its products
// fall back to its producer's catalog).
const _contractVegs = Contract(
  contractId: 'c-vegs',
  name: 'Légumes de saison',
  organizationId: 'org-1',
  producerAccountId: 'producer-1',
  minDeliveryDate: '2020-01-01',
  maxDeliveryDate: '2099-12-31',
  deliveryCount: 10,
  seasonYear: 2026,
  isMainContract: true,
  productPrices: [
    ProductPrice(
      productTypeId: 'pt-1',
      basketSize: BasketSize(name: 'Petit'),
    ),
  ],
  members: [
    ContractMember(
      memberId: 'm-active',
      subscriptionInstant: '2026-01-01T00:00:00Z',
      status: ContractMemberStatus.active,
      subscriptions: [MemberSubscription(productTypeId: 'pt-1')],
    ),
    ContractMember(
      memberId: 'm-cancelled',
      subscriptionInstant: '2026-01-01T00:00:00Z',
      status: ContractMemberStatus.cancelled,
      subscriptions: [MemberSubscription(productTypeId: 'pt-1')],
    ),
  ],
);

const _contractEggs = Contract(
  contractId: 'c-eggs',
  name: 'Œufs fermiers',
  organizationId: 'org-1',
  producerAccountId: 'producer-2',
  minDeliveryDate: '2020-01-01',
  maxDeliveryDate: '2099-12-31',
  deliveryCount: 10,
  seasonYear: 2026,
);

const _endedContract = Contract(
  contractId: 'c-ended',
  name: 'Contrat terminé',
  organizationId: 'org-1',
  producerAccountId: 'producer-3',
  minDeliveryDate: '2020-01-01',
  maxDeliveryDate: '2020-12-31',
  deliveryCount: 10,
  seasonYear: 2020,
);

const _producerAccounts = [
  ProducerAccount(producerAccountId: 'producer-1', name: 'Maraîcher Bio'),
  ProducerAccount(producerAccountId: 'producer-2', name: 'Œufs Fermiers'),
  ProducerAccount(producerAccountId: 'producer-3', name: 'Ferme Terminée'),
];

/// Builds a minimal (unsigned) JWT with the given sub claim.
String _fakeJwt(String sub) {
  final payload = base64Url
      .encode(utf8.encode('{"sub":"$sub","exp":9999999999}'))
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockOrganizationRepository organizationRepository,
  required _MockDeliveryTemplateRepository deliveryTemplateRepository,
  required _MockSyncBloc syncBloc,
  _MockMemberRepository? memberRepository,
  _MockAuthService? authService,
  _MockContractRepository? contractRepository,
  _MockProducerAccountRepository? producerAccountRepository,
  String? deliveryId = 'd-1',
}) async {
  when(() => syncBloc.state).thenReturn(const SyncState.idle());
  when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());

  final memberRepo = memberRepository ?? _MockMemberRepository();
  if (memberRepository == null) {
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Member>[]));
  }

  final auth = authService ?? _MockAuthService();
  if (authService == null) {
    when(() => auth.currentState).thenReturn(const AuthState.unauthenticated());
  }

  final contractRepo = contractRepository ?? _MockContractRepository();
  if (contractRepository == null) {
    when(
      () => contractRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Contract>[]));
  }

  final producerAccountRepo =
      producerAccountRepository ?? _MockProducerAccountRepository();
  if (producerAccountRepository == null) {
    when(
      () => producerAccountRepo.watchAll(),
    ).thenAnswer((_) => Stream.value(const <ProducerAccount>[]));
  }

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrganizationRepository>.value(
          value: organizationRepository,
        ),
        RepositoryProvider<DeliveryTemplateRepository>.value(
          value: deliveryTemplateRepository,
        ),
        RepositoryProvider<MemberRepository>.value(value: memberRepo),
        RepositoryProvider<AuthService>.value(value: auth),
        RepositoryProvider<ContractRepository>.value(value: contractRepo),
        RepositoryProvider<ProducerAccountRepository>.value(
          value: producerAccountRepo,
        ),
      ],
      child: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: MaterialApp(
          home: TimeSlotFormScreen(tenantId: 'org-1', deliveryId: deliveryId),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  late _MockOrganizationRepository organizationRepository;
  late _MockDeliveryTemplateRepository deliveryTemplateRepository;
  late _MockSyncBloc syncBloc;
  late _MockMemberRepository memberRepository;
  late _MockAuthService authService;
  late _MockContractRepository contractRepository;
  late _MockProducerAccountRepository producerAccountRepository;

  setUp(() {
    organizationRepository = _MockOrganizationRepository();
    deliveryTemplateRepository = _MockDeliveryTemplateRepository();
    syncBloc = _MockSyncBloc();
    memberRepository = _MockMemberRepository();
    authService = _MockAuthService();
    contractRepository = _MockContractRepository();
    producerAccountRepository = _MockProducerAccountRepository();
    when(
      () => contractRepository.watch('org-1'),
    ).thenAnswer((_) => Stream.value(const <Contract>[]));
    when(
      () => producerAccountRepository.watchAll(),
    ).thenAnswer((_) => Stream.value(_producerAccounts));
    when(
      () => organizationRepository.watch('org-1'),
    ).thenAnswer((_) => Stream.value(_organization));
    when(
      () => deliveryTemplateRepository.watch('org-1'),
    ).thenAnswer((_) => Stream.value(_templates));
    when(
      () => memberRepository.watch('org-1'),
    ).thenAnswer((_) => Stream.value(const <Member>[]));
    when(
      () => authService.currentState,
    ).thenReturn(const AuthState.unauthenticated());
    when(
      () => organizationRepository.updateDelivery(
        currentOrg: any(named: 'currentOrg'),
        delivery: any(named: 'delivery'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => organizationRepository.addDelivery(
        currentOrg: any(named: 'currentOrg'),
        delivery: any(named: 'delivery'),
      ),
    ).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(_organization);
    registerFallbackValue(_delivery);
    registerFallbackValue(const SyncEvent.mutationApplied());
  });

  testWidgets('editing a delivery persists the selected delivery_template_id', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      organizationRepository: organizationRepository,
      deliveryTemplateRepository: deliveryTemplateRepository,
      syncBloc: syncBloc,
    );

    await tester.tap(find.text('Aucun modèle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marché du samedi').last);
    await tester.pumpAndSettle();
    await _tapSaveButton(tester);
    await tester.pumpAndSettle();

    verify(
      () => organizationRepository.updateDelivery(
        currentOrg: _organization,
        delivery: any(
          named: 'delivery',
          that: isA<Delivery>().having(
            (delivery) => delivery.deliveryTemplateId,
            'deliveryTemplateId',
            'dt-2',
          ),
        ),
      ),
    ).called(1);
    verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
  });

  testWidgets(
    'a failing save shows the generic error snackbar, never the raw exception',
    (tester) async {
      when(
        () => organizationRepository.updateDelivery(
          currentOrg: any(named: 'currentOrg'),
          delivery: any(named: 'delivery'),
        ),
      ).thenThrow(Exception('boom'));

      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
      );

      await _tapSaveButton(tester);
      await tester.pump();

      expect(find.text(kUnexpectedErrorMessage), findsOneWidget);
      expect(find.textContaining('boom'), findsNothing);

      // Let the snackbar auto-dismiss so no timer is left pending.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'editing a delivery renders the scheduled time in 24-hour format',
    (tester) async {
      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
      );

      expect(find.text('18:00'), findsOneWidget);
      expect(find.text('6:00 PM'), findsNothing);
    },
  );

  testWidgets(
    'editing a delivery shows product checkboxes from organization products',
    (tester) async {
      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
      );

      expect(find.widgetWithText(CheckboxListTile, 'Tomates'), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, 'Oeufs'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Tomates'),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Oeufs'),
            )
            .value,
        isFalse,
      );
    },
  );

  testWidgets(
    'creating a delivery auto-selects the default template and pre-fills volunteers',
    (tester) async {
      // The volunteer field only shows when a main contract is linked.
      when(
        () => contractRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(const [_contractVegs]));

      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        contractRepository: contractRepository,
        deliveryId: null,
      );
      await tester.pumpAndSettle();

      expect(find.text('Marché du soir'), findsOneWidget);

      final field = tester.widget<TextFormField>(_minVolunteersField());
      expect(field.controller?.text, '2');
    },
  );

  testWidgets(
    'creating a delivery falls back to the first template when the org has no default',
    (tester) async {
      const orgNoDefault = Organization(
        organizationId: 'org-1',
        name: 'AMAP Test',
        contactEmail: 'test@amap.fr',
        deliveries: [_delivery],
      );
      when(
        () => organizationRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(orgNoDefault));
      when(
        () => contractRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(const [_contractVegs]));

      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        contractRepository: contractRepository,
        deliveryId: null,
      );
      await tester.pumpAndSettle();

      expect(find.text('Marché du soir'), findsOneWidget);

      final field = tester.widget<TextFormField>(_minVolunteersField());
      expect(field.controller?.text, '2');
    },
  );

  testWidgets(
    'creating a delivery auto-selects the default template and pre-fills time',
    (tester) async {
      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        deliveryId: null,
      );
      await tester.pumpAndSettle();

      expect(find.text('18:00'), findsOneWidget);
    },
  );

  testWidgets(
    'creating a delivery updates volunteers when a new template is selected',
    (tester) async {
      when(
        () => contractRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(const [_contractVegs]));

      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        contractRepository: contractRepository,
        deliveryId: null,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marché du samedi').last);
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(_minVolunteersField());
      expect(field.controller?.text, '5');
    },
  );

  testWidgets(
    'editing a delivery persists the selected product checkboxes as basket descriptions',
    (tester) async {
      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
      );

      await tester.ensureVisible(
        find.widgetWithText(CheckboxListTile, 'Tomates'),
      );
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Tomates'));
      await tester.pump();
      await tester.ensureVisible(
        find.widgetWithText(CheckboxListTile, 'Oeufs'),
      );
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Oeufs'));
      await tester.pump();
      await _tapSaveButton(tester);
      await tester.pumpAndSettle();

      verify(
        () => organizationRepository.updateDelivery(
          currentOrg: _organization,
          delivery: any(
            named: 'delivery',
            that: isA<Delivery>().having(
              (delivery) => delivery.basketDescriptions,
              'basketDescriptions',
              const [
                BasketDeliveryDescription(
                  productTypeId: 'pt-2',
                  basketSizeName: 'Petit',
                ),
              ],
            ),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'creating a delivery updates time when a new template is selected',
    (tester) async {
      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        deliveryId: null,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marché du samedi').last);
      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsOneWidget);
    },
  );

  testWidgets(
    'creating a delivery keeps manual volunteer edits when changing template',
    (tester) async {
      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        deliveryId: null,
      );

      await tester.enterText(_minVolunteersField(), '7');
      await tester.tap(find.text('Marché du soir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marché du samedi').last);
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(_minVolunteersField());
      expect(field.controller?.text, '7');
    },
  );

  testWidgets(
    'editing refuses to save when another delivery exists on the same day',
    (tester) async {
      const sameDayConflict = Delivery(
        deliveryId: 'd-2',
        organizationId: 'org-1',
        scheduledDate: '2025-06-14T09:00:00Z',
        status: DeliveryStatus.planned,
        minVolunteersRequired: 1,
      );
      const orgWithConflict = Organization(
        organizationId: 'org-1',
        name: 'AMAP Test',
        contactEmail: 'test@amap.fr',
        defaultDeliveryTemplateId: 'dt-1',
        deliveries: [_delivery, sameDayConflict],
      );
      when(
        () => organizationRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(orgWithConflict));

      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
      );

      await _tapSaveButton(tester);
      await tester.pump();

      expect(
        find.text('Une livraison existe déjà ce jour-là pour cette AMAP.'),
        findsOneWidget,
      );
      verifyNever(
        () => organizationRepository.updateDelivery(
          currentOrg: any(named: 'currentOrg'),
          delivery: any(named: 'delivery'),
        ),
      );
    },
  );

  testWidgets('save button is disabled while a mutation is in flight', (
    tester,
  ) async {
    final completer = Completer<void>();
    when(
      () => organizationRepository.updateDelivery(
        currentOrg: any(named: 'currentOrg'),
        delivery: any(named: 'delivery'),
      ),
    ).thenAnswer((_) => completer.future);

    await _pumpScreen(
      tester,
      organizationRepository: organizationRepository,
      deliveryTemplateRepository: deliveryTemplateRepository,
      syncBloc: syncBloc,
    );

    await _tapSaveButton(tester);
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('time picker opens in French 24-hour format', (tester) async {
    await _pumpScreen(
      tester,
      organizationRepository: organizationRepository,
      deliveryTemplateRepository: deliveryTemplateRepository,
      syncBloc: syncBloc,
    );

    await tester.tap(find.byIcon(Icons.access_time));
    await tester.pumpAndSettle();

    expect(find.textContaining('nnuler'), findsOneWidget);
    expect(find.text('AM'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Coordinateurs par contrat block
  // ---------------------------------------------------------------------------

  group('Coordinateurs par contrat', () {
    // Organization with a delivery that has no contracts.
    const orgNoContracts = Organization(
      organizationId: 'org-1',
      name: 'AMAP Test',
      contactEmail: 'test@amap.fr',
      deliveries: [
        Delivery(
          deliveryId: 'd-nc',
          organizationId: 'org-1',
          scheduledDate: '2025-06-14T18:00:00Z',
          status: DeliveryStatus.planned,
          minVolunteersRequired: 2,
        ),
      ],
    );

    testWidgets(
      'shows "Aucun contrat" message when delivery has no contracts',
      (tester) async {
        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(orgNoContracts));

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          memberRepository: memberRepository,
          authService: authService,
          deliveryId: 'd-nc',
        );
        await tester.pumpAndSettle();

        expect(find.text('Aucun contrat encore défini.'), findsOneWidget);
      },
    );

    testWidgets(
      'shows coordinator name and ✕ button in edit mode with one coordinator',
      (tester) async {
        const coordId = 'coord-1';
        const dId = 'd-with-contracts';
        const cId = 'c-vegs';

        final coord = Member(
          memberId: coordId,
          organizationId: 'org-1',
          roles: const {Role.coordinator},
          firstName: 'Jean',
          lastName: 'Morel',
        );

        // Admin member is the connected user — can remove anyone.
        // memberId == sub by invariant (sub/id unification).
        final me = Member(
          memberId: 'admin-sub',
          organizationId: 'org-1',
          roles: const {Role.admin, Role.coordinator},
          firstName: 'Admin',
          lastName: 'User',
        );

        final orgWithContract = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          deliveries: [
            Delivery(
              deliveryId: dId,
              organizationId: 'org-1',
              scheduledDate: '2099-06-14T18:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 2,
              contracts: [
                DeliveryContract(
                  contractId: cId,
                  coordinators: const [coordId],
                  basketQuantity: 10,
                  deliveryDescription: 'Légumes de saison',
                  status: DeliveryContractStatus.pending,
                  slots: const [],
                ),
              ],
            ),
          ],
        );

        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(orgWithContract));
        when(
          () => memberRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value([coord, me]));
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'org-1',
            accessToken: _fakeJwt('admin-sub'),
          ),
        );
        when(
          () => organizationRepository.unassignCoordinatorById(
            organizationId: any(named: 'organizationId'),
            deliveryId: any(named: 'deliveryId'),
            contractId: any(named: 'contractId'),
            memberId: any(named: 'memberId'),
          ),
        ).thenAnswer((_) async {});

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          memberRepository: memberRepository,
          authService: authService,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        // Coordinator name should be displayed.
        expect(find.text('Jean Morel'), findsOneWidget);
        // ✕ button should be present for admin.
        expect(find.byIcon(Icons.close), findsOneWidget);

        // Tap ✕ to remove coordinator.
        await tester.ensureVisible(find.byIcon(Icons.close));
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        verify(
          () => organizationRepository.unassignCoordinatorById(
            organizationId: 'org-1',
            deliveryId: dId,
            contractId: cId,
            memberId: coordId,
          ),
        ).called(1);
      },
    );

    testWidgets(
      'COORDINATOR non-ADMIN cannot remove another member coordinator entry',
      (tester) async {
        const otherCoordId = 'other-coord';
        // memberId == sub by invariant (sub/id unification).
        const meId = 'me-sub';
        const dId = 'd-noadmin';
        const cId = 'c-bread';

        final me = Member(
          memberId: meId,
          organizationId: 'org-1',
          roles: const {Role.coordinator},
          firstName: 'Alice',
          lastName: 'Me',
        );
        final other = Member(
          memberId: otherCoordId,
          organizationId: 'org-1',
          roles: const {Role.coordinator},
          firstName: 'Bob',
          lastName: 'Other',
        );

        final orgWithBothCoords = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          deliveries: [
            Delivery(
              deliveryId: dId,
              organizationId: 'org-1',
              scheduledDate: '2099-06-14T18:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 2,
              contracts: [
                DeliveryContract(
                  contractId: cId,
                  coordinators: const [otherCoordId, meId],
                  basketQuantity: 10,
                  deliveryDescription: 'Pain',
                  status: DeliveryContractStatus.pending,
                  slots: const [],
                ),
              ],
            ),
          ],
        );

        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(orgWithBothCoords));
        when(
          () => memberRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value([me, other]));
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'org-1',
            accessToken: _fakeJwt('me-sub'),
          ),
        );

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          memberRepository: memberRepository,
          authService: authService,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        // Two close icons found — one enabled (own entry) and one disabled.
        // The disabled one (other member) should have null onPressed.
        final closeIcons = find.byIcon(Icons.close);
        expect(closeIcons, findsNWidgets(2));

        // At least one IconButton should be disabled (other member's entry).
        final iconButtons = tester
            .widgetList<IconButton>(find.byType(IconButton))
            .where(
              (b) => b.icon is Icon && (b.icon as Icon).icon == Icons.close,
            )
            .toList();
        expect(iconButtons.any((b) => b.onPressed == null), isTrue);
      },
    );

    testWidgets(
      'COORDINATOR non-ADMIN does not see [+ Ajouter un coordinateur] button',
      (tester) async {
        const dId = 'd-coordinator-only';

        // memberId == sub by invariant (sub/id unification).
        final me = Member(
          memberId: 'me-sub',
          organizationId: 'org-1',
          roles: const {Role.coordinator},
          firstName: 'Alice',
          lastName: 'Me',
        );

        final orgWithContract = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          deliveries: [
            Delivery(
              deliveryId: dId,
              organizationId: 'org-1',
              scheduledDate: '2099-06-14T18:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 2,
              contracts: const [
                DeliveryContract(
                  contractId: 'c-1',
                  coordinators: [],
                  basketQuantity: 5,
                  deliveryDescription: 'Légumes',
                  status: DeliveryContractStatus.pending,
                  slots: [],
                ),
              ],
            ),
          ],
        );

        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(orgWithContract));
        when(
          () => memberRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value([me]));
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'org-1',
            accessToken: _fakeJwt('me-sub'),
          ),
        );

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          memberRepository: memberRepository,
          authService: authService,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        expect(find.text('Ajouter un coordinateur'), findsNothing);
      },
    );

    testWidgets(
      'ADMIN sees [+ Ajouter un coordinateur] button; selecting a member calls assignCoordinator',
      (tester) async {
        const candidateId = 'candidate-coord';
        const dId = 'd-admin-add';
        const cId = 'c-vegs';

        // memberId == sub by invariant (sub/id unification).
        final admin = Member(
          memberId: 'admin-sub',
          organizationId: 'org-1',
          roles: const {Role.admin, Role.coordinator},
          firstName: 'Admin',
          lastName: 'User',
        );
        final candidate = Member(
          memberId: candidateId,
          organizationId: 'org-1',
          roles: const {Role.coordinator},
          firstName: 'Claire',
          lastName: 'Candidate',
        );

        final orgWithContract = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          deliveries: [
            Delivery(
              deliveryId: dId,
              organizationId: 'org-1',
              scheduledDate: '2099-06-14T18:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 2,
              contracts: const [
                DeliveryContract(
                  contractId: cId,
                  coordinators: [],
                  basketQuantity: 5,
                  deliveryDescription: 'Légumes',
                  status: DeliveryContractStatus.pending,
                  slots: [],
                ),
              ],
            ),
          ],
        );

        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(orgWithContract));
        when(
          () => memberRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value([admin, candidate]));
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'org-1',
            accessToken: _fakeJwt('admin-sub'),
          ),
        );
        when(
          () => organizationRepository.assignCoordinatorById(
            organizationId: any(named: 'organizationId'),
            deliveryId: any(named: 'deliveryId'),
            contractId: any(named: 'contractId'),
            memberId: any(named: 'memberId'),
          ),
        ).thenAnswer((_) async {});
        // The candidate must belong to the contract's coordinator pool to be
        // assignable on the delivery.
        when(() => contractRepository.watch('org-1')).thenAnswer(
          (_) => Stream.value(const [
            Contract(
              contractId: cId,
              name: 'Légumes',
              organizationId: 'org-1',
              producerAccountId: 'producer-1',
              minDeliveryDate: '2020-01-01',
              maxDeliveryDate: '2099-12-31',
              deliveryCount: 10,
              seasonYear: 2026,
              coordinators: [candidateId],
            ),
          ]),
        );

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          memberRepository: memberRepository,
          authService: authService,
          contractRepository: contractRepository,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        expect(find.text('Ajouter un coordinateur'), findsOneWidget);

        await tester.ensureVisible(find.text('Ajouter un coordinateur'));
        await tester.tap(find.text('Ajouter un coordinateur'));
        await tester.pumpAndSettle();

        // Bottom sheet lists the candidate coordinator.
        expect(find.text('Claire Candidate'), findsAtLeastNWidgets(1));

        await tester.tap(find.text('Claire Candidate').last);
        await tester.pumpAndSettle();

        verify(
          () => organizationRepository.assignCoordinatorById(
            organizationId: 'org-1',
            deliveryId: dId,
            contractId: cId,
            memberId: candidateId,
          ),
        ).called(1);
      },
    );

    testWidgets(
      '[ME PORTER COORDINATEUR] is disabled when the member is already a coordinator on that contract',
      (tester) async {
        // memberId == sub by invariant (sub/id unification).
        const meId = 'me-sub';
        const dId = 'd-already-coord';
        const cId = 'c-already';

        final me = Member(
          memberId: meId,
          organizationId: 'org-1',
          roles: const {Role.coordinator},
          firstName: 'Already',
          lastName: 'Assigned',
        );

        final orgAlreadyCoord = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          deliveries: [
            Delivery(
              deliveryId: dId,
              organizationId: 'org-1',
              scheduledDate: '2099-06-14T18:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 2,
              contracts: [
                DeliveryContract(
                  contractId: cId,
                  coordinators: const [meId],
                  basketQuantity: 5,
                  deliveryDescription: 'Légumes',
                  status: DeliveryContractStatus.pending,
                  slots: const [],
                ),
              ],
            ),
          ],
        );

        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(orgAlreadyCoord));
        when(
          () => memberRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value([me]));
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'org-1',
            accessToken: _fakeJwt('me-sub'),
          ),
        );

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          memberRepository: memberRepository,
          authService: authService,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        // The self-assign button should not appear (member already assigned).
        expect(find.text('ME PORTER COORDINATEUR'), findsNothing);
      },
    );

    /// Builds an org with a single PLANNED delivery linking [contractId], whose
    /// [DeliveryContract.coordinators] list is empty (nobody assigned yet).
    Organization buildOrgWithSlotlessContract(String deliveryId, String cId) =>
        Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          deliveries: [
            Delivery(
              deliveryId: deliveryId,
              organizationId: 'org-1',
              scheduledDate: '2099-06-14T18:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 2,
              contracts: [
                DeliveryContract(
                  contractId: cId,
                  coordinators: const [],
                  basketQuantity: 5,
                  deliveryDescription: 'Légumes',
                  status: DeliveryContractStatus.pending,
                  slots: const [],
                ),
              ],
            ),
          ],
        );

    Contract buildContractWithPool(String cId, List<String> pool) => Contract(
      contractId: cId,
      name: 'Légumes',
      organizationId: 'org-1',
      producerAccountId: 'producer-1',
      minDeliveryDate: '2020-01-01',
      maxDeliveryDate: '2099-12-31',
      deliveryCount: 10,
      seasonYear: 2026,
      coordinators: pool,
    );

    testWidgets(
      'coordinator block header shows the contract name from the catalog when the link description is blank',
      (tester) async {
        const dId = 'd-name';
        const cId = 'c-name';
        final org = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          deliveries: [
            Delivery(
              deliveryId: dId,
              organizationId: 'org-1',
              scheduledDate: '2099-06-14T18:00:00',
              status: DeliveryStatus.planned,
              minVolunteersRequired: 2,
              contracts: const [
                DeliveryContract(
                  contractId: cId,
                  coordinators: [],
                  basketQuantity: 5,
                  // Imported links carry a blank description.
                  deliveryDescription: '',
                  status: DeliveryContractStatus.pending,
                  slots: [],
                ),
              ],
            ),
          ],
        );

        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(org));
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'org-1',
            accessToken: _fakeJwt('admin-sub'),
          ),
        );
        when(() => contractRepository.watch('org-1')).thenAnswer(
          (_) => Stream.value(const [
            Contract(
              contractId: cId,
              name: 'Contrat Légumes 2026',
              organizationId: 'org-1',
              producerAccountId: 'producer-1',
              minDeliveryDate: '2020-01-01',
              maxDeliveryDate: '2099-12-31',
              deliveryCount: 10,
              seasonYear: 2026,
            ),
          ]),
        );

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          memberRepository: memberRepository,
          authService: authService,
          contractRepository: contractRepository,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        expect(find.text('Contrat Légumes 2026'), findsOneWidget);
      },
    );

    testWidgets(
      '[ME PORTER COORDINATEUR] is shown when the coordinator belongs to the contract pool',
      (tester) async {
        const meId = 'me-sub';
        const dId = 'd-pool-in';
        const cId = 'c-pool-in';
        final me = Member(
          memberId: meId,
          organizationId: 'org-1',
          roles: const {Role.coordinator},
          firstName: 'In',
          lastName: 'Pool',
        );

        when(() => organizationRepository.watch('org-1')).thenAnswer(
          (_) => Stream.value(buildOrgWithSlotlessContract(dId, cId)),
        );
        when(
          () => memberRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value([me]));
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'org-1',
            accessToken: _fakeJwt(meId),
          ),
        );
        when(() => contractRepository.watch('org-1')).thenAnswer(
          (_) => Stream.value([
            buildContractWithPool(cId, const [meId]),
          ]),
        );

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          memberRepository: memberRepository,
          authService: authService,
          contractRepository: contractRepository,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        expect(find.text('ME PORTER COORDINATEUR'), findsOneWidget);
      },
    );

    testWidgets(
      '[ME PORTER COORDINATEUR] is hidden when the coordinator is not in the contract pool',
      (tester) async {
        const meId = 'me-sub';
        const dId = 'd-pool-out';
        const cId = 'c-pool-out';
        final me = Member(
          memberId: meId,
          organizationId: 'org-1',
          roles: const {Role.coordinator},
          firstName: 'Out',
          lastName: 'Pool',
        );

        when(() => organizationRepository.watch('org-1')).thenAnswer(
          (_) => Stream.value(buildOrgWithSlotlessContract(dId, cId)),
        );
        when(
          () => memberRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value([me]));
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'org-1',
            accessToken: _fakeJwt(meId),
          ),
        );
        when(() => contractRepository.watch('org-1')).thenAnswer(
          (_) => Stream.value([
            buildContractWithPool(cId, const ['another-coord']),
          ]),
        );

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          memberRepository: memberRepository,
          authService: authService,
          contractRepository: contractRepository,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        expect(find.text('ME PORTER COORDINATEUR'), findsNothing);
      },
    );

    testWidgets(
      'delivery IN_PROGRESS disables ✕ for non-admin coordinator own entry',
      (tester) async {
        // memberId == sub by invariant (sub/id unification).
        const meId = 'me-sub';
        const dId = 'd-in-progress';
        const cId = 'c-ip';

        final me = Member(
          memberId: meId,
          organizationId: 'org-1',
          roles: const {Role.coordinator},
          firstName: 'Alice',
          lastName: 'Coord',
        );

        final orgInProgress = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          deliveries: [
            Delivery(
              deliveryId: dId,
              organizationId: 'org-1',
              scheduledDate: '2025-01-01T18:00:00',
              status: DeliveryStatus.inProgress,
              minVolunteersRequired: 2,
              contracts: [
                DeliveryContract(
                  contractId: cId,
                  coordinators: const [meId],
                  basketQuantity: 5,
                  deliveryDescription: 'Légumes',
                  status: DeliveryContractStatus.pending,
                  slots: const [],
                ),
              ],
            ),
          ],
        );

        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(orgInProgress));
        when(
          () => memberRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value([me]));
        when(() => authService.currentState).thenReturn(
          AuthState.authenticated(
            producerId: 'org-1',
            accessToken: _fakeJwt('me-sub'),
          ),
        );

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          memberRepository: memberRepository,
          authService: authService,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        // ✕ button present but disabled for non-admin IN_PROGRESS.
        final closeIcons = find.byIcon(Icons.close);
        expect(closeIcons, findsOneWidget);
        final button = tester.widget<IconButton>(
          find.byWidgetPredicate(
            (w) =>
                w is IconButton &&
                w.icon is Icon &&
                (w.icon as Icon).icon == Icons.close,
          ),
        );
        // The button should be disabled (null onPressed) since IN_PROGRESS.
        expect(button.onPressed, isNull);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Contrats présents block (contract-first selection)
  // ---------------------------------------------------------------------------

  group('Contrats présents', () {
    Future<void> pumpCreation(WidgetTester tester) async {
      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        contractRepository: contractRepository,
        producerAccountRepository: producerAccountRepository,
        deliveryId: null,
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'lists active contracts with their producer name, all pre-selected at '
      'creation',
      (tester) async {
        when(() => contractRepository.watch('org-1')).thenAnswer(
          (_) => Stream.value(const [
            _contractVegs,
            _contractEggs,
            _endedContract,
          ]),
        );

        await pumpCreation(tester);

        expect(find.text('🌿 Contrats présents'), findsOneWidget);
        final vegsTile = find.widgetWithText(
          CheckboxListTile,
          'Légumes de saison — Maraîcher Bio',
        );
        final eggsTile = find.widgetWithText(
          CheckboxListTile,
          'Œufs fermiers — Œufs Fermiers',
        );
        expect(vegsTile, findsOneWidget);
        expect(eggsTile, findsOneWidget);
        expect(tester.widget<CheckboxListTile>(vegsTile).value, isTrue);
        expect(tester.widget<CheckboxListTile>(eggsTile).value, isTrue);
        // An ended contract is not proposed.
        expect(find.text('Contrat terminé — Ferme Terminée'), findsNothing);
        // Products of both selected contracts are proposed.
        expect(
          find.widgetWithText(CheckboxListTile, 'Tomates'),
          findsOneWidget,
        );
        expect(find.widgetWithText(CheckboxListTile, 'Oeufs'), findsOneWidget);
      },
    );

    testWidgets('deselecting a contract hides its products', (tester) async {
      when(
        () => contractRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(const [_contractVegs, _contractEggs]));

      await pumpCreation(tester);

      final eggsTile = find.widgetWithText(
        CheckboxListTile,
        'Œufs fermiers — Œufs Fermiers',
      );
      await tester.ensureVisible(eggsTile);
      await tester.tap(eggsTile);
      await tester.pump();

      expect(find.widgetWithText(CheckboxListTile, 'Oeufs'), findsNothing);
      expect(find.widgetWithText(CheckboxListTile, 'Tomates'), findsOneWidget);
    });

    testWidgets(
      'products come from the contract productPrices, with producer fallback '
      'for legacy contracts',
      (tester) async {
        // producer-1 has a second product not referenced by the vegs
        // contract's productPrices: it must not be offered. producer-2's
        // Oeufs is offered through the legacy (no-price) eggs contract.
        const orgWithExtraProduct = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          defaultDeliveryTemplateId: 'dt-1',
          products: [
            OrgProduct(
              name: 'Tomates',
              productTypeId: 'pt-1',
              producerAccountId: 'producer-1',
              supportedBasketSizes: [BasketSize(name: 'Petit')],
            ),
            OrgProduct(
              name: 'Salades',
              productTypeId: 'pt-3',
              producerAccountId: 'producer-1',
              supportedBasketSizes: [BasketSize(name: 'Petit')],
            ),
            OrgProduct(
              name: 'Oeufs',
              productTypeId: 'pt-2',
              producerAccountId: 'producer-2',
              supportedBasketSizes: [BasketSize(name: 'Petit')],
            ),
          ],
        );
        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(orgWithExtraProduct));
        when(
          () => contractRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(const [_contractVegs, _contractEggs]));

        await pumpCreation(tester);

        expect(
          find.widgetWithText(CheckboxListTile, 'Tomates'),
          findsOneWidget,
        );
        expect(find.widgetWithText(CheckboxListTile, 'Salades'), findsNothing);
        expect(find.widgetWithText(CheckboxListTile, 'Oeufs'), findsOneWidget);
      },
    );

    testWidgets(
      'no contract section when no active contract exists — flat product list',
      (tester) async {
        // Default setUp: contract stream is empty.
        await pumpCreation(tester);

        expect(find.text('🌿 Contrats présents'), findsNothing);
        expect(
          find.widgetWithText(CheckboxListTile, 'Tomates'),
          findsOneWidget,
        );
        expect(find.widgetWithText(CheckboxListTile, 'Oeufs'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // DeliveryContract derivation from active season contracts
  // ---------------------------------------------------------------------------

  group('Dérivation des DeliveryContract', () {
    const productTomates = OrgProduct(
      name: 'Tomates',
      productTypeId: 'pt-1',
      producerAccountId: 'producer-1',
      supportedBasketSizes: [BasketSize(name: 'Petit')],
    );
    const productOeufs = OrgProduct(
      name: 'Oeufs',
      productTypeId: 'pt-2',
      producerAccountId: 'producer-2',
      supportedBasketSizes: [BasketSize(name: 'Petit')],
    );

    testWidgets('creation links the selected active contracts', (tester) async {
      when(
        () => contractRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(const [_contractVegs, _contractEggs]));
      // No existing delivery so the same-day conflict guard cannot trigger.
      const org = Organization(
        organizationId: 'org-1',
        name: 'AMAP Test',
        contactEmail: 'test@amap.fr',
        defaultDeliveryTemplateId: 'dt-1',
        products: [productTomates, productOeufs],
      );
      when(
        () => organizationRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(org));

      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        contractRepository: contractRepository,
        producerAccountRepository: producerAccountRepository,
        deliveryId: null,
      );
      await tester.pumpAndSettle();

      // Pick a date (the time is pre-filled by the default template).
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await _tapSaveButton(tester);
      await tester.pumpAndSettle();

      verify(
        () => organizationRepository.addDelivery(
          currentOrg: org,
          delivery: any(
            named: 'delivery',
            that: isA<Delivery>()
                .having(
                  (delivery) => [
                    for (final c in delivery.contracts)
                      c.copyWith(slots: const []),
                  ],
                  'contracts',
                  const [
                    DeliveryContract(
                      contractId: 'c-vegs',
                      basketQuantity: 1,
                      deliveryDescription: 'Légumes de saison',
                      status: DeliveryContractStatus.pending,
                    ),
                    DeliveryContract(
                      contractId: 'c-eggs',
                      basketQuantity: 0,
                      deliveryDescription: 'Œufs fermiers',
                      status: DeliveryContractStatus.pending,
                    ),
                  ],
                )
                // The default volunteer slot is materialised on the first
                // contract link so volunteers can register.
                .having(
                  (delivery) => delivery.contracts.first.slots.single,
                  'default slot',
                  isA<MemberSlot>()
                      .having((s) => s.slotKind, 'kind', SlotKind.standard)
                      .having((s) => s.status, 'status', SlotStatus.open)
                      .having((s) => s.requiredVolunteers, 'required', 2),
                ),
          ),
        ),
      ).called(1);
    });

    testWidgets(
      'no main contract: hides volunteer controls and creates no slots',
      (tester) async {
        // Only a secondary (non-main) contract is available/selected.
        when(
          () => contractRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(const [_contractEggs]));
        const org = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          defaultDeliveryTemplateId: 'dt-1',
          products: [productTomates, productOeufs],
        );
        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(org));

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          contractRepository: contractRepository,
          producerAccountRepository: producerAccountRepository,
          deliveryId: null,
        );
        await tester.pumpAndSettle();

        // The volunteer controls are hidden when no main contract is linked.
        expect(find.text('Bénévoles minimum requis'), findsNothing);
        expect(find.text('Horaires des créneaux'), findsNothing);

        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await _tapSaveButton(tester);
        await tester.pumpAndSettle();

        verify(
          () => organizationRepository.addDelivery(
            currentOrg: org,
            delivery: any(
              named: 'delivery',
              that: isA<Delivery>().having(
                (d) => d.contracts.every((c) => c.slots.isEmpty),
                'all links slot-less',
                isTrue,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'creation shows the to-be-linked contracts in the coordinator block',
      (tester) async {
        when(
          () => contractRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(const [_contractVegs, _contractEggs]));

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          contractRepository: contractRepository,
          producerAccountRepository: producerAccountRepository,
          deliveryId: null,
        );
        await tester.pumpAndSettle();

        expect(find.text('Aucun contrat encore défini.'), findsNothing);
        // Each contract name now appears twice: once in the coordinator preview
        // block and once as the "Produits présents" per-contract group header.
        expect(find.text('Légumes de saison'), findsNWidgets(2));
        expect(find.text('Œufs fermiers'), findsNWidgets(2));
      },
    );

    const linkedVegs = DeliveryContract(
      contractId: 'c-vegs',
      coordinators: ['coord-1'],
      basketQuantity: 10,
      deliveryDescription: 'Légumes de saison',
      status: DeliveryContractStatus.prepared,
    );
    const orgWithLink = Organization(
      organizationId: 'org-1',
      name: 'AMAP Test',
      contactEmail: 'test@amap.fr',
      products: [productTomates, productOeufs],
      deliveries: [
        Delivery(
          deliveryId: 'd-link',
          organizationId: 'org-1',
          scheduledDate: '2026-07-14T18:00:00',
          status: DeliveryStatus.planned,
          minVolunteersRequired: 2,
          contracts: [linkedVegs],
        ),
      ],
    );

    Future<void> pumpEdit(WidgetTester tester) async {
      when(
        () => contractRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(const [_contractVegs, _contractEggs]));
      when(
        () => organizationRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(orgWithLink));

      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        contractRepository: contractRepository,
        producerAccountRepository: producerAccountRepository,
        deliveryId: 'd-link',
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'editing preserves existing links as-is and adds the newly selected '
      'contracts',
      (tester) async {
        await pumpEdit(tester);

        // c-vegs is derived from the existing link, c-eggs unchecked.
        final vegsTile = find.widgetWithText(
          CheckboxListTile,
          'Légumes de saison — Maraîcher Bio',
        );
        expect(tester.widget<CheckboxListTile>(vegsTile).value, isTrue);
        final eggsTile = find.widgetWithText(
          CheckboxListTile,
          'Œufs fermiers — Œufs Fermiers',
        );
        expect(tester.widget<CheckboxListTile>(eggsTile).value, isFalse);

        await tester.ensureVisible(eggsTile);
        await tester.tap(eggsTile);
        await tester.pump();
        await _tapSaveButton(tester);
        await tester.pumpAndSettle();

        verify(
          () => organizationRepository.updateDelivery(
            currentOrg: orgWithLink,
            delivery: any(
              named: 'delivery',
              that: isA<Delivery>()
                  .having(
                    (delivery) => [
                      for (final c in delivery.contracts)
                        c.copyWith(slots: const []),
                    ],
                    'contracts',
                    const [
                      linkedVegs,
                      DeliveryContract(
                        contractId: 'c-eggs',
                        basketQuantity: 0,
                        deliveryDescription: 'Œufs fermiers',
                        status: DeliveryContractStatus.pending,
                      ),
                    ],
                  )
                  // The slotless delivery gets its default volunteer slot
                  // backfilled on the first link.
                  .having(
                    (delivery) => delivery.contracts.first.slots.single,
                    'backfilled slot',
                    isA<MemberSlot>()
                        .having((s) => s.slotKind, 'kind', SlotKind.standard)
                        .having((s) => s.status, 'status', SlotStatus.open),
                  ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('editing drops a dangling tmp_ link instead of duplicating the '
        're-identified contract', (tester) async {
      // A delivery generated while the contract still had its optimistic
      // tmp_* id, never remapped: the link is dangling (no cached contract
      // carries that id any more).
      const danglingLink = DeliveryContract(
        contractId: 'tmp_contract_1',
        basketQuantity: 0,
        deliveryDescription: 'Légumes de saison',
        status: DeliveryContractStatus.pending,
      );
      const orgWithDangling = Organization(
        organizationId: 'org-1',
        name: 'AMAP Test',
        contactEmail: 'test@amap.fr',
        products: [productTomates, productOeufs],
        deliveries: [
          Delivery(
            deliveryId: 'd-dangling',
            organizationId: 'org-1',
            scheduledDate: '2026-07-14T18:00:00',
            status: DeliveryStatus.planned,
            minVolunteersRequired: 2,
            contracts: [danglingLink],
          ),
        ],
      );
      when(
        () => contractRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(const [_contractVegs]));
      when(
        () => organizationRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(orgWithDangling));

      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        contractRepository: contractRepository,
        producerAccountRepository: producerAccountRepository,
        deliveryId: 'd-dangling',
      );
      await tester.pumpAndSettle();

      // The real contract is offered unchecked (the link carries the tmp
      // id); the user re-selects it.
      final vegsTile = find.widgetWithText(
        CheckboxListTile,
        'Légumes de saison — Maraîcher Bio',
      );
      expect(tester.widget<CheckboxListTile>(vegsTile).value, isFalse);
      await tester.ensureVisible(vegsTile);
      await tester.tap(vegsTile);
      await tester.pump();
      await _tapSaveButton(tester);
      await tester.pumpAndSettle();

      verify(
        () => organizationRepository.updateDelivery(
          currentOrg: orgWithDangling,
          delivery: any(
            named: 'delivery',
            that: isA<Delivery>().having(
              (delivery) => [
                for (final c in delivery.contracts) c.copyWith(slots: const []),
              ],
              'contracts',
              const [
                DeliveryContract(
                  contractId: 'c-vegs',
                  basketQuantity: 1,
                  deliveryDescription: 'Légumes de saison',
                  status: DeliveryContractStatus.pending,
                ),
              ],
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('editing drops the links of a deselected contract', (
      tester,
    ) async {
      await pumpEdit(tester);

      final vegsTile = find.widgetWithText(
        CheckboxListTile,
        'Légumes de saison — Maraîcher Bio',
      );
      await tester.ensureVisible(vegsTile);
      await tester.tap(vegsTile);
      await tester.pump();
      await _tapSaveButton(tester);
      await tester.pumpAndSettle();

      verify(
        () => organizationRepository.updateDelivery(
          currentOrg: orgWithLink,
          delivery: any(
            named: 'delivery',
            that: isA<Delivery>().having(
              (delivery) => delivery.contracts,
              'contracts',
              isEmpty,
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets(
      'deselecting one of two contracts of the same producer drops only '
      'that link',
      (tester) async {
        const contractVegsBis = Contract(
          contractId: 'c-vegs-bis',
          name: 'Légumes bis',
          organizationId: 'org-1',
          producerAccountId: 'producer-1',
          minDeliveryDate: '2020-01-01',
          maxDeliveryDate: '2099-12-31',
          deliveryCount: 10,
          seasonYear: 2026,
          productPrices: [
            ProductPrice(
              productTypeId: 'pt-1',
              basketSize: BasketSize(name: 'Petit'),
            ),
          ],
        );
        when(() => contractRepository.watch('org-1')).thenAnswer(
          (_) => Stream.value(const [_contractVegs, contractVegsBis]),
        );
        const org = Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'test@amap.fr',
          defaultDeliveryTemplateId: 'dt-1',
          products: [productTomates, productOeufs],
        );
        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(org));

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          contractRepository: contractRepository,
          producerAccountRepository: producerAccountRepository,
          deliveryId: null,
        );
        await tester.pumpAndSettle();

        final bisTile = find.widgetWithText(
          CheckboxListTile,
          'Légumes bis — Maraîcher Bio',
        );
        await tester.ensureVisible(bisTile);
        await tester.tap(bisTile);
        await tester.pump();

        // The shared product stays offered through the still-selected
        // contract of the same producer.
        expect(
          find.widgetWithText(CheckboxListTile, 'Tomates'),
          findsOneWidget,
        );

        // Pick a date (the time is pre-filled by the default template).
        await tester.ensureVisible(find.byIcon(Icons.calendar_today));
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await _tapSaveButton(tester);
        await tester.pumpAndSettle();

        verify(
          () => organizationRepository.addDelivery(
            currentOrg: org,
            delivery: any(
              named: 'delivery',
              that: isA<Delivery>().having(
                (delivery) => [
                  for (final c in delivery.contracts)
                    c.copyWith(slots: const []),
                ],
                'contracts',
                const [
                  DeliveryContract(
                    contractId: 'c-vegs',
                    basketQuantity: 1,
                    deliveryDescription: 'Légumes de saison',
                    status: DeliveryContractStatus.pending,
                  ),
                ],
              ),
            ),
          ),
        ).called(1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Créneaux bénévoles block (slot lifecycle: cancel / delete / reschedule)
  // ---------------------------------------------------------------------------

  group('Créneaux bénévoles', () {
    const dId = 'd-slots';
    const cId = 'c-slots';

    const regAlice = MemberRegistration(
      memberId: 'm-alice',
      displayName: 'Alice Volunteer',
      memberEmail: 'alice@example.com',
      registrationInstant: '2025-06-01T10:00:00Z',
      status: RegistrationStatus.registered,
    );
    const regBob = MemberRegistration(
      memberId: 'm-bob',
      displayName: 'Bob Volunteer',
      memberEmail: 'bob@example.com',
      registrationInstant: '2025-06-01T11:00:00Z',
      status: RegistrationStatus.registered,
    );

    Organization orgWithSlot(MemberSlot slot) => Organization(
      organizationId: 'org-1',
      name: 'AMAP Test',
      contactEmail: 'test@amap.fr',
      deliveries: [
        Delivery(
          deliveryId: dId,
          organizationId: 'org-1',
          scheduledDate: '2027-06-14T18:00:00',
          status: DeliveryStatus.planned,
          minVolunteersRequired: 2,
          contracts: [
            DeliveryContract(
              contractId: cId,
              coordinators: const ['coord-1'],
              basketQuantity: 10,
              deliveryDescription: 'Légumes',
              status: DeliveryContractStatus.pending,
              slots: [slot],
            ),
          ],
        ),
      ],
    );

    const registeredSlot = MemberSlot(
      slotId: 'slot-1',
      startTime: '2027-06-14T18:00:00',
      endTime: '2027-06-14T20:00:00',
      activityType: ActivityType.reception,
      requiredVolunteers: 2,
      currentRegistrations: 2,
      status: SlotStatus.open,
      registrations: [regAlice, regBob],
    );

    const emptySlot = MemberSlot(
      slotId: 'slot-1',
      startTime: '2027-06-14T18:00:00',
      endTime: '2027-06-14T20:00:00',
      activityType: ActivityType.reception,
      requiredVolunteers: 2,
      currentRegistrations: 0,
      status: SlotStatus.open,
    );

    const cancelledSlot = MemberSlot(
      slotId: 'slot-1',
      startTime: '2027-06-14T18:00:00',
      endTime: '2027-06-14T20:00:00',
      activityType: ActivityType.reception,
      requiredVolunteers: 2,
      currentRegistrations: 0,
      status: SlotStatus.cancelled,
      registrations: [
        MemberRegistration(
          memberId: 'm-alice',
          displayName: 'Alice Volunteer',
          memberEmail: 'alice@example.com',
          registrationInstant: '2025-06-01T10:00:00Z',
          status: RegistrationStatus.cancelled,
        ),
      ],
    );

    Future<void> pumpWithSlot(WidgetTester tester, MemberSlot slot) async {
      when(
        () => organizationRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(orgWithSlot(slot)));
      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        deliveryId: dId,
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'slot with active registrations: ANNULER enabled, SUPPRIMER disabled',
      (tester) async {
        await pumpWithSlot(tester, registeredSlot);

        expect(find.text('🕐 Créneaux bénévoles'), findsOneWidget);
        expect(find.textContaining('2 inscrits'), findsOneWidget);

        final cancelButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'ANNULER'),
        );
        expect(cancelButton.onPressed, isNotNull);

        final deleteButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'SUPPRIMER'),
        );
        expect(deleteButton.onPressed, isNull);
      },
    );

    testWidgets('empty slot: ANNULER and SUPPRIMER both enabled', (
      tester,
    ) async {
      await pumpWithSlot(tester, emptySlot);

      final cancelButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'ANNULER'),
      );
      expect(cancelButton.onPressed, isNotNull);

      final deleteButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'SUPPRIMER'),
      );
      expect(deleteButton.onPressed, isNotNull);
    });

    testWidgets(
      'cancelled slot shows the ANNULÉ badge and no lifecycle actions',
      (tester) async {
        await pumpWithSlot(tester, cancelledSlot);

        expect(find.text('ANNULÉ'), findsOneWidget);
        expect(find.widgetWithText(OutlinedButton, 'ANNULER'), findsNothing);
        expect(find.widgetWithText(OutlinedButton, 'SUPPRIMER'), findsNothing);
      },
    );

    // A delivery carrying legacy volunteer slots on a secondary (non-main)
    // contract: only the main contract's slots are listed and the orphan slots
    // are pruned on save.
    Organization orgWithMainAndSecondarySlots() => const Organization(
      organizationId: 'org-1',
      name: 'AMAP Test',
      contactEmail: 'test@amap.fr',
      deliveries: [
        Delivery(
          deliveryId: dId,
          organizationId: 'org-1',
          scheduledDate: '2027-06-14T18:00:00',
          status: DeliveryStatus.planned,
          minVolunteersRequired: 2,
          contracts: [
            DeliveryContract(
              contractId: 'c-vegs',
              coordinators: ['coord-1'],
              basketQuantity: 10,
              deliveryDescription: 'Légumes',
              status: DeliveryContractStatus.pending,
              slots: [registeredSlot],
            ),
            DeliveryContract(
              contractId: 'c-eggs',
              basketQuantity: 5,
              deliveryDescription: 'Œufs',
              status: DeliveryContractStatus.pending,
              slots: [emptySlot],
            ),
          ],
        ),
      ],
    );

    testWidgets(
      'lists only the main contract volunteer slots (secondary hidden)',
      (tester) async {
        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(orgWithMainAndSecondarySlots()));
        when(
          () => contractRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(const [_contractVegs, _contractEggs]));

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          contractRepository: contractRepository,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        expect(find.text('🕐 Créneaux bénévoles'), findsOneWidget);
        // Only the main (Légumes) contract slot row is shown.
        expect(find.textContaining('Créneau standard'), findsOneWidget);
        expect(find.textContaining('2 inscrits'), findsOneWidget);
        expect(find.textContaining('0 inscrit'), findsNothing);
      },
    );

    testWidgets(
      'saving prunes the empty volunteer slots of non-main contracts',
      (tester) async {
        when(
          () => organizationRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(orgWithMainAndSecondarySlots()));
        when(
          () => contractRepository.watch('org-1'),
        ).thenAnswer((_) => Stream.value(const [_contractVegs, _contractEggs]));

        await _pumpScreen(
          tester,
          organizationRepository: organizationRepository,
          deliveryTemplateRepository: deliveryTemplateRepository,
          syncBloc: syncBloc,
          contractRepository: contractRepository,
          deliveryId: dId,
        );
        await tester.pumpAndSettle();

        await _tapSaveButton(tester);
        await tester.pumpAndSettle();

        verify(
          () => organizationRepository.updateDelivery(
            currentOrg: any(named: 'currentOrg'),
            delivery: any(
              named: 'delivery',
              that: isA<Delivery>()
                  .having(
                    (d) => d.contracts
                        .firstWhere((c) => c.contractId == 'c-vegs')
                        .slots,
                    'main contract keeps its slot',
                    isNotEmpty,
                  )
                  .having(
                    (d) => d.contracts
                        .firstWhere((c) => c.contractId == 'c-eggs')
                        .slots,
                    'secondary contract slots pruned',
                    isEmpty,
                  ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tap ANNULER → confirmation bottom-sheet → cancelled slot mutation enqueued',
      (tester) async {
        await pumpWithSlot(tester, registeredSlot);

        await tester.ensureVisible(
          find.widgetWithText(OutlinedButton, 'ANNULER'),
        );
        await tester.tap(find.widgetWithText(OutlinedButton, 'ANNULER'));
        await tester.pumpAndSettle();

        expect(find.text('Annuler ce créneau ?'), findsOneWidget);
        expect(
          find.textContaining('2 inscrits seront notifiés'),
          findsOneWidget,
        );

        await tester.tap(find.text("CONFIRMER L'ANNULATION"));
        await tester.pumpAndSettle();

        verify(
          () => organizationRepository.updateDelivery(
            currentOrg: orgWithSlot(registeredSlot),
            delivery: any(
              named: 'delivery',
              that: isA<Delivery>().having(
                (delivery) => delivery.contracts.single.slots.single,
                'cancelled slot',
                isA<MemberSlot>()
                    .having((s) => s.status, 'status', SlotStatus.cancelled)
                    .having(
                      (s) => s.currentRegistrations,
                      'currentRegistrations',
                      0,
                    )
                    .having(
                      (s) => s.registrations.every(
                        (r) => r.status == RegistrationStatus.cancelled,
                      ),
                      'all registrations cancelled',
                      isTrue,
                    ),
              ),
            ),
          ),
        ).called(1);
        verify(() => syncBloc.add(const SyncEvent.mutationApplied())).called(1);
      },
    );

    testWidgets(
      'tap SUPPRIMER on an empty slot → confirmation → slot removed mutation enqueued',
      (tester) async {
        await pumpWithSlot(tester, emptySlot);

        await tester.ensureVisible(
          find.widgetWithText(OutlinedButton, 'SUPPRIMER'),
        );
        await tester.tap(find.widgetWithText(OutlinedButton, 'SUPPRIMER'));
        await tester.pumpAndSettle();

        expect(find.text('Supprimer ce créneau ?'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'SUPPRIMER'));
        await tester.pumpAndSettle();

        verify(
          () => organizationRepository.updateDelivery(
            currentOrg: orgWithSlot(emptySlot),
            delivery: any(
              named: 'delivery',
              that: isA<Delivery>().having(
                (delivery) => delivery.contracts.single.slots,
                'slots',
                isEmpty,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'editing the schedule with active registrations asks for confirmation '
      'and shifts the slot times',
      (tester) async {
        await pumpWithSlot(tester, registeredSlot);

        // Move the delivery one day later via the date picker.
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await _tapSaveButton(tester);
        await tester.pumpAndSettle();

        // Confirmation dialog announcing the reschedule notification.
        expect(
          find.text("2 inscrit(s) seront notifiés du changement d'horaire."),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(FilledButton, 'CONFIRMER'));
        await tester.pumpAndSettle();

        verify(
          () => organizationRepository.updateDelivery(
            currentOrg: orgWithSlot(registeredSlot),
            delivery: any(
              named: 'delivery',
              that: isA<Delivery>().having(
                (delivery) => delivery.contracts.single.slots.single,
                'shifted slot',
                isA<MemberSlot>()
                    .having(
                      (s) => s.startTime,
                      'startTime',
                      '2027-06-15T18:00:00',
                    )
                    .having(
                      (s) => s.registrations,
                      'registrations preserved',
                      registeredSlot.registrations,
                    ),
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('declining the reschedule confirmation does not save', (
      tester,
    ) async {
      await pumpWithSlot(tester, registeredSlot);

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await _tapSaveButton(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'ANNULER'));
      await tester.pumpAndSettle();

      verifyNever(
        () => organizationRepository.updateDelivery(
          currentOrg: any(named: 'currentOrg'),
          delivery: any(named: 'delivery'),
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Horaires des créneaux (per-delivery time overrides)
  // ---------------------------------------------------------------------------

  group('Horaires des créneaux', () {
    const overridesDelivery = Delivery(
      deliveryId: 'd-ov',
      organizationId: 'org-1',
      scheduledDate: '2099-06-14T18:00:00',
      status: DeliveryStatus.planned,
      minVolunteersRequired: 2,
      standardEndTime: '20:30',
      volunteerArrivalTime: '17:45',
      earlySlot: EarlySlot(
        arrivalTime: '16:30',
        explanation: 'Réception des légumes',
        maxVolunteers: 3,
      ),
      // A main contract must be linked for the volunteer slot-time block to show.
      contracts: [
        DeliveryContract(
          contractId: 'c-vegs',
          basketQuantity: 10,
          deliveryDescription: 'Légumes de saison',
          status: DeliveryContractStatus.pending,
        ),
      ],
    );

    const orgWithOverrides = Organization(
      organizationId: 'org-1',
      name: 'AMAP Test',
      contactEmail: 'test@amap.fr',
      deliveries: [overridesDelivery],
    );

    Future<void> pumpEditOverrides(WidgetTester tester) async {
      when(
        () => organizationRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(orgWithOverrides));
      when(
        () => contractRepository.watch('org-1'),
      ).thenAnswer((_) => Stream.value(const [_contractVegs]));

      await _pumpScreen(
        tester,
        organizationRepository: organizationRepository,
        deliveryTemplateRepository: deliveryTemplateRepository,
        syncBloc: syncBloc,
        contractRepository: contractRepository,
        deliveryId: 'd-ov',
      );
      await tester.pumpAndSettle();
    }

    testWidgets('pre-fills the override fields from the edited delivery', (
      tester,
    ) async {
      await pumpEditOverrides(tester);

      // Section title and the two time fields render the override values.
      expect(find.text('Horaires des créneaux'), findsOneWidget);
      expect(find.text('20:30'), findsOneWidget);
      expect(find.text('17:45'), findsOneWidget);

      // The early slot is enabled and shows its own values.
      final earlySwitch = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(earlySwitch.value, isTrue);
      expect(find.text('16:30'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Réception des légumes'),
        findsOneWidget,
      );
    });

    testWidgets('persists the override fields onto the saved delivery', (
      tester,
    ) async {
      await pumpEditOverrides(tester);

      await _tapSaveButton(tester);
      await tester.pumpAndSettle();

      verify(
        () => organizationRepository.updateDelivery(
          currentOrg: orgWithOverrides,
          delivery: any(
            named: 'delivery',
            that: isA<Delivery>()
                .having((d) => d.standardEndTime, 'standardEndTime', '20:30')
                .having(
                  (d) => d.volunteerArrivalTime,
                  'volunteerArrivalTime',
                  '17:45',
                )
                .having(
                  (d) => d.earlySlot,
                  'earlySlot',
                  const EarlySlot(
                    arrivalTime: '16:30',
                    explanation: 'Réception des légumes',
                    maxVolunteers: 3,
                  ),
                ),
          ),
        ),
      ).called(1);
    });

    testWidgets('disabling the early slot clears the override on save', (
      tester,
    ) async {
      await pumpEditOverrides(tester);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      await _tapSaveButton(tester);
      await tester.pumpAndSettle();

      verify(
        () => organizationRepository.updateDelivery(
          currentOrg: orgWithOverrides,
          delivery: any(
            named: 'delivery',
            that: isA<Delivery>().having(
              (d) => d.earlySlot,
              'earlySlot',
              isNull,
            ),
          ),
        ),
      ).called(1);
    });
  });
}
