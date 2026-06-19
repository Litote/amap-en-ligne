import 'package:amap_en_ligne/data/repositories/notification_repository.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Member notification inbox (ADR-005). Reads the offline-first feed from
/// [NotificationRepository.watch] and lets the member mark notifications read
/// (tap) or archive them (swipe). Both are optimistic writes flushed on sync.
class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key, required this.memberId});

  final String memberId;

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  late final NotificationRepository _repo = context
      .read<NotificationRepository>();

  Future<void> _markRead(AppNotification n) async {
    if (n.readAt != null) return;
    await _repo.markRead(
      n,
      readAtIso: DateTime.now().toUtc().toIso8601String(),
    );
    if (mounted) {
      context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
    }
  }

  /// Marks the notification read and, when it carries a deep link, navigates to
  /// the linked screen (e.g. the basket-exchange offer/requests view).
  void _onTap(AppNotification n) {
    _markRead(n);
    final link = n.deepLink;
    if (link != null && link.isNotEmpty) {
      context.go(link);
    }
  }

  Future<void> _archive(AppNotification n) async {
    await _repo.archive(n);
    if (mounted) {
      context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: 'Notifications',
      actions: const [SyncButton()],
      body: StreamBuilder<List<AppNotification>>(
        stream: _repo.watch(widget.memberId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const _EmptyState();
          }
          final sorted = [...notifications]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _NotificationCard(
              notification: sorted[index],
              onTap: () => _onTap(sorted[index]),
              onArchive: () => _archive(sorted[index]),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune notification',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Vous serez prévenu ici des événements de votre AMAP.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onArchive,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = notification.readAt == null;
    return Dismissible(
      key: ValueKey(notification.notificationId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onArchive(),
      background: ColoredBox(
        color: theme.colorScheme.errorContainer,
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 24),
            child: Icon(Icons.archive_outlined),
          ),
        ),
      ),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            _iconFor(notification.type),
            color: isUnread
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          title: Text(
            notification.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(notification.body),
          trailing: isUnread
              ? Icon(Icons.circle, size: 10, color: theme.colorScheme.primary)
              : null,
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) => switch (type) {
    NotificationType.alert => Icons.warning_amber_outlined,
    NotificationType.urgent => Icons.priority_high_outlined,
    NotificationType.reminder => Icons.schedule_outlined,
    NotificationType.info => Icons.info_outline,
  };
}
