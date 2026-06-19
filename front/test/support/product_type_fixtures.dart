import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/domain/sync/client_mutation.dart';
import 'package:amap_en_ligne/domain/sync/entity_payload.dart';
import 'package:amap_en_ligne/domain/sync/entity_type.dart';
import 'package:amap_en_ligne/domain/sync/mutation_op.dart';

const testTenantId = 'producer-1';
const testProducerScopeKey = 'producer-account:producer-1';
const smallBasketSize = BasketSize(name: 'small');
const largeBasketSize = BasketSize(name: 'large');

ProductType buildProductType({
  String productTypeId = 'pt-1',
  String producerAccountId = testTenantId,
  List<BasketSize> supportedBasketSizes = const [],
  String name = 'Vegetables',
  String? description,
}) => ProductType(
  productTypeId: productTypeId,
  producerAccountId: producerAccountId,
  supportedBasketSizes: supportedBasketSizes,
  name: name,
  description: description,
);

ClientMutation buildProductTypeUpsertMutation({
  String clientOpId = 'op-1',
  ProductType? productType,
}) => ClientMutation(
  clientOpId: clientOpId,
  op: Upsert(
    payload: ProductTypePayload(
      productType: productType ?? buildProductType(productTypeId: 'tmp_abc'),
    ),
  ),
);

ClientMutation buildProductTypeDeleteMutation({
  String clientOpId = 'op-1',
  String entityId = 'pt-1',
}) => ClientMutation(
  clientOpId: clientOpId,
  op: Delete(entityType: EntityType.productType, entityId: entityId),
);
