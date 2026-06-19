import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:flutter/material.dart';

/// Confirm dialog for "Suspendre le compte" on an Owner row.
class ConfirmSuspendOwnerDialog extends StatelessWidget {
  const ConfirmSuspendOwnerDialog({super.key, required this.userRow});

  final UserRow userRow;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Suspendre le compte'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Utilisateur : ${userRow.displayName} (${userRow.email})'),
          const SizedBox(height: 12),
          const Text(
            "La suspension bloque l'authentification de l'utilisateur sur "
            "l'instance sans toucher à ses rôles. Les sessions actives "
            "sont invalidées et l'utilisateur reçoit un email de "
            "notification. L'action est réversible via « Réactiver le "
            "compte ».",
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          key: const Key('confirm_suspend_button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('SUSPENDRE'),
        ),
      ],
    );
  }
}

/// Confirm dialog for "Réactiver le compte" on a suspended Owner row.
class ConfirmReactivateOwnerDialog extends StatelessWidget {
  const ConfirmReactivateOwnerDialog({super.key, required this.userRow});

  final UserRow userRow;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Réactiver le compte'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Utilisateur : ${userRow.displayName} (${userRow.email})'),
          const SizedBox(height: 12),
          const Text(
            "La réactivation rétablit l'authentification de l'utilisateur "
            "sur l'instance. Les rôles sont conservés et l'utilisateur "
            "reçoit un email de notification.",
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          key: const Key('confirm_reactivate_button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('RÉACTIVER'),
        ),
      ],
    );
  }
}

/// Confirm dialog for "Suspendre le compte" on a Producteur row.
class ConfirmSuspendProducerDialog extends StatelessWidget {
  const ConfirmSuspendProducerDialog({super.key, required this.userRow});

  final UserRow userRow;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Suspendre le producteur'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Producteur : ${userRow.producerAccountName ?? userRow.displayName}',
          ),
          const SizedBox(height: 12),
          const Text(
            "La suspension marque le producteur comme inactif. Les AMAPs "
            "rattachées voient le statut à jour, mais la fiche est "
            "conservée. L'action est réversible via « Réactiver ».",
          ),
          const SizedBox(height: 8),
          const Text(
            "Note : les comptes des utilisateurs PRODUCER liés ne sont pas "
            "bannis individuellement à ce stade (phase 2.5).",
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          key: const Key('confirm_suspend_button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('SUSPENDRE'),
        ),
      ],
    );
  }
}

/// Confirm dialog for "Réactiver" on a suspended Producteur row.
class ConfirmReactivateProducerDialog extends StatelessWidget {
  const ConfirmReactivateProducerDialog({super.key, required this.userRow});

  final UserRow userRow;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Réactiver le producteur'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Producteur : ${userRow.producerAccountName ?? userRow.displayName}',
          ),
          const SizedBox(height: 12),
          const Text(
            "La réactivation rétablit le statut actif du producteur. Les "
            "AMAPs rattachées le voient à nouveau disponible.",
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          key: const Key('confirm_reactivate_button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('RÉACTIVER'),
        ),
      ],
    );
  }
}

/// Confirm dialog for "Supprimer de l'instance" on an Owner row. Includes
/// the RGPD-driven explanation of what is anonymised vs deleted.
class ConfirmDeleteOwnerDialog extends StatelessWidget {
  const ConfirmDeleteOwnerDialog({super.key, required this.userRow});

  final UserRow userRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text("Supprimer de l'instance"),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Utilisateur : ${userRow.displayName} (${userRow.email})'),
          const SizedBox(height: 12),
          Text(
            'Action irréversible',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "La suppression :\n"
            "  • retire le rôle Owner ;\n"
            "  • supprime le compte du fournisseur d'authentification "
            "(sessions invalidées) ;\n"
            "  • écrit une entrée d'audit privacy-preserving (RGPD).\n"
            "\n"
            "L'utilisateur reçoit un email de notification. Les autres "
            "Owners sont informés de l'action sans que l'identité de "
            "l'utilisateur supprimé ne leur soit transmise.",
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          key: const Key('confirm_delete_button'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: const Text('SUPPRIMER DÉFINITIVEMENT'),
        ),
      ],
    );
  }
}

