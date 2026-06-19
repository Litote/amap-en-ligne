import 'package:amap_en_ligne/data/web_initial_fragment.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _success = false;
  AuthError? _error;
  String? _accessToken;
  String? _refreshToken;
  int? _expiresIn;

  @override
  void initState() {
    super.initState();
    _parseFragmentParams();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Parses access_token, refresh_token, expires_in from the URL fragment.
  // Uses the fragment captured before go_router strips it from the URL.
  void _parseFragmentParams() {
    final fragment = webInitialFragment ?? Uri.base.fragment;
    if (fragment.isEmpty) return;
    final params = Uri.splitQueryString(fragment);
    if (params['type'] != 'recovery') return;
    _accessToken = params['access_token'];
    _refreshToken = params['refresh_token'];
    _expiresIn = int.tryParse(params['expires_in'] ?? '');
  }

  Future<void> _submit() async {
    final accessToken = _accessToken;
    if (accessToken == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().updatePassword(
        accessToken: accessToken,
        newPassword: _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _success = true;
        });
      }
    } on AuthException catch (e) {
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
          _error = AuthError.unknown;
        });
      }
    }
  }

  String _errorMessage(AuthError error) => switch (error) {
    AuthError.invalidOrExpiredToken =>
      'Ce lien a expiré ou est invalide. Demandez un nouveau lien depuis « Mot de passe oublié ».',
    AuthError.weakPassword =>
      'Mot de passe trop faible. Choisissez un mot de passe plus sécurisé.',
    AuthError.samePassword =>
      'Le nouveau mot de passe doit être différent de l\'ancien.',
    AuthError.network =>
      'Erreur réseau. Vérifiez votre connexion et réessayez.',
    _ => 'Une erreur est survenue. Veuillez réessayer.',
  };

  Widget _buildInvalidTokenView(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lien de réinitialisation invalide.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/forgot-password'),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _SuccessCard(
            onLogin: () async {
              final at = _accessToken;
              final rt = _refreshToken;
              final authService = context.read<AuthService>();
              final router = GoRouter.of(context);
              if (at != null && rt != null) {
                await authService.signInWithSession(
                  accessToken: at,
                  refreshToken: rt,
                  expiresIn: _expiresIn,
                );
              }
              // Navigate to /login — the router redirect fires immediately
              // and sends authenticated users to /product-types.
              if (mounted) router.go('/login');
            },
          ),
        ),
      ),
    );
  }

  String? _passwordValidator(String? v) {
    final val = v ?? '';
    if (val.isEmpty) return 'Le mot de passe est requis.';
    if (val.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    return null;
  }

  String? _confirmValidator(String? v) {
    if (v != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_accessToken == null) return _buildInvalidTokenView(context);
    if (_success) return _buildSuccessView(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau mot de passe'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choisissez un nouveau mot de passe',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('reset_password'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: _passwordValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('reset_confirm_password'),
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: _confirmValidator,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage(_error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('reset_submit'),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('RÉINITIALISER MON MOT DE PASSE'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success card
// ---------------------------------------------------------------------------

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.onLogin});

  final Future<void> Function() onLogin;

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
              'Mot de passe réinitialisé',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous pouvez maintenant accéder à votre espace.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('reset_login'),
              onPressed: onLogin,
              child: const Text('SE CONNECTER'),
            ),
          ],
        ),
      ),
    );
  }
}
