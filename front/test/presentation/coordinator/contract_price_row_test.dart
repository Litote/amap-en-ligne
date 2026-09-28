import 'package:amap_en_ligne/presentation/coordinator/contract_price_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats a stored price with two decimals for editing', () {
    expect(formatPriceForInput(3.5), '3.50');
    expect(formatPriceForInput(6), '6.00');
    expect(formatPriceForInput(null), '');
  });
}
