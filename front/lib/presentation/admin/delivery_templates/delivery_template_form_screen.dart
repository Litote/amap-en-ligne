import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_time_utils.dart';
import 'package:amap_en_ligne/presentation/common/app_time_picker.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const _defaultEarlySlotMaxVolunteers = 2;

/// Form screen for creating and editing [DeliveryTemplate] entries.
///
/// When [template] is null, the form creates a new template.
/// When [template] is non-null, the form edits the provided template.
class DeliveryTemplateFormScreen extends StatelessWidget {
  const DeliveryTemplateFormScreen({
    required this.organizationId,
    this.template,
    super.key,
  });

  final String organizationId;
  final DeliveryTemplate? template;

  @override
  Widget build(BuildContext context) => _DeliveryTemplateFormView(
    organizationId: organizationId,
    template: template,
  );
}

class _DeliveryTemplateFormView extends StatefulWidget {
  const _DeliveryTemplateFormView({
    required this.organizationId,
    required this.template,
  });

  final String organizationId;
  final DeliveryTemplate? template;

  @override
  State<_DeliveryTemplateFormView> createState() =>
      _DeliveryTemplateFormViewState();
}

class _DeliveryTemplateFormViewState extends State<_DeliveryTemplateFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _desiredVolunteerCountController;
  late final TextEditingController _explanationController;
  late final TextEditingController _maxVolunteersController;

  TimeOfDay? _standardStartTime;
  TimeOfDay? _standardEndTime;
  TimeOfDay? _volunteerArrivalTime;
  TimeOfDay? _earlyArrivalTime;
  late bool _hasEarlySlot;
  bool _isDefaultTemplate = false;
  bool _didInitializeDefaultTemplate = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameController = TextEditingController(text: t?.name ?? '');
    _desiredVolunteerCountController = TextEditingController(
      text: (t?.desiredVolunteerCount ?? 1).toString(),
    );
    _standardStartTime = parseDeliveryTemplateTime(t?.standardStartTime);
    _standardEndTime = parseDeliveryTemplateTime(t?.standardEndTime);
    _hasEarlySlot = t?.earlySlot != null;
    _volunteerArrivalTime = parseDeliveryTemplateTime(t?.volunteerArrivalTime);
    _earlyArrivalTime = parseDeliveryTemplateTime(t?.earlySlot?.arrivalTime);
    _explanationController = TextEditingController(
      text: t?.earlySlot?.explanation ?? '',
    );
    _maxVolunteersController = TextEditingController(
      text: t?.earlySlot?.maxVolunteers.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _desiredVolunteerCountController.dispose();
    _explanationController.dispose();
    _maxVolunteersController.dispose();
    super.dispose();
  }

  Future<void> _save(Organization organization) async {
    if (!_formKey.currentState!.validate()) return;

    EarlySlot? earlySlot;
    if (_hasEarlySlot) {
      final explanationText = _explanationController.text.trim();
      earlySlot = EarlySlot(
        arrivalTime: formatDeliveryTemplateTime(_earlyArrivalTime!),
        explanation: explanationText.isEmpty ? null : explanationText,
        maxVolunteers: int.parse(_maxVolunteersController.text.trim()),
      );
    }

    final isEdit = widget.template != null;
    final template = DeliveryTemplate(
      deliveryTemplateId: widget.template?.deliveryTemplateId ?? '',
      organizationId: widget.organizationId,
      name: _nameController.text.trim(),
      standardStartTime: formatDeliveryTemplateTime(_standardStartTime!),
      standardEndTime: formatDeliveryTemplateTime(_standardEndTime!),
      desiredVolunteerCount: int.parse(
        _desiredVolunteerCountController.text.trim(),
      ),
      volunteerArrivalTime: _volunteerArrivalTime != null
          ? formatDeliveryTemplateTime(_volunteerArrivalTime!)
          : null,
      earlySlot: earlySlot,
    );

    final templateRepository = context.read<DeliveryTemplateRepository>();
    final organizationRepository = context.read<OrganizationRepository>();
    final syncBloc = context.read<SyncBloc>();

    setState(() => _saving = true);
    try {
      late final DeliveryTemplate savedTemplate;
      if (isEdit) {
        await templateRepository.update(template);
        savedTemplate = template;
      } else {
        savedTemplate = await templateRepository.create(template);
      }

      final shouldUpdateDefaultTemplate =
          _isDefaultTemplate ||
          (widget.template != null &&
              organization.defaultDeliveryTemplateId ==
                  widget.template!.deliveryTemplateId);
      if (shouldUpdateDefaultTemplate) {
        final nextDefaultTemplateId = _isDefaultTemplate
            ? savedTemplate.deliveryTemplateId
            : null;
        if (nextDefaultTemplateId != organization.defaultDeliveryTemplateId) {
          await organizationRepository.updateDefaultDeliveryTemplateId(
            currentOrg: organization,
            defaultDeliveryTemplateId: nextDefaultTemplateId,
          );
        }
      }

      syncBloc.add(const SyncEvent.mutationApplied());
      if (mounted) context.pop();
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickStandardStartTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _standardStartTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked == null) return;
    setState(() => _standardStartTime = picked);
    _formKey.currentState?.validate();
  }

  Future<void> _pickVolunteerArrivalTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime:
          _volunteerArrivalTime ??
          _standardStartTime ??
          const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked == null) return;
    setState(() => _volunteerArrivalTime = picked);
    _formKey.currentState?.validate();
  }

  Future<void> _pickStandardEndTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _standardEndTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked == null) return;
    setState(() => _standardEndTime = picked);
    _formKey.currentState?.validate();
  }

  Future<void> _pickEarlyArrivalTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _earlyArrivalTime ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked == null) return;
    setState(() => _earlyArrivalTime = picked);
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.template != null;
    return ConnectedScaffold(
      title: isEdit ? 'Modifier le modèle' : 'Nouveau modèle',
      body: StreamBuilder<Organization?>(
        stream: context.read<OrganizationRepository>().watch(
          widget.organizationId,
        ),
        builder: (context, snapshot) {
          final organization = snapshot.data;
          if (organization == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_didInitializeDefaultTemplate) {
            _isDefaultTemplate =
                widget.template != null &&
                organization.defaultDeliveryTemplateId ==
                    widget.template!.deliveryTemplateId;
            _didInitializeDefaultTemplate = true;
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du modèle',
                    hintText: 'Ex. Livraison standard',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _desiredVolunteerCountController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre souhaité de bénévoles',
                    hintText: 'Ex. 3',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Champ requis.';
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1) return 'Entier positif requis.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _TimePickerField(
                  label: 'Heure de début de livraison',
                  value: _standardStartTime,
                  onTap: _pickStandardStartTime,
                  validator: (value) => value == null ? 'Champ requis.' : null,
                ),
                const SizedBox(height: 16),
                _TimePickerField(
                  label: "Heure d'arrivée des bénévoles",
                  value: _volunteerArrivalTime,
                  onTap: _pickVolunteerArrivalTime,
                  validator: (value) => validateVolunteerArrivalTime(
                    volunteerArrivalTime: value,
                    standardStartTime: _standardStartTime,
                  ),
                ),
                const SizedBox(height: 16),
                _TimePickerField(
                  label: 'Heure de fin standard',
                  value: _standardEndTime,
                  onTap: _pickStandardEndTime,
                  validator: (value) => validateStandardEndTime(
                    standardStartTime: _standardStartTime,
                    standardEndTime: value,
                  ),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Modèle par défaut'),
                  value: _isDefaultTemplate,
                  onChanged: (value) =>
                      setState(() => _isDefaultTemplate = value),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Activer un créneau anticipé'),
                  value: _hasEarlySlot,
                  onChanged: (value) {
                    if (value && _maxVolunteersController.text.trim().isEmpty) {
                      _maxVolunteersController.text =
                          _defaultEarlySlotMaxVolunteers.toString();
                    }
                    setState(() => _hasEarlySlot = value);
                    _formKey.currentState?.validate();
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (_hasEarlySlot) ...[
                  const SizedBox(height: 8),
                  _TimePickerField(
                    label: "Heure d'arrivée anticipée",
                    value: _earlyArrivalTime,
                    onTap: _pickEarlyArrivalTime,
                    validator: (value) => validateEarlyArrivalTime(
                      hasEarlySlot: _hasEarlySlot,
                      earlyArrivalTime: value,
                      standardStartTime: _standardStartTime,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _explanationController,
                    decoration: const InputDecoration(
                      labelText: 'Explication (optionnel)',
                      hintText: 'Ex. Réception des légumes',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _maxVolunteersController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre max de bénévoles',
                      hintText: 'Ex. 2',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (!_hasEarlySlot) return null;
                      if (v == null || v.trim().isEmpty) return 'Champ requis.';
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1) return 'Entier positif requis.';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saving ? null : () => _save(organization),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Enregistrer' : 'Créer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.validator,
  });

  final String label;
  final TimeOfDay? value;
  final Future<void> Function() onTap;
  final String? Function(TimeOfDay?) validator;

  @override
  Widget build(BuildContext context) {
    return FormField<TimeOfDay>(
      initialValue: value,
      validator: (_) => validator(value),
      builder: (field) => InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.access_time),
            errorText: field.errorText,
          ),
          child: Text(
            value == null
                ? 'Sélectionner une heure'
                : formatDeliveryTemplateTime(value!),
          ),
        ),
      ),
    );
  }
}
