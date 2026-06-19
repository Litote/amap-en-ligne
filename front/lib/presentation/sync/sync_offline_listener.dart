import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_messages.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Surfaces network sync failures ([SyncOffline]) anywhere in the app.
///
/// Mounted once in the authenticated shell, above the `MaterialApp`: unlike
/// [SyncStatusBanner], which only exists on a few dashboard screens, this
/// listener reaches the user on every screen. It shows a reassuring snackbar
/// telling them the server is unreachable and that their changes are saved
/// locally until connectivity returns.
///
/// [messengerKey] must be the same key passed to the `MaterialApp` below,
/// since this widget sits above the app and has no `ScaffoldMessenger` in
/// scope.
class SyncOfflineListener extends StatelessWidget {
  const SyncOfflineListener({
    super.key,
    required this.messengerKey,
    required this.child,
  });

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncBloc, SyncState>(
      listenWhen: (previous, current) => current is SyncOffline,
      listener: (context, state) {
        final messenger = messengerKey.currentState;
        if (messenger == null) return;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(syncServerUnreachableMessage)),
          );
      },
      child: child,
    );
  }
}
