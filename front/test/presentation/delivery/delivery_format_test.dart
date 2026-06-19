import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/delivery/delivery_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  // 2026-01-14 is a Wednesday.
  const wednesday = '2026-01-14T18:00:00';

  group('formatDeliveryDateLine', () {
    test('planning style uses full month and padded minutes', () {
      expect(
        formatDeliveryDateLine(wednesday, longMonth: true),
        'Mercredi 14 janvier • 18h00-20h00',
      );
    });

    test('dashboard style uses abbreviated month and trimmed minutes', () {
      expect(formatDeliveryDateLine(wednesday), startsWith('Mercredi 14 janv'));
      expect(formatDeliveryDateLine(wednesday), endsWith('• 18h-20h'));
    });

    test('uses the provided slot end time for the range end', () {
      expect(
        formatDeliveryDateLine(wednesday, slotEndTime: '2026-01-14T19:30:00'),
        endsWith('• 18h-19h30'),
      );
    });
  });

  test('formatDeliveryDateTime renders a single capitalised start time', () {
    expect(formatDeliveryDateTime(wednesday), 'Mercredi 14 janvier • 18h00');
  });

  group('formatSlotTime', () {
    test('drops minutes for whole hours', () {
      expect(formatSlotTime('2026-01-14T18:00:00'), '18h');
    });

    test('keeps minutes otherwise', () {
      expect(formatSlotTime('2026-01-14T18:30:00'), '18h30');
    });

    test('returns the input unchanged when unparseable', () {
      expect(formatSlotTime('not-a-date'), 'not-a-date');
    });
  });

  group('formatTemplateTime', () {
    test('formats HH:MM', () {
      expect(formatTemplateTime('18:30'), '18h30');
      expect(formatTemplateTime('18:00'), '18h');
      expect(formatTemplateTime('9:5'), '09h05');
    });

    test('returns the input unchanged when malformed', () {
      expect(formatTemplateTime('nope'), 'nope');
    });
  });

  test('activityLabel maps each activity type to its French label', () {
    expect(activityLabel(ActivityType.preparation), 'Préparation paniers');
    expect(activityLabel(ActivityType.reception), 'Réception');
    expect(activityLabel(ActivityType.distribution), 'Distribution');
  });
}
