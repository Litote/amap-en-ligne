# Gestion des Utilisateurs de l'Instance

## Description

Interface réservée au rôle `OWNER` permettant de gérer l'ensemble des utilisateurs présents sur l'instance, toutes organisations confondues. À la différence de la gestion utilisateurs côté AMAP ([`../admin/screen-admin-03-user-management.md`](../admin/screen-admin-03-user-management.md)) qui ne couvre qu'une seule `Organization`, cet écran agrège les comptes provenant de toutes les `Organization` actives — AMAP et Producteurs (cf. `organizationType`) — et permet d'agir sur le rôle plateforme `OWNER` lui-même.

Ce design s'aligne sur le pattern visuel adopté par la gestion membres ADMIN ([`../admin/screen-admin-03-user-management.md`](../admin/screen-admin-03-user-management.md)) : liste plate de ListTiles avec filtres par chips, le détail s'ouvrant en dialog modal plutôt que dans un écran séparé.

L'instance distingue cinq rôles, cf. [ADR-001](../../../../architecture/adr-001-role-management.md) :

| Rôle | Portée | Combinaisons |
|------|--------|--------------|
| `OWNER` | Instance | **Exclusif** — aucun autre rôle |
| `ADMIN` | AMAP (`Member.roles`) | Combinable avec `COORDINATOR` et/ou `VOLUNTEER` au sein d'une même AMAP ; le même utilisateur peut être membre de plusieurs AMAPs |
| `COORDINATOR` | AMAP (`Member.roles`) | Combinable avec `ADMIN` et/ou `VOLUNTEER` |
| `VOLUNTEER` | AMAP (`Member.roles`) | Combinable avec `ADMIN` et/ou `COORDINATOR` |
| `PRODUCER` | Producteur (`Organization` de type `PRODUCER`) | **Exclusif** — aucun autre rôle |

> **Référence** : modèle de rôles et invariants d'exclusivité dans [`../../../../architecture/adr-001-role-management.md`](../../../../architecture/adr-001-role-management.md).

---

## Wireframe — Liste des utilisateurs de l'instance

