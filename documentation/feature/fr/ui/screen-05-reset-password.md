# Réinitialisation du mot de passe (lien magique)

## Description

Écran de réinitialisation du mot de passe via lien magique GoTrue. Route publique, non authentifiée, accessible uniquement sur le Web.

- **Route** : `/reset-password`
- **Accès** : public, non authentifié — web uniquement
- **Déclencheur** : lien de récupération GoTrue envoyé par email, contenant un fragment `#access_token=...&refresh_token=...&type=recovery`

> Note technique : cette route est la cible du lien de récupération GoTrue (déploiement JVM). Le fragment URL est capturé avant que go_router ne le supprime via `webInitialFragment`. Cette route n'est pas utilisée avec Cognito, qui dispose de son propre mécanisme de récupération.

## État — lien invalide

Affiché lorsque le fragment URL est absent ou que `type != recovery`.

- Message : "Lien de réinitialisation invalide."
- Bouton [Réessayer] redirige vers `/forgot-password`.

## Formulaire

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ← Nouveau mot de passe                      │
├─────────────────────────────────────────────┤
│                                             │
│  Choisissez un nouveau mot de passe         │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │ Nouveau mot de passe *        [oeil]│    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ Confirmer le mot de passe *   [oeil]│    │
│  └─────────────────────────────────────┘    │
│                                             │
│  [RÉINITIALISER MON MOT DE PASSE]           │
│                                             │
└─────────────────────────────────────────────┘
```

### Contenu et comportement

- Titre : "Choisissez un nouveau mot de passe"
- Champ "Nouveau mot de passe *" : minimum 8 caractères, avec icône d'affichage/masquage.
- Champ "Confirmer le mot de passe *" : avec icône d'affichage/masquage.
- Le bouton [RÉINITIALISER MON MOT DE PASSE] est désactivé pendant l'envoi.
- [← Retour] dans l'AppBar ramène à `/login`.

### Gestion des erreurs

| Situation | Message affiché |
|-----------|-----------------|
| Token expiré ou invalide | "Ce lien a expiré ou est invalide. Recommencez depuis « Mot de passe oublié »." |
| Mot de passe trop faible | "Mot de passe trop faible. Choisissez un mot de passe plus sécurisé." |
| Nouveau mot de passe identique à l'ancien | "Le nouveau mot de passe doit être différent de l'ancien." |
| Erreur réseau | "Erreur réseau. Vérifiez votre connexion et réessayez." |

## Carte de succès

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│                                             │
│              [ok]                           │
│    Mot de passe réinitialisé                │
│  Vous pouvez maintenant accéder             │
│  à votre espace.                            │
│                                             │
│  [SE CONNECTER]                             │
│                                             │
└─────────────────────────────────────────────┘
```

### Contenu et comportement

- Icône de confirmation verte.
- Titre : "Mot de passe réinitialisé"
- Texte : "Vous pouvez maintenant accéder à votre espace."
- Bouton [SE CONNECTER] : connecte automatiquement l'utilisateur avec le token de session puis redirige vers l'interface appropriée.

## Références

- [screen-04-forgot-password.md](screen-04-forgot-password.md) — demande de code OTP (flux mobile et web)
- [screen-02-login.md](screen-02-login.md) — connexion (destination après réinitialisation réussie)
