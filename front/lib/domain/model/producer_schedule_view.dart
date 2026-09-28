import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';

/// Pure selectors for the producer dashboard, computed from the producer's
/// [ProducerSchedule] projections (one per linked AMAP).

/// An upcoming delivery of the producer, with the name of its AMAP.
typedef ProducerUpcomingDelivery = ({
  String organizationId,
  String organizationName,
  ProducerScheduleDelivery delivery,
});

/// Whether the contract is still being prepared by the AMAP (not active yet).
bool isScheduleContractInPreparation(ProducerScheduleContract contract) =>
    contract.contractStatus == ContractStatus.inPreparation;

/// Suffix shown after a contract name in the producer's delivery lists.
String scheduleContractStatusSuffix(ProducerScheduleContract contract) =>
    isScheduleContractInPreparation(contract) ? ' (en préparation)' : '';

/// Whether the contract counts as running on the dashboard: neither still in
/// preparation nor ended (legacy schedules without a status stay listed).
bool _isRunning(ProducerScheduleContract contract) =>
    contract.contractStatus != ContractStatus.inPreparation &&
    contract.contractStatus != ContractStatus.ended;

/// A contract of the producer that still has an upcoming delivery.
typedef ProducerActiveContract = ({
  String organizationName,
  String contractName,

  /// Basket count of the contract's next delivery.
  int basketQuantity,
});

/// Content of the producer dashboard.
typedef ProducerDashboardSummary = ({
  /// Linked AMAPs (one schedule each, even without any delivery yet).
  int partnerCount,

  /// The soonest active deliveries, from today on.
  List<ProducerUpcomingDelivery> upcoming,

  /// Contracts with at least one upcoming active delivery, sorted by AMAP
  /// then contract name. Contracts still in preparation or ended are left
  /// out.
  List<ProducerActiveContract> activeContracts,
});

/// Builds the dashboard summary at [now]: active (neither completed nor
/// cancelled) deliveries scheduled from today on, the [upcomingLimit] soonest
/// ones listed.
ProducerDashboardSummary producerDashboardSummary(
  List<ProducerSchedule> schedules,
  DateTime now, {
  int upcomingLimit = 3,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final all =
      <ProducerUpcomingDelivery>[
        for (final schedule in schedules)
          for (final delivery in schedule.deliveries)
            if (delivery.status.isActive &&
                !(DateTime.tryParse(delivery.scheduledDate) ?? today).isBefore(
                  today,
                ))
              (
                organizationId: schedule.organizationId,
                organizationName: schedule.organizationName,
                delivery: delivery,
              ),
      ]..sort(
        (a, b) => a.delivery.scheduledDate.compareTo(b.delivery.scheduledDate),
      );

  // First (soonest) occurrence of each (AMAP, contract).
  final contracts = <String, ProducerActiveContract>{};
  for (final entry in all) {
    for (final contract in entry.delivery.contracts.where(_isRunning)) {
      contracts.putIfAbsent(
        '${entry.organizationId}\u0000${contract.contractId}',
        () => (
          organizationName: entry.organizationName,
          contractName: contract.contractName,
          basketQuantity: contract.basketQuantity,
        ),
      );
    }
  }
  final activeContracts = contracts.values.toList()
    ..sort((a, b) {
      final byOrg = a.organizationName.compareTo(b.organizationName);
      return byOrg != 0 ? byOrg : a.contractName.compareTo(b.contractName);
    });

  return (
    partnerCount: schedules.length,
    upcoming: all.take(upcomingLimit).toList(),
    activeContracts: activeContracts,
  );
}
