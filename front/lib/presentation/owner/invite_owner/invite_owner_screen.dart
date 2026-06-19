import 'package:amap_en_ligne/data/repositories/owner_invitation_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_outcome.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/sync/mutation_outcome.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Dedicated screen for inviting a new Owner (instance administrator).
///
/// Mirrors `documentation/feature/fr/ui/owner/screen-owner-04-invite-owner.md`:
/// form fields (Prénom, Nom, Email), informational block on the consequences
/// of the invitation, and a confirmation view after a successful submit.
class InviteOwnerScreen extends StatefulWidget {
  const InviteOwnerScreen({super.key});

  static const String _title = 'Nouvel Administrateur';

  @override
  State<InviteOwnerScreen> createState() => _InviteOwnerScreenState();
}

class _InviteOwnerScreenState extends State<InviteOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _loading = false;
  String? _conflictError;
  String? _confirmedEmail;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ce champ est requis.';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ce champ est requis.';
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Adresse email invalide.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _conflictError = null;
    });

    final repository = context.read<OwnerInvitationRepository>();
    final syncRepository = context.read<SyncRepository>();
    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    try {
      final clientOpId = await repository.create(
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
      final outcome = await syncRepository.sync(tenantId: '');
      if (outcome case SyncSuccess()) {
        final rejected = outcome.rejectedMutations
            .where((mutation) => mutation.clientOpId == clientOpId)
            .firstOrNull;
        if (rejected != null) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _conflictError = _mutationErrorMessage(rejected.error);
          });
          return;
        }
      } else if (outcome case SyncFailure()) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _conflictError =
              "L'envoi de l'invitation a échoué. Veuillez réessayer.";
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _confirmedEmail = email;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _conflictError =
            "L'envoi de l'invitation a échoué. Veuillez réessayer.";
      });
    }
  }

  void _resetForAnother() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _conflictError = null;
      _confirmedEmail = null;
    });
    _formKey.currentState?.reset();
  }

  String _mutationErrorMessage(MutationError? error) {
    if (error == null) {
      return "L'envoi de l'invitation a échoué. Veuillez réessayer.";
    }
    return switch (error.code) {
      MutationErrorCode.uniqueViolation || MutationErrorCode.conflict =>
        "Cette adresse email correspond déjà à un compte ou à une invitation en attente sur l'instance.",
      _ => error.message,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: InviteOwnerScreen._title,
      body: _confirmedEmail != null
          ? _ConfirmationView(
              email: _confirmedEmail!,
              onViewUsers: () => context.go('/owner/users'),
              onInviteAnother: _resetForAnother,
            )
          : _FormView(
              formKey: _formKey,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              emailController: _emailController,
              loading: _loading,
              conflictError: _conflictError,
              onSubmit: _submit,
              onCancel: () => context.go('/owner/dashboard'),
              validateRequired: _validateRequired,
              validateEmail: _validateEmail,
            ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.loading,
    required this.conflictError,
    required this.onSubmit,
    required this.onCancel,
    required this.validateRequired,
    required this.validateEmail,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final bool loading;
  final String? conflictError;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final String? Function(String?) validateRequired;
  final String? Function(String?) validateEmail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inviter un nouvel administrateur de l'instance",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IDENTITÉ', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('first_name_field'),
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateRequired,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('last_name_field'),
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateRequired,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('email_field'),
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: validateEmail,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => onSubmit(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Conséquences de l'invitation",
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "• Un email d'activation est envoyé à l'adresse "
                      "indiquée (lien valide 7 jours).\n"
                      "• Tant que l'activation n'est pas effectuée, le "
                      "compte apparaît en statut « Invité ».\n"
                      "• À l'activation, le rôle Owner est attribué.\n"
                      "• Owner est un rôle exclusif : aucune appartenance "
                      "AMAP ni rattachement producteur n'est créé.\n"
                      "• Les Owners existants reçoivent une notification.",
                    ),
                  ],
                ),
              ),
            ),
            if (conflictError != null) ...[
              const SizedBox(height: 12),
              Text(
                conflictError!,
                key: const Key('conflict_error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  key: const Key('cancel_button'),
                  onPressed: loading ? null : onCancel,
                  style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                  child: const Text('ANNULER'),
                ),
                FilledButton(
                  key: const Key('send_invitation_button'),
                  onPressed: loading ? null : onSubmit,
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("ENVOYER L'INVITATION"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({
    required this.email,
    required this.onViewUsers,
    required this.onInviteAnother,
  });

  final String email;
  final VoidCallback onViewUsers;
  final VoidCallback onInviteAnother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text('Invitation envoyée', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Un email d'activation a été envoyé à $email.",
            key: const Key('confirmation_message'),
          ),
          const SizedBox(height: 8),
          const Text(
            "Le compte apparaît dès maintenant dans la liste des "
            "utilisateurs avec le statut « Invité ». Il deviendra Owner "
            "à l'activation (lien valide 7 jours).",
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                key: const Key('view_users_button'),
                onPressed: onViewUsers,
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                child: const Text('VOIR LA LISTE DES UTILISATEURS'),
              ),
              FilledButton(
                key: const Key('invite_another_button'),
                onPressed: onInviteAnother,
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                child: const Text('INVITER UN AUTRE OWNER'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