```
┌─────────────────────────────────────────────────────────────┐
│  Utilisateurs                                               │
├─────────────────────────────────────────────────────────────┤
│  ← Tableau de bord                      Alice Martin (Owner)│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Utilisateurs de l'instance (1 247)                         │
│                                                             │
│  Rechercher : [_______________________]                     │
│  (nom, prénom, email)                                       │
│                                                             │
│  AMAP       : [Toutes ▼]                                    │
│  Producteur : [Tous ▼]                                      │
│                                                             │
│  Rôle :                                                     │
│  [Tous] [Owner] [Admin] [Coordinateur] [Amapien] [Producteur]│
│                                                             │
│  Statut :                                                   │
│  [Tous] [Actif] [Invité] [Suspendu]                         │
│                                                             │
│  Alice Martin                              [Actif] [Owner] ›│
│  alice@exemple.fr                                           │
│  (Administrateur d'instance)                                │
│  ─────────────────────────────────────────────────────────  │
│  Jean Dupont                         [Actif] [Admin] [Coord]›│
│  jean@exemple.fr                                            │
│  AMAP des Pins · Admin · Coordinateur                       │
│  AMAP du Lac · Amapien                                      │
│  ─────────────────────────────────────────────────────────  │
│  Marie Leblanc                          [Actif] [Producteur]›│
│  marie@lilas.fr                                             │
│  Producteur de : Ferme des Lilas                            │
│  ─────────────────────────────────────────────────────────  │
│  Julie Legrand                         [Invité] [Amapien]  ›│
│  julie@exemple.fr                                           │
│  AMAP des Pins · Amapien                                    │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  Page 1 sur 25 · 50 lignes par page   [Précédent] [Suivant]│
│                                                             │
│  [EXPORTER LA LISTE]                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Wireframe — Dialog : Détail utilisateur

Le tap sur une ligne de la liste ouvre un dialog modal centré. Il n'y a pas de navigation vers un écran séparé. Le dialog présente, dans l'ordre :

1. Titre = nom complet de l'utilisateur + bouton fermer (×)
2. Sous-titre : statut et date d'inscription
3. Bloc `COMPTE` en lecture seule
4. Un seul bloc variable selon le rôle exclusif détenu
5. Zone sensible avec les actions destructives

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ╔═════════════════════════════════════════════════════╗   │
│  ║  Jean Dupont                                    ×   ║   │
│  ║  Actif · Inscrit le 03/01/2025                      ║   │
│  ╠═════════════════════════════════════════════════════╣   │
│  ║                                                     ║   │
│  ║  COMPTE                                             ║   │
│  ║                                                     ║   │
│  ║  Prénom        Jean                                 ║   │
│  ║  Nom           Dupont                               ║   │
│  ║  Email         jean@exemple.fr                      ║   │
│  ║  Téléphone     06 12 34 56 78                       ║   │
│  ║                                                     ║   │
│  ╠═════════════════════════════════════════════════════╣   │
│  ║                                                     ║   │
│  ║  [Bloc variable selon rôle exclusif — voir ci-      ║   │
│  ║   dessous pour chaque variante]                     ║   │
│  ║                                                     ║   │
│  ╠═════════════════════════════════════════════════════╣   │
│  ║  ── ⚠️  Zone sensible ──────────────────────────── ║   │
│  ║                                                     ║   │
│  ║  [SUSPENDRE LE COMPTE]                              ║   │
│  ║  [SUPPRIMER DE L'INSTANCE]                          ║   │
│  ║                                                     ║   │
│  ║                                    [FERMER]         ║   │
│  ╚═════════════════════════════════════════════════════╝   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

Le libellé du bouton d'action principale en zone sensible est contextuel :
- `[SUSPENDRE LE COMPTE]` si le compte est Actif ou Invité
- `[RÉACTIVER LE COMPTE]` si le compte est Suspendu

Les deux boutons d'action ([SUSPENDRE / RÉACTIVER] et [SUPPRIMER]) sont désactivés sur le propre compte de l'Owner connecté (auto-action interdite).

### Variante — bloc AMAP

Affiché lorsque l'utilisateur porte uniquement des rôles AMAP (`ADMIN` / `COORDINATOR` / `VOLUNTEER`). Une ligne par appartenance.

```
│  ║  AMAP                                               ║   │
│  ║                                                     ║   │
│  ║  AMAP des Pins   Admin · Coordinateur   [Modifier]  ║   │
│  ║  AMAP du Lac     Amapien               [Modifier]  ║   │
```

### Variante — bloc PRODUCTEUR

Affiché lorsque l'utilisateur porte le rôle exclusif `PRODUCER`.

```
│  ║  PRODUCTEUR                                         ║   │
│  ║                                                     ║   │
│  ║  Producteur de : Ferme des Lilas                    ║   │
│  ║  Voir la fiche producteur →                         ║   │
```

### Variante — bloc OWNER

Affiché lorsque l'utilisateur porte le rôle exclusif `OWNER`.

```
│  ║  Administrateur d'instance                          ║   │
```

---

## Wireframe — Modal : Modifier les rôles d'un amapien

Sous-modal ouvert depuis le bouton `[Modifier]` d'une ligne d'appartenance AMAP dans le dialog Détail. Il se superpose au dialog Détail.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ╔═════════════════════════════════════════════════════╗   │
│  ║  Modifier les rôles — AMAP des Pins             ×  ║   │
│  ╠═════════════════════════════════════════════════════╣   │
│  ║                                                     ║   │
│  ║  Utilisateur : Jean Dupont                          ║   │
│  ║                                                     ║   │
│  ║  Rôles dans l'AMAP (au moins un, jusqu'à 3)         ║   │
│  ║                                                     ║   │
│  ║  ☑ Admin                                            ║   │
│  ║  ☑ Coordinateur                                     ║   │
│  ║  ☐ Amapien                                          ║   │
│  ║                                                     ║   │
│  ║  Au moins un rôle doit être sélectionné.            ║   │
│  ║  L'AMAP doit conserver au moins un Admin.           ║   │
│  ║                                                     ║   │
│  ║  [RETIRER DE L'AMAP]                                ║   │
│  ║  [ANNULER]                          [SAUVEGARDER]   ║   │
│  ╚═════════════════════════════════════════════════════╝   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Navigation et interactions

### Écran liste

| Élément | Comportement |
|---------|-------------|
| Recherche | Filtrage en temps réel sur prénom, nom et email ; insensible à la casse et aux accents |
| Filtre AMAP | Liste déroulante alimentée par toutes les `Organization` actives de type `AMAP` ; "Toutes" par défaut |
| Filtre Producteur | Liste déroulante alimentée par toutes les `Organization` actives de type `PRODUCER` ; "Tous" par défaut |
| Chips Rôle | Sélection exclusive : `Tous` · `Owner` · `Admin` · `Coordinateur` · `Amapien` · `Producteur` ; filtre sur le rôle `OWNER` ou `PRODUCER`, ou sur l'un des `MemberRole` (`ADMIN` / `COORDINATOR` / `VOLUNTEER`) au sein d'au moins une AMAP |
| Chips Statut | Sélection exclusive : `Tous` · `Actif` · `Invité` · `Suspendu` |
| Tap sur une ligne | Ouvre le dialog « Détail utilisateur » pour cet utilisateur |
| [Précédent] / [Suivant] | Pagination ; 50 lignes par page |
| [EXPORTER LA LISTE] | Génère un export CSV filtré selon les critères de recherche et filtres actifs |

### Dialog Détail utilisateur

| Élément | Comportement |
|---------|-------------|
| Bloc COMPTE | Lecture seule depuis ce dialog ; les modifications de profil restent du ressort de l'utilisateur lui-même |
| [Modifier] (ligne d'appartenance AMAP) | Ouvre le modal « Modifier les rôles d'un amapien » pour l'AMAP correspondante (variante AMAP uniquement) |
| Lien "Voir la fiche producteur →" | Navigue vers la fiche `Organization` productrice correspondante (variante PRODUCTEUR uniquement) |
| Bloc Administrateur d'instance | Indique que l'utilisateur porte le rôle `OWNER` ; lecture seule (variante OWNER uniquement) |
| [SUSPENDRE LE COMPTE] | Actif pour **Owners** (Phase 1), **Producteurs** (Phase 2) et **AMAPiens** (Phase 3). Pour Owner : bloque l'authentification, sessions invalidées, email envoyé ; refusé serveur si dernier Owner. Pour Producteur : flip `active_status = false` sur la ligne `ProducerAccount`. Pour AMAPien : ban auth provider + flip `active_status` sur tous les `Member` rows du sub, rôles préservés ; refusé serveur si l'utilisateur est seul Admin d'une ou plusieurs AMAPs (réponse 409 avec la liste des AMAPs concernées). Libellé devient [RÉACTIVER LE COMPTE] si déjà suspendu. Désactivé sur son propre compte (auto-action interdite). |
| [RÉACTIVER LE COMPTE] | Actif pour **Owners** (Phase 1), **Producteurs** (Phase 2), **AMAPiens** (Phase 3). Symétrique de [SUSPENDRE LE COMPTE]. Email de notification envoyé. |
| [SUPPRIMER DE L'INSTANCE] | Actif pour **Owners** (Phase 1), **Producteurs** (Phase 2.5) et **AMAPiens** (Phase 3). Action destructive ; confirmation renforcée. Pour Owner : supprime du fournisseur d'authentification, retire la ligne `Owner`, audit log SHA-256 ; refusé serveur si dernier Owner. Pour Producteur : énumère les utilisateurs auth liés, supprime chacun, écrit un audit log par sub, passe le `ProducerAccount` en `active_status=false` mais **conserve la fiche** (réattachable). Pour AMAPien : supprime du fournisseur d'authentification, **anonymise** toutes les `Member` rows (sub mis à null, `active_status=false` ; lignes techniques conservées pour préserver l'historique des contrats/livraisons), écrit un audit log par `Member` row (RGPD — hash SHA-256 du sub) ; refusé serveur (409 `LAST_ADMIN` avec liste des AMAPs) si l'utilisateur est seul Admin d'une AMAP. Désactivé sur son propre compte. |
| [FERMER] | Ferme le dialog sans action |
| × (croix titre) | Ferme le dialog sans action |

> La zone sensible (SUSPENDRE / RÉACTIVER / SUPPRIMER) est intentionnellement placée dans le dialog, après une étape de lecture du profil. Les actions destructives restent derrière une confirmation dédiée affichée au moment où le bouton est pressé.

### Modal — Modifier les rôles d'un amapien

| Action | Comportement |
|--------|-------------|
| [SAUVEGARDER] | Persiste la nouvelle liste de rôles AMAP sur le `Member` ; respecte la contrainte « au moins un Admin par AMAP » |
| [RETIRER DE L'AMAP] | Supprime le `Member` correspondant ; bloqué si cela laisserait l'`Organization` sans Admin |
| [ANNULER] | Ferme le modal sans action ; retour au dialog Détail |

> L'invitation d'un nouvel `OWNER` n'est pas accessible depuis cet écran : elle est traitée par l'écran dédié [`screen-owner-04-invite-owner.md`](screen-owner-04-invite-owner.md), atteignable depuis l'entrée « Nouvel Administrateur » du tableau de bord.

---

## États de l'interface

### Badges de rôle

| Rôle | Origine | Libellé affiché |
|------|---------|-----------------|
| `OWNER` | Attribut utilisateur — JWT | Owner |
| `ADMIN` | `Member.roles` dans une `Organization` AMAP | Admin |
| `COORDINATOR` | `Member.roles` dans une `Organization` AMAP | Coordinateur |
| `VOLUNTEER` | `Member.roles` dans une `Organization` AMAP | Amapien |
| `PRODUCER` | Attribut utilisateur rattaché à une `Organization` de type `PRODUCER` | Producteur |

Un utilisateur peut cumuler plusieurs badges **uniquement** lorsqu'il porte des rôles AMAP (`ADMIN`, `COORDINATOR`, `VOLUNTEER`), au sein d'une même AMAP ou entre plusieurs AMAPs. `OWNER` et `PRODUCER` apparaissent toujours seuls.

### Badges de statut

| Statut | Libellé | Sens |
|--------|---------|------|
| Actif | Actif | Compte activé, authentification autorisée |
| Invité | Invité | Invitation envoyée, pas encore activée (lien valide 7 jours) |
| Suspendu | Suspendu | Authentification bloquée par un Owner ; les rôles et appartenances sont conservés |

### Cas limites

| Situation | Comportement |
|-----------|-------------|
| Aucun résultat correspondant aux filtres | « Aucun utilisateur ne correspond aux critères. » |
| Retrait du dernier `ADMIN` d'une AMAP via [RETIRER DE L'AMAP] | Action bloquée — message : « Cette AMAP doit conserver au moins un Admin. » |
| Suppression d'un utilisateur `PRODUCER` actif | Confirmation renforcée — l'utilisateur perd l'accès, l'`Organization` productrice est conservée et doit être rattachée à un autre utilisateur |
| Chargement en cours | Spinner inline sur les boutons d'action ; boutons désactivés |

---

## Règles métier

- Seuls les utilisateurs portant le rôle `OWNER` peuvent accéder à cet écran et à ses actions.
- **Exclusivité `OWNER`** : un utilisateur `OWNER` ne porte aucun autre rôle. L'attribution du rôle s'effectue via l'écran dédié [`screen-owner-04-invite-owner.md`](screen-owner-04-invite-owner.md) (invitation par email).
- **Exclusivité `PRODUCER`** : un utilisateur `PRODUCER` ne porte aucun autre rôle et représente exactement une `Organization` de type `PRODUCER`. L'attribution du rôle `PRODUCER` se fait via la fiche producteur, pas via cet écran.
- **Rôles AMAP cumulables** : un utilisateur sans `OWNER` ni `PRODUCER` peut être `Member` d'une ou plusieurs AMAPs, avec entre 1 et 3 rôles parmi `{ADMIN, COORDINATOR, VOLUNTEER}` au sein de chaque AMAP. Les rôles peuvent différer d'une AMAP à l'autre.
- Chaque `Organization` de type `AMAP` doit toujours conserver au moins un `Member` avec le rôle `ADMIN`. Les opérations de changement de rôle et de retrait d'AMAP via le modal « Modifier les rôles d'un amapien » sont contraintes par cette règle.
- La suspension du compte (`Suspendu`) est globale à l'instance : elle bloque l'authentification mais préserve les rôles, les `Member` et les rattachements producteur pour permettre une réactivation propre.
- La suppression définitive d'un utilisateur retire l'ensemble de ses `Member` et son éventuel rôle `OWNER` / `PRODUCER` ; l'`Organization` productrice associée est conservée et doit être réaffectée.
- Les modifications de rôle suivent le mécanisme de double écriture décrit dans l'[ADR-001](../../../../architecture/adr-001-role-management.md) : DB primaire, fournisseur d'authentification en effet de bord, JWT rafraîchi au prochain cycle.

---

## Références

- **Écran précédent** : [`screen-owner-01-home.md`](screen-owner-01-home.md)
- **Écran suivant** : [`screen-owner-04-invite-owner.md`](screen-owner-04-invite-owner.md)
- **Écran lié (portée organisation)** : [`../admin/screen-admin-03-user-management.md`](../admin/screen-admin-03-user-management.md)
- **Architecture des rôles** : [`../../../../architecture/adr-001-role-management.md`](../../../../architecture/adr-001-role-management.md)
- **Spécifications UI globales** : [`../spec-ui.md`](../spec-ui.md)
