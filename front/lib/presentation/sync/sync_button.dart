import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reusable sync icon button for AppBar [actions].
///
/// Shows a spinning [CircularProgressIndicator] while [SyncRunning] and an
/// [Icons.sync] icon otherwise. Disabled while a sync is in progress.
///
/// Short press → incremental sync ([SyncEvent.requested]).
/// Long press  → confirmation dialog → full bootstrap ([SyncEvent.fullSyncRequested]).
class SyncButton extends StatelessWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final isSyncing = state is SyncRunning;
        return IconButton(
          tooltip: 'Synchroniser (appui long : sync complète)',
          onPressed: isSyncing
              ? null
              : () => context.read<SyncBloc>().add(const SyncEvent.requested()),
          onLongPress: isSyncing ? null : () => _confirmFullSync(context),
          icon: isSyncing
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
        );
      },
    );
  }

  void _confirmFullSync(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Synchronisation complète'),
        content: const Text(
          'Toutes les données locales seront supprimées et '
          'rechargées depuis le serveur. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Synchroniser'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<SyncBloc>().add(const SyncEvent.fullSyncRequested());
      }
    });
  }
}
