import 'package:amap_en_ligne/presentation/coordinator/contract_price_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats a stored price with two decimals for editing', () {
    expect(formatPriceForInput(3.5), '3.50');
    expect(formatPriceForInput(6), '6.00');
    expect(formatPriceForInput(null), '');
  });

  testWidgets('the price field is announced with its basket size', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controllers = <String, TextEditingController>{};
    addTearDown(() {
      for (final c in controllers.values) {
        c.dispose();
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContractPriceRow(
            label: 'Boîte de 6',
            controllerKey: 'eggs:Boîte de 6',
            priceControllers: controllers,
            saving: false,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '3.50');
    await tester.pump();

    // Once filled the hint is gone: the visible size label must still name
    // the field for screen readers.
    final node = tester.getSemantics(find.byType(TextFormField));
    expect(node.label, contains('Boîte de 6'));
    expect(node.value, '3.50');
    handle.dispose();
  });
}
