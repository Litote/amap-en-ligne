import 'package:amap_en_ligne/presentation/common/instant_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  test('formats an ISO-8601 instant as a French local date and time', () {
    final local = DateTime.parse('2026-09-26T06:27:42.216486503Z').toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');

    expect(
      formatInstantFr('2026-09-26T06:27:42.216486503Z'),
      '${local.day} sept. 2026 à ${hh}h$mm',
    );
  });

  test('returns the raw value when it is not a date', () {
    expect(formatInstantFr('not-a-date'), 'not-a-date');
  });
}
