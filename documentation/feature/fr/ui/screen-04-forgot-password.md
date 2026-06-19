# Mot de passe oublié

## Description

Écran de récupération de mot de passe accessible depuis la page de connexion via le lien "Mot de passe oublié". Route publique, non authentifiée.

Ce flux comporte deux étapes affichées sur le même écran — l'étape 2 remplace l'étape 1 sans navigation.

- **Route** : `/forgot-password`
- **Accès** : public, non authentifié
- **Point d'entrée** : lien "Mot de passe oublié" sur [screen-02-login.md](screen-02-login.md)

## Étape 1 — Demande de code

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ← Mot de passe oublié                       │
├─────────────────────────────────────────────┤
│                                             │
│  Récupération de votre mot de passe         │
│  Saisissez votre adresse email pour         │
│  recevoir un code de réinitialisation.      │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │ Email                               │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  [ENVOYER LE CODE]                          │
│                                             │
│  Le code expirera dans 1 heure.             │
│                                             │
└─────────────────────────────────────────────┘
```

### Contenu et comportement

- Titre de la page : "Mot de passe oublié"
- Le champ email est pré-rempli si l'adresse a été transmise en paramètre depuis la page de connexion.
- Le bouton [ENVOYER LE CODE] est désactivé pendant l'envoi.
- Un message sous le bouton indique : "Le code expirera dans 1 heure."
- [← Retour] dans l'AppBar ramène à `/login`.

### Gestion des erreurs

- Erreur réseau : "Erreur réseau. Vérifiez votre connexion et réessayez."

## Étape 2 — Saisie du code et nouveau mot de passe

L'étape 2 s'affiche sur le même écran en remplacement de l'étape 1, sans navigation.

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ← Réinitialisation                          │
├─────────────────────────────────────────────┤
│                                             │
│  Nouveau mot de passe                       │
│  Saisissez le code reçu par email et        │
│  choisissez un nouveau mot de passe.        │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │ Code de réinitialisation            │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ Nouveau mot de passe          [oeil]│    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ Confirmer le mot de passe     [oeil]│    │
│  └─────────────────────────────────────┘    │
│                                             │
│  [RÉINITIALISER]                            │
│                                             │
└─────────────────────────────────────────────┘
```

### Contenu et comportement

- Titre de la page : "Réinitialisation"
- Champ "Code de réinitialisation" : OTP à 6 chiffres reçu par email.
- Champ "Nouveau mot de passe" : minimum 6 caractères, avec icône d'affichage/masquage.
- Champ "Confirmer le mot de passe" : avec icône d'affichage/masquage.
- Le bouton [RÉINITIALISER] est désactivé pendant l'envoi.

### Gestion des erreurs

| Situation | Message affiché |
|-----------|-----------------|
| Code expiré ou invalide | "Ce lien a expiré ou est invalide. Recommencez depuis « Mot de passe oublié »." |
| Mot de passe trop faible | "Mot de passe trop faible. Choisissez un mot de passe plus sécurisé." |
| Nouveau mot de passe identique à l'ancien | "Le nouveau mot de passe doit être différent de l'ancien." |
| Erreur réseau | "Erreur réseau. Vérifiez votre connexion et réessayez." |

### État de succès

Affichage d'une snackbar "Mot de passe réinitialisé." puis redirection automatique vers `/login`.

## Références

- [screen-02-login.md](screen-02-login.md) — connexion (point d'entrée de ce flux)
- [screen-05-reset-password.md](screen-05-reset-password.md) — réinitialisation via lien magique (web uniquement, déploiement JVM)
