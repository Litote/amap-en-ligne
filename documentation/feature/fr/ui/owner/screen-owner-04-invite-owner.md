# Nouvel Administrateur (invitation d'un Owner)

## Description

Écran réservé au rôle `OWNER` permettant d'inviter un nouvel administrateur de l'instance. L'invitation envoie un email d'activation au destinataire ; à l'activation, le compte est créé avec le rôle `OWNER` — exclusif (cf. [ADR-001](../../../../architecture/adr-001-role-management.md) et [`screen-owner-03-user-management.md`](screen-owner-03-user-management.md)).

Cet écran remplace l'ancien modal « Inviter un Owner » qui se trouvait dans l'écran de gestion des utilisateurs : l'invitation est désormais une action de premier plan, accessible directement depuis le tableau de bord via l'entrée « Nouvel Administrateur ».

---

## Wireframe — Formulaire d'invitation

```
┌─────────────────────────────────────────────────────────────┐
│  Nouvel Administrateur                                      │
├─────────────────────────────────────────────────────────────┤
│  ← Tableau de bord                       Alice Martin (Owner)│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Inviter un nouvel administrateur de l'instance             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  IDENTITÉ                                           │   │
│  │                                                     │   │
│  │  Prénom *                                           │   │
│  │  [_________________________________________]        │   │
│  │                                                     │   │
│  │  Nom *                                              │   │
│  │  [_________________________________________]        │   │
│  │                                                     │   │
│  │  Email *                                            │   │
│  │  [_________________________________________]        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ℹ  Conséquences de l'invitation                    │   │
│  │                                                     │   │
│  │  • Un email d'activation est envoyé à l'adresse     │   │
│  │    indiquée (lien valide 7 jours).                  │   │
│  │  • Tant que l'activation n'est pas effectuée, le    │   │
│  │    compte apparaît en statut « Invité ».            │   │
│  │  • À l'activation, le rôle Owner est attribué.      │   │
│  │  • Owner est un rôle exclusif : aucune appartenance │   │
│  │    AMAP ni rattachement producteur n'est créé.      │   │
│  │  • Les Owners existants reçoivent une notification. │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [ANNULER]                          [ENVOYER L'INVITATION]  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Wireframe — Confirmation après envoi

```
┌─────────────────────────────────────────────────────────────┐
│  Nouvel Administrateur                                      │
├─────────────────────────────────────────────────────────────┤
│  ← Tableau de bord                       Alice Martin (Owner)│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ✅  Invitation envoyée                                     │
│                                                             │
│  Un email d'activation a été envoyé à                       │
│  jean.dupont@exemple.fr.                                    │
│                                                             │
│  Le compte apparaît dès maintenant dans la liste des        │
│  utilisateurs avec le statut « Invité ». Il deviendra Owner │
│  à l'activation (lien valide 7 jours).                      │
│                                                             │
│  [VOIR LA LISTE DES UTILISATEURS]   [INVITER UN AUTRE OWNER]│
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Navigation et interactions

### Formulaire

| Élément | Comportement |
|---------|-------------|
| Champ Prénom | Obligatoire ; longueur 1–60 caractères ; espaces de bord supprimés |
| Champ Nom | Obligatoire ; longueur 1–60 caractères ; espaces de bord supprimés |
| Champ Email | Obligatoire ; format email valide ; insensible à la casse ; espaces supprimés |
| [ANNULER] | Revient au tableau de bord sans création de compte |
| [ENVOYER L'INVITATION] | Désactivé tant que les trois champs ne sont pas valides ; déclenche l'appel `POST /v1/organization-requests` équivalent côté Owner (création de compte invité + email d'activation) — voir « Règles métier » |

### Écran de confirmation

| Élément | Comportement |
|---------|-------------|
| [VOIR LA LISTE DES UTILISATEURS] | Navigue vers [`screen-owner-03-user-management.md`](screen-owner-03-user-management.md) avec le filtre Statut positionné sur « Invité » |
| [INVITER UN AUTRE OWNER] | Réinitialise le formulaire et reste sur l'écran courant |
| ← Tableau de bord | Revient à [`screen-owner-01-home.md`](screen-owner-01-home.md) |

---

## États de l'interface

| État | Description |
|------|-------------|
| Saisie | État initial ; bouton [ENVOYER L'INVITATION] désactivé tant que les champs obligatoires ne sont pas valides |
| Validation locale | Messages d'erreur en ligne sous chaque champ (`Prénom requis`, `Email invalide`, …) |
| Soumission | Spinner inline sur le bouton, tous les champs et boutons désactivés |
| Confirmation | Affichage de l'écran de succès avec les deux actions de suivi |
| Erreur serveur | Bandeau d'erreur en haut du formulaire ; les champs restent renseignés |

### Erreurs spécifiques

| Cas | Message |
|-----|---------|
| Email déjà rattaché à un compte de l'instance | « Cette adresse email correspond déjà à un compte sur l'instance. Consultez la fiche de l'utilisateur pour vérifier son rôle. » |
| Email déjà invité (Invitation `Invité` en cours) | « Une invitation est déjà en attente pour cette adresse. Vous pouvez la relancer depuis la liste des utilisateurs. » |
| Erreur réseau / serveur | « L'envoi de l'invitation a échoué. Veuillez réessayer. » |

---

## Règles métier

- Seuls les utilisateurs portant le rôle `OWNER` peuvent accéder à cet écran et déclencher l'invitation.
- L'envoi de l'invitation crée immédiatement un compte au statut `Invité` (cf. badges de statut dans [`screen-owner-03-user-management.md`](screen-owner-03-user-management.md)) et déclenche un email d'activation valide 7 jours.
- À l'activation, le rôle `OWNER` est appliqué — la double écriture base + fournisseur d'authentification (GoTrue `app_metadata.roles` ou Cognito groups) est gérée côté serveur selon le mécanisme défini dans l'[ADR-001](../../../../architecture/adr-001-role-management.md).
- **Exclusivité `OWNER`** : aucune appartenance `Member` ni rattachement `PRODUCER` n'est créé. Le compte invité est exempt de tout autre rôle.
- Les autres `OWNER` actifs de l'instance reçoivent une notification d'invitation (création) puis une notification d'activation (effective).
- Si l'invitation expire (7 jours sans activation), le compte est purgé et une nouvelle invitation peut être émise pour la même adresse.
- Aucune contrainte de dernier Owner ne s'applique ici (action additive uniquement) ; voir [`screen-owner-03-user-management.md`](screen-owner-03-user-management.md) pour la révocation, soumise à la garantie « au moins un Owner ».

---

## Références

- **Écran précédent** : [`screen-owner-01-home.md`](screen-owner-01-home.md)
- **Écran lié** : [`screen-owner-03-user-management.md`](screen-owner-03-user-management.md)
- **Architecture des rôles** : [`../../../../architecture/adr-001-role-management.md`](../../../../architecture/adr-001-role-management.md)
- **Spécifications UI globales** : [`../spec-ui.md`](../spec-ui.md)
