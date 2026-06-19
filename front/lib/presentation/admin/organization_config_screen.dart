import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/admin/organization_config_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen title — kept as a constant so tests can find it by text.
const _kScreenTitle = "Configuration de l'organisation";

/// Minimal email-format check (must contain exactly one '@' with non-empty
/// parts on both sides). Full RFC-5322 parsing is out of scope for an
/// offline-first admin form; a backend upsert will validate the server side.
bool _isValidEmail(String value) {
  final atIndex = value.indexOf('@');
  if (atIndex <= 0) return false;
  final parts = value.split('@');
  if (parts.length != 2) return false;
  return parts[0].isNotEmpty && parts[1].contains('.');
}

/// Minimal URL check: must start with http:// or https:// and have a non-empty
/// host. A website field is optional but, when provided, should be linkable.
bool _isValidUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return false;
  return (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

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
  Widget build(BuildContext context) => BlocListener<OrgConfigBloc, OrgConfigState>(
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
              const SnackBar(
                content: Text('Modifications enregistrées.'),
              ),
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
            _IdentityForm(
              organization: organization,
              saveStatus: saveStatus,
            ),
        },
      ),
    );
}

class _IdentityForm extends StatefulWidget {
  const _IdentityForm({
    required this.organization,
    required this.saveStatus,
  });

  final Organization organization;
  final OrgConfigSaveStatus saveStatus;

  @override
  State<_IdentityForm> createState() => _IdentityFormState();
}

class _IdentityFormState extends State<_IdentityForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _timezoneCtrl;
  late final TextEditingController _languageCtrl;
  late final TextEditingController _websiteCtrl;

  @override
  void initState() {
    super.initState();
    final org = widget.organization;
    _nameCtrl = TextEditingController(text: org.name);
    _emailCtrl = TextEditingController(text: org.contactEmail);
    _timezoneCtrl = TextEditingController(text: org.timezone ?? '');
    _languageCtrl = TextEditingController(text: org.defaultLanguage ?? '');
    _websiteCtrl = TextEditingController(text: org.website ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _timezoneCtrl.dispose();
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
        timezone: _timezoneCtrl.text.trim().isEmpty
            ? null
            : _timezoneCtrl.text.trim(),
        defaultLanguage: _languageCtrl.text.trim().isEmpty
            ? null
            : _languageCtrl.text.trim(),
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
              // --- Section 1 : Identité de l'AMAP ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Identité de l'AMAP",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('org_config_name'),
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nom de l'organisation *",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Le nom est requis'
                            : null,
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
                            return "L'email de contact est requis";
                          }
                          if (!_isValidEmail(v.trim())) {
                            return "L'adresse email n'est pas valide";
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // --- Section 2 : Paramètres régionaux ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Paramètres régionaux',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('org_config_timezone'),
                        controller: _timezoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fuseau horaire',
                          hintText: 'ex. Europe/Paris',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('org_config_language'),
                        controller: _languageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Langue par défaut',
                          hintText: 'ex. fr',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // --- Section 3 : Présence en ligne ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Présence en ligne',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
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
                          if (!_isValidUrl(v.trim())) {
                            return "L'URL n'est pas valide (ex. https://…)";
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                      ),
                    ],
                  ),
                ),
              ),
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
}
