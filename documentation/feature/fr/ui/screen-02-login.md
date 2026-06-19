# Connexion

## Description
Interface d'authentification permettant aux utilisateurs de se connecter à leur compte. Point d'entrée principal des fonctionnalités authentifiées de l'application.

> **📋 Référence** : Structure détaillée dans `../../../architecture/data-model.md` - Section MEMBER, ORGANIZATION.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                    🥕 Connexion                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📱 Bienvenue                                               │
│                                                             │
│  👤 Connexion à votre compte                               │
│                                                             │
│  Email                                                      │
│  [________________________________]                        │
│                                                             │
│  Mot de passe                                               │
│  [••••••••••••••••••••••••••••••]                          │
│                                                             │
│  Serveur                                                    │
│  [Serveur par défaut pré-rempli]                           │
│                                                             │
│  ☑️ Se souvenir de moi                                      │
│                                                             │
│  [SE CONNECTER] 🟢                                          │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  🔗 Mot de passe oublié ?                                   │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  ℹ️  Première connexion ? Vous devez avoir reçu une        │
│      invitation par email de votre coordinateur.           │
│                                                             │
│  📧 Pas d'invitation ? Contactez votre organisation        │
│      ou créez une nouvelle organisation ci-dessus.         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales
- **[SE CONNECTER]** : Authentification avec email/mot de passe
- **🔗 Mot de passe oublié ?** : Accès à [screen-04-forgot-password.md](screen-04-forgot-password.md)

### Validation des données
- **Format email** : Vérification de la validité de l'adresse email
- **Mot de passe requis** : Validation de la présence du mot de passe
- **Authentification** : Vérification des credentials côté serveur
- **Tentatives limitées** : Protection contre les attaques par force brute

### États de l'interface
- **Formulaire vide** : État initial avec bouton [SE CONNECTER] désactivé
- **Saisie en cours** : Validation temps réel des champs
- **Authentification** : Indicateur de traitement avec loader
- **Succès** : Redirection vers le tableau de bord approprié
- **Erreur** : Affichage des erreurs avec possibilité de retry

### Gestion des erreurs
- **Identifiants incorrects** : Message d'erreur générique pour la sécurité
- **Compte suspendu** : Message spécifique avec contact administrateur
- **Trop de tentatives** : Verrouillage temporaire avec délai
- **Problème technique** : Message générique avec support contact

## Navigation post-connexion

### Redirection automatique selon le profil
- **Amapien** : Redirection vers [Tableau de bord Amapien](member/screen-member-01-home.md)
- **Coordinateur** : Redirection vers l'interface coordinateur
- **Producteur** : Redirection vers [Tableau de bord Producteur](producer/screen-producer-01-home.md)
- **Owner/Admin** : Redirection vers le tableau de bord correspondant
- **Première connexion** : Guide d'accueil et configuration des préférences

### Persistance de session
- **Option "Se souvenir"** : Session étendue (30 jours)
- **Session standard** : Expiration après 24h d'inactivité
- **Déconnexion automatique** : Notification avant expiration

## Création d'organisation

### Accès non-authentifié
- **Visibilité publique** : Lien visible sans connexion requise
- **Processus indépendant** : Navigation vers [Écran 3 - Création Organisation](screen-03-organization-creation.md)
- **Validation administrative** : Processus d'approbation obligatoire

## Sécurité et confidentialité

### Mesures de protection
- **HTTPS obligatoire** : Chiffrement de toutes les communications
- **Protection CSRF** : Tokens de validation des formulaires
- **Rate limiting** : Limitation des tentatives de connexion
- **Audit des connexions** : Log des tentatives et succès

### Données personnelles
- **RGPD compliant** : Gestion des données selon la réglementation
- **Consentement éclairé** : Information sur l'utilisation des données
- **Droit à l'oubli** : Possibilité de suppression des données

## Adaptation mobile

### Interface responsive
- **Formulaire optimisé** : Champs adaptés aux écrans tactiles
- **Clavier approprié** : Type email automatique pour le champ email
- **Touch-friendly** : Boutons de taille suffisante pour le touch
- **Navigation simplifiée** : Liens et actions clairement séparés

## Messages et notifications

### Messages d'aide contextuelle
- **Première visite** : Explication du processus d'inscription
- **Invitation reçue** : Guide pour activer son compte
- **Organisation inexistante** : Orientation vers la création

### Notifications système
- **Maintenance programmée** : Avertissement des interruptions
- **Nouvelles fonctionnalités** : Information des améliorations
- **Sécurité** : Alertes de connexions suspectes

## Références

### Documentation liée
- **Spécifications UI** : [`spec-ui.md`](spec-ui.md) - Section "Authentification"
- **Données** : `../../../architecture/data-model.md` - Entités MEMBER, ORGANIZATION
- **Navigation** : [Écran 3](screen-03-organization-creation.md) - Création d'organisation
- **Mot de passe oublié** : [`screen-04-forgot-password.md`](screen-04-forgot-password.md)
- **Réinitialisation (lien magique web)** : [`screen-05-reset-password.md`](screen-05-reset-password.md)
- **Sécurité** : `../../../architecture/security.md` - Authentification et autorisation
- **Dashboards** : [Amapien](member/screen-member-01-home.md), [Admin](admin/screen-admin-01-home.md), [Owner](owner/screen-owner-01-home.md) et [Producteur](producer/screen-producer-01-home.md)
