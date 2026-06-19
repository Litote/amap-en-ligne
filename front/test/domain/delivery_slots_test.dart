import 'package:amap_en_ligne/domain/model/delivery_slots.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scheduled = DateTime(2026, 7, 14, 18, 0);

  group('defaultVolunteerSlots', () {
    test('sans template : un créneau STANDARD ouvert de deux heures', () {
      final slots = defaultVolunteerSlots(
        scheduled: scheduled,
        requiredVolunteers: 3,
      );

      expect(slots, hasLength(1));
      final slot = slots.single;
      expect(slot.slotId, isNull);
      expect(slot.slotKind, SlotKind.standard);
      expect(slot.status, SlotStatus.open);
      expect(slot.startTime, '2026-07-14T18:00:00');
      expect(slot.endTime, '2026-07-14T20:00:00');
      expect(slot.requiredVolunteers, 3);
      expect(slot.currentRegistrations, 0);
      expect(slot.registrations, isEmpty);
    });

    test('avec template : fin du créneau alignée sur le template', () {
      const template = DeliveryTemplate(
        deliveryTemplateId: 'tpl-1',
        organizationId: 'org-1',
        name: 'Marché du soir',
        standardStartTime: '18:00',
        standardEndTime: '20:30',
        desiredVolunteerCount: 4,
      );

      final slots = defaultVolunteerSlots(
        scheduled: scheduled,
        requiredVolunteers: 4,
        template: template,
      );

      expect(slots, hasLength(1));
      expect(slots.single.endTime, '2026-07-14T20:30:00');
    });

    test('avec créneau anticipé : un créneau EARLY supplémentaire', () {
      const template = DeliveryTemplate(
        deliveryTemplateId: 'tpl-1',
        organizationId: 'org-1',
        name: 'Marché du soir',
        standardStartTime: '18:00',
        standardEndTime: '20:00',
        desiredVolunteerCount: 4,
        earlySlot: EarlySlot(
          arrivalTime: '17:00',
          explanation: 'Réception des légumes',
          maxVolunteers: 2,
        ),
      );

      final slots = defaultVolunteerSlots(
        scheduled: scheduled,
        requiredVolunteers: 4,
        template: template,
      );

      expect(slots, hasLength(2));
      final early = slots.last;
      expect(early.slotKind, SlotKind.early);
      expect(early.startTime, '2026-07-14T17:00:00');
      expect(early.endTime, '2026-07-14T20:00:00');
      expect(early.requiredVolunteers, 2);
      expect(early.status, SlotStatus.open);
    });

    test(
      'avec volunteerArrivalTime : le créneau STANDARD commence à l\'heure d\'arrivée',
      () {
        const template = DeliveryTemplate(
          deliveryTemplateId: 'tpl-1',
          organizationId: 'org-1',
          name: 'Marché du soir',
          standardStartTime: '18:00',
          standardEndTime: '20:00',
          volunteerArrivalTime: '17:30',
          desiredVolunteerCount: 4,
        );

        final slots = defaultVolunteerSlots(
          scheduled: scheduled,
          requiredVolunteers: 4,
          template: template,
        );

        expect(slots, hasLength(1));
        expect(slots.single.slotKind, SlotKind.standard);
        expect(slots.single.startTime, '2026-07-14T17:30:00');
        expect(slots.single.endTime, '2026-07-14T20:00:00');
      },
    );

    test('override de fin/arrivée : prioritaire sur le template', () {
      const template = DeliveryTemplate(
        deliveryTemplateId: 'tpl-1',
        organizationId: 'org-1',
        name: 'Marché du soir',
        standardStartTime: '18:00',
        standardEndTime: '20:00',
        volunteerArrivalTime: '17:30',
        desiredVolunteerCount: 4,
      );

      final slots = defaultVolunteerSlots(
        scheduled: scheduled,
        requiredVolunteers: 4,
        template: template,
        standardEndTimeOverride: '21:15',
        volunteerArrivalTimeOverride: '16:45',
      );

      expect(slots, hasLength(1));
      expect(slots.single.startTime, '2026-07-14T16:45:00');
      expect(slots.single.endTime, '2026-07-14T21:15:00');
    });

    test('override créneau anticipé sans template : crée le créneau EARLY', () {
      final slots = defaultVolunteerSlots(
        scheduled: scheduled,
        requiredVolunteers: 3,
        standardEndTimeOverride: '20:00',
        earlySlotOverride: const EarlySlot(
          arrivalTime: '16:30',
          explanation: 'Réception',
          maxVolunteers: 2,
        ),
      );

      expect(slots, hasLength(2));
      final early = slots.last;
      expect(early.slotKind, SlotKind.early);
      expect(early.startTime, '2026-07-14T16:30:00');
      expect(early.endTime, '2026-07-14T20:00:00');
      expect(early.requiredVolunteers, 2);
    });

    test('override créneau anticipé : prioritaire sur celui du template', () {
      const template = DeliveryTemplate(
        deliveryTemplateId: 'tpl-1',
        organizationId: 'org-1',
        name: 'Marché du soir',
        standardStartTime: '18:00',
        standardEndTime: '20:00',
        earlySlot: EarlySlot(
          arrivalTime: '17:00',
          explanation: 'Template',
          maxVolunteers: 2,
        ),
      );

      final slots = defaultVolunteerSlots(
        scheduled: scheduled,
        requiredVolunteers: 4,
        template: template,
        earlySlotOverride: const EarlySlot(
          arrivalTime: '16:15',
          explanation: 'Override',
          maxVolunteers: 5,
        ),
      );

      final early = slots.last;
      expect(early.startTime, '2026-07-14T16:15:00');
      expect(early.requiredVolunteers, 5);
    });

    test('heure anticipée invalide : pas de créneau EARLY', () {
      const template = DeliveryTemplate(
        deliveryTemplateId: 'tpl-1',
        organizationId: 'org-1',
        name: 'Marché du soir',
        standardStartTime: '18:00',
        standardEndTime: '20:00',
        earlySlot: EarlySlot(
          arrivalTime: 'invalid',
          explanation: 'x',
          maxVolunteers: 2,
        ),
      );

      final slots = defaultVolunteerSlots(
        scheduled: scheduled,
        requiredVolunteers: 1,
        template: template,
      );

      expect(slots, hasLength(1));
      expect(slots.single.slotKind, SlotKind.standard);
    });
  });
}
