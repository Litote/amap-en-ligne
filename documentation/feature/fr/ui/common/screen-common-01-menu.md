# Menu principal

## Description

Menu de navigation affiché après connexion. Le contenu est adapté aux rôles actifs de l'utilisateur.

Un utilisateur peut détenir plusieurs valeurs de `MemberRole` simultanément (ex. : `COORDINATOR` + `ADMIN`).
Dans ce cas, le menu est **fusionné** : toutes les entrées correspondant aux rôles de l'utilisateur sont affichées dans un seul menu, regroupées par section de rôle en ordre croissant de privilège (AMAPIEN → COORDINATEUR → ADMIN). Les items communs à plusieurs rôles n'apparaissent qu'une seule fois, dans la section du rôle le moins privilégié qui les inclut. Les items communs à tous les rôles ([Notifications], [Préférences], [Aide], [Déconnexion]) sont affichés une seule fois en bas du menu, séparés par un séparateur horizontal.

Les rôles plateforme (`Role.OWNER`) et les perspectives producteur (`ProducerAccount`) sont distincts de `MemberRole` et disposent de menus séparés, non fusionnés avec les menus `MemberRole`.

> **Référence** : structure des rôles dans [`../../../../architecture/adr-001-role-management.md`](../../../../architecture/adr-001-role-management.md).

## Wireframes ASCII

### Menus mono-rôle (référence)

#### Version bénévole (MemberRole.VOLUNTEER)
```
┌─────────────────────────────────────────────────────────────┐
│                     🥕 Amap Livraisons                      │
├─────────────────────────────────────────────────────────────┤
│  👤 Marie Dupont (AMAPIEN)                        [Fermer] │
├─────────────────────────────────────────────────────────────┤
│  [ACCUEIL]                                                   │
│  [MES CONTRATS]                                              │
│  [MON HISTORIQUE]                                            │
│  ────────────────────────────────────────────────────────   │
│  [NOTIFICATIONS]                                             │
│  [PRÉFÉRENCES]                                               │
│  [AIDE]                                                      │
│  [DÉCONNEXION]                                               │
└─────────────────────────────────────────────────────────────┘
```

#### Version coordinateur (MemberRole.COORDINATOR)
```
┌─────────────────────────────────────────────────────────────┐
│                     🥕 Amap Livraisons                      │
├─────────────────────────────────────────────────────────────┤
│  👤 Jean Morel (COORDINATEUR)                      [Fermer] │
├─────────────────────────────────────────────────────────────┤
│  [ACCUEIL]                                                   │
│  [MES CONTRATS]                                              │
│  [MON HISTORIQUE]                                            │
│  [PLANNING DES LIVRAISONS]                                   │
│  [Gestion des livraisons]                                      │
│  [CONTRATS DE SAISON]                                        │
│  [CONTRATS DES AMAPIENS]                                     │
│  ────────────────────────────────────────────────────────   │
│  [NOTIFICATIONS]                                             │
│  [PRÉFÉRENCES]                                               │
│  [AIDE]                                                      │
│  [DÉCONNEXION]                                               │
└─────────────────────────────────────────────────────────────┘
```

#### Version admin (MemberRole.ADMIN)
```
┌─────────────────────────────────────────────────────────────┐
│                     🥕 Amap Livraisons                      │
├─────────────────────────────────────────────────────────────┤
│  👤 Sophie Leroy (ADMIN)                           [Fermer] │
├─────────────────────────────────────────────────────────────┤
│  [TABLEAU DE BORD]                                           │
│  [UTILISATEURS]                                              │
│  [PRODUCTEURS]                                               │
│  [TEMPLATES DE LIVRAISON]                                    │
│  [DEMANDES D'ADHÉSION]                                       │
│  [CONFIGURATION DE L'ORGANISATION]                           │
│  ────────────────────────────────────────────────────────   │
│  [NOTIFICATIONS]                                             │
│  [PRÉFÉRENCES]                                               │
│  [AIDE]                                                      │
│  [DÉCONNEXION]                                               │
└─────────────────────────────────────────────────────────────┘
```

#### Version owner (Role.OWNER — rôle plateforme, distinct de MemberRole)
```
┌─────────────────────────────────────────────────────────────┐
│                     🥕 Amap Livraisons                      │
├─────────────────────────────────────────────────────────────┤
│  👤 Alice Martin (OWNER)                           [Fermer] │
├─────────────────────────────────────────────────────────────┤
│  [ACCUEIL]                                                   │
│  [DEMANDES D'ORGANISATION]                                   │
│  [UTILISATEURS]                                              │
│  ────────────────────────────────────────────────────────   │
│  [NOTIFICATIONS]                                             │
│  [PRÉFÉRENCES]                                               │
│  [AIDE]                                                      │
│  [DÉCONNEXION]                                               │
└─────────────────────────────────────────────────────────────┘
```

