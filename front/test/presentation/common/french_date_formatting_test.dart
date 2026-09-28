import 'package:amap_en_ligne/presentation/common/french_date_formatting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  test(
    'ensureFrenchDateFormattingInitialized loads French locale data',
    () async {
      await ensureFrenchDateFormattingInitialized();

      final formatted = DateFormat(
        'MMMM yyyy',
        'fr',
      ).format(DateTime(2025, 1, 15));

      expect(formatted, isNotEmpty);
    },
  );

  group('frenchDateFormat', () {
    setUpAll(ensureFrenchDateFormattingInitialized);

    test('the first of the month reads 1er', () {
      expect(
        frenchDateFormat('EEEE d MMMM').format(DateTime(2026, 10, 1)),
        'jeudi 1er octobre',
      );
      expect(
        frenchDateFormat('d MMM yyyy').format(DateTime(2026, 10, 1)),
        '1er oct. 2026',
      );
    });

    test('other days and quoted text are left as they are', () {
      expect(
        frenchDateFormat(
          "EEEE d MMMM • HH'h'mm",
        ).format(DateTime(2026, 10, 8, 18)),
        'jeudi 8 octobre • 18h00',
      );
      expect(
        frenchDateFormat(
          "d MMM yyyy 'à' HH'h'mm",
        ).format(DateTime(2026, 10, 1, 9, 5)),
        '1er oct. 2026 à 09h05',
      );
    });

    test('a two-digit day stays numeric', () {
      expect(
        frenchDateFormat('dd/MM/yyyy').format(DateTime(2026, 10, 1)),
        '01/10/2026',
      );
    });
  });
}
