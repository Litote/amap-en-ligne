import 'package:flutter/material.dart';

enum NavItemKind { action, sectionHeader, separator }

/// A single entry in the navigation menu.
///
/// Three kinds are supported:
/// - [NavItemKind.action] — a tappable item with a route or [onTap] callback.
/// - [NavItemKind.sectionHeader] — a non-tappable role section label (e.g. "— Bénévole —").
/// - [NavItemKind.separator] — a visual horizontal rule before the common items.
class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    this.route,
    this.badgeCount,
    this.onTap,
    this.kind = NavItemKind.action,
  });

  const NavItem.sectionHeader(String sectionLabel)
    : kind = NavItemKind.sectionHeader,
      label = sectionLabel,
      icon = Icons.label, // unused in rendering
      route = null,
      badgeCount = null,
      onTap = null;

  const NavItem.separator()
    : kind = NavItemKind.separator,
      label = '',
      icon = Icons.horizontal_rule, // unused in rendering
      route = null,
      badgeCount = null,
      onTap = null;

  final NavItemKind kind;
  final String label;
  final IconData icon;
  final String? route;
  final int? badgeCount;
  final VoidCallback? onTap;
}
