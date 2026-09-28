import 'package:amap_en_ligne/presentation/common/french_date_formatting.dart';
import 'package:flutter/material.dart';

/// Header title of the app's date pickers. The default French one
/// ("Sélectionner une date") is truncated in the landscape layout.
const datePickerHelpText = 'Choisir une date';

/// A read-only text field that opens a date picker on tap.
///
/// [controller] holds the value as an ISO date (`yyyy-MM-dd`) — that is what
/// callers read and write; the field itself shows it in French
/// ("1 oct. 2026").
///
/// Domain-agnostic — can be used in any form that needs a date input.
class DatePickerField extends StatefulWidget {
  const DatePickerField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.enabled,
    required this.onChanged,
    this.initialDateFallback,
    this.extraValidator,
    this.firstDate,
  });

  final TextEditingController controller;

  /// Field label, e.g. "Date de première livraison *".
  final String labelText;
  final bool enabled;
  final VoidCallback onChanged;

  /// Date the picker opens on while the field is empty (e.g. the start date
  /// for an end-date field); today when absent or null.
  final DateTime? Function()? initialDateFallback;

  /// Rule checked once the date is valid (e.g. the end date not before the
  /// start date), shown under the field; null when it holds.
  final String? Function()? extraValidator;

  /// Earliest date the picker offers (e.g. the start date for an end-date
  /// field); no bound when absent or null.
  final DateTime? Function()? firstDate;

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late final _focusNode = FocusNode();
  final _displayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncDisplay);
    _syncDisplay();
  }

  @override
  void didUpdateWidget(DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncDisplay);
      widget.controller.addListener(_syncDisplay);
      _syncDisplay();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncDisplay);
    _displayController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncDisplay() {
    final iso = widget.controller.text.trim();
    final date = DateTime.tryParse(iso);
    _displayController.text = date == null
        ? iso
        : frenchDateFormat('d MMM yyyy').format(date);
  }

  /// "Choisir la date de première livraison" for "Date de première livraison *".
  String get _pickerTooltip {
    final label = widget.labelText.replaceAll('*', '').trim();
    if (label.isEmpty) return datePickerHelpText;
    return 'Choisir la ${label[0].toLowerCase()}${label.substring(1)}';
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: _displayController,
    focusNode: _focusNode,
    enabled: widget.enabled,
    readOnly: true,
    onTap: widget.enabled ? _showDatePicker : null,
    decoration: InputDecoration(
      labelText: widget.labelText,
      suffixIcon: widget.enabled
          ? IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: _pickerTooltip,
              onPressed: _showDatePicker,
            )
          : null,
    ),
    // Validate the ISO value, not the French display.
    validator: (_) => DateTime.tryParse(widget.controller.text.trim()) == null
        ? 'Date invalide'
        : widget.extraValidator?.call(),
  );

  Future<void> _showDatePicker() async {
    _focusNode.unfocus();
    final dateText = widget.controller.text.trim();
    final firstDate = widget.firstDate?.call() ?? DateTime(1900);
    final parsedDate =
        DateTime.tryParse(dateText) ??
        widget.initialDateFallback?.call() ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      // The picker refuses an initial date before its first date.
      initialDate: parsedDate.isBefore(firstDate) ? firstDate : parsedDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      helpText: datePickerHelpText,
    );
    if (picked != null) {
      widget.controller.text = picked.toString().split(' ')[0];
      widget.onChanged();
    }
  }
}
