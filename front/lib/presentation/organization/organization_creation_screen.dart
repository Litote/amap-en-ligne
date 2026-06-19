import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/organization_creation_request.dart';
import 'package:amap_en_ligne/presentation/common/terms_checkbox_tile.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_bloc.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_event.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class OrganizationCreationScreen extends StatelessWidget {
  const OrganizationCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OrganizationCreationBloc(publicApi: context.read<PublicApi>()),
      child: const _OrganizationCreationView(),
    );
  }
}

class _OrganizationCreationView extends StatelessWidget {
  const _OrganizationCreationView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle AMAP'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: BlocBuilder<OrganizationCreationBloc, OrganizationCreationState>(
        builder: (context, state) {
          if (state is OrganizationCreationSuccess) {
            return _SuccessView(requestId: state.response.requestId);
          }
          return _FormView(state: state);
        },
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                "Demande de création d'AMAP soumise",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Un email de confirmation vous a été envoyé.\n'
                'Délai de traitement habituel : moins de 3 jours ouvrés.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Référence : $requestId',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const _NextStepsCard(),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text("RETOUR À L'ACCUEIL"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prochaines étapes :',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const Text('1. Examen de votre demande par notre équipe'),
            const Text("2. Activation de votre organisation"),
            const Text("3. Accès à votre espace d'administration"),
          ],
        ),
      ),
    );
  }
}

class _FormView extends StatefulWidget {
  const _FormView({required this.state});

  final OrganizationCreationState state;

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _submitterCommentController = TextEditingController();
  final String _timezone = 'Europe/Paris';
  final String _language = 'fr';
  bool _termsAccepted = false;

  @override
  void dispose() {
    _orgNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _submitterCommentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) return;
    context.read<OrganizationCreationBloc>().add(
      OrganizationCreationEvent.submitted(
        organizationName: _orgNameController.text.trim(),
        timezone: _timezone,
        defaultLanguage: _language,
        adminFirstName: _firstNameController.text.trim(),
        adminLastName: _lastNameController.text.trim(),
        adminEmail: _emailController.text.trim(),
        organizationType: OrganizationType.amap,
        submitterComment: _submitterCommentController.text.trim().isEmpty
            ? null
            : _submitterCommentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitting = widget.state is OrganizationCreationSubmitting;
    final error = widget.state is OrganizationCreationError
        ? (widget.state as OrganizationCreationError).message
        : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Créer une nouvelle AMAP',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Votre demande sera examinée par notre équipe. '
                  'Vous recevrez une confirmation par email sous 3 jours ouvrés.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(label: 'INFORMATIONS AMAP'),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('org_name'),
                  controller: _orgNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Nom de l'AMAP *",
                    border: OutlineInputBorder(),
                  ),
                  validator: _requireNonEmpty,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(
                  label: "COMPTE ADMINISTRATEUR DE L'ORGANISATION",
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('first_name'),
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requireNonEmpty,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('last_name'),
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requireNonEmpty,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('admin_email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(label: 'MESSAGE (OPTIONNEL)'),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('submitter_comment'),
                  controller: _submitterCommentController,
                  decoration: const InputDecoration(
                    labelText: 'Informations complémentaires',
                    hintText:
                        'Décrivez votre projet, votre contexte, vos questions…',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 2000,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: submitting
                        ? null
                        : () => context.push(
                            '/register/producer',
                            extra: {
                              'firstName': _firstNameController.text.trim(),
                              'lastName': _lastNameController.text.trim(),
                              'email': _emailController.text.trim(),
                            },
                          ),
                    child: const Text('Vous êtes producteur ?'),
                  ),
                ),
                const SizedBox(height: 8),
                TermsCheckboxTile(
                  key: const Key('terms'),
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: submitting ? null : () => context.go('/'),
                        child: const Text('ANNULER'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('submit'),
                        onPressed: (submitting || !_termsAccepted)
                            ? null
                            : _submit,
                        child: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('CRÉER'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _requireNonEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requis.';
    return null;
  }

  static String? _validateEmail(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'L\'email est requis.';
    if (!val.contains('@') || !val.contains('.')) {
      return 'Saisissez un email valide.';
    }
    return null;
  }
}

// ignore: unused_element
class _ControlledDropdown<T> extends StatelessWidget {
  const _ControlledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
