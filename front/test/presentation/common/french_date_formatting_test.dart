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
}
