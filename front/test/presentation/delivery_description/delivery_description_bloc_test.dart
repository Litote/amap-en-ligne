import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_bloc.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_event.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockProductTypeRepository extends Mock
    implements ProductTypeRepository {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _productType = ProductType(
  productTypeId: 'pt-1',
  producerAccountId: 'pa-1',
  name: 'Légumes',
  itemTypes: [
    ItemType(id: 'it-1', name: 'carottes', imageSvg: '<svg></svg>'),
    ItemType(id: 'it-2', name: 'courgettes'),
  ],
);

final _delivery = Delivery(
  deliveryId: 'd-1',
  organizationId: 'org-1',
  scheduledDate: '2025-06-14T09:00:00',
  status: DeliveryStatus.planned,
  minVolunteersRequired: 2,
);

final _org = Organization(
  organizationId: 'org-1',
  name: 'AMAP test',
  contactEmail: 'test@example.com',
  products: const [
    OrgProduct(
      name: 'Légumes',
      productTypeId: 'pt-1',
      producerAccountId: 'pa-1',
      supportedBasketSizes: [BasketSize(name: 'Medium')],
    ),
  ],
  deliveries: [_delivery],
);

// A loaded state with no descriptions yet.
DeliveryDescriptionLoaded _loadedState({
  List<BasketDeliveryDescription> descriptions = const [],
}) => DeliveryDescriptionLoaded(
  org: _org,
  delivery: _delivery,
  productTypes: const [_productType],
  localDescriptions: descriptions,
);

void main() {
  late _MockOrganizationRepository orgRepo;
  late _MockProductTypeRepository productTypeRepo;

  setUpAll(() {
    // Mocktail requires fallback values for custom types used with any().
    registerFallbackValue(
      const Organization(
        organizationId: 'fallback-org',
        name: 'fallback',
        contactEmail: 'fallback@example.com',
      ),
    );
    registerFallbackValue(const <BasketDeliveryDescription>[]);
  });

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    productTypeRepo = _MockProductTypeRepository();
    // Default: watch returns an empty stream with one value.
    when(
      () => productTypeRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const [_productType]));
  });

  DeliveryDescriptionBloc buildBloc() => DeliveryDescriptionBloc(
    organizationRepository: orgRepo,
    productTypeRepository: productTypeRepo,
  );

  // ---------------------------------------------------------------------------
  // DeliveryDescriptionRequested
  // ---------------------------------------------------------------------------

  blocTest<DeliveryDescriptionBloc, DeliveryDescriptionState>(
    'GIVEN an org WHEN DeliveryDescriptionRequested THEN emits Loaded',
    build: buildBloc,
    act: (bloc) => bloc.add(
      DeliveryDescriptionEvent.requested(org: _org, deliveryId: 'd-1'),
    ),
    expect: () => [
      isA<DeliveryDescriptionLoaded>()
          .having((s) => s.delivery.deliveryId, 'deliveryId', 'd-1')
          .having((s) => s.localDescriptions, 'localDescriptions', isEmpty),
    ],
  );

  // ---------------------------------------------------------------------------
  // ItemToggled — add
  // ---------------------------------------------------------------------------

  blocTest<DeliveryDescriptionBloc, DeliveryDescriptionState>(
    'GIVEN a delivery WHEN ItemToggled THEN item is added to localDescriptions',
    build: buildBloc,
    seed: () => _loadedState(),
    act: (bloc) => bloc.add(
      const DeliveryDescriptionEvent.itemToggled(
        productTypeId: 'pt-1',
        basketSizeName: 'Medium',
        itemTypeId: 'it-1',
      ),
    ),
    expect: () => [
      isA<DeliveryDescriptionLoaded>()
          .having((s) => s.localDescriptions, 'localDescriptions', [
            isA<BasketDeliveryDescription>()
                .having((d) => d.productTypeId, 'productTypeId', 'pt-1')
                .having((d) => d.basketSizeName, 'basketSizeName', 'Medium')
                .having((d) => d.items.first.itemTypeId, 'itemTypeId', 'it-1')
                // Only a tiny label snapshot rides on the item (no SVG).
                .having((d) => d.items.first.name, 'name', 'carottes'),
          ]),
    ],
  );

  // ---------------------------------------------------------------------------
  // ItemToggled — remove (toggle off)
  // ---------------------------------------------------------------------------

  blocTest<DeliveryDescriptionBloc, DeliveryDescriptionState>(
    'GIVEN a selected item WHEN ItemToggled again THEN item is removed',
    build: buildBloc,
    seed: () => _loadedState(
      descriptions: const [
        BasketDeliveryDescription(
          productTypeId: 'pt-1',
          basketSizeName: 'Medium',
          items: [DeliveryItem(itemTypeId: 'it-1')],
        ),
      ],
    ),
    act: (bloc) => bloc.add(
      const DeliveryDescriptionEvent.itemToggled(
        productTypeId: 'pt-1',
        basketSizeName: 'Medium',
        itemTypeId: 'it-1',
      ),
    ),
    expect: () => [
      isA<DeliveryDescriptionLoaded>().having(
        (s) => s.localDescriptions,
        'localDescriptions',
        isEmpty,
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // WeightChanged
  // ---------------------------------------------------------------------------

  blocTest<DeliveryDescriptionBloc, DeliveryDescriptionState>(
    'GIVEN a selected item WHEN WeightChanged THEN weight is updated',
    build: buildBloc,
    seed: () => _loadedState(
      descriptions: const [
        BasketDeliveryDescription(
          productTypeId: 'pt-1',
          basketSizeName: 'Medium',
          items: [DeliveryItem(itemTypeId: 'it-1')],
        ),
      ],
    ),
    act: (bloc) => bloc.add(
      const DeliveryDescriptionEvent.weightChanged(
        productTypeId: 'pt-1',
        basketSizeName: 'Medium',
        itemTypeId: 'it-1',
        weight: '500g',
      ),
    ),
    expect: () => [
      isA<DeliveryDescriptionLoaded>().having(
        (s) => s.localDescriptions.first.items.first.weight,
        'weight',
        '500g',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // DeliveryDescriptionSaveRequested
  // ---------------------------------------------------------------------------

  blocTest<DeliveryDescriptionBloc, DeliveryDescriptionState>(
    'GIVEN a loaded state WHEN SaveRequested THEN emits Saving then Saved',
    setUp: () => when(
      () => orgRepo.updateDeliveryDescription(
        currentOrg: any(named: 'currentOrg'),
        deliveryId: any(named: 'deliveryId'),
        basketDescriptions: any(named: 'basketDescriptions'),
        itemTypes: any(named: 'itemTypes'),
      ),
    ).thenAnswer((_) async {}),
    build: buildBloc,
    seed: () => _loadedState(),
    act: (bloc) => bloc.add(const DeliveryDescriptionEvent.saveRequested()),
    expect: () => [
      const DeliveryDescriptionState.saving(),
      const DeliveryDescriptionState.saved(),
    ],
    verify: (_) => verify(
      () => orgRepo.updateDeliveryDescription(
        currentOrg: any(named: 'currentOrg'),
        deliveryId: any(named: 'deliveryId'),
        basketDescriptions: any(named: 'basketDescriptions'),
        itemTypes: any(named: 'itemTypes'),
      ),
    ).called(1),
  );

  // ---------------------------------------------------------------------------
  // Catalog dedup: SVG is stored once in Organization.itemTypes, not per item
  // ---------------------------------------------------------------------------

  blocTest<DeliveryDescriptionBloc, DeliveryDescriptionState>(
    'GIVEN a composition WHEN SaveRequested THEN the used SVG component is merged '
    'into the org-level catalog (and the delivery item carries no SVG)',
    setUp: () => when(
      () => orgRepo.updateDeliveryDescription(
        currentOrg: any(named: 'currentOrg'),
        deliveryId: any(named: 'deliveryId'),
        basketDescriptions: any(named: 'basketDescriptions'),
        itemTypes: any(named: 'itemTypes'),
      ),
    ).thenAnswer((_) async {}),
    build: buildBloc,
    seed: () => _loadedState(
      descriptions: const [
        BasketDeliveryDescription(
          productTypeId: 'pt-1',
          basketSizeName: 'Medium',
          items: [DeliveryItem(itemTypeId: 'it-1', name: 'carottes')],
        ),
      ],
    ),
    act: (bloc) => bloc.add(const DeliveryDescriptionEvent.saveRequested()),
    verify: (_) {
      final captured =
          verify(
                () => orgRepo.updateDeliveryDescription(
                  currentOrg: any(named: 'currentOrg'),
                  deliveryId: any(named: 'deliveryId'),
                  basketDescriptions: any(named: 'basketDescriptions'),
                  itemTypes: captureAny(named: 'itemTypes'),
                ),
              ).captured.single
              as List<ItemType>;
      // The SVG-bearing component used by the composition is in the catalog once.
      expect(captured.where((it) => it.id == 'it-1').length, 1);
      expect(
        captured.firstWhere((it) => it.id == 'it-1').imageSvg,
        '<svg></svg>',
      );
    },
  );
}
