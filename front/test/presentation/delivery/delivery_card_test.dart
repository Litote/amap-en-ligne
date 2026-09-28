import 'dart:ui';

import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/organization_fixtures.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  const memberId = 'm1';
  const member = Member(memberId: memberId, organizationId: 'org-1');

  Future<void> pumpCard(
    WidgetTester tester, {
    required Delivery delivery,
    required Organization org,
    required DeliveryCardVariant variant,
    bool pendingContractActivation = false,
    Member viewer = member,
    List<Contract> contracts = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryCard(
              delivery: delivery,
              member: viewer,
              org: org,
              membersById: {viewer.memberId: viewer},
              variant: variant,
              pendingContractActivation: pendingContractActivation,
              contracts: contracts,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('planning: pending contract activation flags inactive contract', (
    tester,
  ) async {
    final slot = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
    final delivery = buildDelivery(
      contracts: [
        buildContract(slots: [slot]),
      ],
    );
    await pumpCard(
      tester,
      delivery: delivery,
      org: buildOrg(deliveries: [delivery]),
      variant: DeliveryCardVariant.planning,
      pendingContractActivation: true,
    );

    expect(find.text('🚧 Contrat inactif'), findsOneWidget);
    expect(find.text("S'INSCRIRE"), findsNothing);
    expect(find.text('✅ COMPLET'), findsNothing);
  });

  group('contrat en préparation', () {
    Contract contractOf(String id, String name, ContractStatus status) =>
        Contract(
          contractId: id,
          name: name,
          organizationId: 'org-1',
          producerAccountId: 'producer-$id',
          minDeliveryDate: '2020-01-01',
          maxDeliveryDate: '2100-12-31',
          deliveryCount: 10,
          seasonYear: 2026,
          status: status,
          productPrices: [ProductPrice(productTypeId: 'pt-$id')],
        );

    final contracts = [
      contractOf('active', 'Oeufs', ContractStatus.active),
      contractOf('prep', 'Fromages test', ContractStatus.inPreparation),
    ];
    final delivery = buildDelivery(
      contracts: [
        buildContract(contractId: 'active'),
        buildContract(contractId: 'prep'),
      ],
    );

    for (final variant in DeliveryCardVariant.values) {
      testWidgets('$variant : caché à un amapien', (tester) async {
        await pumpCard(
          tester,
          delivery: delivery,
          org: buildOrg(deliveries: [delivery]),
          variant: variant,
          contracts: contracts,
        );

        expect(find.textContaining('Oeufs'), findsWidgets);
        expect(find.textContaining('Fromages test'), findsNothing);
      });
    }

    testWidgets('visible pour un coordinateur', (tester) async {
      await pumpCard(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.planning,
        contracts: contracts,
        viewer: const Member(
          memberId: memberId,
          organizationId: 'org-1',
          roles: {Role.volunteer, Role.coordinator},
        ),
      );

      expect(find.textContaining('Fromages test'), findsOneWidget);
    });
  });

  group('header time range ends with the standard slot', () {
    // A full standard slot ending at 20:30, two hours being the old default.
    Delivery deliveryEndingAt2030() {
      final slot = buildSlot(
        startTime: '2030-01-16T19:00:00',
        endTime: '2030-01-16T20:30:00',
        requiredVolunteers: 1,
        currentRegistrations: 1,
        status: SlotStatus.full,
        registrations: [buildRegistration(memberId: 'volunteer-1')],
      );
      return buildDelivery(
        scheduledDate: '2030-01-16T19:00:00',
        contracts: [
          buildContract(slots: [slot]),
        ],
      );
    }

    testWidgets('planning', (tester) async {
      final delivery = deliveryEndingAt2030();
      await pumpCard(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.planning,
      );

      expect(find.textContaining('• 19h00-20h30'), findsOneWidget);
    });

    testWidgets('dashboard', (tester) async {
      final delivery = deliveryEndingAt2030();
      await pumpCard(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.dashboard,
      );

      expect(find.textContaining('• 19h-20h30'), findsOneWidget);
    });
  });

  testWidgets('planning: full standard slot shows COMPLET and no register', (
    tester,
  ) async {
    final slot = buildSlot(
      requiredVolunteers: 2,
      currentRegistrations: 2,
      registrations: [
        buildRegistration(memberId: 'volunteer-1'),
        buildRegistration(memberId: 'volunteer-2'),
      ],
    );
    final delivery = buildDelivery(
      contracts: [
        buildContract(slots: [slot]),
      ],
    );
    await pumpCard(
      tester,
      delivery: delivery,
      org: buildOrg(deliveries: [delivery]),
      variant: DeliveryCardVariant.planning,
    );

    expect(find.text('✅ COMPLET'), findsOneWidget);
    expect(find.text("S'INSCRIRE"), findsNothing);
  });

  group('coordinateur inscrit (non compté parmi les bénévoles)', () {
    final delivery = buildDelivery(
      contracts: [
        buildContract(
          coordinators: [memberId],
          slots: [
            buildSlot(
              requiredVolunteers: 2,
              registrations: [buildRegistration(memberId: memberId)],
            ),
          ],
        ),
      ],
    );

    testWidgets('planning', (tester) async {
      await pumpCard(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.planning,
      );

      expect(
        find.text('✅ Vous êtes inscrit(e) comme coordinateur'),
        findsOneWidget,
      );
      expect(find.text('✅ Vous êtes inscrit(e) comme bénévole'), findsNothing);
    });

    testWidgets('dashboard', (tester) async {
      await pumpCard(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.dashboard,
      );

      expect(find.text('✅ Inscrit(e) comme coordinateur'), findsOneWidget);
    });
  });

  testWidgets('dashboard: registered member sees Inscrit(e) and unregister', (
    tester,
  ) async {
    final reg = buildRegistration(memberId: memberId);
    final slot = buildSlot(
      requiredVolunteers: 3,
      currentRegistrations: 1,
      registrations: [reg],
    );
    final delivery = buildDelivery(
      contracts: [
        buildContract(slots: [slot]),
      ],
    );
    await pumpCard(
      tester,
      delivery: delivery,
      org: buildOrg(deliveries: [delivery]),
      variant: DeliveryCardVariant.dashboard,
    );

    expect(find.text('✅ Inscrit(e)'), findsOneWidget);
    expect(find.text('SE DÉSINSCRIRE'), findsOneWidget);
  });

  testWidgets('dashboard: open slot shows S\'INSCRIRE', (tester) async {
    final slot = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
    final delivery = buildDelivery(
      contracts: [
        buildContract(slots: [slot]),
      ],
    );
    await pumpCard(
      tester,
      delivery: delivery,
      org: buildOrg(deliveries: [delivery]),
      variant: DeliveryCardVariant.dashboard,
    );

    expect(find.text("S'INSCRIRE"), findsOneWidget);
  });

  testWidgets(
    'dashboard: a full slot on one contract still offers S\'INSCRIRE when another contract slot is open',
    (tester) async {
      // Mirrors imported deliveries that carry one STANDARD slot per contract:
      // the first (Légumes) is full, the others are open. Capacity must consider
      // every standard slot, not just the first one.
      final fullSlot = buildSlot(
        requiredVolunteers: 1,
        currentRegistrations: 3,
      );
      final openSlot = buildSlot(
        requiredVolunteers: 1,
        currentRegistrations: 0,
      );
      final delivery = buildDelivery(
        contracts: [
          buildContract(contractId: 'c-legumes', slots: [fullSlot]),
          buildContract(contractId: 'c-pain', slots: [openSlot]),
        ],
      );
      await pumpCard(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.dashboard,
      );

      expect(find.text("S'INSCRIRE"), findsOneWidget);
      expect(find.text('✅ COMPLET'), findsNothing);
    },
  );

  testWidgets(
    'planning: basket composition section lists items with weight (read-only)',
    (tester) async {
      final slot = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
      final delivery = buildDelivery(
        contracts: [
          buildContract(slots: [slot]),
        ],
        basketDescriptions: const [
          BasketDeliveryDescription(
            productTypeId: 'pt-1',
            basketSizeName: 'Medium',
            items: [
              DeliveryItem(
                itemTypeId: 'it-1',
                name: 'Carottes',
                weight: '500g',
              ),
              DeliveryItem(itemTypeId: 'it-2', name: 'Betteraves'),
            ],
          ),
        ],
      );
      await pumpCard(
        tester,
        delivery: delivery,
        // The SVG icon lives once in the org-level catalog, resolved by id.
        org: buildOrg(
          deliveries: [delivery],
          itemTypes: const [
            ItemType(id: 'it-1', name: 'Carottes', imageSvg: '<svg></svg>'),
          ],
        ),
        variant: DeliveryCardVariant.planning,
      );

      expect(find.text('🧺 Composition du panier'), findsOneWidget);
      // Screen readers get an actionable, emoji-free header.
      final semantics = tester.ensureSemantics();
      final headerNode = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^Composition du panier$')),
      );
      final header = headerNode.getSemanticsData();
      expect(header.hasAction(SemanticsAction.tap), isTrue);
      expect(header.flagsCollection.isButton, isTrue);
      expect(header.flagsCollection.isExpanded, Tristate.isFalse);
      // No ancestor may block accessibility focus: the web engine then folds
      // the header into the card's node (what ExpansionTile's live region did).
      for (var node = headerNode.parent; node != null; node = node.parent) {
        expect(
          node.getSemanticsData().flagsCollection.isAccessibilityFocusBlocked,
          isFalse,
        );
      }
      semantics.dispose();
      // The section is collapsed by default — expand it to reveal items.
      await tester.tap(find.text('🧺 Composition du panier'));
      await tester.pumpAndSettle();

      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Carottes'), findsOneWidget);
      expect(find.text('500g'), findsOneWidget);
      expect(find.text('Betteraves'), findsOneWidget);
    },
  );

  testWidgets('planning: a delivery without volunteer slot (secondary '
      'contract only) leaves no blank gap before the coordinators', (
    tester,
  ) async {
    final delivery = buildDelivery(
      scheduledDate: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .split('.')
          .first,
      contracts: [buildContract(slots: const [])],
    );
    await pumpCard(
      tester,
      delivery: delivery,
      org: buildOrg(deliveries: [delivery]),
      variant: DeliveryCardVariant.planning,
    );

    final dateBottom = tester.getRect(find.textContaining('📅')).bottom;
    final coordinatorsTop = tester.getRect(find.text('👥 Coordinateurs :')).top;
    // Only the regular spacing: no room reserved for the (absent) volunteer
    // badge, counter and registration actions.
    expect(coordinatorsTop - dateBottom, lessThanOrEqualTo(16));
  });

  testWidgets('planning: no composition section when no items are described', (
    tester,
  ) async {
    final slot = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
    final delivery = buildDelivery(
      contracts: [
        buildContract(slots: [slot]),
      ],
    );
    await pumpCard(
      tester,
      delivery: delivery,
      org: buildOrg(deliveries: [delivery]),
      variant: DeliveryCardVariant.planning,
    );

    expect(find.text('🧺 Composition du panier'), findsNothing);
  });

  testWidgets('counter sums STANDARD and EARLY slots (/5)', (tester) async {
    final standard = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
    final early = buildSlot(
      requiredVolunteers: 2,
      currentRegistrations: 0,
    ).copyWith(slotKind: SlotKind.early);
    final delivery = buildDelivery(
      contracts: [
        buildContract(slots: [standard, early]),
      ],
    );
    await pumpCard(
      tester,
      delivery: delivery,
      org: buildOrg(deliveries: [delivery]),
      variant: DeliveryCardVariant.planning,
    );

    expect(find.textContaining('0/5 bénévoles'), findsOneWidget);
    // Cancelled slots must not inflate the denominator.
    expect(find.textContaining('0/3 bénévoles'), findsNothing);
  });

  testWidgets(
    'dashboard: early capacity shows early slot badge with remaining count',
    (tester) async {
      final standard = buildSlot(
        requiredVolunteers: 3,
        currentRegistrations: 0,
      );
      final early = buildSlot(
        requiredVolunteers: 2,
        currentRegistrations: 0,
      ).copyWith(slotKind: SlotKind.early);
      final delivery = buildDelivery(
        contracts: [
          buildContract(slots: [standard, early]),
        ],
      );
      await pumpCard(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.dashboard,
      );

      expect(
        find.textContaining('⏰ Créneau anticipé disponible'),
        findsOneWidget,
      );
      expect(find.textContaining('2 places restantes'), findsOneWidget);
      expect(find.byType(Tooltip), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'dashboard: early slot badge is hidden when member is already registered',
    (tester) async {
      final reg = buildRegistration(memberId: memberId);
      final standard = buildSlot(
        requiredVolunteers: 3,
        currentRegistrations: 1,
        registrations: [reg],
      );
      final early = buildSlot(
        requiredVolunteers: 2,
        currentRegistrations: 0,
      ).copyWith(slotKind: SlotKind.early);
      final delivery = buildDelivery(
        contracts: [
          buildContract(slots: [standard, early]),
        ],
      );
      await pumpCard(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.dashboard,
      );

      expect(
        find.textContaining('⏰ Créneau anticipé disponible'),
        findsNothing,
      );
      expect(find.text('✅ Inscrit(e)'), findsOneWidget);
    },
  );

  testWidgets(
    'dashboard: early capacity singular shows "place restante" (not plural)',
    (tester) async {
      final standard = buildSlot(
        requiredVolunteers: 3,
        currentRegistrations: 0,
      );
      final early = buildSlot(
        requiredVolunteers: 1,
        currentRegistrations: 0,
      ).copyWith(slotKind: SlotKind.early);
      final delivery = buildDelivery(
        contracts: [
          buildContract(slots: [standard, early]),
        ],
      );
      await pumpCard(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.dashboard,
      );

      expect(find.textContaining('1 place restante)'), findsOneWidget);
      expect(find.textContaining('1 places restantes'), findsNothing);
    },
  );

  testWidgets('planning: early slot badge has a Tooltip with explanation', (
    tester,
  ) async {
    final standard = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
    final early = buildSlot(
      requiredVolunteers: 2,
      currentRegistrations: 0,
    ).copyWith(slotKind: SlotKind.early);
    final delivery = buildDelivery(
      contracts: [
        buildContract(slots: [standard, early]),
      ],
    );
    await pumpCard(
      tester,
      delivery: delivery,
      org: buildOrg(deliveries: [delivery]),
      variant: DeliveryCardVariant.planning,
    );

    expect(
      find.textContaining('⏰ Créneau anticipé disponible'),
      findsOneWidget,
    );
    expect(find.byType(Tooltip), findsAtLeastNWidgets(1));
  });

  Future<void> pumpCardWithTemplate(
    WidgetTester tester, {
    required Delivery delivery,
    required Organization org,
    required DeliveryCardVariant variant,
    DeliveryTemplate? template,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryCard(
              delivery: delivery,
              member: member,
              org: org,
              membersById: {member.memberId: member},
              variant: variant,
              template: template,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('planning: explanation shows when early slot has explanation', (
    tester,
  ) async {
    final standard = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
    final early = buildSlot(
      requiredVolunteers: 2,
      currentRegistrations: 0,
    ).copyWith(slotKind: SlotKind.early);
    final delivery = buildDelivery(
      contracts: [
        buildContract(slots: [standard, early]),
      ],
    );
    const template = DeliveryTemplate(
      deliveryTemplateId: 'tpl-1',
      organizationId: 'org-1',
      name: 'Modèle test',
      standardStartTime: '18:00',
      standardEndTime: '20:00',
      earlySlot: EarlySlot(
        arrivalTime: '17:00',
        explanation: 'Réception des légumes',
        maxVolunteers: 2,
      ),
    );

    await pumpCardWithTemplate(
      tester,
      delivery: delivery,
      org: buildOrg(deliveries: [delivery]),
      variant: DeliveryCardVariant.planning,
      template: template,
    );

    expect(find.textContaining('Réception des légumes'), findsOneWidget);
  });

  testWidgets(
    'planning: explanation is hidden when early slot has no explanation',
    (tester) async {
      final standard = buildSlot(
        requiredVolunteers: 3,
        currentRegistrations: 0,
      );
      final early = buildSlot(
        requiredVolunteers: 2,
        currentRegistrations: 0,
      ).copyWith(slotKind: SlotKind.early);
      final delivery = buildDelivery(
        contracts: [
          buildContract(slots: [standard, early]),
        ],
      );
      const template = DeliveryTemplate(
        deliveryTemplateId: 'tpl-1',
        organizationId: 'org-1',
        name: 'Modèle sans explication',
        standardStartTime: '18:00',
        standardEndTime: '20:00',
        earlySlot: EarlySlot(arrivalTime: '17:00', maxVolunteers: 2),
      );

      await pumpCardWithTemplate(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.planning,
        template: template,
      );

      expect(find.textContaining('ℹ️'), findsNothing);
    },
  );

  testWidgets(
    'dashboard: explanation is hidden when early slot has no explanation',
    (tester) async {
      final standard = buildSlot(
        requiredVolunteers: 3,
        currentRegistrations: 0,
      );
      final early = buildSlot(
        requiredVolunteers: 2,
        currentRegistrations: 0,
      ).copyWith(slotKind: SlotKind.early);
      final delivery = buildDelivery(
        contracts: [
          buildContract(slots: [standard, early]),
        ],
      );
      const template = DeliveryTemplate(
        deliveryTemplateId: 'tpl-1',
        organizationId: 'org-1',
        name: 'Modèle sans explication',
        standardStartTime: '18:00',
        standardEndTime: '20:00',
        earlySlot: EarlySlot(arrivalTime: '17:00', maxVolunteers: 2),
      );

      await pumpCardWithTemplate(
        tester,
        delivery: delivery,
        org: buildOrg(deliveries: [delivery]),
        variant: DeliveryCardVariant.dashboard,
        template: template,
      );

      // Explanation text must not appear when null.
      expect(find.textContaining('Réception'), findsNothing);
    },
  );

  testWidgets('dashboard: compact coordinator line shows phone link', (
    tester,
  ) async {
    const coordinator = Member(
      memberId: 'coord-1',
      organizationId: 'org-1',
      firstName: 'Jean',
      lastName: 'Morel',
      phone: '06 12 34 56 78',
    );
    final slot = buildSlot(requiredVolunteers: 3, currentRegistrations: 0);
    final delivery = buildDelivery(
      contracts: [
        buildContract(coordinators: const ['coord-1'], slots: [slot]),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryCard(
              delivery: delivery,
              member: member,
              org: buildOrg(deliveries: [delivery]),
              membersById: {coordinator.memberId: coordinator},
              variant: DeliveryCardVariant.dashboard,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('06 12 34 56 78'), findsOneWidget);
  });

  group('shared basket pickup line (planning)', () {
    const coSharerId = 'm2';
    const coSharer = Member(
      memberId: coSharerId,
      organizationId: 'org-1',
      firstName: 'Paul',
      lastName: 'Martin',
    );

    Contract sharedContract() => const Contract(
      contractId: 'c-1',
      name: 'Panier légumes',
      organizationId: 'org-1',
      producerAccountId: 'pa-1',
      minDeliveryDate: '2026-01-01',
      maxDeliveryDate: '2026-12-31',
      deliveryCount: 2,
      seasonYear: 2026,
      sharedBaskets: [
        SharedBasket(sharedBasketId: 'sb-1', memberIds: [memberId, coSharerId]),
      ],
    );

    // Two deliveries linked to c-1: d-0 (earlier) → member's turn, d-1 → co-sharer's turn.
    final d0 = buildDelivery(
      deliveryId: 'd-0',
      scheduledDate: '2026-02-01T09:00:00',
      contracts: [
        buildContract(slots: [buildSlot(requiredVolunteers: 1)]),
      ],
    );
    final d1 = buildDelivery(
      deliveryId: 'd-1',
      scheduledDate: '2026-02-08T09:00:00',
      contracts: [
        buildContract(slots: [buildSlot(requiredVolunteers: 1)]),
      ],
    );

    Future<void> pumpShared(WidgetTester tester, Delivery delivery) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeliveryCard(
                delivery: delivery,
                member: member,
                org: buildOrg(deliveries: [d0, d1]),
                membersById: {member.memberId: member, coSharerId: coSharer},
                variant: DeliveryCardVariant.planning,
                contracts: [sharedContract()],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets("shows the member's turn on their pickup week", (tester) async {
      await pumpShared(tester, d0);
      expect(
        find.textContaining("c'est votre tour de récupérer le panier"),
        findsOneWidget,
      );
    });

    testWidgets("shows the co-sharer's turn on the alternate week", (
      tester,
    ) async {
      await pumpShared(tester, d1);
      expect(find.textContaining('récupéré par Paul Martin'), findsOneWidget);
    });

    testWidgets('shows nothing when no contracts are provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryCard(
              delivery: d0,
              member: member,
              org: buildOrg(deliveries: [d0, d1]),
              membersById: {member.memberId: member},
              variant: DeliveryCardVariant.planning,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Panier partagé'), findsNothing);
    });
  });
}
