import 'package:flutter/material.dart';

/// Eye button toggling a password field's visibility. The tooltip names the
/// action, so screen readers do not announce an unlabelled button.
class PasswordVisibilityButton extends StatelessWidget {
  const PasswordVisibilityButton({
    required this.obscured,
    required this.onPressed,
    super.key,
  });

  /// Whether the password is currently hidden.
  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: obscured ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
    icon: Icon(obscured ? Icons.visibility : Icons.visibility_off),
    onPressed: onPressed,
  );
}
