import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validateStandardEndTime rejects end before or equal to start', () {
    expect(
      validateStandardEndTime(
        standardStartTime: const TimeOfDay(hour: 18, minute: 0),
        standardEndTime: const TimeOfDay(hour: 17, minute: 30),
      ),
      "L'heure de fin doit être après l'heure de début.",
    );
    expect(
      validateStandardEndTime(
        standardStartTime: const TimeOfDay(hour: 18, minute: 0),
        standardEndTime: const TimeOfDay(hour: 18, minute: 30),
      ),
      isNull,
    );
  });

  test('validateEarlyArrivalTime requires an earlier time when enabled', () {
    expect(
      validateEarlyArrivalTime(
        hasEarlySlot: true,
        earlyArrivalTime: const TimeOfDay(hour: 18, minute: 0),
        standardStartTime: const TimeOfDay(hour: 18, minute: 0),
      ),
      "L'arrivée anticipée doit être avant l'heure de début de livraison.",
    );
    expect(
      validateEarlyArrivalTime(
        hasEarlySlot: true,
        earlyArrivalTime: const TimeOfDay(hour: 17, minute: 30),
        standardStartTime: const TimeOfDay(hour: 18, minute: 0),
      ),
      isNull,
    );
  });

  group('validateVolunteerArrivalTime', () {
    test(
      'returns null when volunteerArrivalTime is null (field is optional)',
      () {
        expect(
          validateVolunteerArrivalTime(
            volunteerArrivalTime: null,
            standardStartTime: const TimeOfDay(hour: 18, minute: 0),
          ),
          isNull,
        );
      },
    );

    test('returns null when arrival is before standard start', () {
      expect(
        validateVolunteerArrivalTime(
          volunteerArrivalTime: const TimeOfDay(hour: 17, minute: 30),
          standardStartTime: const TimeOfDay(hour: 18, minute: 0),
        ),
        isNull,
      );
    });

    test('returns null when arrival equals standard start', () {
      expect(
        validateVolunteerArrivalTime(
          volunteerArrivalTime: const TimeOfDay(hour: 18, minute: 0),
          standardStartTime: const TimeOfDay(hour: 18, minute: 0),
        ),
        isNull,
      );
    });

    test('returns error message when arrival is after standard start', () {
      expect(
        validateVolunteerArrivalTime(
          volunteerArrivalTime: const TimeOfDay(hour: 18, minute: 30),
          standardStartTime: const TimeOfDay(hour: 18, minute: 0),
        ),
        "L'arrivée des bénévoles doit être avant ou à l'heure de début de livraison.",
      );
    });
  });

  test('parseDeliveryTemplateTime accepts HH:mm values', () {
    final parsed = parseDeliveryTemplateTime('17:05');

    expect(parsed, const TimeOfDay(hour: 17, minute: 5));
    expect(
      formatDeliveryTemplateTime(const TimeOfDay(hour: 9, minute: 0)),
      '09:00',
    );
  });
}
