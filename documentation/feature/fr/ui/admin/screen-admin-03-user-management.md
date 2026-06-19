# Ajout d'Utilisateurs à l'Organisation

## Description
Interface permettant aux coordinateurs et aux admins d'ajouter de nouveaux membres à leur organisation. Inclut la gestion des rôles (Amapien/Coordinateur/Admin) et l'envoi d'invitations par email avec création de compte automatisée.

> **📋 Référence** : Structure détaillée dans `../../../../architecture/data-model.md` - Section MEMBER, ORGANIZATION.

## Architecture technique

L'écran est **entièrement servi par le sync offline-first** : la liste des membres, les invitations en attente, les changements de statut et de rôle sont des mutations `POST /v1/sync` sur l'entité `Member` ou la nouvelle entité `MemberInvitation`. Aucun appel REST authentifié n'est utilisé (cf. `AI_CONTEXT.md` racine → « API surface principle »).

- **Liste des membres actifs** : lecture du scope `organization:{id}` (entité `Member`, qui porte désormais `firstName`/`lastName`/`email`/`phone` + `accountStatus`).
- **Invitations en attente** : lecture de la même scope (entité `MemberInvitation`, synchronisée).
- **Inviter un membre** : `Upsert(MemberInvitationPayload)` avec id `tmp_*` ; le back génère le token et envoie l'email lors de l'application de la mutation, et renvoie le `invitation_id` via `MutationOutcome.serverEntityId`.
- **Relancer une invitation** : nouveau `Upsert(MemberInvitationPayload)` avec `resend_requested_at` fraîchement mis à jour ; le back régénère le token et renvoie l'email.
- **Modifier les rôles, activer, suspendre, supprimer** : `Upsert/Delete(MemberPayload)` — `MemberService` côté back orchestre les side-effects (`UserProvisioningPort.banUser/unbanUser/deleteUser`, `AccountLifecycleEmailPort`, `AccountDeletionLog`).
- **Rejets serveur** : `MutationOutcome.error.code` porte `LAST_ADMIN` / `SELF_ACTION_FORBIDDEN` / `FORBIDDEN` ; le front transforme ces codes en SnackBars contextuels.

Tous les changements sont **disponibles offline** (queue de mutations locale) et appliqués au prochain cycle de sync.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                🥕 Gestion des Utilisateurs                 │
├─────────────────────────────────────────────────────────────┤
│  ← Retour dashboard                            👤 Marie D.   │
│  📊 Organisation: AMAP des Collines            📱 [Menu]     │
└─────────────────────────────────────────────────────────────┘

