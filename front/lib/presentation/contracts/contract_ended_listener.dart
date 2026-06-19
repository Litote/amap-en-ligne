import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wraps [child] and listens for [SyncSucceeded] states that carry
/// rejected mutations related to contract validation errors.
///
/// When detected, shows a SnackBar with the appropriate error message:
/// - [MutationErrorCode.contractEnded] — contract season has already ended
/// - [MutationErrorCode.invalidSubscription] — member subscription is empty
///   or does not match any contract product price.
///
/// Placement: wrap any screen that may enqueue a mutation against a contract
/// (e.g. member subscription or delivery link). Today this
/// covers [CoordinatorMemberContractsScreen], [CoordinatorContractsScreen]
/// and [TimeSlotFormScreen].
class ContractEndedListener extends StatelessWidget {
  const ContractEndedListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncBloc, SyncState>(
      listenWhen: (_, current) => current is SyncSucceeded,
      listener: (context, state) {
        if (state is! SyncSucceeded) return;
        for (final mutation in state.rejectedMutations) {
          if (mutation.status != MutationStatus.rejected) continue;
          final code = mutation.error?.code;
          String? message;
          if (code == MutationErrorCode.contractEnded) {
            message = 'Opération refusée : ce contrat est terminé.';
          } else if (code == MutationErrorCode.invalidSubscription) {
            message =
                'Opération refusée : la souscription ne correspond pas aux produits du contrat.';
          }
          if (message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
            break;
          }
        }
      },
      child: child,
    );
  }
}
