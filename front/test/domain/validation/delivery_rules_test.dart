import 'package:amap_en_ligne/domain/validation/delivery_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const start = 18 * 60; // 18:00

  test('accepts coherent slot times', () {
    expect(
      deliverySlotTimesError(
        startMinutes: start,
        standardEndTime: '20:00',
        volunteerArrivalTime: '17:45',
        earlyArrivalTime: '17:00',
        earlyMaxVolunteers: 2,
        minVolunteers: 1,
      ),
      isNull,
    );
    expect(deliverySlotTimesError(startMinutes: start), isNull);
  });

  test('rejects incoherent slot times like the back', () {
    expect(
      deliverySlotTimesError(startMinutes: start, standardEndTime: '18:00'),
      "L'heure de fin doit être après l'heure de début de la livraison.",
    );
    expect(
      deliverySlotTimesError(
        startMinutes: start,
        volunteerArrivalTime: '18:15',
      ),
      "L'arrivée des bénévoles doit être avant ou à l'heure de début de livraison.",
    );
    expect(
      deliverySlotTimesError(startMinutes: start, earlyArrivalTime: '18:00'),
      "L'arrivée anticipée doit être avant l'heure de début de livraison.",
    );
    expect(
      deliverySlotTimesError(startMinutes: start, earlyMaxVolunteers: 0),
      'Le nombre de bénévoles du créneau anticipé doit être au moins 1.',
    );
    expect(
      deliverySlotTimesError(startMinutes: start, minVolunteers: 0),
      'Le nombre minimum de bénévoles doit être au moins 1.',
    );
  });

  group('isDeliveryClosable', () {
    final now = DateTime(2026, 10, 1, 9);

    test('allows closing on the scheduled day, even before its start', () {
      expect(isDeliveryClosable('2026-10-01T18:00:00', now: now), isTrue);
    });

    test('allows closing a past delivery', () {
      expect(isDeliveryClosable('2026-09-24T18:00:00', now: now), isTrue);
    });

    test('refuses closing before the scheduled day, like the back', () {
      expect(isDeliveryClosable('2026-10-02T08:00:00', now: now), isFalse);
    });
  });
}
