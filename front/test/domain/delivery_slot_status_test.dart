import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/organization_fixtures.dart';

void main() {
  Delivery deliveryWith({
    required DeliveryStatus status,
    required int required,
    required int current,
  }) {
    // Build actual registrations with non-coordinator member IDs so that
    // nonCoordinatorActiveRegistrations counts them correctly.
    // The default buildContract coordinator is 'member-1', so use 'volunteer-N'.
    final registrations = List.generate(
      current,
      (i) => buildRegistration(memberId: 'volunteer-${i + 1}'),
    );
    final slot = buildSlot(
      requiredVolunteers: required,
      currentRegistrations: current,
      registrations: registrations,
    );
    return buildDelivery(
      status: status,
      contracts: [
        buildContract(slots: [slot]),
      ],
    );
  }

  group('deliverySlotStatus', () {
    test('completed and cancelled deliveries are closed', () {
      expect(
        deliverySlotStatus(
          deliveryWith(
            status: DeliveryStatus.completed,
            required: 4,
            current: 1,
          ),
        ),
        SlotStatus.closed,
      );
      expect(
        deliverySlotStatus(
          deliveryWith(
            status: DeliveryStatus.cancelled,
            required: 4,
            current: 1,
          ),
        ),
        SlotStatus.closed,
      );
    });

    test('no required volunteers is open', () {
      expect(
        deliverySlotStatus(
          buildDelivery(status: DeliveryStatus.planned, contracts: const []),
        ),
        SlotStatus.open,
      );
    });

    test('fully staffed is full', () {
      expect(
        deliverySlotStatus(
          deliveryWith(
            status: DeliveryStatus.confirmed,
            required: 3,
            current: 3,
          ),
        ),
        SlotStatus.full,
      );
    });

    test('half staffed or more is open', () {
      expect(
        deliverySlotStatus(
          deliveryWith(status: DeliveryStatus.planned, required: 4, current: 2),
        ),
        SlotStatus.open,
      );
    });

    test('under half staffed is critical', () {
      expect(
        deliverySlotStatus(
          deliveryWith(status: DeliveryStatus.planned, required: 4, current: 1),
        ),
        SlotStatus.critical,
      );
    });

    test('only main contracts contribute when mainContractIds is given', () {
      // Main contract is fully staffed; the secondary contract is empty but
      // must not drag the status down to critical.
      final delivery = buildDelivery(
        status: DeliveryStatus.confirmed,
        contracts: [
          buildContract(
            contractId: 'c-veg',
            coordinators: const [],
            slots: [
              buildSlot(
                requiredVolunteers: 2,
                registrations: [
                  buildRegistration(memberId: 'volunteer-1'),
                  buildRegistration(memberId: 'volunteer-2'),
                ],
              ),
            ],
          ),
          buildContract(
            contractId: 'c-eggs',
            coordinators: const [],
            slots: [buildSlot(requiredVolunteers: 5)],
          ),
        ],
      );
      expect(
        deliverySlotStatus(delivery, mainContractIds: {'c-veg'}),
        SlotStatus.full,
      );
    });

    test('excludes coordinators of any linked contract', () {
      final delivery = buildDelivery(
        status: DeliveryStatus.confirmed,
        contracts: [
          buildContract(
            contractId: 'c-veg',
            coordinators: const [],
            slots: [
              buildSlot(
                requiredVolunteers: 2,
                registrations: [
                  buildRegistration(memberId: 'volunteer-1'),
                  // Coordinator of the secondary contract — not a volunteer.
                  buildRegistration(memberId: 'coord-eggs'),
                ],
              ),
            ],
          ),
          buildContract(
            contractId: 'c-eggs',
            coordinators: const ['coord-eggs'],
            slots: const [],
          ),
        ],
      );
      // Only 1 real volunteer for 2 needed ⇒ half staffed ⇒ open (not full).
      expect(
        deliverySlotStatus(delivery, mainContractIds: {'c-veg'}),
        SlotStatus.open,
      );
    });
  });
}
