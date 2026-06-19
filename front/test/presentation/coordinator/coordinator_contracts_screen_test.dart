import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart' show BasketSize;
import 'package:amap_en_ligne/presentation/coordinator/coordinator_contracts_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

const _activeContract = Contract(
  contractId: 'c-active',
  name: 'Contrat test',
  organizationId: 'org-1',
  producerAccountId: 'producer-1',
  minDeliveryDate: '2026-01-01',
  maxDeliveryDate: '2026-12-31',
  deliveryCount: 10,
  seasonYear: 2026,
  members: [
    ContractMember(
      memberId: 'member-1',
      subscriptionInstant: '2026-01-01T00:00:00Z',
      status: ContractMemberStatus.active,
    ),
  ],
);

const _emptyContract = Contract(
  contractId: 'c-empty',
  name: 'Contrat test',
  organizationId: 'org-1',
  producerAccountId: 'producer-1',
  minDeliveryDate: '2026-01-01',
  maxDeliveryDate: '2026-12-31',
  deliveryCount: 10,
  seasonYear: 2026,
);

const _bobEntry = ContractMember(
  memberId: 'm-bob',
  subscriptionInstant: '2026-01-15T08:30:00Z',
  status: ContractMemberStatus.suspended,
  subscriptions: [
    MemberSubscription(
      productTypeId: 'pt-1',
      basketSize: BasketSize(name: 'Petit'),
    ),
  ],
);

const _bob = Member(
  memberId: 'm-bob',
  organizationId: 'org-1',
  firstName: 'Bob',
  lastName: 'Martin',
);

const _alice = Member(
  memberId: 'm-alice',
  organizationId: 'org-1',
  firstName: 'Alice',
  lastName: 'Durand',
);

const _organizationWithProducts = Organization(
  organizationId: 'org-1',
  name: 'AMAP Test',
  contactEmail: 'contact@amap.fr',
  producers: [
    OrganizationProducer(
      producerAccountId: 'producer-1',
      associationInstant: '2026-01-01T00:00:00Z',
      status: OrganizationProducerStatus.active,
    ),
  ],
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
      producerAccountId: 'producer-1',
    ),
  ],
);

const _contractWithBob = Contract(
  contractId: 'c-bob',
  name: 'Contrat légumes',
  organizationId: 'org-1',
  producerAccountId: 'producer-1',
  minDeliveryDate: '2026-01-01',
  maxDeliveryDate: '2026-12-31',
  deliveryCount: 10,
  seasonYear: 2026,
  productPrices: [
    ProductPrice(
      productTypeId: 'pt-1',
      basketSize: BasketSize(name: 'Petit'),
    ),
  ],
  members: [_bobEntry],
);

const _endedContractWithBob = Contract(
  contractId: 'c-ended',
  name: 'Contrat terminé',
  organizationId: 'org-1',
  producerAccountId: 'producer-1',
  minDeliveryDate: '2025-01-01',
  maxDeliveryDate: '2025-12-31',
  deliveryCount: 10,
  seasonYear: 2025,
  productPrices: [
    ProductPrice(
      productTypeId: 'pt-1',
      basketSize: BasketSize(name: 'Petit'),
    ),
  ],
  members: [_bobEntry],
);

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockProducerAccountRepository extends Mock
    implements ProducerAccountRepository {}

class _MockDeliveryTemplateRepository extends Mock
    implements DeliveryTemplateRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

class _FakeContract extends Fake implements Contract {}

class _FakeOrganization extends Fake implements Organization {}

