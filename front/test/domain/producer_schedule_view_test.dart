import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule_view.dart';
import 'package:flutter_test/flutter_test.dart';

ProducerScheduleDelivery _delivery(
  String id,
  String date, {
  DeliveryStatus status = DeliveryStatus.planned,
  List<(String, String, int)> contracts = const [('c-1', 'Fromages', 12)],
  Map<String, ContractStatus> contractStatuses = const {},
}) => ProducerScheduleDelivery(
  deliveryId: id,
  scheduledDate: date,
  status: status,
  contracts: [
    for (final (id, name, baskets) in contracts)
      ProducerScheduleContract(
        contractId: id,
        contractName: name,
        basketQuantity: baskets,
        status: DeliveryContractStatus.pending,
        contractStatus: contractStatuses[id],
      ),
  ],
);

ProducerSchedule _schedule(
  String orgId,
  String orgName,
  List<ProducerScheduleDelivery> deliveries,
) => ProducerSchedule(
  organizationId: orgId,
  producerAccountId: 'pa-1',
  organizationName: orgName,
  deliveries: deliveries,
);

void main() {
  final now = DateTime(2026, 10, 1, 9);

  test('empty schedules give an empty summary', () {
    final summary = producerDashboardSummary(const [], now);

    expect(summary.partnerCount, 0);
    expect(summary.upcoming, isEmpty);
    expect(summary.activeContracts, isEmpty);
  });

  test(
    'counts partners, keeps the 3 soonest active deliveries of today on',
    () {
      final summary = producerDashboardSummary([
        _schedule('org-a', 'AMAP A', [
          _delivery('past', '2026-09-24T18:00'),
          _delivery('today', '2026-10-01T18:00'),
          _delivery('d3', '2026-10-15T18:00'),
          _delivery(
            'cancelled',
            '2026-10-02T18:00',
            status: DeliveryStatus.cancelled,
          ),
        ]),
        _schedule('org-b', 'AMAP B', [
          _delivery('d2', '2026-10-08T18:00', contracts: [('c-2', 'Oeufs', 5)]),
          _delivery('d4', '2026-10-22T18:00', contracts: [('c-2', 'Oeufs', 6)]),
        ]),
        // Linked AMAP without any delivery yet: still a partner.
        _schedule('org-c', 'AMAP C', const []),
      ], now);

      expect(summary.partnerCount, 3);
      expect(summary.upcoming.map((u) => u.delivery.deliveryId), [
        'today',
        'd2',
        'd3',
      ]);
      expect(summary.upcoming.first.organizationName, 'AMAP A');
    },
  );

  test('active contracts: one per AMAP and contract, soonest quantity', () {
    final summary = producerDashboardSummary([
      _schedule('org-b', 'AMAP B', [
        _delivery('d4', '2026-10-22T18:00', contracts: [('c-2', 'Oeufs', 6)]),
        _delivery('d2', '2026-10-08T18:00', contracts: [('c-2', 'Oeufs', 5)]),
      ]),
      _schedule('org-a', 'AMAP A', [
        _delivery(
          'd1',
          '2026-10-01T18:00',
          contracts: [('c-1', 'Fromages', 12), ('c-3', 'Yaourts', 0)],
        ),
        _delivery('old', '2026-09-01T18:00', contracts: [('c-9', 'Ancien', 3)]),
      ]),
    ], now);

    expect(
      summary.activeContracts.map(
        (c) => '${c.organizationName}/${c.contractName}/${c.basketQuantity}',
      ),
      ['AMAP A/Fromages/12', 'AMAP A/Yaourts/0', 'AMAP B/Oeufs/5'],
    );
  });

  test('active contracts leave out contracts in preparation or ended', () {
    final summary = producerDashboardSummary([
      _schedule('org-a', 'AMAP A', [
        _delivery(
          'd1',
          '2026-10-01T18:00',
          contracts: [
            ('c-1', 'Fromages', 12),
            ('c-2', 'Fromages test', 0),
            ('c-3', 'Ancien', 4),
            ('c-4', 'Yaourts', 2),
          ],
          contractStatuses: const {
            'c-1': ContractStatus.active,
            'c-2': ContractStatus.inPreparation,
            'c-3': ContractStatus.ended,
          },
        ),
      ]),
    ], now);

    // Legacy schedules without contract_status (c-4) stay listed.
    expect(summary.activeContracts.map((c) => c.contractName), [
      'Fromages',
      'Yaourts',
    ]);
    // The delivery itself stays upcoming: the producer still prepares it.
    expect(summary.upcoming.single.delivery.deliveryId, 'd1');
    final prepared = summary.upcoming.single.delivery.contracts[1];
    expect(isScheduleContractInPreparation(prepared), isTrue);
    expect(scheduleContractStatusSuffix(prepared), ' (en préparation)');
    expect(
      scheduleContractStatusSuffix(
        summary.upcoming.single.delivery.contracts.first,
      ),
      '',
    );
  });
}
