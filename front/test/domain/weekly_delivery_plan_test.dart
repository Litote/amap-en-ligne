import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/model/weekly_delivery_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const orgId = 'org-1';
  const contractId = 'c-1';

  Contract buildContract({
    String id = contractId,
    String minDate = '2026-01-05',
    String maxDate = '2026-01-26',
    List<ProductPrice> productPrices = const [],
    bool isMainContract = false,
  }) => Contract(
    contractId: id,
    name: 'Contrat test',
    organizationId: orgId,
    producerAccountId: 'pa-1',
    minDeliveryDate: minDate,
    maxDeliveryDate: maxDate,
    deliveryCount: 4,
    seasonYear: 2026,
    productPrices: productPrices,
    isMainContract: isMainContract,
  );

  Organization buildOrg({
    List<Delivery> deliveries = const [],
    List<OrgProduct> products = const [],
  }) => Organization(
    organizationId: orgId,
    name: 'AMAP Test',
    contactEmail: 'test@example.com',
    deliveries: deliveries,
    products: products,
  );

  var counter = 0;
  int nextTmpId() => ++counter;

  setUp(() => counter = 0);

  group('planWeeklyDeliveries', () {
    test('génère une livraison par semaine sur 4 semaines', () {
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-26',
      );
      final org = buildOrg();

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: org,
        template: null,
        nextTmpId: nextTmpId,
      );

      expect(plan.newCount, 4);
      expect(plan.linkedCount, 0);
      expect(plan.totalAffected, 4);
      expect(plan.deliveries.length, 4);

      // All new deliveries should reference the contract.
      for (final d in plan.deliveries) {
        expect(d.deliveryId, startsWith('tmp_delivery_'));
        expect(d.contracts.any((dc) => dc.contractId == contractId), isTrue);
        expect(d.status, DeliveryStatus.planned);
      }

      // Dates should be weekly starting from minDeliveryDate.
      final dates = plan.deliveries
          .map((d) => d.scheduledDate.split('T').first)
          .toList();
      expect(
        dates,
        containsAll(['2026-01-05', '2026-01-12', '2026-01-19', '2026-01-26']),
      );
    });

    test('lie une livraison existante au même jour sans doublon de date', () {
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
      );
      final existingDelivery = Delivery(
        deliveryId: 'del-existing',
        organizationId: orgId,
        scheduledDate: '2026-01-05T10:00:00',
        status: DeliveryStatus.planned,
        minVolunteersRequired: 2,
        contracts: const [],
      );
      final org = buildOrg(deliveries: [existingDelivery]);

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: org,
        template: null,
        nextTmpId: nextTmpId,
      );

      expect(plan.newCount, 0);
      expect(plan.linkedCount, 1);
      expect(plan.totalAffected, 1);
      // No duplicate — still one delivery in the result.
      expect(plan.deliveries.length, 1);
      expect(plan.deliveries.first.deliveryId, 'del-existing');
      expect(
        plan.deliveries.first.contracts.any(
          (dc) => dc.contractId == contractId,
        ),
        isTrue,
      );
    });

    test('ne lie pas si la livraison est déjà liée au contrat', () {
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
      );
      final alreadyLinked = Delivery(
        deliveryId: 'del-linked',
        organizationId: orgId,
        scheduledDate: '2026-01-05T18:00:00',
        status: DeliveryStatus.planned,
        minVolunteersRequired: 1,
        contracts: [
          const DeliveryContract(
            contractId: contractId,
            basketQuantity: 0,
            deliveryDescription: 'Contrat test',
            status: DeliveryContractStatus.pending,
          ),
        ],
      );
      final org = buildOrg(deliveries: [alreadyLinked]);

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: org,
        template: null,
        nextTmpId: nextTmpId,
      );

      expect(plan.newCount, 0);
      expect(plan.linkedCount, 0);
      expect(plan.totalAffected, 0);
      // Delivery unchanged.
      expect(plan.deliveries.length, 1);
      expect(plan.deliveries.first.contracts.length, 1);
    });

    test('utilise l\'heure du template pour les nouvelles livraisons', () {
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
      );
      final template = const DeliveryTemplate(
        deliveryTemplateId: 'tpl-1',
        organizationId: orgId,
        name: 'Modèle matin',
        standardStartTime: '09:30',
        standardEndTime: '11:00',
        desiredVolunteerCount: 3,
      );
      final org = buildOrg();

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: org,
        template: template,
        nextTmpId: nextTmpId,
      );

      expect(plan.newCount, 1);
      final scheduledDate = plan.deliveries.first.scheduledDate;
      // Should contain 09:30.
      expect(scheduledDate, contains('09:30'));
    });

    test('utilise 18h par défaut sans template', () {
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
      );
      final org = buildOrg();

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: org,
        template: null,
        nextTmpId: nextTmpId,
      );

      expect(plan.newCount, 1);
      final scheduledDate = plan.deliveries.first.scheduledDate;
      expect(scheduledDate, contains('18:00'));
    });

    test(
      'retourne les livraisons inchangées si les dates ne peuvent pas être parsées',
      () {
        final contract = buildContract(
          minDate: 'invalid-date',
          maxDate: '2026-01-26',
        );
        final delivery = Delivery(
          deliveryId: 'del-1',
          organizationId: orgId,
          scheduledDate: '2026-01-05T18:00:00',
          status: DeliveryStatus.planned,
          minVolunteersRequired: 1,
          contracts: const [],
        );
        final org = buildOrg(deliveries: [delivery]);

        final plan = planWeeklyDeliveries(
          contract: contract,
          org: org,
          template: null,
          nextTmpId: nextTmpId,
        );

        expect(plan.newCount, 0);
        expect(plan.linkedCount, 0);
        expect(plan.deliveries, org.deliveries);
      },
    );

    test('les nouvelles livraisons portent les produits des prix du contrat '
        'en basket descriptions', () {
      const tomates = OrgProduct(
        name: 'Tomates',
        productTypeId: 'pt-1',
        producerAccountId: 'pa-1',
        supportedBasketSizes: [
          BasketSize(name: 'Petit'),
          BasketSize(name: 'Grand'),
        ],
      );
      const oeufs = OrgProduct(
        name: 'Oeufs',
        productTypeId: 'pt-2',
        producerAccountId: 'pa-2',
        supportedBasketSizes: [BasketSize(name: 'Petit')],
      );
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
        productPrices: const [
          ProductPrice(
            productTypeId: 'pt-1',
            basketSize: BasketSize(name: 'Petit'),
          ),
        ],
      );
      final org = buildOrg(products: const [tomates, oeufs]);

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: org,
        template: null,
        nextTmpId: nextTmpId,
      );

      expect(plan.newCount, 1);
      expect(plan.deliveries.single.basketDescriptions, const [
        BasketDeliveryDescription(
          productTypeId: 'pt-1',
          basketSizeName: 'Petit',
        ),
        BasketDeliveryDescription(
          productTypeId: 'pt-1',
          basketSizeName: 'Grand',
        ),
      ]);
    });

    test('contrat sans prix : basket descriptions des produits du producteur '
        'uniquement', () {
      const tomates = OrgProduct(
        name: 'Tomates',
        productTypeId: 'pt-1',
        producerAccountId: 'pa-1',
        supportedBasketSizes: [BasketSize(name: 'Petit')],
      );
      const oeufs = OrgProduct(
        name: 'Oeufs',
        productTypeId: 'pt-2',
        producerAccountId: 'pa-2',
        supportedBasketSizes: [BasketSize(name: 'Petit')],
      );
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
      );
      final org = buildOrg(products: const [tomates, oeufs]);

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: org,
        template: null,
        nextTmpId: nextTmpId,
      );

      expect(plan.newCount, 1);
      expect(plan.deliveries.single.basketDescriptions, const [
        BasketDeliveryDescription(
          productTypeId: 'pt-1',
          basketSizeName: 'Petit',
        ),
      ]);
    });

    test('les nouvelles livraisons portent un créneau bénévole STANDARD '
        'ouvert', () {
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
        isMainContract: true,
      );
      final template = const DeliveryTemplate(
        deliveryTemplateId: 'tpl-1',
        organizationId: orgId,
        name: 'Modèle soir',
        standardStartTime: '18:00',
        standardEndTime: '20:00',
        desiredVolunteerCount: 3,
        earlySlot: EarlySlot(
          arrivalTime: '17:00',
          explanation: 'Réception',
          maxVolunteers: 2,
        ),
      );

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: buildOrg(),
        template: template,
        nextTmpId: nextTmpId,
      );

      expect(plan.newCount, 1);
      final slots = plan.deliveries.single.contracts.single.slots;
      expect(slots, hasLength(2));
      expect(slots.first.slotKind, SlotKind.standard);
      expect(slots.first.status, SlotStatus.open);
      expect(slots.first.requiredVolunteers, 3);
      expect(slots.first.startTime, '2026-01-05T18:00:00');
      expect(slots.first.endTime, '2026-01-05T20:00:00');
      expect(slots.last.slotKind, SlotKind.early);
      expect(slots.last.requiredVolunteers, 2);
    });

    test('sans template : créneau STANDARD de deux heures basé sur 18h', () {
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
        isMainContract: true,
      );

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: buildOrg(),
        template: null,
        nextTmpId: nextTmpId,
      );

      final slots = plan.deliveries.single.contracts.single.slots;
      expect(slots, hasLength(1));
      expect(slots.single.slotKind, SlotKind.standard);
      expect(slots.single.startTime, '2026-01-05T18:00:00');
      expect(slots.single.endTime, '2026-01-05T20:00:00');
      expect(slots.single.requiredVolunteers, 1);
    });

    test('un contrat secondaire ne génère aucun créneau bénévole', () {
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
        // isMainContract defaults to false.
      );

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: buildOrg(),
        template: null,
        nextTmpId: nextTmpId,
      );

      expect(plan.newCount, 1);
      expect(plan.deliveries.single.contracts.single.slots, isEmpty);
    });

    test(
      'lier le contrat principal à une livraison sans créneau les ajoute',
      () {
        // A delivery created by a secondary contract already exists (no slots);
        // linking the main contract materialises the volunteer slots on it.
        final existingDelivery = Delivery(
          deliveryId: 'del-existing',
          organizationId: orgId,
          scheduledDate: '2026-01-05T18:00:00',
          status: DeliveryStatus.planned,
          minVolunteersRequired: 4,
          contracts: const [
            DeliveryContract(
              contractId: 'c-eggs',
              basketQuantity: 5,
              status: DeliveryContractStatus.pending,
              deliveryDescription: 'Œufs',
            ),
          ],
        );
        final mainContract = buildContract(
          id: 'c-veg',
          minDate: '2026-01-05',
          maxDate: '2026-01-05',
          isMainContract: true,
        );

        final plan = planWeeklyDeliveries(
          contract: mainContract,
          org: buildOrg(deliveries: [existingDelivery]),
          template: null,
          nextTmpId: nextTmpId,
        );

        expect(plan.linkedCount, 1);
        final delivery = plan.deliveries.single;
        final mainLink = delivery.contracts.firstWhere(
          (c) => c.contractId == 'c-veg',
        );
        expect(mainLink.slots, hasLength(1));
        expect(mainLink.slots.single.requiredVolunteers, 4);
        // The secondary contract stays slotless.
        final eggsLink = delivery.contracts.firstWhere(
          (c) => c.contractId == 'c-eggs',
        );
        expect(eggsLink.slots, isEmpty);
      },
    );

    test('ne modifie pas les basket descriptions des livraisons liées', () {
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
      );
      final existingDelivery = Delivery(
        deliveryId: 'del-existing',
        organizationId: orgId,
        scheduledDate: '2026-01-05T10:00:00',
        status: DeliveryStatus.planned,
        minVolunteersRequired: 2,
        basketDescriptions: const [
          BasketDeliveryDescription(
            productTypeId: 'pt-9',
            basketSizeName: 'Petit',
          ),
        ],
      );
      final org = buildOrg(deliveries: [existingDelivery]);

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: org,
        template: null,
        nextTmpId: nextTmpId,
      );

      expect(plan.linkedCount, 1);
      expect(
        plan.deliveries.single.basketDescriptions,
        existingDelivery.basketDescriptions,
      );
    });

    test('ignore les livraisons annulées lors du matching de dates', () {
      final contract = buildContract(
        minDate: '2026-01-05',
        maxDate: '2026-01-05',
      );
      final cancelledDelivery = Delivery(
        deliveryId: 'del-cancelled',
        organizationId: orgId,
        scheduledDate: '2026-01-05T18:00:00',
        status: DeliveryStatus.cancelled,
        minVolunteersRequired: 1,
        contracts: const [],
      );
      final org = buildOrg(deliveries: [cancelledDelivery]);

      final plan = planWeeklyDeliveries(
        contract: contract,
        org: org,
        template: null,
        nextTmpId: nextTmpId,
      );

      // Cancelled delivery is not matched → new delivery is created.
      expect(plan.newCount, 1);
      expect(plan.linkedCount, 0);
    });
  });

  group('resolveSavedContract', () {
    test('retrouve le contrat par id quand il est encore en cache', () {
      final saved = buildContract(id: 'tmp_contract_1');
      final other = buildContract(id: 'c-other');

      final resolved = resolveSavedContract([other, saved], saved);

      expect(resolved.contractId, 'tmp_contract_1');
    });

    test('retrouve le contrat remappé par clé naturelle quand l\'id tmp a '
        'disparu', () {
      final saved = buildContract(id: 'tmp_contract_1');
      // Same natural key (producer, name, season, dates) but a server id.
      final remapped = buildContract(id: 'c-real');
      final unrelated = Contract(
        contractId: 'c-other',
        name: 'Autre contrat',
        organizationId: orgId,
        producerAccountId: 'pa-1',
        minDeliveryDate: '2026-01-05',
        maxDeliveryDate: '2026-01-26',
        deliveryCount: 4,
        seasonYear: 2026,
      );

      final resolved = resolveSavedContract([unrelated, remapped], saved);

      expect(resolved.contractId, 'c-real');
    });

    test('retombe sur le contrat sauvé quand aucun candidat n\'existe', () {
      final saved = buildContract(id: 'tmp_contract_1');

      final resolved = resolveSavedContract(const [], saved);

      expect(resolved, saved);
    });
  });
}
