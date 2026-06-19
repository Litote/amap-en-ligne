import 'package:amap_en_ligne/data/server/server_presets.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:flutter/foundation.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_event.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/server/server_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _passwordController = TextEditingController();
  bool _rememberMe = !kIsWeb;
  bool _obscurePassword = true;
  bool _initialContextLoaded = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openServerSelection() {
    final onSelected = context.read<ValueChanged<ServerConfig>>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServerSelectionScreen(
          presets: serverPresets,
          onSelected: onSelected,
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthEvent.loginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialContextLoaded) return;
    _initialContextLoaded = true;
    _loadRememberedContext();
  }

  Future<void> _loadRememberedContext() async {
    final store = context.read<RememberedUserContextStore>();
    final serverConfig = context.read<ServerConfig>();
    final remembered = await store.read(serverId: serverConfig.id);
    if (!mounted || remembered == null) return;
    setState(() {
      if (_emailController.text.trim().isEmpty) {
        _emailController.text = remembered.email;
      }
      _rememberMe = remembered.rememberMe;
    });
  }

  @override
  Widget build(BuildContext context) {
    final serverConfig = context.read<ServerConfig>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: BlocBuilder<AuthBloc, AuthViewState>(
        builder: (context, state) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 48,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Connexion à votre compte',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      AutofillGroup(
                        child: Column(
                          children: [
                            TextFormField(
                              key: const Key('login_email'),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateEmail,
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('login_password'),
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
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
                              validator: _validatePassword,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        key: const Key('login_server'),
                        onTap: _openServerSelection,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Serveur',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.chevron_right),
                          ),
                          child: Text(
                            serverConfig.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CheckboxListTile(
                        key: const Key('login_remember_me'),
                        value: _rememberMe,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Se souvenir de moi'),
                        onChanged: state.submitting
                            ? null
                            : (value) {
                                setState(() => _rememberMe = value ?? false);
                              },
                      ),
                      const SizedBox(height: 8),
                      if (state.lastError != null) ...[
                        Text(
                          _errorMessage(state.lastError!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton(
                        key: const Key('login_submit'),
                        onPressed: state.submitting ? null : _submit,
                        child: state.submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('SE CONNECTER'),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          final email = _emailController.text.trim();
                          context.push(
                            '/forgot-password',
                            extra: email.isNotEmpty ? email : null,
                          );
                        },
                        child: const Text('Mot de passe oublié ?'),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Première connexion ? Vous devez avoir reçu une invitation '
                        'par email de votre coordinateur.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Pas d'invitation ? Contactez votre organisation ou "
                        'créez une nouvelle organisation depuis la page d\'accueil.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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

  static String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Le mot de passe est requis.';
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    return null;
  }

  static String _errorMessage(AuthError error) {
    switch (error) {
      case AuthError.invalidCredentials:
        return 'Email ou mot de passe incorrect.';
      case AuthError.network:
        return 'Erreur réseau. Vérifiez votre connexion et réessayez.';
      default:
        return 'Échec de l\'authentification. Veuillez réessayer.';
    }
  }
}
