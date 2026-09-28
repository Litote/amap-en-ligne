import 'package:flutter/material.dart';

/// A read-only text field that opens a date picker on tap.
///
/// Domain-agnostic — can be used in any form that needs a date input.
class DatePickerField extends StatefulWidget {
  const DatePickerField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    focusNode: _focusNode,
    enabled: widget.enabled,
    readOnly: true,
    decoration: InputDecoration(
      labelText: widget.labelText,
      suffixIcon: widget.enabled
          ? IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _showDatePicker,
            )
          : null,
    ),
    validator: (value) =>
        DateTime.tryParse(value?.trim() ?? '') == null ? 'Date invalide' : null,
  );

  Future<void> _showDatePicker() async {
    _focusNode.unfocus();
    final dateText = widget.controller.text.trim();
    final parsedDate = DateTime.tryParse(dateText) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parsedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      widget.controller.text = picked.toString().split(' ')[0];
      widget.onChanged();
    }
  }
}
