import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/presentation/contracts/contract_view.dart';
import 'package:flutter/material.dart';

/// Multi-select chip group for choosing coordinator(s) from a list of members.
///
/// Exposes [CoordinatorSelectorState] publicly so callers can hold a
/// [GlobalKey<CoordinatorSelectorState>] and read [getSelectedCoordinators].
class CoordinatorSelector extends StatefulWidget {
  const CoordinatorSelector({
    super.key,
    required this.coordinators,
    required this.saving,
    required this.initialCoordinatorIds,
  });

  final List<Member> coordinators;
  final bool saving;
  final Set<String> initialCoordinatorIds;

  @override
  State<CoordinatorSelector> createState() => CoordinatorSelectorState();
}

class CoordinatorSelectorState extends State<CoordinatorSelector> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.initialCoordinatorIds};
  }

  @override
  void didUpdateWidget(CoordinatorSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCoordinatorIds != widget.initialCoordinatorIds) {
      _selectedIds = {...widget.initialCoordinatorIds};
    }
  }

  Set<String> getSelectedCoordinators() => _selectedIds;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final member in widget.coordinators)
        FilterChip(
          label: Text(memberDisplayName(member)),
          selected: _selectedIds.contains(member.memberId),
          onSelected: widget.saving
              ? null
              : (selected) {
                  setState(() {
                    if (selected) {
                      _selectedIds.add(member.memberId);
                    } else {
                      _selectedIds.remove(member.memberId);
                    }
                  });
                },
        ),
    ],
  );
}
