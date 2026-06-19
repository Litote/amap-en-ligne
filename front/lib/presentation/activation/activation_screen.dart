import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Activation screen reached from the link in the activation email.
///
/// The [token] is extracted from the URL query parameter `?token=...` by
/// go_router and passed directly to this widget.  No BLoC — plain
/// [StatefulWidget] with [setState] is sufficient for the simple
/// form/loading/success/error lifecycle.
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key, required this.token});

  final String token;

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  ActivationResult? _result;
  ActivationError? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<PublicApi>().activate(
        token: widget.token,
        password: _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _result = result;
        });
      }
    } on ActivationException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.error;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = ActivationError.serverError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _result != null
                ? _SuccessCard(
                    result: _result!,
                    onLogin: () async {
                      final router = GoRouter.of(context);
                      await _rememberUserContext(_result!.email);
                      if (!mounted) return;
                      router.go(
                        '/login?email=${Uri.encodeQueryComponent(_result!.email)}',
                      );
                    },
                  )
                : _FormCard(
                    formKey: _formKey,
                    passwordController: _passwordController,
                    confirmController: _confirmController,
                    obscurePassword: _obscurePassword,
                    obscureConfirm: _obscureConfirm,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onToggleConfirm: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    loading: _loading,
                    error: _error,
                    onSubmit: _submit,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _rememberUserContext(String email) async {
    if (email.isEmpty) return;
    final store = context.read<RememberedUserContextStore>();
    final server = context.read<ServerConfig>();
    final remembered = await store.read(serverId: server.id);
    await store.write(
      RememberedUserContext(
        email: email,
        serverId: server.id,
        rememberMe: remembered?.rememberMe ?? !kIsWeb,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success card
// ---------------------------------------------------------------------------

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.result, required this.onLogin});

  final ActivationResult result;
  final Future<void> Function() onLogin;

  String _successMessage() {
    switch (result.kind) {
      case ActivationKind.owner:
        return 'Votre compte Owner a été activé. '
            'Vous pouvez maintenant vous connecter.';
      case ActivationKind.producer:
        final producerName = result.organizationName ?? '';
        return 'Votre compte producteur pour $producerName a été activé.';
      case ActivationKind.organizationAdmin:
        final orgName = result.organizationName ?? '';
        return 'Votre compte pour $orgName a été activé.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Compte activé',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(_successMessage(), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => onLogin(),
              child: const Text('SE CONNECTER'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form card
// ---------------------------------------------------------------------------

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final bool loading;
  final ActivationError? error;
  final VoidCallback onSubmit;

  String? _validatePassword(String? v) {
    final val = v ?? '';
    if (val.isEmpty) return 'Le mot de passe est requis.';
    if (val.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  String? get _errorMessage {
    if (error == null) return null;
    return switch (error!) {
      ActivationError.invalidToken => "Ce lien d'activation est invalide.",
      ActivationError.expired =>
        "Ce lien d'activation a expiré. Contactez l'administrateur.",
      ActivationError.alreadyActivated =>
        'Ce compte a déjà été activé. Connectez-vous.',
      ActivationError.serverError =>
        'Une erreur est survenue. Veuillez réessayer.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Activer votre compte',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisissez un mot de passe pour finaliser la création de votre compte.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('password'),
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Mot de passe *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: onTogglePassword,
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('confirm_password'),
                controller: confirmController,
                obscureText: obscureConfirm,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: onToggleConfirm,
                  ),
                ),
                validator: _validateConfirm,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('submit'),
                onPressed: loading ? null : onSubmit,
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ACTIVER MON COMPTE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