│  👥 Ajouter des utilisateurs                               │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📝 NOUVEAU MEMBRE                                      │ │
│  │                                                         │ │
│  │  Prénom *                                               │ │
│  │  [________________________________]                    │ │
│  │                                                         │ │
│  │  Nom *                                                  │ │
│  │  [________________________________]                    │ │
│  │                                                         │ │
│  │  Email *                                                │ │
│  │  [________________________________]                    │ │
│  │                                                         │ │
│  │  Téléphone (optionnel)                                  │ │
│  │  [________________________________]                    │ │
│  │                                                         │ │
│  │  Rôles dans l'organisation *                            │ │
│  │  ☐ Amapien (membre standard)                             │ │
│  │  ☐ Coordinateur (accès gestion)                         │ │
│  │  ☐ Admin (accès complet)                                │ │
│  │                                                         │ │
│  │  ☑️ Envoyer l'invitation par email                      │ │
│  │                                                         │ │
│  │  [ANNULER]                      [AJOUTER MEMBRE] 🟢     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📋 INVITATION GROUPÉE                                  │ │
│  │                                                         │ │
│  │  Inviter plusieurs personnes en une fois :             │ │
│  │                                                         │ │
│  │  Format : prénom,nom,email (un par ligne)              │ │
│  │  [Marie,Martin,marie.martin@email.com                   │ │
│  │  Pierre,Dupont,pierre.dupont@email.com                  │ │
│  │  ___________________________________________              │ │
│  │  ___________________________________________]             │ │
│  │                                                         │ │
│  │  Rôles : ☐ Amapien  ☐ Coordinateur  ☐ Admin             │ │
│  │                                                         │ │
│  │  [TRAITER LES INVITATIONS] 🟠                          │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📊 Membres actuels (23)                                   │
│                                                             │
│  🔍 Rechercher : [_______________] 🔎                       │
│  Filtrer : [Tous ▼] [Amapiens ▼] [Coordinateurs ▼]         │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  👤 Marie Martin               📧 marie.m@email.com     │ │
│  │     🟢 Coordinateur • Actif • Rejoint le 15/12/2024     │ │
│  │     📞 06 12 34 56 78                   [MODIFIER] ⚙️   │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  👤 Pierre Dupont              📧 pierre.d@email.com    │ │
│  │     🔵 Amapien • Actif • Rejoint le 03/01/2025          │ │
│  │     📞 06 87 65 43 21                   [MODIFIER] ⚙️   │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  👤 Julie Legrand              📧 julie.l@email.com     │ │
│  │     🟡 Invitation envoyée le 28/12/2024 [RELANCER] 📧   │ │
│  │     ⏱️  En attente d'activation                          │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  [EXPORTER LA LISTE] 📄           [INVITER EN MASSE] 📨     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales
- **[AJOUTER MEMBRE]** : Création d'un nouveau membre avec envoi optionnel d'invitation
- **[TRAITER LES INVITATIONS]** : Traitement en lot des invitations multiples
- **[MODIFIER]** : Édition des informations d'un membre existant
- **[RELANCER]** : Renvoi d'invitation à un utilisateur non activé
- **[DEMANDER LA CONNEXION]** : Relance groupée — renvoie l'e-mail d'invitation à **tous** les membres encore en attente d'activation (statut `PENDING_ACTIVATION`), en une seule action. Un bandeau apparaît au-dessus de la liste dès qu'au moins une invitation est en attente et indique le nombre de membres concernés.
- **[EXPORTER LA LISTE]** : Export CSV/Excel de la liste des membres
- **[INVITER EN MASSE]** : Import CSV pour invitations multiples

### Validation des données
- **Champs obligatoires** : Prénom, nom, email, rôle marqués d'un astérisque (*)
- **Format email** : Vérification de la validité et unicité dans l'organisation
- **Format CSV** : Validation du format pour les invitations groupées
- **Limites** : Maximum 50 invitations simultanées pour éviter le spam

### États des membres

Un membre actif peut afficher plusieurs badges de rôle simultanément. Exemples :

- **🟣 Admin** : Membre ayant le rôle Admin
- **🟢 Coordinateur** : Membre ayant le rôle Coordinateur
- **🔵 Amapien** : Membre ayant le rôle Amapien (membre standard)
- **🟣 Admin • 🟢 Coordinateur** : Membre cumulant les deux rôles
- **🟡 Invitation envoyée** : En attente d'activation, possibilité de relance
- **🔴 Compte suspendu** : Accès temporairement désactivé
- **⚫ Compte supprimé** : Membre retiré de l'organisation

### Processus d'invitation
- **Envoi automatique** : Email d'invitation avec lien d'activation sécurisé
- **Délai d'activation** : 7 jours pour activer le compte
- **Relance automatique** : Rappel après 3 jours si pas d'activation
- **Expiration** : Lien d'invitation expire après 7 jours

### Relance groupée « Demander la connexion »

Quand au moins un membre n'a jamais activé son compte (statut `PENDING_ACTIVATION`), un bandeau au-dessus de la liste affiche « N membre(s) ne se sont pas encore connectés » avec un bouton **[DEMANDER LA CONNEXION]**. Le bouton ouvre une fenêtre permettant de **personnaliser le message** de l'e-mail de relance :

- **Titre du message (optionnel)** : remplace l'objet par défaut de l'e-mail d'invitation.
- **Corps du message (optionnel)** : remplace le texte d'introduction de l'e-mail.

