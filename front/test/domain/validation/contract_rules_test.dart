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

  group('weeklyDeliveryCount', () {
    test('counts both bounds: four Wednesdays from the 7th to the 28th', () {
      expect(
        weeklyDeliveryCount(DateTime(2026, 10, 7), DateTime(2026, 10, 28)),
        4,
      );
    });

    test('a single-day contract has one delivery', () {
      expect(
        weeklyDeliveryCount(DateTime(2026, 10, 7), DateTime(2026, 10, 7)),
        1,
      );
    });

    test('a partial last week does not add a delivery', () {
      expect(
        weeklyDeliveryCount(DateTime(2026, 10, 7), DateTime(2026, 10, 20)),
        2,
      );
    });

    test('an inverted range falls back to one delivery', () {
      expect(
        weeklyDeliveryCount(DateTime(2026, 10, 28), DateTime(2026, 10, 7)),
        1,
      );
    });
  });
}
