import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/validation/input_rules.dart';
import 'package:amap_en_ligne/presentation/admin/organization_config_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen title — kept as a constant so tests can find it by text.
const _kScreenTitle = "Configuration de l'organisation";

/// Admin screen for editing the core identity fields of the organization:
/// name, contact e-mail, timezone, default language, and website.
///
/// Mirrors `documentation/feature/fr/ui/admin/screen-admin-02-organization-config.md`.
///
/// Uses [OrgConfigBloc], created internally from the [OrganizationRepository]
/// available in the widget tree.
class OrganizationConfigScreen extends StatelessWidget {
  const OrganizationConfigScreen({required this.tenantId, super.key});

  final String tenantId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => OrgConfigBloc(
      organizationRepository: context.read<OrganizationRepository>(),
      tenantId: tenantId,
    ),
    child: const _OrganizationConfigView(),
  );
}

class _OrganizationConfigView extends StatelessWidget {
  const _OrganizationConfigView();

  @override
  Widget build(BuildContext context) =>
      BlocListener<OrgConfigBloc, OrgConfigState>(
        listenWhen: (prev, curr) {
          if (curr is! OrgConfigReady) return false;
          if (prev is! OrgConfigReady) return false;
          return prev.saveStatus != curr.saveStatus;
        },
        listener: (context, state) {
          if (state is! OrgConfigReady) return;
          switch (state.saveStatus) {
            case OrgConfigSaveStatus.success:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Modifications enregistrées.')),
              );
              context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
            case OrgConfigSaveStatus.failure:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.saveErrorMessage ??
                        "Échec de l'enregistrement des modifications",
                  ),
                ),
              );
            case OrgConfigSaveStatus.idle:
            case OrgConfigSaveStatus.saving:
              break;
          }
        },
        child: BlocBuilder<OrgConfigBloc, OrgConfigState>(
          builder: (context, state) => switch (state) {
            OrgConfigLoading() => const ConnectedScaffold(
              title: _kScreenTitle,
              body: Center(child: CircularProgressIndicator()),
            ),
            OrgConfigMissing() => const ConnectedScaffold(
              title: _kScreenTitle,
              body: Center(
                child: Text(
                  'Organisation non disponible. Vérifiez la synchronisation.',
                ),
              ),
            ),
            OrgConfigReady(:final organization, :final saveStatus) =>
              _IdentityForm(organization: organization, saveStatus: saveStatus),
          },
        ),
      );
}

class _IdentityForm extends StatefulWidget {
  const _IdentityForm({required this.organization, required this.saveStatus});

  final Organization organization;
  final OrgConfigSaveStatus saveStatus;

  @override
  State<_IdentityForm> createState() => _IdentityFormState();
}

class _IdentityFormState extends State<_IdentityForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late String _timezone;
  late final TextEditingController _languageCtrl;
  late final TextEditingController _websiteCtrl;

  @override
  void initState() {
    super.initState();
    final org = widget.organization;
    _nameCtrl = TextEditingController(text: org.name);
    _emailCtrl = TextEditingController(text: org.contactEmail);
    _timezone = org.timezone ?? kSupportedTimezones.first;
    _languageCtrl = TextEditingController(text: org.defaultLanguage ?? '');
    _websiteCtrl = TextEditingController(text: org.website ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _languageCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<OrgConfigBloc>().add(
      OrgConfigEvent.saved(
        name: _nameCtrl.text,
        contactEmail: _emailCtrl.text,
        timezone: _timezone,
        defaultLanguage: _languageCtrl.text.trim(),
        website: _websiteCtrl.text.trim().isEmpty
            ? null
            : _websiteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = widget.saveStatus == OrgConfigSaveStatus.saving;
    return ConnectedScaffold(
      title: _kScreenTitle,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(context, "Identité de l'AMAP", _identityFields()),
              const SizedBox(height: 12),
              _section(context, 'Paramètres régionaux', _regionalFields()),
              const SizedBox(height: 12),
              _section(context, 'Présence en ligne', _onlineFields()),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('org_config_save_button'),
                onPressed: isSaving ? null : _save,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ENREGISTRER LES MODIFICATIONS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A titled card grouping one section of the form.
  Widget _section(BuildContext context, String title, List<Widget> fields) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ...fields,
            ],
          ),
        ),
      );

  List<Widget> _identityFields() => [
    TextFormField(
      key: const Key('org_config_name'),
      controller: _nameCtrl,
      decoration: const InputDecoration(
        labelText: "Nom de l'organisation *",
        border: OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.trim().isEmpty)
          ? kFieldRequiredMessage
          : requiredName(v),
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 12),
    TextFormField(
      key: const Key('org_config_email'),
      controller: _emailCtrl,
      decoration: const InputDecoration(
        labelText: 'Email de contact *',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return kFieldRequiredMessage;
        }
        if (!isValidEmail(v)) {
          return kInvalidEmailMessage;
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    ),
  ];

  List<Widget> _regionalFields() => [
    DropdownButtonFormField<String>(
      key: const Key('org_config_timezone'),
      initialValue: _timezone,
      decoration: const InputDecoration(
        labelText: 'Fuseau horaire *',
        border: OutlineInputBorder(),
      ),
      items: [
        // Keep a legacy zone outside the list selectable.
        for (final zone in {...kSupportedTimezones, _timezone})
          DropdownMenuItem(value: zone, child: Text(zone)),
      ],
      onChanged: (zone) {
        if (zone != null) setState(() => _timezone = zone);
      },
    ),
    const SizedBox(height: 12),
    TextFormField(
      key: const Key('org_config_language'),
      controller: _languageCtrl,
      decoration: const InputDecoration(
        labelText: 'Langue par défaut *',
        hintText: 'ex. fr',
        border: OutlineInputBorder(),
      ),
      validator: requiredLanguageCode,
      textInputAction: TextInputAction.next,
    ),
  ];

  List<Widget> _onlineFields() => [
    TextFormField(
      key: const Key('org_config_website'),
      controller: _websiteCtrl,
      decoration: const InputDecoration(
        labelText: 'Site web',
        hintText: 'https://…',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.url,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        if (!isValidHttpUrl(v)) {
          return kInvalidUrlMessage;
        }
        return null;
      },
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _save(),
    ),
  ];
}
