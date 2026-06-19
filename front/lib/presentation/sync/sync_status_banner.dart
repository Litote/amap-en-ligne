import 'package:amap_en_ligne/data/repositories/error_report_repository.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_messages.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Reusable banner that surfaces [SyncFailed], [SyncOffline] and non-empty
/// rejected-mutations states from [SyncBloc].
///
/// Renders as [SizedBox.shrink] when there is nothing to report.
///
/// On [SyncOffline] (server unreachable), a reassuring banner is shown with a
/// single retry button — no copy/report actions, since there is nothing
/// actionable to report.
///
/// On [SyncFailed], three icon buttons are shown:
/// - Retry ([Icons.refresh]) — re-dispatches [SyncEvent.requested].
/// - Copy ([Icons.content_copy]) — writes the error message to clipboard.
/// - Report ([Icons.flag_outlined]) — submits an [ErrorReport] via
///   [ErrorReportRepository] and captures it to Sentry. Disabled after the
///   first successful tap.
class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  /// Becomes true after the user taps "Signaler le problème" once.
  bool _reported = false;

  Future<void> _copyError(BuildContext context, String message) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Erreur copiée')));
  }

  Future<void> _reportError(BuildContext context, String message) async {
    final db = context.read<AppDatabase>();
    final repo = context.read<ErrorReportRepository>();
    final bloc = context.read<SyncBloc>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final cursors = await db.readAllScopeCursors();
    final firstScope = cursors.keys
        .where(
          (k) =>
              k.startsWith('organization:') ||
              k.startsWith('producer-account:'),
        )
        .firstOrNull;

    if (firstScope == null) return;

    await repo.create(errorMessage: message, scopeKey: firstScope);

    await Sentry.captureMessage(
      message,
      level: SentryLevel.info,
      hint: Hint.withMap({'source': 'user_reported'}),
    );

    if (!context.mounted) return;
    bloc.add(const SyncEvent.mutationApplied());
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Problème signalé')),
    );
    setState(() => _reported = true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        return switch (state) {
          SyncOffline() => MaterialBanner(
            leading: const Icon(Icons.cloud_off),
            content: const Text(syncServerUnreachableMessage),
            actions: [
              Tooltip(
                message: 'Réessayer',
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      context.read<SyncBloc>().add(const SyncEvent.requested()),
                ),
              ),
            ],
          ),
          SyncFailed(:final message) => MaterialBanner(
            content: Text('Échec de la synchronisation : $message'),
            actions: [
              Tooltip(
                message: 'Réessayer',
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      context.read<SyncBloc>().add(const SyncEvent.requested()),
                ),
              ),
              Tooltip(
                message: "Copier l'erreur",
                child: IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () => _copyError(context, message),
                ),
              ),
              Tooltip(
                message: 'Signaler le problème',
                child: IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  onPressed: _reported
                      ? null
                      : () => _reportError(context, message),
                ),
              ),
            ],
          ),
          SyncSucceeded(rejectedMutations: final rejected)
              when rejected.isNotEmpty =>
            MaterialBanner(
              content: const Text(
                'Un problème de synchronisation est survenu. '
                'Certaines modifications locales n\'ont pas pu être appliquées.',
              ),
              actions: [
                TextButton(
                  onPressed: () => context.read<SyncBloc>().add(
                    const SyncEvent.fullSyncRequested(),
                  ),
                  child: const Text('Recharger'),
                ),
              ],
            ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
