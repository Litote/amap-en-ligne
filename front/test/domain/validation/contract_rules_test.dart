import 'package:amap_en_ligne/domain/validation/contract_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('season year must be an integer in the accepted range', () {
    expect(seasonYearError('2026'), isNull);
    expect(seasonYearError('abc'), 'Année invalide');
    expect(seasonYearError('1999'), 'Année invalide (entre 2000 et 2100)');
  });

  test('first delivery date must not be after the last one', () {
    expect(contractDateRangeError('2026-10-01', '2026-12-17'), isNull);
    expect(contractDateRangeError('2026-10-01', '2026-10-01'), isNull);
    expect(
      contractDateRangeError('2026-12-17', '2026-10-01'),
      'La date de première livraison doit précéder la date de dernière livraison.',
    );
  });
}