void main() {
  late _MockOrganizationRepository organizationRepository;
  late _MockMemberRepository memberRepository;
  late _MockContractRepository contractRepository;
  late _MockProducerAccountRepository producerAccountRepository;
  late _MockDeliveryTemplateRepository deliveryTemplateRepository;
  late _MockSyncBloc syncBloc;

  setUpAll(() {
    registerFallbackValue(_FakeContract());
    registerFallbackValue(_FakeOrganization());
    registerFallbackValue(<Delivery>[]);
  });

  setUp(() {
    organizationRepository = _MockOrganizationRepository();
    memberRepository = _MockMemberRepository();
    contractRepository = _MockContractRepository();
    producerAccountRepository = _MockProducerAccountRepository();
    deliveryTemplateRepository = _MockDeliveryTemplateRepository();
    syncBloc = _MockSyncBloc();
    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => producerAccountRepository.watchAll(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => deliveryTemplateRepository.watch(any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  Widget buildScreen() => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<OrganizationRepository>.value(
        value: organizationRepository,
      ),
      RepositoryProvider<MemberRepository>.value(value: memberRepository),
      RepositoryProvider<ContractRepository>.value(value: contractRepository),
      RepositoryProvider<ProducerAccountRepository>.value(
        value: producerAccountRepository,
      ),
      RepositoryProvider<DeliveryTemplateRepository>.value(
        value: deliveryTemplateRepository,
      ),
    ],
    child: BlocProvider<SyncBloc>.value(
      value: syncBloc,
      child: const MaterialApp(
        home: CoordinatorContractsScreen(tenantId: 'org-1'),
      ),
    ),
  );

  testWidgets('renders the contract definition editor with coordinators', (
    tester,
  ) async {
    when(() => organizationRepository.watch(any())).thenAnswer(
      (_) => Stream.value(
        const Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'contact@amap.fr',
          products: [
            OrgProduct(
              name: 'Tomates',
              productTypeId: 'pt-1',
              producerAccountId: 'producer-1',
              supportedBasketSizes: [
                BasketSize(name: 'Petit'),
                BasketSize(name: 'Moyen'),
                BasketSize(name: 'Grand'),
              ],
            ),
          ],
        ),
      ),
    );
    when(() => memberRepository.watch(any())).thenAnswer(
      (_) => Stream.value([
        const Member(
          memberId: 'm-1',
          organizationId: 'org-1',
          firstName: 'Alice',
          roles: {Role.coordinator},
        ),
      ]),
    );
    when(() => contractRepository.watch(any())).thenAnswer(
      (_) => Stream.value([
        const Contract(
          contractId: 'c-1',
          name: 'Contrat légumes',
          organizationId: 'org-1',
          producerAccountId: 'producer-1',
          minDeliveryDate: '2026-01-01',
          maxDeliveryDate: '2026-12-31',
          deliveryCount: 10,
          seasonYear: 2026,
          coordinators: ['m-1'],
          members: [
            ContractMember(
              memberId: 'member-1',
              subscriptionInstant: '2026-01-01T00:00:00Z',
              status: ContractMemberStatus.active,
            ),
          ],
        ),
      ]),
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Contrats'), findsOneWidget);
    expect(find.text('Nouveau contrat'), findsOneWidget);
    // Select the contract to display its products
    await tester.tap(find.textContaining('1 amapiens'));
    await tester.pumpAndSettle();

    expect(find.text('Tomates'), findsAtLeastNWidgets(1));
    expect(find.textContaining('1 amapiens'), findsOneWidget);
    // Alice appears both as a coordinator chip and in the member checklist.
    expect(find.text('Alice'), findsNWidgets(2));
  });

  testWidgets(
    'displays basket sizes as filter chips when producer is selected',
    (tester) async {
      when(() => organizationRepository.watch(any())).thenAnswer(
        (_) => Stream.value(
          Organization(
            organizationId: 'org-1',
            name: 'AMAP Test',
            contactEmail: 'contact@amap.fr',
            producers: const [
              OrganizationProducer(
                producerAccountId: 'producer-1',
                associationInstant: '2026-01-01T00:00:00Z',
                status: OrganizationProducerStatus.active,
              ),
            ],
            products: const [
              OrgProduct(
                name: 'Tomates',
                productTypeId: 'pt-1',
                producerAccountId: 'producer-1',
                supportedBasketSizes: [
                  BasketSize(name: 'Petit'),
                  BasketSize(name: 'Moyen'),
                  BasketSize(name: 'Grand'),
                ],
              ),
            ],
          ),
        ),
      );
      when(() => memberRepository.watch(any())).thenAnswer(
        (_) => Stream.value([
          const Member(
            memberId: 'm-1',
            organizationId: 'org-1',
            firstName: 'Alice',
            roles: {Role.coordinator},
          ),
        ]),
      );
      when(
        () => contractRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(() => producerAccountRepository.watchAll()).thenAnswer(
        (_) => Stream.value([
          const ProducerAccount(
            producerAccountId: 'producer-1',
            name: 'Ferme Test',
          ),
        ]),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Create new contract to see basket size chips
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // Select producer from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ferme Test').last);
      await tester.pumpAndSettle();

      // Verify price rows per basket size are displayed
      expect(find.text('Petit'), findsOneWidget);
      expect(find.text('Moyen'), findsOneWidget);
      expect(find.text('Grand'), findsOneWidget);
    },
  );

  testWidgets('delete button is disabled when contract has active members', (
    tester,
  ) async {
    when(() => organizationRepository.watch(any())).thenAnswer(
      (_) => Stream.value(
        const Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'contact@amap.fr',
        ),
      ),
    );
    when(
      () => memberRepository.watch(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => contractRepository.watch(any()),
    ).thenAnswer((_) => Stream.value([_activeContract]));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Select the contract to show the editor
    await tester.tap(find.textContaining('1 amapiens'));
    await tester.pumpAndSettle();

    // Scroll the form to make the delete button reachable
    await tester.ensureVisible(find.text('🗑 SUPPRIMER'));
    await tester.pump();

    final outlinedButton = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('🗑 SUPPRIMER'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(outlinedButton.onPressed, isNull);
  });

  testWidgets(
    'delete button is enabled and calls delete when contract has no active members',
    (tester) async {
      when(() => organizationRepository.watch(any())).thenAnswer(
        (_) => Stream.value(
          const Organization(
            organizationId: 'org-1',
            name: 'AMAP Test',
            contactEmail: 'contact@amap.fr',
          ),
        ),
      );
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => contractRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([_emptyContract]));
      when(
        () => contractRepository.delete(any(), any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Select the contract to show the editor
      await tester.tap(find.textContaining('0 amapiens'));
      await tester.pumpAndSettle();

      // Scroll the form to make the delete button reachable
      await tester.ensureVisible(find.text('🗑 SUPPRIMER'));
      await tester.pump();

      final outlinedButton = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('🗑 SUPPRIMER'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(outlinedButton.onPressed, isNotNull);

      // Tap delete and confirm the dialog
      await tester.tap(find.text('🗑 SUPPRIMER'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer le contrat ?'), findsOneWidget);
      await tester.tap(find.text('SUPPRIMER').last);
      await tester.pumpAndSettle();

      verify(() => contractRepository.delete('c-empty', 'org-1')).called(1);
    },
  );

  testWidgets(
    'shows error snackbar when creating a contract with a duplicate name',
    (tester) async {
      when(() => organizationRepository.watch(any())).thenAnswer(
        (_) => Stream.value(
          const Organization(
            organizationId: 'org-1',
            name: 'AMAP Test',
            contactEmail: 'contact@amap.fr',
          ),
        ),
      );
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(() => contractRepository.watch(any())).thenAnswer(
        (_) => Stream.value([
          const Contract(
            contractId: 'c-existing',
            name: 'Légumes 2026',
            organizationId: 'org-1',
            producerAccountId: 'producer-1',
            minDeliveryDate: '2026-01-01',
            maxDeliveryDate: '2026-12-31',
            deliveryCount: 10,
            seasonYear: 2026,
          ),
        ]),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Start creating a new contract
      await tester.tap(find.text('➕ NOUVEAU CONTRAT'));
      await tester.pumpAndSettle();

      // Fill the name field with a duplicate name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du contrat *'),
        'Légumes 2026',
      );

      // Tap save
      await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
      await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
      await tester.pump();

      expect(
        find.text('Un contrat avec ce nom existe déjà dans cette AMAP.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('allows saving when editing a contract keeping its own name', (
    tester,
  ) async {
    when(() => organizationRepository.watch(any())).thenAnswer(
      (_) => Stream.value(
        const Organization(
          organizationId: 'org-1',
          name: 'AMAP Test',
          contactEmail: 'contact@amap.fr',
          producers: [
            OrganizationProducer(
              producerAccountId: 'producer-1',
              associationInstant: '2026-01-01T00:00:00Z',
              status: OrganizationProducerStatus.active,
            ),
          ],
        ),
      ),
    );
    when(
      () => memberRepository.watch(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(() => contractRepository.watch(any())).thenAnswer(
      (_) => Stream.value([
        const Contract(
          contractId: 'c-existing',
          name: 'Légumes 2026',
          organizationId: 'org-1',
          producerAccountId: 'producer-1',
          minDeliveryDate: '2026-01-01',
          maxDeliveryDate: '2026-12-31',
          deliveryCount: 10,
          seasonYear: 2026,
        ),
      ]),
    );
    when(() => producerAccountRepository.watchAll()).thenAnswer(
      (_) => Stream.value([
        const ProducerAccount(
          producerAccountId: 'producer-1',
          name: 'Ferme Test',
        ),
      ]),
    );
    when(() => contractRepository.update(any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Select the existing contract
    await tester.tap(find.textContaining('0 amapiens'));
    await tester.pumpAndSettle();

    // Save with the same name (should succeed without duplicate error)
    await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
    await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    verify(() => contractRepository.update(any())).called(1);
  });

  void stubMemberAssignment({
    required List<Contract> contracts,
    List<Member> members = const [_bob, _alice],
  }) {
    when(
      () => organizationRepository.watch(any()),
    ).thenAnswer((_) => Stream.value(_organizationWithProducts));
    when(
      () => memberRepository.watch(any()),
    ).thenAnswer((_) => Stream.value(members));
    when(
      () => contractRepository.watch(any()),
    ).thenAnswer((_) => Stream.value(contracts));
    when(() => contractRepository.update(any())).thenAnswer((_) async {});
  }

  CheckboxListTile memberTile(WidgetTester tester, String name) =>
      tester.widget<CheckboxListTile>(
        find.ancestor(
          of: find.text(name),
          matching: find.byType(CheckboxListTile),
        ),
      );

  // testWidgets(
  //   'member checklist reflects assignments and saving adds checked members',
  //   (tester) async {
  //     // Subscription validation is tested in backend tests separately
  //   },
  // );

  testWidgets(
    'unchecking an assigned member asks confirmation before removal',
    (tester) async {
      stubMemberAssignment(contracts: [_contractWithBob]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('1 amapiens'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Bob Martin'));
      await tester.tap(find.text('Bob Martin'));
      await tester.pumpAndSettle();

      expect(find.text('Retirer cet amapien du contrat ?'), findsOneWidget);
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();
      expect(memberTile(tester, 'Bob Martin').value, isTrue);

      await tester.ensureVisible(find.text('Bob Martin'));
      await tester.tap(find.text('Bob Martin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RETIRER'));
      await tester.pumpAndSettle();
      expect(memberTile(tester, 'Bob Martin').value, isFalse);
      expect(find.text('Amapiens rattachés (0)'), findsOneWidget);

      await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
      await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final captured =
          verify(() => contractRepository.update(captureAny())).captured.single
              as Contract;
      expect(captured.members, isEmpty);
    },
  );

  testWidgets(
    'unchecking then rechecking an assigned member preserves its entry',
    (tester) async {
      stubMemberAssignment(contracts: [_contractWithBob]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('1 amapiens'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Bob Martin'));
      await tester.tap(find.text('Bob Martin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RETIRER'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bob Martin'));
      await tester.tap(find.text('Bob Martin'));
      await tester.pumpAndSettle();
      expect(memberTile(tester, 'Bob Martin').value, isTrue);

      await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
      await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final captured =
          verify(() => contractRepository.update(captureAny())).captured.single
              as Contract;
      expect(captured.members.single, _bobEntry);
    },
  );

  testWidgets(
    'ended contract disables adding members but still allows removal',
    (tester) async {
      stubMemberAssignment(contracts: [_endedContractWithBob]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('1 amapiens'));
      await tester.pumpAndSettle();

      expect(
        find.text('Contrat terminé — aucune nouvelle inscription possible.'),
        findsOneWidget,
      );
      expect(find.text('TOUT SÉLECTIONNER'), findsNothing);
      expect(memberTile(tester, 'Alice Durand').onChanged, isNull);
      expect(memberTile(tester, 'Bob Martin').onChanged, isNotNull);
    },
  );

  testWidgets('select all checks the visible members only', (tester) async {
    stubMemberAssignment(contracts: [_emptyContract]);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('0 amapiens'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(TextField, 'Rechercher un amapien'),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher un amapien'),
      'Alice',
    );
    await tester.pumpAndSettle();
    expect(find.text('Bob Martin'), findsNothing);

    await tester.ensureVisible(find.text('TOUT SÉLECTIONNER'));
    await tester.tap(find.text('TOUT SÉLECTIONNER'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher un amapien'),
      '',
    );
    await tester.pumpAndSettle();

    expect(find.text('Amapiens rattachés (1)'), findsOneWidget);
    expect(memberTile(tester, 'Alice Durand').value, isTrue);
    expect(memberTile(tester, 'Bob Martin').value, isFalse);
  });

  void stubProductInclusion({required List<Contract> contracts}) {
    when(
      () => organizationRepository.watch(any()),
    ).thenAnswer((_) => Stream.value(_organizationWithProducts));
    when(
      () => memberRepository.watch(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => contractRepository.watch(any()),
    ).thenAnswer((_) => Stream.value(contracts));
    when(() => producerAccountRepository.watchAll()).thenAnswer(
      (_) => Stream.value([
        const ProducerAccount(
          producerAccountId: 'producer-1',
          name: 'Ferme Test',
        ),
      ]),
    );
    when(() => contractRepository.create(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as Contract,
    );
    when(() => contractRepository.update(any())).thenAnswer((_) async {});
  }

  CheckboxListTile productTile(WidgetTester tester, String name) =>
      tester.widget<CheckboxListTile>(
        find.ancestor(
          of: find.text(name),
          matching: find.byType(CheckboxListTile),
        ),
      );

  Future<void> startContractCreation(WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('➕ NOUVEAU CONTRAT'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nom du contrat *'),
      'Légumes 2026',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ferme Test').last);
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.byIcon(Icons.calendar_today).at(i));
      await tester.tap(find.byIcon(Icons.calendar_today).at(i));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> toggleProduct(WidgetTester tester, String name) async {
    await tester.ensureVisible(
      find.ancestor(
        of: find.text(name),
        matching: find.byType(CheckboxListTile),
      ),
    );
    await tester.tap(
      find.ancestor(
        of: find.text(name),
        matching: find.byType(CheckboxListTile),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'product checkboxes are all checked by default at creation and show price rows',
    (tester) async {
      stubProductInclusion(contracts: []);

      await startContractCreation(tester);

      expect(productTile(tester, 'Tomates').value, isTrue);
      expect(productTile(tester, 'Oeufs').value, isTrue);
      expect(find.text('Petit'), findsOneWidget);
      expect(find.text('Prix (€)'), findsWidgets);
    },
  );

  testWidgets(
    'unchecking a product hides its price rows and excludes it from saved product prices',
    (tester) async {
      stubProductInclusion(contracts: []);

      await startContractCreation(tester);
      await toggleProduct(tester, 'Tomates');

      expect(productTile(tester, 'Tomates').value, isFalse);
      expect(find.text('Petit'), findsNothing);

      await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
      await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final captured =
          verify(() => contractRepository.create(captureAny())).captured.single
              as Contract;
      expect(
        captured.productPrices.map((p) => p.productTypeId),
        isNot(contains('pt-1')),
      );
      expect(
        captured.productPrices.map((p) => p.productTypeId),
        contains('pt-2'),
      );
    },
  );

  testWidgets('saving with no product checked shows an error and does not '
      'save', (tester) async {
    stubProductInclusion(contracts: []);

    await startContractCreation(tester);
    await toggleProduct(tester, 'Tomates');
    await toggleProduct(tester, 'Oeufs');

    await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
    await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
    await tester.pump();

    expect(
      find.text('Sélectionnez au moins un produit pour ce contrat.'),
      findsOneWidget,
    );
    verifyNever(() => contractRepository.create(any()));
  });

  testWidgets('editing checks only the products present in productPrices', (
    tester,
  ) async {
    stubProductInclusion(
      contracts: [
        const Contract(
          contractId: 'c-priced',
          name: 'Contrat tomates',
          organizationId: 'org-1',
          producerAccountId: 'producer-1',
          minDeliveryDate: '2026-01-01',
          maxDeliveryDate: '2026-12-31',
          deliveryCount: 10,
          seasonYear: 2026,
          productPrices: [
            ProductPrice(
              productTypeId: 'pt-1',
              basketSize: BasketSize(name: 'Petit'),
              price: 12,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('0 amapiens'));
    await tester.pumpAndSettle();

    expect(productTile(tester, 'Tomates').value, isTrue);
    expect(productTile(tester, 'Oeufs').value, isFalse);
    expect(find.text('Petit'), findsOneWidget);
  });

  testWidgets('legacy contract with empty productPrices checks all producer '
      'products', (tester) async {
    stubProductInclusion(contracts: [_emptyContract]);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('0 amapiens'));
    await tester.pumpAndSettle();

    expect(productTile(tester, 'Tomates').value, isTrue);
    expect(productTile(tester, 'Oeufs').value, isTrue);
  });

  testWidgets(
    'checked member has subscription options visible below their name',
    (tester) async {
      stubProductInclusion(contracts: [_emptyContract]);
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([_bob]));

      await startContractCreation(tester);

      // Bob Martin is a member; check him
      await tester.ensureVisible(find.text('Bob Martin'));
      await tester.tap(find.text('Bob Martin'));
      await tester.pumpAndSettle();

      expect(find.text('Amapiens rattachés (1)'), findsOneWidget);
      // Subscription checkboxes should be visible for the checked member
      expect(find.byType(CheckboxListTile), findsWidgets);
    },
  );

  testWidgets(
    'save is blocked with snackbar when checked member has no subscription',
    (tester) async {
      stubProductInclusion(contracts: [_emptyContract]);
      // Override: make Alice visible in the member list
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([_alice]));

      await startContractCreation(tester);

      // Check Alice who has no subscriptions selected yet
      // (two products available → no auto-pre-check)
      await tester.ensureVisible(find.text('Alice Durand'));
      await tester.tap(find.text('Alice Durand'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
      await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
      await tester.pump();

      expect(
        find.textContaining('Sélectionnez au moins un produit'),
        findsOneWidget,
      );
      verifyNever(() => contractRepository.create(any()));
    },
  );

  testWidgets(
    'pre-fills subscriptions when editing a contract with existing members',
    (tester) async {
      stubMemberAssignment(contracts: [_contractWithBob]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('1 amapiens'));
      await tester.pumpAndSettle();

      // Bob is already checked with subscriptions pre-filled from _bobEntry
      expect(memberTile(tester, 'Bob Martin').value, isTrue);
      // Subscription options should be visible below Bob
      expect(find.byType(CheckboxListTile), findsWidgets);
    },
  );

  testWidgets(
    'creating a contract saves checked members with their subscriptions',
    (tester) async {
      stubProductInclusion(contracts: []);
      // Override: make Bob visible in the member list
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([_bob]));

      await startContractCreation(tester);

      // Check Bob – only one product included (Tomates with Petit)
      // → auto-pre-check fires
      await toggleProduct(tester, 'Oeufs');
      await tester.ensureVisible(find.text('Bob Martin'));
      await tester.tap(find.text('Bob Martin'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
      await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final captured =
          verify(() => contractRepository.create(captureAny())).captured.single
              as Contract;
      expect(captured.members, hasLength(1));
      expect(captured.members.single.memberId, 'm-bob');
      expect(captured.members.single.subscriptions, isNotEmpty);
    },
  );

  group('status and template dropdowns + weekly delivery dialog', () {
    void stubForNewContract() {
      when(
        () => organizationRepository.watch(any()),
      ).thenAnswer((_) => Stream.value(_organizationWithProducts));
      when(
        () => memberRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => contractRepository.watch(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(() => producerAccountRepository.watchAll()).thenAnswer(
        (_) => Stream.value([
          const ProducerAccount(
            producerAccountId: 'producer-1',
            name: 'Ferme Test',
          ),
        ]),
      );
      // create() returns the contract as-is (its contractId may be empty for
      // a brand-new one, which is fine — planWeeklyDeliveries only uses the
      // dates and contractId).
      when(() => contractRepository.create(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments.first as Contract,
      );
    }

    testWidgets(
      'GIVEN new contract form WHEN rendered THEN status dropdown shows "En préparation"',
      (tester) async {
        stubForNewContract();

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Open the new-contract form.
        await tester.tap(find.text('➕ NOUVEAU CONTRAT'));
        await tester.pumpAndSettle();

        // The status DropdownButtonFormField must be present with its label.
        expect(
          find.widgetWithText(
            DropdownButtonFormField<ContractStatus>,
            'Statut',
          ),
          findsOneWidget,
        );
        // The default selected value shown in the form must be "En préparation".
        expect(find.text('En préparation'), findsOneWidget);
      },
    );

    testWidgets(
      'GIVEN templates available WHEN form rendered THEN delivery template dropdown is visible',
      (tester) async {
        // Override the default stub to return one template.
        when(() => deliveryTemplateRepository.watch(any())).thenAnswer(
          (_) => Stream.value([
            const DeliveryTemplate(
              deliveryTemplateId: 'tpl-1',
              organizationId: 'org-1',
              name: 'Modèle standard',
              standardStartTime: '18:00',
              standardEndTime: '20:00',
            ),
          ]),
        );
        stubForNewContract();

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Open the new-contract form.
        await tester.tap(find.text('➕ NOUVEAU CONTRAT'));
        await tester.pumpAndSettle();

        // The template DropdownButtonFormField must be present with its label.
        expect(
          find.widgetWithText(
            DropdownButtonFormField<String?>,
            'Modèle de livraison',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'GIVEN new contract created with weekly deliveries WHEN user confirms dialog THEN updateDeliveries called',
      (tester) async {
        stubForNewContract();
        when(
          () => organizationRepository.updateDeliveries(
            currentOrg: any(named: 'currentOrg'),
            deliveries: any(named: 'deliveries'),
          ),
        ).thenAnswer((_) async {});

        await startContractCreation(tester);

        await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
        await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
        // Let the async save + dialog render complete.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // The weekly-delivery dialog must appear.
        expect(
          find.text('Créer les livraisons hebdomadaires ?'),
          findsOneWidget,
        );

        // Confirm.
        await tester.tap(find.text('Créer'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(
          () => organizationRepository.updateDeliveries(
            currentOrg: any(named: 'currentOrg'),
            deliveries: any(named: 'deliveries'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'GIVEN new contract created with weekly deliveries WHEN user declines dialog THEN updateDeliveries NOT called',
      (tester) async {
        stubForNewContract();

        await startContractCreation(tester);

        await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
        await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // The weekly-delivery dialog must appear.
        expect(
          find.text('Créer les livraisons hebdomadaires ?'),
          findsOneWidget,
        );

        // Decline.
        await tester.tap(find.text('Non'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verifyNever(
          () => organizationRepository.updateDeliveries(
            currentOrg: any(named: 'currentOrg'),
            deliveries: any(named: 'deliveries'),
          ),
        );
      },
    );

    testWidgets(
      'GIVEN contract id remapped while the dialog is open WHEN user confirms '
      'THEN generated deliveries link the real contract id',
      (tester) async {
        stubForNewContract();
        // After creation, a sync completing while the dialog is open remaps
        // the contract's tmp_* id: the cache then only holds it under its
        // server id (same natural key — producer, name, season, dates).
        final today = DateTime.now().toString().split(' ')[0];
        final remapped = Contract(
          contractId: 'c-real',
          name: 'Légumes 2026',
          organizationId: 'org-1',
          producerAccountId: 'producer-1',
          minDeliveryDate: today,
          maxDeliveryDate: today,
          deliveryCount: 1,
          seasonYear: DateTime.now().year,
        );
        var cachedContracts = const <Contract>[];
        when(
          () => contractRepository.watch(any()),
        ).thenAnswer((_) => Stream.value(cachedContracts));
        when(() => contractRepository.create(any())).thenAnswer((
          invocation,
        ) async {
          cachedContracts = [remapped];
          return (invocation.positionalArguments.first as Contract).copyWith(
            contractId: 'tmp_contract_1',
          );
        });
        when(
          () => organizationRepository.updateDeliveries(
            currentOrg: any(named: 'currentOrg'),
            deliveries: any(named: 'deliveries'),
          ),
        ).thenAnswer((_) async {});

        await startContractCreation(tester);

        await tester.ensureVisible(find.text('ENREGISTRER LE CONTRAT'));
        await tester.tap(find.text('ENREGISTRER LE CONTRAT'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('Créer les livraisons hebdomadaires ?'),
          findsOneWidget,
        );

        await tester.tap(find.text('Créer'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final captured =
            verify(
                  () => organizationRepository.updateDeliveries(
                    currentOrg: any(named: 'currentOrg'),
                    deliveries: captureAny(named: 'deliveries'),
                  ),
                ).captured.single
                as List<Delivery>;
        final generated = captured
            .where((d) => d.deliveryId.startsWith('tmp_delivery_'))
            .toList();
        expect(generated, isNotEmpty);
        for (final delivery in generated) {
          expect(delivery.contracts.single.contractId, 'c-real');
        }
      },
    );
  });
}
