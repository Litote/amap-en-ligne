import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/organization_member_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/organization_fixtures.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------

  final now = DateTime(2026, 5, 26, 10, 0, 0);
  final tomorrow = now.add(const Duration(days: 1));
  final inThreeDays = now.add(const Duration(days: 3));
  final yesterday = now.subtract(const Duration(days: 1));

  String isoOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T18:00:00';

  MemberRegistration activeReg(String memberId) => buildRegistration(
    memberId: memberId,
    status: RegistrationStatus.registered,
  );

  MemberRegistration cancelledReg(String memberId) => buildRegistration(
    memberId: memberId,
    status: RegistrationStatus.cancelled,
  );

  MemberRegistration completedReg(String memberId) => buildRegistration(
    memberId: memberId,
    status: RegistrationStatus.completed,
  );

  MemberSlot slotWith({
    int requiredVolunteers = 3,
    int currentRegistrations = 0,
    SlotKind slotKind = SlotKind.standard,
    List<MemberRegistration> registrations = const [],
    String startTime = '2025-06-14T18:00:00',
    String endTime = '2025-06-14T20:00:00',
  }) => buildSlot(
    requiredVolunteers: requiredVolunteers,
    currentRegistrations: currentRegistrations,
    registrations: registrations,
    startTime: startTime,
    endTime: endTime,
  ).copyWith(slotKind: slotKind);

  // ---------------------------------------------------------------------------
  // nextRegistrationFor
  // ---------------------------------------------------------------------------

  group('nextRegistrationFor', () {
    test('returns null when no deliveries', () {
      final org = buildOrg(deliveries: []);
      expect(nextRegistrationFor(org, 'member-1', now: now), isNull);
    });

    test('returns null when member is not registered anywhere', () {
      final delivery = buildDelivery(
        scheduledDate: isoOf(tomorrow),
        status: DeliveryStatus.planned,
        contracts: [
          buildContract(slots: [slotWith()]),
        ],
      );
      final org = buildOrg(deliveries: [delivery]);
      expect(nextRegistrationFor(org, 'member-1', now: now), isNull);
    });

    test('returns the upcoming delivery where member is registered', () {
      final reg = activeReg('member-1');
      final delivery = buildDelivery(
        scheduledDate: isoOf(tomorrow),
        status: DeliveryStatus.planned,
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [delivery]);
      final result = nextRegistrationFor(org, 'member-1', now: now);
      expect(result?.deliveryId, delivery.deliveryId);
    });

    test('returns the chronologically first upcoming registration', () {
      final reg = activeReg('member-1');
      final d1 = buildDelivery(
        deliveryId: 'd-1',
        scheduledDate: isoOf(inThreeDays),
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      final d2 = buildDelivery(
        deliveryId: 'd-2',
        scheduledDate: isoOf(tomorrow),
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d1, d2]);
      final result = nextRegistrationFor(org, 'member-1', now: now);
      expect(result?.deliveryId, 'd-2');
    });

    test('ignores past deliveries even when registered', () {
      final reg = activeReg('member-1');
      final delivery = buildDelivery(
        scheduledDate: isoOf(yesterday),
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [delivery]);
      expect(nextRegistrationFor(org, 'member-1', now: now), isNull);
    });

    test('ignores cancelled registrations', () {
      final reg = cancelledReg('member-1');
      final delivery = buildDelivery(
        scheduledDate: isoOf(tomorrow),
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [delivery]);
      expect(nextRegistrationFor(org, 'member-1', now: now), isNull);
    });

    test('ignores COMPLETED / CANCELLED deliveries', () {
      final reg = activeReg('member-1');
      final cancelled = buildDelivery(
        deliveryId: 'd-cancelled',
        scheduledDate: isoOf(tomorrow),
        status: DeliveryStatus.cancelled,
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      final completed = buildDelivery(
        deliveryId: 'd-completed',
        scheduledDate: isoOf(inThreeDays),
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [cancelled, completed]);
      expect(nextRegistrationFor(org, 'member-1', now: now), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // upcomingActiveDeliveries
  // ---------------------------------------------------------------------------

  group('upcomingActiveDeliveries', () {
    test('returns empty list when no deliveries', () {
      expect(upcomingActiveDeliveries(buildOrg(), now), isEmpty);
    });

    test('returns active future deliveries sorted chronologically', () {
      final d1 = buildDelivery(
        deliveryId: 'd-1',
        scheduledDate: isoOf(inThreeDays),
        contracts: [
          buildContract(slots: [slotWith()]),
        ],
      );
      final d2 = buildDelivery(
        deliveryId: 'd-2',
        scheduledDate: isoOf(tomorrow),
        contracts: [
          buildContract(slots: [slotWith()]),
        ],
      );
      final org = buildOrg(deliveries: [d1, d2]);
      final result = upcomingActiveDeliveries(org, now);
      expect(result.map((d) => d.deliveryId).toList(), ['d-2', 'd-1']);
    });

    test('excludes past deliveries', () {
      final past = buildDelivery(
        deliveryId: 'd-past',
        scheduledDate: isoOf(yesterday),
      );
      final org = buildOrg(deliveries: [past]);
      expect(upcomingActiveDeliveries(org, now), isEmpty);
    });

    test('excludes COMPLETED and CANCELLED deliveries', () {
      final cancelled = buildDelivery(
        deliveryId: 'd-cancelled',
        scheduledDate: isoOf(tomorrow),
        status: DeliveryStatus.cancelled,
      );
      final completed = buildDelivery(
        deliveryId: 'd-completed',
        scheduledDate: isoOf(inThreeDays),
        status: DeliveryStatus.completed,
      );
      final org = buildOrg(deliveries: [cancelled, completed]);
      expect(upcomingActiveDeliveries(org, now), isEmpty);
    });

    test('respects the limit parameter', () {
      final deliveries = [
        for (var i = 1; i <= 8; i++)
          buildDelivery(
            deliveryId: 'd-$i',
            scheduledDate: isoOf(now.add(Duration(days: i))),
            contracts: [
              buildContract(slots: [slotWith()]),
            ],
          ),
      ];
      final org = buildOrg(deliveries: deliveries);
      expect(upcomingActiveDeliveries(org, now, limit: 3).length, 3);
    });

    test('excludes deliveries without volunteer slots', () {
      final withSlots = buildDelivery(
        deliveryId: 'd-with-slots',
        scheduledDate: isoOf(tomorrow),
        contracts: [
          buildContract(slots: [slotWith()]),
        ],
      );
      final withoutSlots = buildDelivery(
        deliveryId: 'd-without-slots',
        scheduledDate: isoOf(inThreeDays),
        contracts: [buildContract(slots: [])],
      );
      final noContracts = buildDelivery(
        deliveryId: 'd-no-contracts',
        scheduledDate: isoOf(inThreeDays),
      );
      final org = buildOrg(deliveries: [withSlots, withoutSlots, noContracts]);
      final result = upcomingActiveDeliveries(org, now);
      expect(result.map((d) => d.deliveryId).toList(), ['d-with-slots']);
    });
  });

  // ---------------------------------------------------------------------------
  // isRegisteredOn
  // ---------------------------------------------------------------------------

  group('isRegisteredOn', () {
    test('returns false when no contracts', () {
      final delivery = buildDelivery(contracts: []);
      expect(isRegisteredOn(delivery, 'member-1'), isFalse);
    });

    test('returns true when member has an active registration', () {
      final reg = activeReg('member-1');
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      expect(isRegisteredOn(delivery, 'member-1'), isTrue);
    });

    test('returns false when only registration is cancelled', () {
      final reg = cancelledReg('member-1');
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      expect(isRegisteredOn(delivery, 'member-1'), isFalse);
    });

    test('returns false when a different member is registered', () {
      final reg = activeReg('other-member');
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      expect(isRegisteredOn(delivery, 'member-1'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // slotsByKind
  // ---------------------------------------------------------------------------

  group('slotsByKind', () {
    test('returns null for both when no slots', () {
      final contract = buildContract(slots: []);
      final result = slotsByKind(contract);
      expect(result.standard, isNull);
      expect(result.early, isNull);
    });

    test('returns standard slot only', () {
      final std = slotWith(slotKind: SlotKind.standard);
      final contract = buildContract(slots: [std]);
      final result = slotsByKind(contract);
      expect(result.standard, isNotNull);
      expect(result.early, isNull);
    });

    test('returns both standard and early slots', () {
      final std = slotWith(slotKind: SlotKind.standard);
      final early = slotWith(slotKind: SlotKind.early);
      final contract = buildContract(slots: [std, early]);
      final result = slotsByKind(contract);
      expect(result.standard, isNotNull);
      expect(result.early, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // slotCapacity
  // ---------------------------------------------------------------------------

  group('slotCapacity', () {
    test('STANDARD slot returns requiredVolunteers', () {
      final slot = slotWith(requiredVolunteers: 5, slotKind: SlotKind.standard);
      expect(slotCapacity(slot), 5);
    });

    test('EARLY slot returns its materialised requiredVolunteers', () {
      final slot = slotWith(requiredVolunteers: 2, slotKind: SlotKind.early);
      expect(slotCapacity(slot), 2);
    });

    test('slot sized for no volunteers returns 0', () {
      final slot = slotWith(requiredVolunteers: 0, slotKind: SlotKind.early);
      expect(slotCapacity(slot), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // deliveryVolunteerStaffing
  // ---------------------------------------------------------------------------

  group('deliveryVolunteerStaffing', () {
    test('sums STANDARD and EARLY required and current across contracts', () {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(
                requiredVolunteers: 3,
                currentRegistrations: 1,
                registrations: [buildRegistration(memberId: 'volunteer-1')],
                slotKind: SlotKind.standard,
              ),
              slotWith(
                requiredVolunteers: 2,
                currentRegistrations: 0,
                slotKind: SlotKind.early,
              ),
            ],
          ),
        ],
      );
      final staffing = deliveryVolunteerStaffing(delivery);
      expect(staffing.required, 5);
      expect(staffing.current, 1);
    });

    test('excludes CANCELLED slots from the totals', () {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(
                requiredVolunteers: 3,
                currentRegistrations: 2,
                registrations: [
                  buildRegistration(memberId: 'volunteer-1'),
                  buildRegistration(memberId: 'volunteer-2'),
                ],
                slotKind: SlotKind.standard,
              ),
              slotWith(
                requiredVolunteers: 4,
                currentRegistrations: 1,
                slotKind: SlotKind.early,
              ).copyWith(status: SlotStatus.cancelled),
            ],
          ),
        ],
      );
      final staffing = deliveryVolunteerStaffing(delivery);
      expect(staffing.required, 3);
      expect(staffing.current, 2);
    });

    test('returns zeros when the delivery has no slots', () {
      final delivery = buildDelivery(contracts: [buildContract(slots: [])]);
      final staffing = deliveryVolunteerStaffing(delivery);
      expect(staffing.required, 0);
      expect(staffing.current, 0);
    });

    test('counts only the main contracts when mainContractIds is given', () {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            contractId: 'c-veg',
            coordinators: const [],
            slots: [
              slotWith(
                requiredVolunteers: 3,
                registrations: [activeReg('volunteer-1')],
              ),
            ],
          ),
          buildContract(
            contractId: 'c-eggs',
            coordinators: const [],
            slots: [
              slotWith(
                requiredVolunteers: 2,
                registrations: [activeReg('volunteer-2')],
              ),
            ],
          ),
        ],
      );
      final staffing = deliveryVolunteerStaffing(
        delivery,
        mainContractIds: {'c-veg'},
      );
      expect(staffing.required, 3);
      expect(staffing.current, 1);
    });

    test('falls back to counting every contract when none is main', () {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            contractId: 'c-veg',
            coordinators: const [],
            slots: [slotWith(requiredVolunteers: 3)],
          ),
          buildContract(
            contractId: 'c-eggs',
            coordinators: const [],
            slots: [slotWith(requiredVolunteers: 2)],
          ),
        ],
      );
      // mainContractIds references a contract that is not linked here.
      final staffing = deliveryVolunteerStaffing(
        delivery,
        mainContractIds: {'c-other'},
      );
      expect(staffing.required, 5);
    });

    test('excludes coordinators of any linked contract from current', () {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            contractId: 'c-veg',
            coordinators: const [],
            slots: [
              slotWith(
                requiredVolunteers: 3,
                registrations: [
                  activeReg('volunteer-1'),
                  // Coordinator of the secondary contract, registered on the
                  // main slot: must not inflate the volunteer count.
                  activeReg('coord-eggs'),
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
      final staffing = deliveryVolunteerStaffing(
        delivery,
        mainContractIds: {'c-veg'},
      );
      expect(staffing.required, 3);
      expect(staffing.current, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // activeRegistrationsCount
  // ---------------------------------------------------------------------------

  group('activeRegistrationsCount', () {
    test('returns 0 for empty registrations', () {
      final slot = slotWith();
      expect(activeRegistrationsCount(slot), 0);
    });

    test('counts only non-CANCELLED registrations', () {
      final slot = slotWith(
        registrations: [
          activeReg('m-1'),
          cancelledReg('m-2'),
          completedReg('m-3'),
        ],
      );
      expect(activeRegistrationsCount(slot), 2);
    });

    test('returns 0 when all registrations are cancelled', () {
      final slot = slotWith(
        registrations: [cancelledReg('m-1'), cancelledReg('m-2')],
      );
      expect(activeRegistrationsCount(slot), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // activeRegistrationsExcluding
  // ---------------------------------------------------------------------------

  group('activeRegistrationsExcluding', () {
    test('returns 0 for empty registrations', () {
      final slot = slotWith();
      expect(activeRegistrationsExcluding(slot, <String>{}), 0);
    });

    test('counts non-cancelled registrations when no coordinators', () {
      final slot = slotWith(
        registrations: [
          activeReg('m-1'),
          cancelledReg('m-2'),
          completedReg('m-3'),
        ],
      );
      expect(activeRegistrationsExcluding(slot, <String>{}), 2);
    });

    test('excludes coordinators from the count', () {
      final slot = slotWith(
        registrations: [
          activeReg('m-1'),
          activeReg('m-2'),
          activeReg('coordinator-1'),
          completedReg('m-3'),
          cancelledReg('m-4'),
        ],
      );
      expect(
        activeRegistrationsExcluding(slot, {'coordinator-1'}),
        3,
      );
    });

    test('excludes multiple coordinators from the count', () {
      final slot = slotWith(
        registrations: [
          activeReg('m-1'),
          activeReg('coordinator-1'),
          activeReg('coordinator-2'),
          completedReg('m-2'),
        ],
      );
      expect(
        activeRegistrationsExcluding(
          slot,
          {'coordinator-1', 'coordinator-2'},
        ),
        2,
      );
    });

    test('ignores cancelled registrations even if not a coordinator', () {
      final slot = slotWith(
        registrations: [
          activeReg('m-1'),
          cancelledReg('m-2'),
        ],
      );
      expect(activeRegistrationsExcluding(slot, <String>{}), 1);
    });

    test(
      'excludes coordinators even if their registration is in any status',
      () {
        final slot = slotWith(
          registrations: [
            activeReg('m-1'),
            completedReg('coordinator-1'),
            activeReg('coordinator-2'),
          ],
        );
        expect(
          activeRegistrationsExcluding(
            slot,
            {'coordinator-1', 'coordinator-2'},
          ),
          1,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // slotHasCapacity
  // ---------------------------------------------------------------------------

  group('slotHasCapacity', () {
    test('STANDARD slot has capacity when not full', () {
      final slot = slotWith(
        requiredVolunteers: 3,
        registrations: [activeReg('m-1')],
        slotKind: SlotKind.standard,
      );
      expect(slotHasCapacity(slot), isTrue);
    });

    test('STANDARD slot has no capacity when full', () {
      final slot = slotWith(
        requiredVolunteers: 2,
        registrations: [activeReg('m-1'), activeReg('m-2')],
        slotKind: SlotKind.standard,
      );
      expect(slotHasCapacity(slot), isFalse);
    });

    test('slot sized for no volunteers has no capacity', () {
      final slot = slotWith(slotKind: SlotKind.early, requiredVolunteers: 0);
      expect(slotHasCapacity(slot), isFalse);
    });

    test('CANCELLED slot never has capacity even when empty', () {
      final slot = slotWith(
        requiredVolunteers: 3,
        slotKind: SlotKind.standard,
      ).copyWith(status: SlotStatus.cancelled);
      expect(slotHasCapacity(slot), isFalse);
    });

    test('EARLY slot with remaining capacity returns true', () {
      final slot = slotWith(
        slotKind: SlotKind.early,
        requiredVolunteers: 3,
        registrations: [activeReg('m-1')],
      );
      expect(slotHasCapacity(slot), isTrue);
    });

    test('EARLY slot at full capacity returns false', () {
      final slot = slotWith(
        slotKind: SlotKind.early,
        requiredVolunteers: 2,
        registrations: [activeReg('m-1'), activeReg('m-2')],
      );
      expect(slotHasCapacity(slot), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // currentSeasonYear
  // ---------------------------------------------------------------------------

  group('currentSeasonYear', () {
    Contract activeContract(int seasonYear) => Contract(
      contractId: 'c-$seasonYear',
      name: 'Contrat $seasonYear',
      organizationId: 'org-1',
      producerAccountId: 'producer-1',
      minDeliveryDate: '$seasonYear-01-01',
      maxDeliveryDate: '$seasonYear-12-31',
      deliveryCount: 10,
      seasonYear: seasonYear,
      status: ContractStatus.active,
    );

    Contract inactiveContract(int seasonYear) => Contract(
      contractId: 'c-inactive-$seasonYear',
      name: 'Contrat inactif $seasonYear',
      organizationId: 'org-1',
      producerAccountId: 'producer-1',
      minDeliveryDate: '$seasonYear-01-01',
      maxDeliveryDate: '$seasonYear-12-31',
      deliveryCount: 10,
      seasonYear: seasonYear,
      status: ContractStatus.inPreparation,
    );

    final now2026 = DateTime(2026, 6, 1);

    test('returns now.year when no contracts', () {
      expect(currentSeasonYear([], now2026), 2026);
    });

    test('returns now.year when no ACTIVE contracts', () {
      expect(currentSeasonYear([inactiveContract(2025)], now2026), 2026);
    });

    test('returns highest active seasonYear', () {
      expect(
        currentSeasonYear([
          activeContract(2025),
          activeContract(2026),
        ], now2026),
        2026,
      );
    });

    test('switches season when a N+1 contract becomes ACTIVE', () {
      // Simulates the moment a 2027 contract is activated while in 2026.
      expect(
        currentSeasonYear([
          activeContract(2026),
          activeContract(2027),
        ], now2026),
        2027,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // seasonContractIds
  // ---------------------------------------------------------------------------

  group('seasonContractIds', () {
    Contract contractForYear(String id, int year) => Contract(
      contractId: id,
      name: 'Contrat $id',
      organizationId: 'org-1',
      producerAccountId: 'producer-1',
      minDeliveryDate: '$year-01-01',
      maxDeliveryDate: '$year-12-31',
      deliveryCount: 10,
      seasonYear: year,
      status: ContractStatus.active,
    );

    test('returns empty set when no contracts', () {
      expect(seasonContractIds([], 2026), isEmpty);
    });

    test('returns ids only for contracts matching seasonYear', () {
      final c2026a = contractForYear('c-2026-a', 2026);
      final c2026b = contractForYear('c-2026-b', 2026);
      final c2025 = contractForYear('c-2025', 2025);
      final result = seasonContractIds([c2026a, c2026b, c2025], 2026);
      expect(result, containsAll(['c-2026-a', 'c-2026-b']));
      expect(result, isNot(contains('c-2025')));
      expect(result.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // completedRegistrationsInSeason
  // ---------------------------------------------------------------------------

  group('completedRegistrationsInSeason', () {
    test('returns 0 when no completed registrations', () {
      final org = buildOrg(deliveries: []);
      expect(completedRegistrationsInSeason(org, 'member-1', {'c-1'}), 0);
    });

    test('returns 0 when seasonContractIds is empty', () {
      final d = buildDelivery(
        scheduledDate: '2026-03-15T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(registrations: [completedReg('member-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      expect(completedRegistrationsInSeason(org, 'member-1', {}), 0);
    });

    test('counts only contracts in seasonContractIds, excludes others', () {
      final inSeason = buildDelivery(
        deliveryId: 'd-in',
        scheduledDate: '2026-03-15T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: 'c-season',
            slots: [
              slotWith(registrations: [completedReg('member-1')]),
            ],
          ),
        ],
      );
      final outOfSeason = buildDelivery(
        deliveryId: 'd-out',
        scheduledDate: '2025-12-20T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: 'c-old',
            slots: [
              slotWith(registrations: [completedReg('member-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [inSeason, outOfSeason]);
      expect(completedRegistrationsInSeason(org, 'member-1', {'c-season'}), 1);
    });
  });

  // ---------------------------------------------------------------------------
  // lastCompletedDelivery
  // ---------------------------------------------------------------------------

  group('lastCompletedDelivery', () {
    test('returns null when no completed registrations', () {
      final org = buildOrg();
      expect(lastCompletedDelivery(org, 'member-1'), isNull);
    });

    test('returns the most recent completed delivery', () {
      final older = buildDelivery(
        deliveryId: 'd-older',
        scheduledDate: '2026-01-10T18:00:00',
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [completedReg('member-1')]),
            ],
          ),
        ],
      );
      final newer = buildDelivery(
        deliveryId: 'd-newer',
        scheduledDate: '2026-02-20T18:00:00',
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [completedReg('member-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [older, newer]);
      expect(lastCompletedDelivery(org, 'member-1')?.deliveryId, 'd-newer');
    });

    test('ignores non-completed registrations', () {
      final delivery = buildDelivery(
        deliveryId: 'd-1',
        scheduledDate: '2026-01-10T18:00:00',
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [activeReg('member-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [delivery]);
      expect(lastCompletedDelivery(org, 'member-1'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // findAvailableSlot
  // ---------------------------------------------------------------------------

  group('findAvailableSlot', () {
    test('skips CANCELLED slots even when otherwise empty', () {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(
                requiredVolunteers: 3,
                slotKind: SlotKind.standard,
              ).copyWith(status: SlotStatus.cancelled),
            ],
          ),
        ],
      );
      final result = findAvailableSlot(delivery, SlotKind.standard);
      expect(result, isNull);
    });

    test('returns null when no slots of the requested kind', () {
      final delivery = buildDelivery(
        contracts: [
          buildContract(slots: [slotWith(slotKind: SlotKind.early)]),
        ],
      );
      final result = findAvailableSlot(delivery, SlotKind.standard);
      expect(result, isNull);
    });

    test('returns contractId and slotKind when capacity available', () {
      final delivery = buildDelivery(
        deliveryId: 'd-1',
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(requiredVolunteers: 3, slotKind: SlotKind.standard),
            ],
          ),
        ],
      );
      final result = findAvailableSlot(delivery, SlotKind.standard);
      expect(result?.contractId, 'c-1');
      expect(result?.slotKind, SlotKind.standard);
    });

    test('returns null when STANDARD slot is full', () {
      final delivery = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(
                requiredVolunteers: 1,
                registrations: [activeReg('m-1')],
                slotKind: SlotKind.standard,
              ),
            ],
          ),
        ],
      );
      final result = findAvailableSlot(delivery, SlotKind.standard);
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // personalRegistrations
  // ---------------------------------------------------------------------------

  group('personalRegistrations', () {
    test('returns empty when no deliveries', () {
      expect(personalRegistrations(buildOrg(), 'member-1'), isEmpty);
    });

    test('returns registrations for memberId only', () {
      final d = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(
                registrations: [activeReg('member-1'), activeReg('member-2')],
              ),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      final result = personalRegistrations(org, 'member-1');
      expect(result.length, 1);
      expect(result.first.registration.memberId, 'member-1');
    });
  });

  // ---------------------------------------------------------------------------
  // personalCompletedRegistrations
  // ---------------------------------------------------------------------------

  group('personalCompletedRegistrations', () {
    test('returns empty when no completed registrations', () {
      final d = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [activeReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      expect(personalCompletedRegistrations(org, 'm-1'), isEmpty);
    });

    test('returns only completed registrations, desc chronological order', () {
      final older = buildDelivery(
        deliveryId: 'd-older',
        scheduledDate: '2026-01-10T18:00:00',
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final newer = buildDelivery(
        deliveryId: 'd-newer',
        scheduledDate: '2026-02-20T18:00:00',
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [older, newer]);
      final result = personalCompletedRegistrations(org, 'm-1');
      expect(result.length, 2);
      // Most recent first.
      expect(result.first.delivery.deliveryId, 'd-newer');
      expect(result.last.delivery.deliveryId, 'd-older');
    });
  });

  // ---------------------------------------------------------------------------
  // personalUpcomingRegistrations
  // ---------------------------------------------------------------------------

  group('personalUpcomingRegistrations', () {
    test('returns empty when no upcoming registrations', () {
      final org = buildOrg();
      expect(personalUpcomingRegistrations(org, 'm-1', now), isEmpty);
    });

    test('returns future active deliveries where member is registered', () {
      final reg = activeReg('m-1');
      final d = buildDelivery(
        scheduledDate: isoOf(tomorrow),
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      final result = personalUpcomingRegistrations(org, 'm-1', now);
      expect(result.length, 1);
    });

    test('excludes cancelled registrations', () {
      final reg = cancelledReg('m-1');
      final d = buildDelivery(
        scheduledDate: isoOf(tomorrow),
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      expect(personalUpcomingRegistrations(org, 'm-1', now), isEmpty);
    });

    test('excludes past deliveries', () {
      final reg = activeReg('m-1');
      final d = buildDelivery(
        scheduledDate: isoOf(yesterday),
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [reg]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      expect(personalUpcomingRegistrations(org, 'm-1', now), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // teammatesOn
  // ---------------------------------------------------------------------------

  group('teammatesOn', () {
    test('returns empty when no other registrations', () {
      final d = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(registrations: [activeReg('self')]),
            ],
          ),
        ],
      );
      expect(teammatesOn(d, 'self'), isEmpty);
    });

    test('excludes self and cancelled registrations', () {
      final d = buildDelivery(
        contracts: [
          buildContract(
            slots: [
              slotWith(
                registrations: [
                  activeReg('self'),
                  activeReg('m-2'),
                  cancelledReg('m-3'),
                ],
              ),
            ],
          ),
        ],
      );
      final result = teammatesOn(d, 'self');
      expect(result.length, 1);
      expect(result.first.memberId, 'm-2');
    });

    test('deduplicates same member appearing in multiple slots', () {
      final d = buildDelivery(
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(
                slotKind: SlotKind.standard,
                registrations: [activeReg('m-2')],
              ),
              slotWith(
                slotKind: SlotKind.early,
                registrations: [activeReg('m-2')],
              ),
            ],
          ),
        ],
      );
      final result = teammatesOn(d, 'self');
      expect(result.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // seasonRegistrationsCount
  // ---------------------------------------------------------------------------

  group('seasonRegistrationsCount', () {
    test('returns 0 when seasonContractIds is empty', () {
      final org = buildOrg();
      expect(seasonRegistrationsCount(org, 'm-1', {}), 0);
    });

    test('counts upcoming (registered) registrations', () {
      final d = buildDelivery(
        deliveryId: 'd-upcoming',
        scheduledDate: '2026-12-10T18:00:00',
        status: DeliveryStatus.planned,
        contracts: [
          buildContract(
            contractId: 'c-season',
            slots: [
              slotWith(registrations: [activeReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      expect(seasonRegistrationsCount(org, 'm-1', {'c-season'}), 1);
    });

    test('counts completed registrations', () {
      final d = buildDelivery(
        deliveryId: 'd-done',
        scheduledDate: '2026-06-10T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: 'c-season',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      expect(seasonRegistrationsCount(org, 'm-1', {'c-season'}), 1);
    });

    test('excludes cancelled registrations', () {
      final d = buildDelivery(
        deliveryId: 'd-cancelled',
        scheduledDate: '2026-07-10T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: 'c-season',
            slots: [
              slotWith(registrations: [cancelledReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      expect(seasonRegistrationsCount(org, 'm-1', {'c-season'}), 0);
    });

    test('excludes registrations on out-of-season contracts', () {
      final inSeason = buildDelivery(
        deliveryId: 'd-in',
        scheduledDate: '2026-06-10T18:00:00',
        contracts: [
          buildContract(
            contractId: 'c-season',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final outSeason = buildDelivery(
        deliveryId: 'd-out',
        scheduledDate: '2025-12-10T18:00:00',
        contracts: [
          buildContract(
            contractId: 'c-old',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [inSeason, outSeason]);
      expect(seasonRegistrationsCount(org, 'm-1', {'c-season'}), 1);
    });

    test('counts both upcoming and completed, excludes cancelled', () {
      // 1 completed + 2 active/upcoming + 1 cancelled = 3
      final d1 = buildDelivery(
        deliveryId: 'd-completed',
        scheduledDate: '2026-06-10T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: 'c-season',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final d2 = buildDelivery(
        deliveryId: 'd-future-1',
        scheduledDate: '2026-12-01T18:00:00',
        status: DeliveryStatus.planned,
        contracts: [
          buildContract(
            contractId: 'c-season',
            slots: [
              slotWith(registrations: [activeReg('m-1')]),
            ],
          ),
        ],
      );
      final d3 = buildDelivery(
        deliveryId: 'd-future-2',
        scheduledDate: '2026-12-08T18:00:00',
        status: DeliveryStatus.planned,
        contracts: [
          buildContract(
            contractId: 'c-season',
            slots: [
              slotWith(registrations: [activeReg('m-1')]),
            ],
          ),
        ],
      );
      final d4 = buildDelivery(
        deliveryId: 'd-cancelled-reg',
        scheduledDate: '2026-11-10T18:00:00',
        status: DeliveryStatus.planned,
        contracts: [
          buildContract(
            contractId: 'c-season',
            slots: [
              slotWith(registrations: [cancelledReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d1, d2, d3, d4]);
      expect(seasonRegistrationsCount(org, 'm-1', {'c-season'}), 3);
    });
  });

  // ---------------------------------------------------------------------------
  // seasonLabel
  // ---------------------------------------------------------------------------

  group('seasonLabel', () {
    final now = DateTime(2026, 6, 14);

    Contract makeContract({
      required String id,
      required int seasonYear,
      required String minDate,
      required String maxDate,
    }) => Contract(
      contractId: id,
      name: 'Contrat $id',
      organizationId: 'org-1',
      producerAccountId: 'producer-1',
      minDeliveryDate: minDate,
      maxDeliveryDate: maxDate,
      deliveryCount: 10,
      seasonYear: seasonYear,
    );

    test('fallback to now.year when no contracts', () {
      expect(seasonLabel([], 2026, now), 'Saison 2026');
    });

    test('fallback to now.year when no contracts for the given seasonYear', () {
      final contract = makeContract(
        id: 'c-1',
        seasonYear: 2025,
        minDate: '2025-06-01',
        maxDate: '2025-12-31',
      );
      expect(seasonLabel([contract], 2026, now), 'Saison 2026');
    });

    test('single year range returns "Saison <year>"', () {
      final contract = makeContract(
        id: 'c-1',
        seasonYear: 2026,
        minDate: '2026-04-01',
        maxDate: '2026-12-31',
      );
      expect(seasonLabel([contract], 2026, now), 'Saison 2026');
    });

    test('cross-year range returns "Saison <startYear>-<endYear>"', () {
      final contract = makeContract(
        id: 'c-1',
        seasonYear: 2026,
        minDate: '2026-06-01',
        maxDate: '2027-03-31',
      );
      expect(seasonLabel([contract], 2026, now), 'Saison 2026-2027');
    });

    test('multiple contracts: uses earliest min and latest max', () {
      final c1 = makeContract(
        id: 'c-1',
        seasonYear: 2026,
        minDate: '2026-06-01',
        maxDate: '2026-12-31',
      );
      final c2 = makeContract(
        id: 'c-2',
        seasonYear: 2026,
        minDate: '2026-09-01',
        maxDate: '2027-03-31',
      );
      expect(seasonLabel([c1, c2], 2026, now), 'Saison 2026-2027');
    });

    test('ignores contracts from other seasons', () {
      final c2025 = makeContract(
        id: 'c-2025',
        seasonYear: 2025,
        minDate: '2025-01-01',
        maxDate: '2025-12-31',
      );
      final c2026 = makeContract(
        id: 'c-2026',
        seasonYear: 2026,
        minDate: '2026-06-01',
        maxDate: '2027-03-31',
      );
      expect(seasonLabel([c2025, c2026], 2026, now), 'Saison 2026-2027');
    });
  });

  // ---------------------------------------------------------------------------
  // seasonMonthlyParticipationCounts
  // ---------------------------------------------------------------------------

  group('seasonMonthlyParticipationCounts', () {
    final now2026 = DateTime(2026, 6, 14);

    Contract makeSeasonContract({
      required String id,
      required int seasonYear,
      required String minDate,
      required String maxDate,
    }) => Contract(
      contractId: id,
      name: 'Contrat $id',
      organizationId: 'org-1',
      producerAccountId: 'producer-1',
      minDeliveryDate: minDate,
      maxDeliveryDate: maxDate,
      deliveryCount: 10,
      seasonYear: seasonYear,
    );

    test('returns empty list when seasonContractIds is empty', () {
      final org = buildOrg();
      expect(seasonMonthlyParticipationCounts(org, 'm-1', [], {}), isEmpty);
    });

    test('returns empty list when no contracts match the season ids', () {
      final contract = makeSeasonContract(
        id: 'c-1',
        seasonYear: 2026,
        minDate: '2026-06-01',
        maxDate: '2026-12-31',
      );
      final org = buildOrg();
      // Pass a different id in the set.
      expect(
        seasonMonthlyParticipationCounts(org, 'm-1', [contract], {'c-other'}),
        isEmpty,
      );
    });

    test(
      'single-year season: full range enumerated in order, zeros included',
      () {
        final contract = makeSeasonContract(
          id: 'c-1',
          seasonYear: 2026,
          minDate: '2026-06-01',
          maxDate: '2026-08-31',
        );
        final org = buildOrg(); // no completed deliveries
        final result = seasonMonthlyParticipationCounts(
          org,
          'm-1',
          [contract],
          {'c-1'},
        );
        expect(result.length, 3); // June, July, August
        expect(result[0], (year: 2026, month: 6, count: 0));
        expect(result[1], (year: 2026, month: 7, count: 0));
        expect(result[2], (year: 2026, month: 8, count: 0));
      },
    );

    test('cross-year season: correct months in chronological order', () {
      final contract = makeSeasonContract(
        id: 'c-1',
        seasonYear: 2026,
        minDate: '2026-11-01',
        maxDate: '2027-02-28',
      );
      final org = buildOrg();
      final result = seasonMonthlyParticipationCounts(
        org,
        'm-1',
        [contract],
        {'c-1'},
      );
      // Nov 2026, Dec 2026, Jan 2027, Feb 2027.
      expect(result.length, 4);
      expect(result[0], (year: 2026, month: 11, count: 0));
      expect(result[1], (year: 2026, month: 12, count: 0));
      expect(result[2], (year: 2027, month: 1, count: 0));
      expect(result[3], (year: 2027, month: 2, count: 0));
    });

    test('example from spec: June 2026 → March 2027 yields 10 months', () {
      final contract = makeSeasonContract(
        id: 'c-spec',
        seasonYear: 2026,
        minDate: '2026-06-01',
        maxDate: '2027-03-31',
      );
      final org = buildOrg();
      final result = seasonMonthlyParticipationCounts(
        org,
        'm-1',
        [contract],
        {'c-spec'},
      );
      expect(result.length, 10);
      expect(result.first, (year: 2026, month: 6, count: 0));
      expect(result.last, (year: 2027, month: 3, count: 0));
    });

    test('counts only COMPLETED registrations, not active/cancelled', () {
      final contract = makeSeasonContract(
        id: 'c-1',
        seasonYear: 2026,
        minDate: '2026-06-01',
        maxDate: '2026-08-31',
      );
      final julyCompleted = buildDelivery(
        deliveryId: 'd-completed',
        scheduledDate: '2026-07-15T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final julyActive = buildDelivery(
        deliveryId: 'd-active',
        scheduledDate: '2026-07-22T18:00:00',
        status: DeliveryStatus.planned,
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(registrations: [activeReg('m-1')]),
            ],
          ),
        ],
      );
      final augCancelled = buildDelivery(
        deliveryId: 'd-cancelled',
        scheduledDate: '2026-08-05T18:00:00',
        status: DeliveryStatus.planned,
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(registrations: [cancelledReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(
        deliveries: [julyCompleted, julyActive, augCancelled],
      );
      final result = seasonMonthlyParticipationCounts(
        org,
        'm-1',
        [contract],
        {'c-1'},
      );
      expect(result.length, 3);
      expect(result[0], (year: 2026, month: 6, count: 0)); // June: nothing
      expect(result[1], (year: 2026, month: 7, count: 1)); // July: 1 completed
      expect(result[2], (
        year: 2026,
        month: 8,
        count: 0,
      )); // Aug: cancelled only
    });

    test('excludes deliveries linked to out-of-season contracts', () {
      final contract = makeSeasonContract(
        id: 'c-season',
        seasonYear: 2026,
        minDate: '2026-06-01',
        maxDate: '2026-07-31',
      );
      final inSeason = buildDelivery(
        deliveryId: 'd-in',
        scheduledDate: '2026-06-15T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: 'c-season',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final outSeason = buildDelivery(
        deliveryId: 'd-out',
        scheduledDate: '2026-06-20T18:00:00',
        status: DeliveryStatus.completed,
        contracts: [
          buildContract(
            contractId: 'c-old',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [inSeason, outSeason]);
      final result = seasonMonthlyParticipationCounts(
        org,
        'm-1',
        [contract],
        {'c-season'},
      );
      expect(result.length, 2);
      expect(result[0], (year: 2026, month: 6, count: 1));
      expect(result[1], (year: 2026, month: 7, count: 0));
    });

    test('multiple contracts define the outer range', () {
      final c1 = makeSeasonContract(
        id: 'c-1',
        seasonYear: 2026,
        minDate: '2026-06-01',
        maxDate: '2026-09-30',
      );
      final c2 = makeSeasonContract(
        id: 'c-2',
        seasonYear: 2026,
        minDate: '2026-08-01',
        maxDate: '2026-11-30',
      );
      final org = buildOrg();
      final result = seasonMonthlyParticipationCounts(
        org,
        'm-1',
        [c1, c2],
        {'c-1', 'c-2'},
      );
      // June through November = 6 months.
      expect(result.length, 6);
      expect(result.first, (year: 2026, month: 6, count: 0));
      expect(result.last, (year: 2026, month: 11, count: 0));
    });

    test('ignores now parameter — all tests pass regardless of "today"', () {
      // This selector has no `now` param; the range is contract-driven.
      final contract = makeSeasonContract(
        id: 'c-1',
        seasonYear: 2026,
        minDate: '2026-06-01',
        maxDate: '2026-06-30',
      );
      final org = buildOrg();
      final result = seasonMonthlyParticipationCounts(
        org,
        'm-1',
        [contract],
        {'c-1'},
      );
      expect(result.length, 1);
      expect(result.first, (year: 2026, month: 6, count: 0));
    });

    // Unused by test — suppress the warning.
    test('now2026 fixture defined', () => expect(now2026.year, 2026));
  });

  // ---------------------------------------------------------------------------
  // memberRankIn — standard ranking with ex-aequo
  // ---------------------------------------------------------------------------

  group('memberRankIn', () {
    Member buildActiveMember(String id) => Member(
      memberId: id,
      organizationId: 'org-1',
      accountStatus: MemberAccountStatus.active,
      roles: const {Role.volunteer},
    );

    test('returns null when member not in activeMembers', () {
      final org = buildOrg();
      final result = memberRankIn(org, [], 'nobody', {'c-1'});
      expect(result, isNull);
    });

    test('returns rank 1 for member with most participations', () {
      final d1 = buildDelivery(
        deliveryId: 'd-1',
        scheduledDate: '2026-01-10T18:00:00',
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(
                registrations: [completedReg('m-1'), completedReg('m-2')],
              ),
            ],
          ),
        ],
      );
      final d2 = buildDelivery(
        deliveryId: 'd-2',
        scheduledDate: '2026-02-10T18:00:00',
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      // m-1 has 2 completions, m-2 has 1 — m-1 is rank 1, not tied.
      final org = buildOrg(deliveries: [d1, d2]);
      final m1 = buildActiveMember('m-1');
      final m2 = buildActiveMember('m-2');
      final result = memberRankIn(org, [m1, m2], 'm-1', {'c-1'});
      expect(result?.rank, 1);
      expect(result?.total, 2);
      expect(result?.tied, isFalse);
    });

    test('everyone-at-zero → rank 1, tied=true for all', () {
      // Standard ranking: when everyone has 0 participations, everyone is rank 1.
      final m1 = buildActiveMember('m-a');
      final m2 = buildActiveMember('m-b');
      final m3 = buildActiveMember('m-c');
      final org = buildOrg(deliveries: []);

      final resultA = memberRankIn(org, [m1, m2, m3], 'm-a', {'c-1'});
      final resultB = memberRankIn(org, [m1, m2, m3], 'm-b', {'c-1'});
      final resultC = memberRankIn(org, [m1, m2, m3], 'm-c', {'c-1'});

      expect(resultA?.rank, 1);
      expect(resultA?.tied, isTrue);
      expect(resultB?.rank, 1);
      expect(resultB?.tied, isTrue);
      expect(resultC?.rank, 1);
      expect(resultC?.tied, isTrue);
    });

    test('partial ties: members with same count share rank, untied leader', () {
      // m-1 has 3 completions, m-2 and m-3 each have 1 → standard ranks: 1, 2, 2.
      final d1 = buildDelivery(
        deliveryId: 'd-1',
        scheduledDate: '2026-01-10T18:00:00',
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(
                registrations: [
                  completedReg('m-1'),
                  completedReg('m-2'),
                  completedReg('m-3'),
                ],
              ),
            ],
          ),
        ],
      );
      final d2 = buildDelivery(
        deliveryId: 'd-2',
        scheduledDate: '2026-02-10T18:00:00',
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final d3 = buildDelivery(
        deliveryId: 'd-3',
        scheduledDate: '2026-03-10T18:00:00',
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d1, d2, d3]);
      final m1 = buildActiveMember('m-1');
      final m2 = buildActiveMember('m-2');
      final m3 = buildActiveMember('m-3');

      final r1 = memberRankIn(org, [m1, m2, m3], 'm-1', {'c-1'});
      final r2 = memberRankIn(org, [m1, m2, m3], 'm-2', {'c-1'});
      final r3 = memberRankIn(org, [m1, m2, m3], 'm-3', {'c-1'});

      // m-1 is rank 1 alone (no one else has 3).
      expect(r1?.rank, 1);
      expect(r1?.tied, isFalse);
      // m-2 and m-3 both have 1 → standard rank 2, tied.
      expect(r2?.rank, 2);
      expect(r2?.tied, isTrue);
      expect(r3?.rank, 2);
      expect(r3?.tied, isTrue);
    });

    test('excludes members not in activeMembers from denominator', () {
      final d = buildDelivery(
        scheduledDate: '2026-01-10T18:00:00',
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(
                registrations: [completedReg('m-1'), completedReg('suspended')],
              ),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      // Only m-1 is in activeMembers — total is 1.
      final m1 = buildActiveMember('m-1');
      final result = memberRankIn(org, [m1], 'm-1', {'c-1'});
      expect(result?.rank, 1);
      expect(result?.total, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // memberActivityStatus
  // ---------------------------------------------------------------------------

  group('memberActivityStatus', () {
    test('inactive when 0 completions in season', () {
      final org = buildOrg();
      expect(
        memberActivityStatus(org, 'm-1', {'c-1'}),
        MemberActivityStatus.inactive,
      );
    });

    test('occasional when 1 completion in season', () {
      final d = buildDelivery(
        scheduledDate: '2026-03-10T18:00:00',
        contracts: [
          buildContract(
            contractId: 'c-1',
            slots: [
              slotWith(registrations: [completedReg('m-1')]),
            ],
          ),
        ],
      );
      final org = buildOrg(deliveries: [d]);
      expect(
        memberActivityStatus(org, 'm-1', {'c-1'}),
        MemberActivityStatus.occasional,
      );
    });

    test('occasional when 4 completions in season', () {
      final deliveries = [
        for (var i = 1; i <= 4; i++)
          buildDelivery(
            deliveryId: 'd-$i',
            scheduledDate: '2026-0$i-10T18:00:00',
            contracts: [
              buildContract(
                contractId: 'c-1',
                slots: [
                  slotWith(registrations: [completedReg('m-1')]),
                ],
              ),
            ],
          ),
      ];
      final org = buildOrg(deliveries: deliveries);
      expect(
        memberActivityStatus(org, 'm-1', {'c-1'}),
        MemberActivityStatus.occasional,
      );
    });

    test('active when 5 or more completions in season', () {
      final deliveries = [
        for (var i = 1; i <= 5; i++)
          buildDelivery(
            deliveryId: 'd-$i',
            scheduledDate: '2026-0$i-10T18:00:00',
            contracts: [
              buildContract(
                contractId: 'c-1',
                slots: [
                  slotWith(registrations: [completedReg('m-1')]),
                ],
              ),
            ],
          ),
      ];
      final org = buildOrg(deliveries: deliveries);
      expect(
        memberActivityStatus(org, 'm-1', {'c-1'}),
        MemberActivityStatus.active,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // participationDistribution
  // ---------------------------------------------------------------------------

  group('participationDistribution', () {
    Member buildActiveMember(String id) => Member(
      memberId: id,
      organizationId: 'org-1',
      accountStatus: MemberAccountStatus.active,
      roles: const {Role.volunteer},
    );

    test('returns zeros when no members', () {
      final result = participationDistribution(buildOrg(), [], {'c-1'});
      expect(result.active, 0);
      expect(result.occasional, 0);
      expect(result.inactive, 0);
    });

    test('correctly distributes 2 active, 3 occasional, 2 inactive', () {
      // Build deliveries: 2 members with ≥5, 3 with 1-4, 2 with 0.
      // m-a and m-b get 5 completions each (active).
      // m-c, m-d, m-e get 1 completion each (occasional).
      // m-f and m-g get 0 (inactive).
      final deliveries = <Delivery>[];
      for (var i = 1; i <= 5; i++) {
        deliveries.add(
          buildDelivery(
            deliveryId: 'da-$i',
            scheduledDate: '2026-0$i-10T18:00:00',
            contracts: [
              buildContract(
                contractId: 'c-1',
                slots: [
                  slotWith(registrations: [completedReg('m-a')]),
                ],
              ),
            ],
          ),
        );
        deliveries.add(
          buildDelivery(
            deliveryId: 'db-$i',
            scheduledDate: '2026-0$i-11T18:00:00',
            contracts: [
              buildContract(
                contractId: 'c-1',
                slots: [
                  slotWith(registrations: [completedReg('m-b')]),
                ],
              ),
            ],
          ),
        );
      }
      deliveries.add(
        buildDelivery(
          deliveryId: 'dc-1',
          scheduledDate: '2026-01-12T18:00:00',
          contracts: [
            buildContract(
              contractId: 'c-1',
              slots: [
                slotWith(
                  registrations: [
                    completedReg('m-c'),
                    completedReg('m-d'),
                    completedReg('m-e'),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final org = buildOrg(deliveries: deliveries);
      final members = [
        buildActiveMember('m-a'),
        buildActiveMember('m-b'),
        buildActiveMember('m-c'),
        buildActiveMember('m-d'),
        buildActiveMember('m-e'),
        buildActiveMember('m-f'),
        buildActiveMember('m-g'),
      ];

      final result = participationDistribution(org, members, {'c-1'});
      expect(result.active, 2);
      expect(result.occasional, 3);
      expect(result.inactive, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Coordinator selectors
  // ---------------------------------------------------------------------------

  group('Coordinator selectors', () {
    final alice = const Member(
      memberId: 'm-1',
      organizationId: 'org-1',
      firstName: 'Alice',
      lastName: 'Dupont',
    );
    final bob = const Member(
      memberId: 'm-2',
      organizationId: 'org-1',
      firstName: 'Bob',
      lastName: 'Martin',
    );
    final carol = const Member(
      memberId: 'm-3',
      organizationId: 'org-1',
      firstName: 'Carol',
      lastName: 'Petit',
    );
    final allMembers = [alice, bob, carol];

    // --- coordinatorsForContract ---

    group('coordinatorsForContract', () {
      test('returns empty list when contract has no coordinators', () {
        final contract = buildContract(coordinators: const []);
        expect(coordinatorsForContract(contract, allMembers), isEmpty);
      });

      test('returns members in contract.coordinators order', () {
        final contract = buildContract(coordinators: const ['m-2', 'm-1']);
        final result = coordinatorsForContract(contract, allMembers);
        expect(result.map((m) => m.memberId).toList(), ['m-2', 'm-1']);
      });

      test('filters out ids not present in members list', () {
        final contract = buildContract(
          coordinators: const ['m-1', 'unknown-id', 'm-3'],
        );
        final result = coordinatorsForContract(contract, allMembers);
        expect(result.map((m) => m.memberId).toList(), ['m-1', 'm-3']);
      });

      test('returns all matching members when all ids are found', () {
        final contract = buildContract(coordinators: const ['m-1', 'm-2']);
        final result = coordinatorsForContract(contract, allMembers);
        expect(result, hasLength(2));
      });
    });

    // --- coordinatorsFor ---

    group('coordinatorsFor', () {
      test('returns empty when no delivery contracts', () {
        final delivery = buildDelivery(contracts: const []);
        expect(coordinatorsFor(delivery, allMembers), isEmpty);
      });

      test('returns deduplicated union across multiple contracts', () {
        final delivery = buildDelivery(
          contracts: [
            buildContract(
              contractId: 'c-1',
              coordinators: const ['m-1', 'm-2'],
            ),
            buildContract(
              contractId: 'c-2',
              coordinators: const ['m-2', 'm-3'],
            ),
          ],
        );
        final result = coordinatorsFor(delivery, allMembers);
        // m-2 appears in both contracts — deduped, first-appearance order.
        expect(result.map((m) => m.memberId).toList(), ['m-1', 'm-2', 'm-3']);
      });

      test('stable order: first appearance wins across contracts', () {
        final delivery = buildDelivery(
          contracts: [
            buildContract(contractId: 'c-1', coordinators: const ['m-3']),
            buildContract(
              contractId: 'c-2',
              coordinators: const ['m-1', 'm-3'],
            ),
          ],
        );
        final result = coordinatorsFor(delivery, allMembers);
        expect(result.map((m) => m.memberId).toList(), ['m-3', 'm-1']);
      });
    });

    // --- isCoordinatorOf ---

    group('isCoordinatorOf', () {
      test('returns true when memberId is in coordinators', () {
        final contract = buildContract(coordinators: const ['m-1', 'm-2']);
        expect(isCoordinatorOf(contract, 'm-1'), isTrue);
      });

      test('returns false when memberId is not in coordinators', () {
        final contract = buildContract(coordinators: const ['m-2']);
        expect(isCoordinatorOf(contract, 'm-1'), isFalse);
      });

      test('returns false when coordinators is empty', () {
        final contract = buildContract(coordinators: const []);
        expect(isCoordinatorOf(contract, 'm-1'), isFalse);
      });
    });

    // --- deliveriesMissingCoordinator ---

    group('deliveriesMissingCoordinator', () {
      test('returns empty when all CONFIRMED contracts have coordinators', () {
        final delivery = buildDelivery(
          status: DeliveryStatus.confirmed,
          contracts: [
            buildContract(contractId: 'c-1', coordinators: const ['m-1']),
          ],
        );
        final org = buildOrg(deliveries: [delivery]);
        expect(deliveriesMissingCoordinator(org), isEmpty);
      });

      test('PLANNED delivery with empty coordinators is ignored', () {
        final delivery = buildDelivery(
          status: DeliveryStatus.planned,
          contracts: [buildContract(coordinators: const [])],
        );
        final org = buildOrg(deliveries: [delivery]);
        expect(deliveriesMissingCoordinator(org), isEmpty);
      });

      test('IN_PROGRESS delivery is never re-checked', () {
        final delivery = buildDelivery(
          status: DeliveryStatus.inProgress,
          contracts: [buildContract(coordinators: const [])],
        );
        final org = buildOrg(deliveries: [delivery]);
        expect(deliveriesMissingCoordinator(org), isEmpty);
      });

      test('COMPLETED delivery is never re-checked', () {
        final delivery = buildDelivery(
          status: DeliveryStatus.completed,
          contracts: [buildContract(coordinators: const [])],
        );
        final org = buildOrg(deliveries: [delivery]);
        expect(deliveriesMissingCoordinator(org), isEmpty);
      });

      test('CANCELLED delivery is never re-checked', () {
        final delivery = buildDelivery(
          status: DeliveryStatus.cancelled,
          contracts: [buildContract(coordinators: const [])],
        );
        final org = buildOrg(deliveries: [delivery]);
        expect(deliveriesMissingCoordinator(org), isEmpty);
      });

      test(
        'returns the contract missing a coordinator for a CONFIRMED delivery',
        () {
          final contract = buildContract(
            contractId: 'c-missing',
            coordinators: const [],
          );
          final delivery = buildDelivery(
            deliveryId: 'd-confirmed',
            status: DeliveryStatus.confirmed,
            contracts: [contract],
          );
          final org = buildOrg(deliveries: [delivery]);
          final result = deliveriesMissingCoordinator(org);
          expect(result, hasLength(1));
          expect(result.single.delivery.deliveryId, 'd-confirmed');
          expect(result.single.contract.contractId, 'c-missing');
        },
      );

      test('preserves order of deliveries and contracts', () {
        final c1 = buildContract(
          contractId: 'c-1',
          coordinators: const ['m-1'],
        );
        final c2 = buildContract(contractId: 'c-2', coordinators: const []);
        final c3 = buildContract(contractId: 'c-3', coordinators: const []);
        final d1 = buildDelivery(
          deliveryId: 'd-1',
          status: DeliveryStatus.confirmed,
          contracts: [c1, c2],
        );
        final d2 = buildDelivery(
          deliveryId: 'd-2',
          status: DeliveryStatus.confirmed,
          contracts: [c3],
        );
        final org = buildOrg(deliveries: [d1, d2]);
        final result = deliveriesMissingCoordinator(org);
        expect(result, hasLength(2));
        expect(result[0].delivery.deliveryId, 'd-1');
        expect(result[0].contract.contractId, 'c-2');
        expect(result[1].delivery.deliveryId, 'd-2');
        expect(result[1].contract.contractId, 'c-3');
      });
    });
  });

  group('isDeliveryPendingContractActivation', () {
    Contract seasonContract(String id, ContractStatus status) => Contract(
      contractId: id,
      name: 'Contrat $id',
      organizationId: 'org-1',
      producerAccountId: 'producer-1',
      minDeliveryDate: '2026-01-01',
      maxDeliveryDate: '2026-12-31',
      deliveryCount: 10,
      seasonYear: 2026,
      status: status,
    );

    test('true quand tous les contrats liés sont en préparation', () {
      final delivery = buildDelivery(
        contracts: [buildContract(contractId: 'c-prep')],
      );
      final contractsById = {
        'c-prep': seasonContract('c-prep', ContractStatus.inPreparation),
      };

      expect(
        isDeliveryPendingContractActivation(delivery, contractsById),
        isTrue,
      );
    });

    test('false dès qu\'un contrat lié est actif', () {
      final delivery = buildDelivery(
        contracts: [
          buildContract(contractId: 'c-prep'),
          buildContract(contractId: 'c-active'),
        ],
      );
      final contractsById = {
        'c-prep': seasonContract('c-prep', ContractStatus.inPreparation),
        'c-active': seasonContract('c-active', ContractStatus.active),
      };

      expect(
        isDeliveryPendingContractActivation(delivery, contractsById),
        isFalse,
      );
    });

    test('false sans contrat lié ou avec uniquement des liens inconnus', () {
      final noContracts = buildDelivery(contracts: const []);
      final unknownLink = buildDelivery(
        contracts: [buildContract(contractId: 'c-unknown')],
      );

      expect(
        isDeliveryPendingContractActivation(noContracts, const {}),
        isFalse,
      );
      expect(
        isDeliveryPendingContractActivation(unknownLink, const {}),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // defaultPlanningMonth
  // ---------------------------------------------------------------------------

  group('defaultPlanningMonth', () {
    final june29 = DateTime(2026, 6, 29, 10, 0);

    String isoOnDay(int year, int month, int day) =>
        '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}T18:00:00';

    test('advances to next month when last delivery has passed', () {
      final org = buildOrg(
        deliveries: [
          buildDelivery(scheduledDate: isoOnDay(2026, 6, 21)),
          buildDelivery(
            deliveryId: 'd-2',
            scheduledDate: isoOnDay(2026, 6, 14),
          ),
        ],
      );
      expect(defaultPlanningMonth(org, june29), DateTime(2026, 7));
    });

    test('keeps current month when an upcoming delivery exists', () {
      final org = buildOrg(
        deliveries: [
          buildDelivery(scheduledDate: isoOnDay(2026, 6, 21)),
          buildDelivery(
            deliveryId: 'd-2',
            scheduledDate: isoOnDay(2026, 6, 30),
          ),
        ],
      );
      expect(defaultPlanningMonth(org, june29), DateTime(2026, 6));
    });

    test('keeps current month when no delivery this month', () {
      final org = buildOrg(
        deliveries: [buildDelivery(scheduledDate: isoOnDay(2026, 7, 5))],
      );
      expect(defaultPlanningMonth(org, june29), DateTime(2026, 6));
    });
  });
}
