import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/presentation/common/terms_checkbox_tile.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_bloc.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_event.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProducerRequestScreen extends StatelessWidget {
  const ProducerRequestScreen({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
  });

  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProducerRequestBloc(publicApi: context.read<PublicApi>()),
      child: _ProducerRequestView(
        initialFirstName: initialFirstName,
        initialLastName: initialLastName,
        initialEmail: initialEmail,
      ),
    );
  }
}

class _ProducerRequestView extends StatelessWidget {
  const _ProducerRequestView({
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
  });

  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Demande Producteur'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: BlocBuilder<ProducerRequestBloc, ProducerRequestState>(
        builder: (context, state) {
          if (state is ProducerRequestSuccess) {
            return _SuccessView(requestId: state.response.requestId);
          }
          return _FormView(
            state: state,
            initialFirstName: initialFirstName,
            initialLastName: initialLastName,
            initialEmail: initialEmail,
          );
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
                'Demande producteur soumise',
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
            const Text('2. Validation de votre compte producteur'),
            const Text('3. Réception du lien d’activation par email'),
          ],
        ),
      ),
    );
  }
}

class _FormView extends StatefulWidget {
  const _FormView({
    required this.state,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
  });

  final ProducerRequestState state;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  final _producerNameController = TextEditingController();
  final _submitterCommentController = TextEditingController();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.initialFirstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.initialLastName ?? '',
    );
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _producerNameController.dispose();
    _submitterCommentController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) return;
    context.read<ProducerRequestBloc>().add(
      ProducerRequestEvent.submitted(
        producerName: _producerNameController.text.trim(),
        adminFirstName: _firstNameController.text.trim(),
        adminLastName: _lastNameController.text.trim(),
        adminEmail: _emailController.text.trim(),
        submitterComment: _submitterCommentController.text.trim().isEmpty
            ? null
            : _submitterCommentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitting = widget.state is ProducerRequestSubmitting;
    final error = widget.state is ProducerRequestError
        ? (widget.state as ProducerRequestError).message
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
                  'Créer un compte producteur',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Votre demande sera examinée par notre équipe. '
                  'Vous recevrez une confirmation par email sous 3 jours ouvrés.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                _SectionHeader(label: 'INFORMATIONS PRODUCTEUR'),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('producer_name'),
                  controller: _producerNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nom du producteur *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requireNonEmpty,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 24),
                _SectionHeader(label: 'COMPTE ADMINISTRATEUR PRODUCTEUR'),
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
                _SectionHeader(label: 'MESSAGE (OPTIONNEL)'),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('submitter_comment'),
                  controller: _submitterCommentController,
                  decoration: const InputDecoration(
                    labelText: 'Informations complémentaires',
                    hintText:
                        'Présentez votre exploitation, vos produits, vos questions…',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 2000,
                ),
                const SizedBox(height: 24),
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
                        onPressed: submitting ? null : _submit,
                        child: Text(
                          submitting ? 'ENVOI...' : 'ENVOYER LA DEMANDE',
                        ),
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

  String? _requireNonEmpty(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Ce champ est requis.';
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Ce champ est requis.';
    if (!trimmed.contains('@')) return 'Email invalide.';
    return null;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
