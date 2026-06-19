import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_bloc.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_event.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductTypeRepository extends Mock
    implements ProductTypeRepository {}

class _MockIdGenerator extends Mock implements IdGenerator {}

const _baseProductType = ProductType(
  productTypeId: 'pt-1',
  producerAccountId: 'pa-1',
  name: 'Légumes',
);

void main() {
  late _MockProductTypeRepository repo;
  late _MockIdGenerator idGen;

  setUpAll(() {
    // Mocktail requires fallback values for custom types used with any().
    registerFallbackValue(
      const ProductType(
        productTypeId: 'fallback',
        producerAccountId: 'fallback',
        name: 'fallback',
      ),
    );
    registerFallbackValue(const <ItemType>[]);
  });

  setUp(() {
    repo = _MockProductTypeRepository();
    idGen = _MockIdGenerator();
    // Stub next() so id generation is deterministic.
    when(() => idGen.next()).thenReturn('generated-id');
  });

  ItemTypesBloc buildBloc() =>
      ItemTypesBloc(productTypeRepository: repo, idGenerator: idGen);

  blocTest<ItemTypesBloc, ItemTypesState>(
    'GIVEN a product type WHEN ItemTypesRequested THEN emits ItemTypesLoaded',
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const ItemTypesEvent.requested(productType: _baseProductType)),
    expect: () => [const ItemTypesState.loaded(productType: _baseProductType)],
  );

  blocTest<ItemTypesBloc, ItemTypesState>(
    'GIVEN a product type WHEN ItemTypeAdded THEN state contains new ItemType',
    setUp: () =>
        when(() => repo.updateItemTypes(any(), any())).thenAnswer((_) async {}),
    build: buildBloc,
    seed: () => const ItemTypesState.loaded(productType: _baseProductType),
    act: (bloc) => bloc.add(
      const ItemTypesEvent.added(name: 'carottes', imageSvg: '<svg></svg>'),
    ),
    expect: () => [
      isA<ItemTypesSaving>(),
      isA<ItemTypesSaved>()
          .having((s) => s.productType.itemTypes, 'itemTypes', [
            isA<ItemType>()
                .having((it) => it.name, 'name', 'carottes')
                .having((it) => it.imageSvg, 'imageSvg', '<svg></svg>'),
          ]),
    ],
    verify: (_) => verify(() => repo.updateItemTypes(any(), any())).called(1),
  );

  blocTest<ItemTypesBloc, ItemTypesState>(
    'GIVEN a product type with one item WHEN ItemTypeRemoved THEN list is empty',
    setUp: () =>
        when(() => repo.updateItemTypes(any(), any())).thenAnswer((_) async {}),
    build: buildBloc,
    seed: () => ItemTypesState.loaded(
      productType: _baseProductType.copyWith(
        itemTypes: const [ItemType(id: 'it-1', name: 'carottes')],
      ),
    ),
    act: (bloc) => bloc.add(const ItemTypesEvent.removed(itemTypeId: 'it-1')),
    expect: () => [
      isA<ItemTypesSaving>(),
      isA<ItemTypesSaved>().having(
        (s) => s.productType.itemTypes,
        'itemTypes',
        isEmpty,
      ),
    ],
    verify: (_) => verify(() => repo.updateItemTypes(any(), any())).called(1),
  );

  blocTest<ItemTypesBloc, ItemTypesState>(
    'GIVEN a product type with one item WHEN ItemTypeUpdated THEN item is replaced',
    setUp: () =>
        when(() => repo.updateItemTypes(any(), any())).thenAnswer((_) async {}),
    build: buildBloc,
    seed: () => ItemTypesState.loaded(
      productType: _baseProductType.copyWith(
        itemTypes: const [ItemType(id: 'it-1', name: 'carottes')],
      ),
    ),
    act: (bloc) => bloc.add(
      const ItemTypesEvent.updated(
        itemType: ItemType(id: 'it-1', name: 'carottes bio'),
      ),
    ),
    expect: () => [
      isA<ItemTypesSaving>(),
      isA<ItemTypesSaved>().having(
        (s) => s.productType.itemTypes.first.name,
        'name',
        'carottes bio',
      ),
    ],
  );
}