Les deux champs sont facultatifs : laissés vides, le message par défaut est utilisé. Le lien d'activation et la signature sont **toujours ajoutés automatiquement** à la fin de l'e-mail, quel que soit le texte saisi. À la confirmation, l'e-mail est renvoyé à chaque membre en attente et un retour indique le nombre d'envois réussis.

```
┌─────────────────────────────────────────────────────────────┐
│  3 membre(s) ne se sont pas encore connectés.               │
│                                  [DEMANDER LA CONNEXION] 📧  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Demander la connexion                                   ❌  │
├─────────────────────────────────────────────────────────────┤
│  L'e-mail d'invitation sera renvoyé à 3 membre(s).          │
│  Laissez les champs vides pour le message par défaut.       │
│                                                             │
│  Titre du message (optionnel)                               │
│  [________________________________]                         │
│                                                             │
│  Corps du message (optionnel)                               │
│  [________________________________]                         │
│  [________________________________]                         │
│                                                             │
│  [ANNULER]                              [RENVOYER] 🟢       │
└─────────────────────────────────────────────────────────────┘
```

## Gestion des rôles et permissions

Un membre peut cumuler plusieurs rôles simultanément (ex : Coordinateur + Admin). Les rôles sont stockés en base de données et synchronisés sur les appareils via le mécanisme de sync habituel. Le token d'authentification reflète également les rôles actifs et est mis à jour en arrière-plan lors de chaque changement — un court délai (au plus un cycle de rafraîchissement du token) peut s'écouler avant que les nouvelles permissions soient effectives côté serveur.

### Rôle Amapien (Membre standard)
- **Accès** : Tableau de bord personnel, planning, inscriptions
- **Permissions** : S'inscrire/désinscrire des créneaux, consulter son historique
- **Restrictions** : Pas d'accès aux outils de gestion

### Rôle Coordinateur
- **Accès** : Tous les écrans de gestion en plus de l'interface Amapien
- **Permissions** : Gestion créneaux, alertes, utilisateurs, statistiques
- **Responsabilités** : Animation de l'organisation, suivi des livraisons

### Rôle Admin
- **Accès** : Tout ce que fait un Coordinateur, plus la gestion des autres Admins
- **Permissions supplémentaires** : Promouvoir ou rétrograder des utilisateurs vers/depuis le rôle Admin ; supprimer l'organisation
- **Contrainte** : Au moins un Admin obligatoire par organisation — il est impossible de rétrograder le dernier Admin

### Modification des rôles
- **Ajout ou retrait de Coordinateur** : Prise d'effet immédiate sur les accès gestion après synchronisation ; validation par email recommandée lors d'une promotion initiale
- **Ajout du rôle Admin** : Réservé aux Admins existants ; confirmation par email requise ; notification envoyée à tous les Admins de l'organisation
- **Retrait du rôle Admin** : Possible uniquement si au moins un autre Admin existe dans l'organisation ; sinon l'action est bloquée avec un message d'erreur explicite
- **Cumul de rôles** : Un membre peut être à la fois Coordinateur et Admin ; les permissions s'additionnent
- **Sécurité** : Au moins un Admin obligatoire par organisation

## Interface de modification membre

