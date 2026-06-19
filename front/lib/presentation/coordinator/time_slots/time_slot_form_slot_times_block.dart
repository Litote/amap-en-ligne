import 'package:amap_en_ligne/presentation/common/app_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Editable per-delivery slot-time overrides: the volunteer arrival time, the
/// end time, and an optional early slot (arrival + capacity + explanation).
///
/// Empty fields fall back to the selected template, then to the hard-coded
/// defaults when the delivery is saved.
class SlotTimesBlock extends StatelessWidget {
  const SlotTimesBlock({
    super.key,
    required this.arrivalTime,
    required this.endTime,
    required this.earlySlotEnabled,
    required this.earlySlotArrivalTime,
    required this.earlySlotMaxCtrl,
    required this.earlySlotExplanationCtrl,
    required this.onPickArrival,
    required this.onPickEnd,
    required this.onToggleEarlySlot,
    required this.onPickEarlyArrival,
  });

  final TimeOfDay? arrivalTime;
  final TimeOfDay? endTime;
  final bool earlySlotEnabled;
  final TimeOfDay? earlySlotArrivalTime;
  final TextEditingController earlySlotMaxCtrl;
  final TextEditingController earlySlotExplanationCtrl;
  final VoidCallback onPickArrival;
  final VoidCallback onPickEnd;
  final ValueChanged<bool> onToggleEarlySlot;
  final VoidCallback onPickEarlyArrival;

  Widget _timeField(
    BuildContext context, {
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) => InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value == null
              ? 'Selon le modèle'
              : formatAppTimeOfDay(context, value),
        ),
      ),
    );

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Horaires des créneaux',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _timeField(
          context,
          label: 'Heure d\'arrivée des bénévoles',
          value: arrivalTime,
          onTap: onPickArrival,
        ),
        const SizedBox(height: 12),
        _timeField(
          context,
          label: 'Heure de fin',
          value: endTime,
          onTap: onPickEnd,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Créneau anticipé'),
          value: earlySlotEnabled,
          onChanged: onToggleEarlySlot,
        ),
        if (earlySlotEnabled) ...[
          _timeField(
            context,
            label: 'Arrivée (créneau anticipé)',
            value: earlySlotArrivalTime,
            onTap: onPickEarlyArrival,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: earlySlotMaxCtrl,
            decoration: const InputDecoration(
              labelText: 'Bénévoles max (créneau anticipé)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: earlySlotExplanationCtrl,
            decoration: const InputDecoration(
              labelText: 'Explication (créneau anticipé, facultatif)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ],
    );
}
