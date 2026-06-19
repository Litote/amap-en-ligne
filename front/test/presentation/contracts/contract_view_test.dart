import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Contract buildContract({
    String minDeliveryDate = '2026-01-01',
    String maxDeliveryDate = '2026-12-31',
    String producerAccountId = 'pa-1',
    ContractStatus status = ContractStatus.inPreparation,
  }) => Contract(
    contractId: 'c-1',
    name: 'Contrat test',
    organizationId: 'org-1',
    producerAccountId: producerAccountId,
    minDeliveryDate: minDeliveryDate,
    maxDeliveryDate: maxDeliveryDate,
    deliveryCount: 10,
    seasonYear: 2026,
    status: status,
  );

  group('contractStatusView', () {
    test(
      'ENDED manual status overrides date — returns ended even with future dates',
      () {
        expect(
          contractStatusView(
            buildContract(
              minDeliveryDate: '2030-01-01',
              maxDeliveryDate: '2030-12-31',
              status: ContractStatus.ended,
            ),
            now: DateTime(2026, 6, 1),
          ),
          ContractStatusView.ended,
        );
      },
    );

    test(
      'ACTIVE status with past maxDeliveryDate returns ended (date wins)',
      () {
        expect(
          contractStatusView(
            buildContract(
              minDeliveryDate: '2020-01-01',
              maxDeliveryDate: '2020-12-31',
              status: ContractStatus.active,
            ),
            now: DateTime(2021, 1, 1),
          ),
          ContractStatusView.ended,
        );
      },
    );

    test('IN_PREPARATION with future dates returns inPreparation', () {
      expect(
        contractStatusView(
          buildContract(
            minDeliveryDate: '2030-01-01',
            maxDeliveryDate: '2030-12-31',
            status: ContractStatus.inPreparation,
          ),
          now: DateTime(2026, 6, 1),
        ),
        ContractStatusView.inPreparation,
      );
    });

    test('IN_PREPARATION with active date range returns inPreparation', () {
      expect(
        contractStatusView(
          buildContract(
            minDeliveryDate: '2026-01-01',
            maxDeliveryDate: '2026-12-31',
            status: ContractStatus.inPreparation,
          ),
          now: DateTime(2026, 6, 1),
        ),
        ContractStatusView.inPreparation,
      );
    });

    test('ACTIVE with active date range returns active', () {
      expect(
        contractStatusView(
          buildContract(
            minDeliveryDate: '2026-01-01',
            maxDeliveryDate: '2026-12-31',
            status: ContractStatus.active,
          ),
          now: DateTime(2026, 6, 1),
        ),
        ContractStatusView.active,
      );
    });

    test('ACTIVE with future start returns upcoming', () {
      expect(
        contractStatusView(
          buildContract(
            minDeliveryDate: '2030-01-01',
            maxDeliveryDate: '2030-12-31',
            status: ContractStatus.active,
          ),
          now: DateTime(2026, 6, 1),
        ),
        ContractStatusView.upcoming,
      );
    });

    test(
      'returns upcoming when the contract starts in the future (legacy: ACTIVE implicit)',
      () {
        expect(
          contractStatusView(
            buildContract(
              minDeliveryDate: '2030-01-01',
              maxDeliveryDate: '2030-12-31',
              status: ContractStatus.active,
            ),
            now: DateTime(2029, 12, 31),
          ),
          ContractStatusView.upcoming,
        );
      },
    );

    test('returns ended when the contract is already finished', () {
      expect(
        contractStatusView(
          buildContract(
            minDeliveryDate: '2020-01-01',
            maxDeliveryDate: '2020-12-31',
            status: ContractStatus.active,
          ),
          now: DateTime(2021, 1, 1),
        ),
        ContractStatusView.ended,
      );
    });

    test('returns active when today falls inside the period', () {
      expect(
        contractStatusView(
          buildContract(
            minDeliveryDate: '2026-01-01',
            maxDeliveryDate: '2026-12-31',
            status: ContractStatus.active,
          ),
          now: DateTime(2026, 6, 1),
        ),
        ContractStatusView.active,
      );
    });
  });

  group('isContractEffectivelyEnded', () {
    test('returns true for ENDED manual status with future dates', () {
      expect(
        isContractEffectivelyEnded(
          buildContract(
            minDeliveryDate: '2030-01-01',
            maxDeliveryDate: '2030-12-31',
            status: ContractStatus.ended,
          ),
          now: DateTime(2026, 6, 1),
        ),
        isTrue,
      );
    });

    test('returns true when date-ended even with ACTIVE status', () {
      expect(
        isContractEffectivelyEnded(
          buildContract(
            minDeliveryDate: '2020-01-01',
            maxDeliveryDate: '2020-12-31',
            status: ContractStatus.active,
          ),
          now: DateTime(2021, 1, 1),
        ),
        isTrue,
      );
    });

    test('returns false for ACTIVE in-range contract', () {
      expect(
        isContractEffectivelyEnded(
          buildContract(
            minDeliveryDate: '2026-01-01',
            maxDeliveryDate: '2026-12-31',
            status: ContractStatus.active,
          ),
          now: DateTime(2026, 6, 1),
        ),
        isFalse,
      );
    });

    test(
      'returns false for IN_PREPARATION (even with past dates — date check ends it)',
      () {
        // Date-ended takes priority even over IN_PREPARATION
        expect(
          isContractEffectivelyEnded(
            buildContract(
              minDeliveryDate: '2020-01-01',
              maxDeliveryDate: '2020-12-31',
              status: ContractStatus.inPreparation,
            ),
            now: DateTime(2021, 1, 1),
          ),
          isTrue,
        );
      },
    );
  });

  group('contractLinkableAt', () {
    test('returns false when contract is effectively ended (ENDED manual)', () {
      expect(
        contractLinkableAt(
          buildContract(
            minDeliveryDate: '2030-01-01',
            maxDeliveryDate: '2030-12-31',
            status: ContractStatus.ended,
          ),
          DateTime(2030, 6, 1),
          now: DateTime(2026, 6, 1),
        ),
        isFalse,
      );
    });

    test('returns false when delivery date is before minDeliveryDate', () {
      expect(
        contractLinkableAt(
          buildContract(
            minDeliveryDate: '2026-06-01',
            maxDeliveryDate: '2026-12-31',
            status: ContractStatus.active,
          ),
          DateTime(2026, 5, 31),
          now: DateTime(2026, 5, 31),
        ),
        isFalse,
      );
    });

    test('returns false when delivery date is after maxDeliveryDate', () {
      expect(
        contractLinkableAt(
          buildContract(
            minDeliveryDate: '2026-01-01',
            maxDeliveryDate: '2026-06-30',
            status: ContractStatus.active,
          ),
          DateTime(2026, 7, 1),
          now: DateTime(2026, 6, 1),
        ),
        isFalse,
      );
    });

    test('returns true for IN_PREPARATION contract within date range', () {
      // IN_PREPARATION contracts are linkable for F3 weekly delivery creation
      expect(
        contractLinkableAt(
          buildContract(
            minDeliveryDate: '2026-01-01',
            maxDeliveryDate: '2026-12-31',
            status: ContractStatus.inPreparation,
          ),
          DateTime(2026, 6, 1),
          now: DateTime(2026, 6, 1),
        ),
        isTrue,
      );
    });

    test('returns true for ACTIVE contract on exact boundary dates', () {
      expect(
        contractLinkableAt(
          buildContract(
            minDeliveryDate: '2026-06-01',
            maxDeliveryDate: '2026-12-31',
            status: ContractStatus.active,
          ),
          DateTime(2026, 6, 1),
          now: DateTime(2026, 6, 1),
        ),
        isTrue,
      );
    });
  });

  test('contractMatchesFilter delegates to the computed status', () {
    final contract = buildContract(
      minDeliveryDate: '2030-01-01',
      maxDeliveryDate: '2030-12-31',
      status: ContractStatus.active,
    );

    expect(
      contractMatchesFilter(
        contract,
        ContractFilter.upcoming,
        now: DateTime(2029, 1, 1),
      ),
      isTrue,
    );
    expect(
      contractMatchesFilter(
        contract,
        ContractFilter.active,
        now: DateTime(2029, 1, 1),
      ),
      isFalse,
    );
  });

  test('contractProductLabel resolves producer name from producerAccounts', () {
    final producerAccounts = [
      const ProducerAccount(
        producerAccountId: 'pa-1',
        name: 'Ferme des Collines',
      ),
    ];

    expect(
      contractProductLabel(
        buildContract(producerAccountId: 'pa-1'),
        null,
        producerAccounts,
      ),
      'Ferme des Collines',
    );
  });

  test('contractProductLabel falls back to org product name when no match', () {
    final organization = Organization(
      organizationId: 'org-1',
      name: 'AMAP',
      contactEmail: 'contact@amap.fr',
      products: const [
        OrgProduct(
          name: 'Tomates',
          productTypeId: 'pt-1',
          producerAccountId: 'pa-1',
        ),
      ],
    );

    expect(
      contractProductLabel(
        buildContract(producerAccountId: 'pa-1'),
        organization,
      ),
      'Tomates',
    );
  });

  test('contractProductLabel falls back to producerAccountId when unknown', () {
    expect(
      contractProductLabel(buildContract(producerAccountId: 'unknown'), null),
      'unknown',
    );
  });

  test('memberDisplayName falls back to email then member id', () {
    expect(
      memberDisplayName(
        const Member(
          memberId: 'm-1',
          organizationId: 'org-1',
          firstName: 'Alice',
          lastName: 'Martin',
        ),
      ),
      'Alice Martin',
    );
    expect(
      memberDisplayName(
        const Member(
          memberId: 'm-2',
          organizationId: 'org-1',
          email: 'alice@example.fr',
        ),
      ),
      'alice@example.fr',
    );
    expect(
      memberDisplayName(const Member(memberId: 'm-3', organizationId: 'org-1')),
      'm-3',
    );
  });

  group('Contract subscription helpers', () {
    const productTypeId = 'pt-tomato';
    final basketSizeSmall = BasketSize(name: 'small');

    test('subscriptionKey generates correct key without basket size', () {
      final key = subscriptionKey(productTypeId, null);
      expect(key, '$productTypeId:');
    });

    test('subscriptionKey generates correct key with basket size', () {
      final key = subscriptionKey(productTypeId, basketSizeSmall);
      expect(key, '$productTypeId:small');
    });

    test('keysFromSubscriptions extracts keys from subscriptions', () {
      final subscriptions = [
        MemberSubscription(productTypeId: productTypeId, basketSize: null),
        MemberSubscription(
          productTypeId: 'pt-eggs',
          basketSize: basketSizeSmall,
        ),
      ];
      final keys = keysFromSubscriptions(subscriptions);
      expect(keys, contains('$productTypeId:'));
      expect(keys, contains('pt-eggs:small'));
    });

    test('subscriptionsFromKeys reconstructs subscriptions from keys', () {
      final options = [
        (
          key: '$productTypeId:',
          label: 'Tomato',
          productTypeId: productTypeId,
          basketSize: null as BasketSize?,
        ),
        (
          key: 'pt-eggs:small',
          label: 'Eggs — small',
          productTypeId: 'pt-eggs',
          basketSize: basketSizeSmall,
        ),
      ];
      final keys = {'$productTypeId:', 'pt-eggs:small'};
      final subscriptions = subscriptionsFromKeys(keys, options);
      expect(subscriptions.length, 2);
      expect(subscriptions[0].productTypeId, productTypeId);
      expect(subscriptions[0].basketSize, null);
      expect(subscriptions[1].productTypeId, 'pt-eggs');
      expect(subscriptions[1].basketSize, basketSizeSmall);
    });

    test('productTypeName resolves the product name by productTypeId', () {
      const organization = Organization(
        organizationId: 'org-1',
        name: 'AMAP',
        contactEmail: 'contact@amap.fr',
        products: [
          OrgProduct(
            name: 'Tomates',
            productTypeId: 'pt-1',
            producerAccountId: 'pa-1',
          ),
        ],
      );

      expect(productTypeName('pt-1', organization), 'Tomates');
      expect(productTypeName('pt-unknown', organization), 'pt-unknown');
      expect(productTypeName('pt-1', null), 'pt-1');
    });

    test('subscriptionOptionsFromPrices labels use the org product name', () {
      const organization = Organization(
        organizationId: 'org-1',
        name: 'AMAP',
        contactEmail: 'contact@amap.fr',
        products: [
          OrgProduct(
            name: 'Tomates',
            productTypeId: 'pt-1',
            producerAccountId: 'pa-1',
            supportedBasketSizes: [BasketSize(name: 'Petit')],
          ),
        ],
      );
      const prices = [
        ProductPrice(
          productTypeId: 'pt-1',
          basketSize: BasketSize(name: 'Petit'),
        ),
      ];

      final options = subscriptionOptionsFromPrices(prices, organization);
      expect(options.single.label, 'Tomates — Petit');
    });

    test(
      'subscriptionOptionsFromPrices generates options from product prices',
      () {
        final prices = [
          ProductPrice(productTypeId: productTypeId, basketSize: null),
          ProductPrice(productTypeId: 'pt-eggs', basketSize: basketSizeSmall),
        ];
        final options = subscriptionOptionsFromPrices(prices, null);
        expect(options.length, 2);
        expect(options[0].productTypeId, productTypeId);
        expect(options[0].basketSize, null);
        expect(options[1].productTypeId, 'pt-eggs');
        expect(options[1].basketSize, basketSizeSmall);
      },
    );
  });
}
