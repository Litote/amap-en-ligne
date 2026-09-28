import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown by the router for any unknown location (replaces go_router's default
/// English "Page Not Found" page).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 16),
            Text(
              'Page introuvable',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              "Cette adresse ne correspond à aucune page de l'application.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text("RETOUR À L'ACCUEIL"),
            ),
          ],
        ),
      ),
    ),
  );
}
