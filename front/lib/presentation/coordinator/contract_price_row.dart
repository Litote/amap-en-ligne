import 'package:flutter/material.dart';

/// One row in the price section of the contract editor: a text field for the
/// price of a single basket size (or the overall price when sizes are not used).
class ContractPriceRow extends StatelessWidget {
  const ContractPriceRow({
    super.key,
    required this.label,
    required this.controllerKey,
    required this.priceControllers,
    required this.saving,
  });

  final String? label;
  final String controllerKey;
  final Map<String, TextEditingController> priceControllers;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final controller = priceControllers.putIfAbsent(
      controllerKey,
      TextEditingController.new,
    );
    final displayLabel = label ?? 'Prix (€)';
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(displayLabel)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Prix (€)',
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