#### Version producteur (perspective ProducerAccount — distincte de MemberRole)
```
┌─────────────────────────────────────────────────────────────┐
│                     🥕 Amap Livraisons                      │
├─────────────────────────────────────────────────────────────┤
│  👤 Ferme des Collines (PRODUCTEUR)                [Fermer] │
├─────────────────────────────────────────────────────────────┤
│  [ACCUEIL PRODUCTEUR]                                        │
│  ────────────────────────────────────────────────────────   │
│  [NOTIFICATIONS]                                             │
│  [PRÉFÉRENCES]                                               │
│  [AIDE]                                                      │
│  [DÉCONNEXION]                                               │
└─────────────────────────────────────────────────────────────┘
```

### Exemples de menus fusionnés (multi-rôles)

#### a) AMAPIEN + COORDINATEUR
```
┌─────────────────────────────────────────────────────────────┐
│                     🥕 Amap Livraisons                      │
├─────────────────────────────────────────────────────────────┤
│  👤 Marie Dupont                                   [Fermer] │
│  Rôles : AMAPIEN · COORDINATEUR                            │
├─────────────────────────────────────────────────────────────┤
│  — Amapien —                                               │
│  [ACCUEIL]                                                   │
│  [MES CONTRATS]                                              │
│  [MON HISTORIQUE]                                            │
│  — Coordinateur —                                            │
│  [PLANNING DES LIVRAISONS]                                   │
│  [Gestion des livraisons]                                      │
│  [CONTRATS DE SAISON]                                        │
│  [CONTRATS DES AMAPIENS]                                     │
│  ────────────────────────────────────────────────────────   │
│  [NOTIFICATIONS]                                             │
│  [PRÉFÉRENCES]                                               │
│  [AIDE]                                                      │
│  [DÉCONNEXION]                                               │
└─────────────────────────────────────────────────────────────┘
```

#### b) COORDINATEUR + ADMIN
```
┌─────────────────────────────────────────────────────────────┐
│                     🥕 Amap Livraisons                      │
├─────────────────────────────────────────────────────────────┤
│  👤 Sophie Leroy                                   [Fermer] │
│  Rôles : COORDINATEUR · ADMIN                               │
├─────────────────────────────────────────────────────────────┤
│  — Coordinateur —                                            │
│  [ACCUEIL]                                                   │
│  [MES CONTRATS]                                              │
│  [MON HISTORIQUE]                                            │
│  [PLANNING DES LIVRAISONS]                                   │
│  [Gestion des livraisons]                                      │
│  [CONTRATS DE SAISON]                                        │
│  [CONTRATS DES AMAPIENS]                                     │
│  — Admin —                                                   │
│  [TABLEAU DE BORD]                                           │
│  [UTILISATEURS]                                              │
│  [PRODUCTEURS]                                               │
│  [TEMPLATES DE LIVRAISON]                                    │
│  [DEMANDES D'ADHÉSION]                                       │
│  [CONFIGURATION DE L'ORGANISATION]                           │
│  ────────────────────────────────────────────────────────   │
│  [NOTIFICATIONS]                                             │
│  [PRÉFÉRENCES]                                               │
│  [AIDE]                                                      │
│  [DÉCONNEXION]                                               │
└─────────────────────────────────────────────────────────────┘
```

