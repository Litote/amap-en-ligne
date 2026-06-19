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
    final slot = buildSlot(
      requiredVolunteers: required,
      currentRegistrations: current,
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
  });
}
