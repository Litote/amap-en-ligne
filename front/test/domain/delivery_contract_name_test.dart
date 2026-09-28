import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/delivery_contract_name.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const contract = Contract(
    contractId: 'c-1',
    name: 'Légumes 2026/2027',
    organizationId: 'org-1',
    producerAccountId: 'pa-1',
    minDeliveryDate: '2026-04-08',
    maxDeliveryDate: '2026-12-23',
    deliveryCount: 37,
    seasonYear: 2026,
  );

  DeliveryContract link({String description = ''}) => DeliveryContract(
    contractId: 'c-1',
    basketQuantity: 10,
    deliveryDescription: description,
    status: DeliveryContractStatus.pending,
  );

  group('deliveryContractName', () {
    test('prefers the live contract name over the link snapshot', () {
      expect(
        deliveryContractName(link(description: 'Ancien nom'), [contract]),
        'Légumes 2026/2027',
      );
    });

    test('falls back to the snapshot when the contract is unknown', () {
      expect(
        deliveryContractName(link(description: 'Légumes'), const []),
        'Légumes',
      );
    });

    test('falls back to the snapshot when the contract name is blank', () {
      expect(
        deliveryContractName(link(description: 'Légumes'), [
          contract.copyWith(name: '  '),
        ]),
        'Légumes',
      );
    });

    test('is empty when neither the contract nor the snapshot names it', () {
      expect(deliveryContractName(link(), const []), isEmpty);
    });
  });
}
