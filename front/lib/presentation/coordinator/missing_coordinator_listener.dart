import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wraps [child] and listens for [SyncSucceeded] states that carry a
/// rejected mutation with [MutationErrorCode.missingCoordinator].
///
/// When detected, shows a SnackBar listing the contract descriptions that
/// still lack a coordinator.
///
/// Placement: wrap any screen that may enqueue an Upsert(OrganizationPayload)
/// with status=CONFIRMED. Today this covers [CoordinatorDashboardSection] and
/// [TimeSlotFormScreen]; the CONFIRMED transition has no dedicated UI yet —
/// this listener is a safety net for any future write that triggers the guard.
class MissingCoordinatorListener extends StatelessWidget {
  const MissingCoordinatorListener({required this.child, this.org, super.key});

  final Widget child;

  /// The current [Organization] — used to resolve contract descriptions for
  /// the snackbar message. May be null when the org is not yet loaded.
  final Organization? org;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncBloc, SyncState>(
      listenWhen: (_, current) => current is SyncSucceeded,
      listener: (context, state) {
        if (state is! SyncSucceeded) return;
        final missing = state.rejectedMutations.where(
          (m) =>
              m.status == MutationStatus.rejected &&
              m.error?.code == MutationErrorCode.missingCoordinator,
        );
        if (missing.isEmpty) return;

        // Resolve contract descriptions from the current org if available.
        final contractNames = _resolveContractNames(org);
        final detail = contractNames.isNotEmpty
            ? ' : aucun coordinateur sur le(s) contrat(s) ${contractNames.join(', ')}.'
            : '.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cette livraison ne peut pas être confirmée$detail'),
          ),
        );
      },
      child: child,
    );
  }

  /// Collects delivery-description labels for all contracts missing a
  /// coordinator on CONFIRMED deliveries in [org].
  static List<String> _resolveContractNames(Organization? org) {
    if (org == null) return const [];
    final names = <String>[];
    for (final delivery in org.deliveries) {
      if (delivery.status != DeliveryStatus.confirmed) continue;
      for (final contract in delivery.contracts) {
        if (contract.coordinators.isEmpty) {
          names.add(contract.deliveryDescription);
        }
      }
    }
    return names;
  }
}
