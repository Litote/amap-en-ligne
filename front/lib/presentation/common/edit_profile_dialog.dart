import 'package:flutter/material.dart';

/// Which entity type the dialog is editing.
enum _ProfileType { owner, producer }

/// A dialog for editing the current user's profile information.
///
/// For [owner] type: shows Prénom, Nom, Email (required) and Téléphone
/// (optional) fields.
/// For [producer] type: shows Nom de l'entreprise (required) and Email de
/// contact, Adresse, Site web (all optional) fields.
///
/// Pre-fills every field from the [initialValues] map. The [onSubmit]
/// callback is invoked with the final map of field values when the user
/// taps "Enregistrer".
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog._({
    required _ProfileType type,
    required Map<String, String?> initialValues,
    required ValueChanged<Map<String, String?>> onSubmit,
  }) : _type = type,
       _initialValues = initialValues,
       _onSubmit = onSubmit;

  /// Creates an edit-profile dialog pre-filled with [Owner] data.
  factory EditProfileDialog.forOwner({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    required ValueChanged<Map<String, String?>> onSubmit,
  }) => EditProfileDialog._(
    type: _ProfileType.owner,
    initialValues: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
    },
    onSubmit: onSubmit,
  );

  /// Creates an edit-profile dialog pre-filled with [ProducerAccount] data.
  factory EditProfileDialog.forProducer({
    required String name,
    String? contactEmail,
    String? address,
    String? website,
    required ValueChanged<Map<String, String?>> onSubmit,
  }) => EditProfileDialog._(
    type: _ProfileType.producer,
    initialValues: {
      'name': name,
      'contactEmail': contactEmail,
      'address': address,
      'website': website,
    },
    onSubmit: onSubmit,
  );

  final _ProfileType _type;
  final Map<String, String?> _initialValues;
  final ValueChanged<Map<String, String?>> _onSubmit;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  // Owner controllers.
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  // Producer controllers.
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactEmailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _websiteCtrl;

  @override
  void initState() {
    super.initState();
    final v = widget._initialValues;
    _firstNameCtrl = TextEditingController(text: v['firstName'] ?? '');
    _lastNameCtrl = TextEditingController(text: v['lastName'] ?? '');
    _emailCtrl = TextEditingController(text: v['email'] ?? '');
    _phoneCtrl = TextEditingController(text: v['phone'] ?? '');
    _nameCtrl = TextEditingController(text: v['name'] ?? '');
    _contactEmailCtrl = TextEditingController(text: v['contactEmail'] ?? '');
    _addressCtrl = TextEditingController(text: v['address'] ?? '');
    _websiteCtrl = TextEditingController(text: v['website'] ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final Map<String, String?> fields;
    if (widget._type == _ProfileType.owner) {
      fields = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      };
    } else {
      fields = {
        'name': _nameCtrl.text.trim(),
        'contactEmail': _contactEmailCtrl.text.trim().isEmpty
            ? null
            : _contactEmailCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        'website': _websiteCtrl.text.trim().isEmpty
            ? null
            : _websiteCtrl.text.trim(),
      };
    }

    Navigator.of(context).pop();
    widget._onSubmit(fields);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier mes informations'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget._type == _ProfileType.owner
                ? _ownerFields()
                : _producerFields(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }

  List<Widget> _ownerFields() => [
    _field(controller: _firstNameCtrl, label: 'Prénom', required: true),
    const SizedBox(height: 12),
    _field(controller: _lastNameCtrl, label: 'Nom', required: true),
    const SizedBox(height: 12),
    _field(
      controller: _emailCtrl,
      label: 'Email',
      required: true,
      keyboardType: TextInputType.emailAddress,
    ),
    const SizedBox(height: 12),
    _field(
      controller: _phoneCtrl,
      label: 'Téléphone (optionnel)',
      required: false,
      keyboardType: TextInputType.phone,
    ),
  ];

  List<Widget> _producerFields() => [
    _field(controller: _nameCtrl, label: "Nom de l'entreprise", required: true),
    const SizedBox(height: 12),
    _field(
      controller: _contactEmailCtrl,
      label: 'Email de contact (optionnel)',
      required: false,
      keyboardType: TextInputType.emailAddress,
    ),
    const SizedBox(height: 12),
    _field(
      controller: _addressCtrl,
      label: 'Adresse (optionnel)',
      required: false,
    ),
    const SizedBox(height: 12),
    _field(
      controller: _websiteCtrl,
      label: 'Site web (optionnel)',
      required: false,
      keyboardType: TextInputType.url,
    ),
  ];

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool required,
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    keyboardType: keyboardType,
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null
        : null,
  );
}