/// Confirm dialog for "Supprimer de l'instance" on a Producteur row.
/// Phase 2.5 semantics: the producer entity is kept (marked inactive), the
/// auth users tied to it are deleted from the auth provider.
class ConfirmDeleteProducerDialog extends StatelessWidget {
  const ConfirmDeleteProducerDialog({super.key, required this.userRow});

  final UserRow userRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text("Supprimer le producteur"),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Producteur : ${userRow.producerAccountName ?? userRow.displayName}',
          ),
          const SizedBox(height: 12),
          Text(
            'Action irréversible — confirmation renforcée',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "La suppression :\n"
            "  • supprime tous les comptes utilisateurs Producteur liés "
            "(sessions invalidées) ;\n"
            "  • écrit une entrée d'audit privacy-preserving par compte "
            "supprimé (RGPD — hash SHA-256 du sub).\n"
            "\n"
            "La fiche du producteur est **conservée** et passe en statut "
            "« Suspendu ». Elle pourra être rattachée à un autre "
            "utilisateur plus tard.",
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          key: const Key('confirm_delete_button'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: const Text('SUPPRIMER DÉFINITIVEMENT'),
        ),
      ],
    );
  }
}

/// Confirm dialog for "Suspendre le compte" on an AMAP member row.
class ConfirmSuspendMemberDialog extends StatelessWidget {
  const ConfirmSuspendMemberDialog({super.key, required this.userRow});

  final UserRow userRow;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Suspendre le compte'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Utilisateur : ${userRow.displayName}'),
          if (userRow.email.isNotEmpty) Text(userRow.email),
          const SizedBox(height: 12),
          const Text(
            "La suspension bloque l'authentification de l'utilisateur sur "
            "l'instance. Toutes ses appartenances AMAP passent en statut "
            "« suspendu » mais les rôles sont conservés pour permettre une "
            "réactivation propre.",
          ),
          const SizedBox(height: 8),
          const Text(
            "Si l'utilisateur est seul Admin d'une AMAP, l'action sera "
            "refusée — désignez d'abord un autre Admin.",
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          key: const Key('confirm_suspend_button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('SUSPENDRE'),
        ),
      ],
    );
  }
}

/// Confirm dialog for "Réactiver le compte" on a suspended AMAP member.
class ConfirmReactivateMemberDialog extends StatelessWidget {
  const ConfirmReactivateMemberDialog({super.key, required this.userRow});

  final UserRow userRow;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Réactiver le compte'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Utilisateur : ${userRow.displayName}'),
          const SizedBox(height: 12),
          const Text(
            "La réactivation rétablit l'authentification de l'utilisateur "
            "et réactive toutes ses appartenances AMAP.",
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          key: const Key('confirm_reactivate_button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('RÉACTIVER'),
        ),
      ],
    );
  }
}

/// Confirm dialog for "Supprimer de l'instance" on an AMAP member row.
class ConfirmDeleteMemberDialog extends StatelessWidget {
  const ConfirmDeleteMemberDialog({super.key, required this.userRow});

  final UserRow userRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text("Supprimer de l'instance"),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Utilisateur : ${userRow.displayName}'),
          const SizedBox(height: 12),
          Text(
            'Action irréversible — confirmation renforcée',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "La suppression :\n"
            "  • supprime le compte du fournisseur d'authentification "
            "(sessions invalidées) ;\n"
            "  • anonymise toutes les appartenances AMAP (sub retiré, "
            "statut « suspendu ») — les lignes techniques sont conservées "
            "pour préserver l'historique des contrats et livraisons ;\n"
            "  • écrit une entrée d'audit privacy-preserving par AMAP "
            "(RGPD — hash SHA-256 du sub).\n"
            "\n"
            "Si l'utilisateur est seul Admin d'une AMAP, l'action sera "
            "refusée.",
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          key: const Key('confirm_delete_member_button'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: const Text('SUPPRIMER DÉFINITIVEMENT'),
        ),
      ],
    );
  }
}
