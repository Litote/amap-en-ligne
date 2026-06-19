import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Listens for [SyncSucceeded] states carrying a rejected mutation with
/// [MutationErrorCode.conflict] — an offline race where another device
/// deleted/cancelled a slot or registrations changed between the local
/// validation and the server-side guard.
class SlotConflictListener extends StatelessWidget {
  const SlotConflictListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<SyncBloc, SyncState>(
      listenWhen: (_, current) => current is SyncSucceeded,
      listener: (context, state) {
        if (state is! SyncSucceeded) return;
        final conflicts = state.rejectedMutations.where(
          (m) =>
              m.status == MutationStatus.rejected &&
              m.error?.code == MutationErrorCode.conflict,
        );
        if (conflicts.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Opération refusée par le serveur : des bénévoles sont encore '
              'inscrits sur cette livraison.',
            ),
          ),
        );
      },
      child: child,
    );
}
