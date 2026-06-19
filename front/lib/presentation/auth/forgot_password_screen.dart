import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_event.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_view_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordBloc(service: context.read<AuthService>()),
      child: _ForgotPasswordView(initialEmail: initialEmail),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView({this.initialEmail});

  final String? initialEmail;

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _requestFormKey = GlobalKey<FormState>();
  final _confirmFormKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (!_requestFormKey.currentState!.validate()) return;
    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordEvent.resetRequested(
        email: _emailController.text.trim(),
        redirectTo: kIsWeb ? '${Uri.base.origin}/reset-password' : null,
      ),
    );
  }

  void _submitConfirm(String email) {
    if (!_confirmFormKey.currentState!.validate()) return;
    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordEvent.confirmRequested(
        email: email,
        token: _tokenController.text.trim(),
        newPassword: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordBloc, ForgotPasswordViewState>(
      listenWhen: (prev, curr) => !prev.success && curr.success,
      listener: (context, state) async {
        final messenger = ScaffoldMessenger.of(context);
        final router = GoRouter.of(context);
        await _rememberUserContext(state.email ?? _emailController.text.trim());
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Mot de passe réinitialisé.')),
        );
        router.go(
          '/login?email=${Uri.encodeQueryComponent(state.email ?? _emailController.text.trim())}',
        );
      },
      child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordViewState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.codeSent ? 'Réinitialisation' : 'Mot de passe oublié',
              ),
              leading: BackButton(onPressed: () => context.go('/login')),
            ),
            body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  child: state.codeSent
                      ? _ConfirmForm(
                          formKey: _confirmFormKey,
                          tokenController: _tokenController,
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          submitting: state.submitting,
                          lastError: state.lastError,
                          email: state.email ?? '',
                          onSubmit: () => _submitConfirm(state.email ?? ''),
                        )
                      : _RequestForm(
                          formKey: _requestFormKey,
                          emailController: _emailController,
                          submitting: state.submitting,
                          lastError: state.lastError,
                          onSubmit: _submitRequest,
                        ),
                ),
              ),
            ),
          );
        },
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

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.formKey,
    required this.emailController,
    required this.submitting,
    required this.lastError,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool submitting;
  final AuthError? lastError;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Récupération de votre mot de passe',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Saisissez votre adresse email pour recevoir un code de réinitialisation.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('forgot_email'),
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: _validateEmail,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 24),
          if (lastError != null) ...[
            Text(
              _requestErrorMessage(lastError!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            key: const Key('forgot_submit'),
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ENVOYER LE CODE'),
          ),
          const SizedBox(height: 16),
          Text(
            'Le code expirera dans 1 heure.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'L\'email est requis.';
    if (!v.contains('@') || !v.contains('.')) {
      return 'Saisissez un email valide.';
    }
    return null;
  }

  static String _requestErrorMessage(AuthError error) {
    switch (error) {
      case AuthError.network:
        return 'Erreur réseau. Vérifiez votre connexion et réessayez.';
      default:
        return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }
}

class _ConfirmForm extends StatelessWidget {
  const _ConfirmForm({
    required this.formKey,
    required this.tokenController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.submitting,
    required this.lastError,
    required this.email,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController tokenController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool submitting;
  final AuthError? lastError;
  final String email;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nouveau mot de passe',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Saisissez le code reçu par email et choisissez un nouveau mot de passe.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('forgot_token'),
            controller: tokenController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Code de réinitialisation',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Code requis' : null,
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('forgot_new_password'),
            controller: passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Le mot de passe est requis.';
              if (v.length < 6) {
                return 'Le mot de passe doit contenir au moins 6 caractères.';
              }
              return null;
            },
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('forgot_confirm_password'),
            controller: confirmPasswordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v != passwordController.text) {
                return 'Les mots de passe ne correspondent pas.';
              }
              return null;
            },
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 24),
          if (lastError != null) ...[
            Text(
              _confirmErrorMessage(lastError!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            key: const Key('forgot_confirm_submit'),
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('RÉINITIALISER'),
          ),
        ],
      ),
    );
  }

  static String _confirmErrorMessage(AuthError error) {
    switch (error) {
      case AuthError.invalidOrExpiredToken:
        return 'Ce lien a expiré ou est invalide. Recommencez depuis « Mot de passe oublié ».';
      case AuthError.weakPassword:
        return 'Mot de passe trop faible. Choisissez un mot de passe plus sécurisé.';
      case AuthError.samePassword:
        return 'Le nouveau mot de passe doit être différent de l\'ancien.';
      case AuthError.network:
        return 'Erreur réseau. Vérifiez votre connexion et réessayez.';
      default:
        return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }
}
