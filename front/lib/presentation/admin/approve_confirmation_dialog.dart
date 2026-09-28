import 'package:flutter/material.dart';

/// Asks the owner to confirm an approval — mirroring the reject flow, which
/// already goes through a dialog. Resolves to `true` only on explicit confirm.
Future<bool> confirmApproval(
  BuildContext context, {
  required String message,
}) async =>
    await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approuver la demande ?'),
        semanticLabel: 'Approuver la demande ?',
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Approuver'),
          ),
        ],
      ),
    ) ??
    false;

/// Success feedback shown once an approval went through.
const kApprovalSuccessMessage =
    "Demande approuvée : le lien d'activation a été envoyé.";

/// Success feedback shown once a rejection went through.
const kRejectionSuccessMessage = 'Demande rejetée.';

/// Success feedback shown once an activation link was sent again.
const kResendSuccessMessage = "Lien d'activation renvoyé.";