#### c) AMAPIEN + COORDINATEUR + ADMIN
```
┌─────────────────────────────────────────────────────────────┐
│                     🥕 Amap Livraisons                      │
├─────────────────────────────────────────────────────────────┤
│  👤 Alice Martin                                   [Fermer] │
│  Rôles : AMAPIEN · COORDINATEUR · ADMIN                    │
├─────────────────────────────────────────────────────────────┤
│  — Amapien —                                               │
│  [ACCUEIL]                                                   │
│  [MES CONTRATS]                                              │
│  [MON HISTORIQUE]                                            │
│  — Coordinateur —                                            │
│  [PLANNING DES LIVRAISONS]                                   │
│  [Gestion des livraisons]                                      │
│  [CONTRATS DE SAISON]                                        │
│  [CONTRATS DES AMAPIENS]                                     │
│  — Admin —                                                   │
│  [TABLEAU DE BORD]                                           │
│  [UTILISATEURS]                                              │
│  [PRODUCTEURS]                                               │
│  [TEMPLATES DE LIVRAISON]                                    │
│  [DEMANDES D'ADHÉSION]                                       │
│  [CONFIGURATION DE L'ORGANISATION]                           │
│  ────────────────────────────────────────────────────────   │
│  [NOTIFICATIONS]                                             │
│  [PRÉFÉRENCES]                                               │
│  [AIDE]                                                      │
│  [DÉCONNEXION]                                               │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Comportement général
- Le menu s'ouvre via un bouton `[Menu]` dans l'en-tête.
- Sur mobile : panneau plein écran.
- Sur desktop : panneau latéral.
- La fermeture se fait par `[Fermer]`, clic extérieur ou choix d'une entrée.

### Affichage multi-rôles
- L'en-tête affiche tous les rôles actifs de l'utilisateur séparés par `·`, en ordre croissant de privilège : AMAPIEN → COORDINATEUR → ADMIN.
- Les entrées de menu sont regroupées par section de rôle, dans le même ordre croissant.
- Les items communs à plusieurs rôles n'apparaissent qu'une seule fois, dans la section du rôle le moins privilégié qui les inclut.
- [Notifications], [Préférences], [Aide] et [Déconnexion] sont toujours affichés une seule fois en bas du menu, séparés par un séparateur horizontal, quel que soit le nombre de rôles.
- Les rôles plateforme (`OWNER`) et les perspectives producteur (`ProducerAccount`) ne se fusionnent pas avec les `MemberRole` — ils disposent de menus distincts.

### Accès aux écrans
- Un écran n'est accessible qu'aux rôles dont le menu le propose, même en saisissant son adresse ou en suivant un ancien lien : écrans owner (y compris « Demandes d'organisation » et « Demandes producteurs ») → OWNER ; autres écrans admin et « Utilisateurs » → ADMIN ; écrans coordinateur → COORDINATOR ou ADMIN ; espace producteur (catalogue, livraisons) → producteur ; écrans amapien (accueil, contrats, planning, historique, échanges) → tout membre de l'AMAP. Sinon l'utilisateur est renvoyé vers sa page d'accueil.
- [Notifications], [Préférences] et [Aide] restent accessibles à tous.

### Entrées par rôle
- **VOLUNTEER** : [Accueil](../member/screen-member-01-home.md), [Mes contrats](../member/screen-member-04-contracts.md), [Mon historique](../member/screen-member-03-history.md)
- **COORDINATOR** : [Accueil](../member/screen-member-01-home.md), [Mes contrats](../member/screen-member-04-contracts.md), [Mon historique](../member/screen-member-03-history.md), [Planning des livraisons](../member/screen-member-02-delivery-plan.md), [Gestion des livraisons](../coordinator/screen-coordinator-02-time-slots.md), [Contrats de saison](../coordinator/screen-coordinator-09-contract-definition.md), [Contrat par Amapien](../coordinator/screen-coordinator-08-member-contracts.md)
- **ADMIN** : [Tableau de bord](../admin/screen-admin-01-home.md), [Utilisateurs](../admin/screen-admin-03-user-management.md), [Producteurs](../admin/screen-admin-04-producer-management.md), [Modèles de livraison](../admin/screen-admin-05-delivery-template.md), [Demandes d'adhésion](../admin/screen-admin-06-membership-requests.md), [Configuration de l'organisation](../admin/screen-admin-02-organization-config.md)
- **OWNER** : [Accueil](../owner/screen-owner-01-home.md), [Demandes d'organisation](../owner/screen-owner-02-organization-requests.md), [Utilisateurs](../owner/screen-owner-03-user-management.md), [Nouvel Administrateur](../owner/screen-owner-04-invite-owner.md)
- **PRODUCER** : [Accueil producteur](../producer/screen-producer-01-home.md)
- (tous) : [Notifications] (boîte de réception `/notifications` : titre, texte et date de réception « Reçue le … » de chaque notification, les plus récentes en premier ; une notification de demande d'adhésion indique en plus l'état actuel de la demande — « Demande en attente », « Demande approuvée » ou « Demande rejetée » — et un tap ouvre les demandes d'adhésion ; un tap la marque lue et suit son lien, le bouton « Archiver » ou un glissement vers la gauche l'archive), [Préférences](screen-common-02-user-preferences.md), [Aide](screen-common-05-help.md), [Déconnexion]

## Références

- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
- **Gestion des rôles** : [`../../../../architecture/adr-001-role-management.md`](../../../../architecture/adr-001-role-management.md)
