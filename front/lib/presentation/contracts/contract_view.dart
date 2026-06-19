import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_account.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';

enum ContractFilter { all, inPreparation, active, upcoming, ended }

enum ContractStatusView { inPreparation, active, upcoming, ended }

ContractStatusView contractStatusView(Contract contract, {DateTime? now}) {
  if (contract.status == ContractStatus.ended) return ContractStatusView.ended;
  final today = _normalizeDate(now ?? DateTime.now());
  final end = _parseDate(contract.maxDeliveryDate);
  if (end != null && end.isBefore(today)) return ContractStatusView.ended;
  if (contract.status == ContractStatus.inPreparation) {
    return ContractStatusView.inPreparation;
  }
  final start = _parseDate(contract.minDeliveryDate);
  if (start != null && start.isAfter(today)) return ContractStatusView.upcoming;
  return ContractStatusView.active;
}

bool isContractEffectivelyEnded(Contract contract, {DateTime? now}) =>
    contractStatusView(contract, now: now) == ContractStatusView.ended;

bool contractLinkableAt(Contract contract, DateTime date, {DateTime? now}) {
  if (isContractEffectivelyEnded(contract, now: now)) return false;
  final min = _parseDate(contract.minDeliveryDate);
  final max = _parseDate(contract.maxDeliveryDate);
  final d = _normalizeDate(date);
  if (min != null && d.isBefore(min)) return false;
  if (max != null && d.isAfter(max)) return false;
  return true;
}

bool contractMatchesFilter(
  Contract contract,
  ContractFilter filter, {
  DateTime? now,
}) {
  if (filter == ContractFilter.all) return true;
  final status = contractStatusView(contract, now: now);
  return switch (filter) {
    ContractFilter.all => true,
    ContractFilter.inPreparation => status == ContractStatusView.inPreparation,
    ContractFilter.active => status == ContractStatusView.active,
    ContractFilter.upcoming => status == ContractStatusView.upcoming,
    ContractFilter.ended => status == ContractStatusView.ended,
  };
}

String contractProductLabel(
  Contract contract,
  Organization? organization, [
  List<ProducerAccount> producerAccounts = const [],
]) {
  for (final account in producerAccounts) {
    if (account.producerAccountId == contract.producerAccountId) {
      return account.name;
    }
  }
  final products = organization?.products ?? const <OrgProduct>[];
  for (final product in products) {
    if (product.producerAccountId == contract.producerAccountId) {
      return product.name;
    }
  }
  return contract.producerAccountId;
}

String contractStatusLabel(ContractStatusView status) => switch (status) {
  ContractStatusView.inPreparation => 'En préparation',
  ContractStatusView.active => 'Actif',
  ContractStatusView.upcoming => 'À venir',
  ContractStatusView.ended => 'Terminé',
};

String contractMemberStatusLabel(ContractMemberStatus status) =>
    switch (status) {
      ContractMemberStatus.active => 'Actif',
      ContractMemberStatus.suspended => 'Suspendu',
      ContractMemberStatus.completed => 'Terminé',
      ContractMemberStatus.cancelled => 'Annulé',
      ContractMemberStatus.notPresent => 'Absent',
    };

String memberDisplayName(Member member) {
  final fullName = [
    member.firstName?.trim() ?? '',
    member.lastName?.trim() ?? '',
  ].where((part) => part.isNotEmpty).join(' ');
  if (fullName.isNotEmpty) return fullName;
  final email = member.email?.trim();
  if (email != null && email.isNotEmpty) return email;
  return member.memberId;
}

DateTime? _parseDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return _normalizeDate(parsed);
}

DateTime _normalizeDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Product name resolution: lookup in organization.products by productTypeId, or fallback to raw id.
String productTypeName(String productTypeId, Organization? organization) {
  if (organization == null) return productTypeId;
  for (final product in organization.products) {
    if (product.productTypeId == productTypeId) {
      return product.name;
    }
  }
  return productTypeId;
}

/// Generates a unique key for a subscription option: "productTypeId:basketSizeName" or "productTypeId:" if no size.
String subscriptionKey(String productTypeId, BasketSize? basketSize) {
  return '$productTypeId:${basketSize?.name ?? ''}';
}

/// A selectable subscription option (product + optional basket size).
typedef SubscriptionOption = ({
  String key,
  String label,
  String productTypeId,
  BasketSize? basketSize,
});

/// Derives subscription options from a contract's persisted product prices.
/// Used by the member-contract editor to render checkboxes for assigned contracts.
List<SubscriptionOption> subscriptionOptionsFromPrices(
  List<ProductPrice> productPrices,
  Organization? organization,
) {
  final options = <SubscriptionOption>[];
  for (final price in productPrices) {
    final productName = productTypeName(price.productTypeId, organization);
    final basketSize = price.basketSize;
    if (basketSize == null) {
      options.add((
        key: subscriptionKey(price.productTypeId, null),
        label: productName,
        productTypeId: price.productTypeId,
        basketSize: null,
      ));
    } else {
      options.add((
        key: subscriptionKey(price.productTypeId, basketSize),
        label: '$productName — ${basketSize.name}',
        productTypeId: price.productTypeId,
        basketSize: basketSize,
      ));
    }
  }
  return options;
}

/// Converts a set of subscription keys back to MemberSubscription objects,
/// ordered by their appearance in [options].
List<MemberSubscription> subscriptionsFromKeys(
  Set<String> keys,
  List<SubscriptionOption> options,
) {
  final result = <MemberSubscription>[];
  for (final option in options) {
    if (keys.contains(option.key)) {
      result.add(
        MemberSubscription(
          productTypeId: option.productTypeId,
          basketSize: option.basketSize,
        ),
      );
    }
  }
  return result;
}

/// Converts a list of MemberSubscription objects to their subscription keys.
Set<String> keysFromSubscriptions(List<MemberSubscription> subscriptions) {
  return {
    for (final sub in subscriptions)
      subscriptionKey(sub.productTypeId, sub.basketSize),
  };
}
