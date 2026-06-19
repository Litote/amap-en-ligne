import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_view.dart';
import 'package:flutter/material.dart';

/// Checkboxes for a single member's subscription options within a contract.
///
/// Renders one [CheckboxListTile] per subscription option derived from the
/// contract's [ProductPrice] list.
class ContractSubscriptionCheckboxes extends StatelessWidget {
  const ContractSubscriptionCheckboxes({
    super.key,
    required this.memberId,
    required this.memberSubscriptionKeys,
    required this.productPrices,
    required this.organization,
    required this.saving,
    required this.onSubscriptionToggled,
  });

  final String memberId;
  final Set<String> memberSubscriptionKeys;
  final List<ProductPrice> productPrices;
  final Organization organization;
  final bool saving;
  final void Function(String key, {required bool selected})
  onSubscriptionToggled;

  @override
  Widget build(BuildContext context) {
    final options = subscriptionOptionsFromPrices(productPrices, organization);

    return Column(
      children: [
        for (final option in options)
          CheckboxListTile(
            value: memberSubscriptionKeys.contains(option.key),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: Text(
              option.label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onChanged: saving
                ? null
                : (value) => onSubscriptionToggled(
                    option.key,
                    selected: value ?? false,
                  ),
          ),
      ],
    );
  }
}
