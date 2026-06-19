# Activation de compte

## Description

Écran d'activation de compte organisateur, accessible depuis le lien d'activation envoyé par email après approbation d'une demande d'organisation. Route publique, non authentifiée.

- **Route** : `/activate?token=...`
- **Accès** : public, non authentifié
- **Déclencheur** : lien d'activation envoyé par email suite à l'approbation d'une demande d'organisation par un administrateur
- **Paramètre** : `token` extrait de l'URL par le routeur

## Formulaire

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│                                             │
│         Activer votre compte                │
│  Choisissez un mot de passe pour            │
│  finaliser la création de votre compte.     │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │ Mot de passe *                [oeil]│    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ Confirmer le mot de passe *   [oeil]│    │
│  └─────────────────────────────────────┘    │
│                                             │
│  [ACTIVER MON COMPTE]                       │
│                                             │
└─────────────────────────────────────────────┘
```

### Contenu et comportement

- Titre : "Activer votre compte"
- Sous-titre : "Choisissez un mot de passe pour finaliser la création de votre compte."
- Champ "Mot de passe *" : minimum 8 caractères, avec icône d'affichage/masquage.
- Champ "Confirmer le mot de passe *" : avec icône d'affichage/masquage.
- Le bouton [ACTIVER MON COMPTE] est désactivé pendant l'envoi.
- Appelle `POST /v1/activate` (public, non authentifié).

### Gestion des erreurs

| Situation | Message affiché |
|-----------|-----------------|
| Token invalide | "Ce lien d'activation est invalide." |
| Token expiré | "Ce lien d'activation a expiré. Contactez l'administrateur." |
| Compte déjà activé | "Ce compte a déjà été activé. Connectez-vous." |
| Erreur serveur | "Une erreur est survenue. Veuillez réessayer." |

## Carte de succès

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│                                             │
│              [ok]                           │
│          Compte activé                      │
│  Votre compte pour AMAP des Collines        │
│  a été activé.                              │
│                                             │
│  [SE CONNECTER]                             │
│                                             │
└─────────────────────────────────────────────┘
```

### Contenu et comportement

- Icône de confirmation verte.
- Titre : "Compte activé"
- Texte : "Votre compte pour [nom de l'organisation] a été activé."
- Bouton [SE CONNECTER] redirige vers `/login`.

## Références

- [screen-03-organization-creation.md](screen-03-organization-creation.md) — demande d'organisation qui précède ce flux
- [screen-02-login.md](screen-02-login.md) — connexion (destination après activation réussie)
