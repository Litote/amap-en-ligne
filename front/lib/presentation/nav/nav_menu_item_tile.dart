import 'package:amap_en_ligne/presentation/nav/nav_item.dart';
import 'package:flutter/material.dart';

/// A single row in the navigation menu.
///
/// Renders differently depending on [NavItem.kind]:
/// - [NavItemKind.action]        — tappable [ListTile] with icon and label.
/// - [NavItemKind.sectionHeader] — non-tappable role section label.
/// - [NavItemKind.separator]     — horizontal divider before common items.
class NavMenuItemTile extends StatelessWidget {
  const NavMenuItemTile({
    super.key,
    required this.item,
    required this.onTap,
    this.selected = false,
  });

  final NavItem item;
  final VoidCallback onTap;

  /// Whether this entry is the one of the displayed screen (highlighted and
  /// announced as selected).
  final bool selected;

  @override
  Widget build(BuildContext context) => switch (item.kind) {
    NavItemKind.sectionHeader => _SectionHeader(label: item.label),
    NavItemKind.separator => const Divider(height: 1),
    NavItemKind.action => _ActionTile(
      item: item,
      onTap: onTap,
      selected: selected,
    ),
  };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.item,
    required this.onTap,
    required this.selected,
  });

  final NavItem item;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    Widget tile = ListTile(
      leading: Icon(item.icon),
      title: Text(item.label),
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      onTap: onTap,
    );
    if (item.badgeCount != null) {
      tile = Badge(
        label: item.badgeCount! > 0 ? Text('${item.badgeCount}') : null,
        child: tile,
      );
    }
    return tile;
  }
}
