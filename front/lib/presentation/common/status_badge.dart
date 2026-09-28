import 'package:flutter/material.dart';

/// Read-only status / role badge drawn as a [Chip].
///
/// On the web, Flutter exposes every chip — even a non-selectable one — as a
/// checkbox (`RawChip` maps `selected` to `aria-checked`), so a screen reader
/// announced « Planifiée, case non cochée ». The badge is exposed as plain
/// text instead. Use it for any chip that only displays information.
class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.label, {
    super.key,
    this.labelStyle,
    this.backgroundColor,
    this.side,
    this.compact = true,
  });

  final String label;
  final TextStyle? labelStyle;
  final Color? backgroundColor;
  final BorderSide? side;

  /// No padding and a shrink-wrapped tap target (list badges).
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: ExcludeSemantics(
      child: Chip(
        label: Text(label),
        labelStyle: labelStyle,
        backgroundColor: backgroundColor,
        side: side,
        padding: compact ? EdgeInsets.zero : null,
        materialTapTargetSize: compact
            ? MaterialTapTargetSize.shrinkWrap
            : null,
      ),
    ),
  );
}