### Modal d'édition
```
┌─────────────────────────────────────────────────────────────┐
│  ⚙️  Modifier Marie Martin                             ❌   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Prénom *                                                   │
│  [Marie_________________________]                           │
│                                                             │
│  Nom *                                                      │
│  [Martin________________________]                           │
│                                                             │
│  Email *                                                    │
│  [marie.m@email.com_____________] 🔒                        │
│                                                             │
│  Téléphone                                                  │
│  [06 12 34 56 78________________]                           │
│                                                             │
│  Statut                                                     │
│  ⚪ Actif   ⚪ Suspendu   ⚪ Supprimer de l'organisation     │
│                                                             │
│  Rôles (plusieurs choix possibles)                          │
│  ☐ Amapien   ☑ Coordinateur   ☐ Admin                       │
│                                                             │
│  ⚠️  Seuls les Admins peuvent attribuer ou retirer le rôle Admin │
│  (case Admin visible uniquement si l'utilisateur connecté   │
│   est lui-même Admin)                                       │
│                                                             │
│  ⚠️  Changer le rôle nécessite une confirmation par email  │
│                                                             │
│  [ANNULER]                              [SAUVEGARDER] 🟢   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Actions administratives
- **Suspension temporaire** : Désactivation du compte sans suppression
- **Suppression définitive** : Retrait de l'organisation avec confirmation
- **Réactivation** : Restauration d'un compte suspendu

## Invitations en masse

### Import CSV
- **Format attendu** : prénom,nom,email,rôle (optionnel)
- **Validation** : Vérification de l'unicité et du format
- **Feedback** : Rapport détaillé des succès/échecs
- **Limite** : 50 invitations maximum par lot

### Traitement en lot
```
┌─────────────────────────────────────────────────────────────┐
│  📨 Traitement des invitations                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📊 Résumé du traitement :                                  │
│                                                             │
│  ✅ Invitations envoyées : 8                               │
│  ⚠️  Emails déjà utilisés : 2                               │
│  ❌ Erreurs de format : 1                                   │
│                                                             │
│  📋 Détail :                                                │
│  • marie.martin@email.com ✅ Envoyée                       │
│  • pierre.dupont@email.com ✅ Envoyée                      │
│  • julie.legrand@email.com ⚠️ Déjà membre                  │
│  • contact@invalid ❌ Format email invalide                │
│                                                             │
│  [FERMER]                                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Recherche et filtres

### Options de recherche
- **Recherche textuelle** : Par nom, prénom, email
- **Filtre par rôle** : Amapiens, Coordinateurs, ou tous
- **Filtre par statut** : Actifs, invitations en attente, suspendus
- **Tri** : Par nom, date d'inscription, rôle, statut

### Export des données
- **Format CSV** : Liste complète avec toutes les informations
- **Format Excel** : Version formatée pour traitement bureautique
- **Données incluses** : Nom, prénom, email, téléphone, rôle, statut, date d'inscription

## Notifications et communications

### Email d'invitation type
```
Subject: Invitation à rejoindre AMAP des Collines

Bonjour Marie,

Pierre Dupont vous invite à rejoindre l'organisation "AMAP des Collines" 
sur la plateforme AmapEnLigne.

Rôle proposé : Coordinateur

Pour accepter cette invitation et créer votre compte :
👉 [ACCEPTER L'INVITATION]

Ce lien expire dans 7 jours.
```

### Rappels automatiques
- **J+3** : Premier rappel si invitation non activée
- **J+6** : Dernier rappel avant expiration
- **Coordinateur** : Notification des invitations expirées

## Règles de sécurité

### Contrôles d'accès
- **Seuls les coordinateurs et les admins** peuvent ajouter des utilisateurs
- **Auto-invitation interdite** : Un utilisateur ne peut s'ajouter lui-même
- **Validation email** : Obligatoire pour toute invitation
- **Attribution du rôle Admin** : Réservée aux Admins existants — aucun autre rôle ne peut attribuer ou retirer ce rôle
- **Protection du dernier Admin** : L'action est bloquée si elle laisserait l'organisation sans aucun Admin

### Audit des actions
- **Traçabilité** : Log de toutes les actions (ajout, modification, suppression)
- **Historique** : Conservation des modifications pour audit
- **Notifications** : Alerte en cas d'actions sensibles (promotion coordinateur)

## Références

### Documentation liée
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md) - Section "Gestion des utilisateurs"
- **Données** : `../../../../architecture/data-model.md` - Entités MEMBER, ORGANIZATION
- **Navigation** : [Dashboard admin](screen-admin-01-home.md)
- **Processus** : `../../regles-metier.md` - Rôles et permissions des utilisateurs
