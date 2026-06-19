# Contrat par Amapien

## Description

Écran de gestion permettant au coordinateur d'associer des contrats membre (*MEMBER_CONTRACT*) aux Amapiens à partir des contrats de saison (*CONTRACT*).

Les contrats proposés à l'affectation correspondent aux contrats de saison déjà définis dans l'écran [Contrats de saison](screen-coordinator-09-contract-definition.md).

Cet écran offre la vue **par Amapien**. Pour rattacher plusieurs Amapiens d'un coup à un même contrat, utiliser la liste à cocher « Amapiens rattachés » du détail du contrat dans l'écran [Contrats de saison](screen-coordinator-09-contract-definition.md).

Le coordinateur peut :
- consulter la liste des Amapiens et leur situation contractuelle actuelle
- affecter un ou plusieurs contrats à un Amapien
- retirer un contrat d'un Amapien
- repérer rapidement les statuts utiles à l'organisation des livraisons

## Wireframe ASCII

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                 📄 Contrat par Amapien                                      │
├──────────────────────────────────────────────────────────────────────────────┤
│  👤 Jean Morel • Coordinateur                                  📱 [Menu]    │
└──────────────────────────────────────────────────────────────────────────────┘
│                                                                              │
│  📊 Synthèse : 42 Amapiens • 31 avec contrat actif • 6 sans contrat         │
│                                                                              │
│  🔍 Rechercher un Amapien : [________________________]                       │
│  Filtres : [Tous ▼] [Statut contrat ▼] [Producteur ▼]                       │
│                                                                              │
│  ┌──────────────────────────────┬──────────────────────────────────────────┐ │
│  │  👥 Amapiens                 │  👤 Marie Dupont                         │ │
│  │                              │  🟢 2 contrats actifs • 🔵 1 à venir      │ │
│  │  ┌────────────────────────┐  │                                          │ │
│  │  │ Marie Dupont          │  │  Contrats attribués                       │ │
│  │  │ 🟢 2 actifs • 🔵 1     │  │  ┌──────────────────────────────────────┐ │ │
│  │  │ [VOIR]                │  │  │ 🌿 Panier légumes printemps          │ │ │
│  │  └────────────────────────┘  │  │ 🟢 Actif • 1 avr 2025 → 30 sept 2025│ │ │
│  │  ┌────────────────────────┐  │  │ [RETIRER]                            │ │ │
│  │  │ Paul Martin           │  │  └──────────────────────────────────────┘ │ │
│  │  │ ⚪ Aucun contrat       │  │  ┌──────────────────────────────────────┐ │ │
│  │  │ [VOIR]                │  │  │ 🍞 Pain artisanal                    │ │ │
│  │  └────────────────────────┘  │  │ 🔵 À venir • 15 sept 2025 → 15 déc  │ │ │
│  │  └──────────────────────────  │  │ [RETIRER]                            │ │ │
│  │                              │  └──────────────────────────────────────┘ │ │
│  │                              │                                          │ │
│  │                              │  Contrats disponibles à l'affectation    │ │
│  │                              │  ☐ 🥚 Œufs fermiers • Semestre hiver      │ │
│  │                              │  ☐ 🧀 Fromages de chèvre • Saison été     │ │
│  │                              │  ☐ 🍎 Fruits • Automne 2025               │ │
│  │                              │                                          │ │
│  │                              │  [AFFECTER LA SÉLECTION]                 │ │
│  │                              │                                          │ │
│  └──────────────────────────────┴──────────────────────────────────────────┘ │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

| Contrôle | Cible | Comportement |
|----------|-------|--------------|
| `[Menu]` | menu principal | Ouvre le menu partagé ([Menu principal](../common/screen-common-01-menu.md)) |
| Champ `Rechercher un Amapien` | `/coordinator/member-contracts` | Filtre la liste par nom et prénom sans quitter l'écran |
| Filtre `[Tous ▼]` | `/coordinator/member-contracts` | Restreint la liste des Amapiens selon le segment choisi |
| Filtre `[Statut contrat ▼]` | `/coordinator/member-contracts` | Filtre les Amapiens selon leur situation contractuelle |
| Filtre `[Producteur ▼]` | `/coordinator/member-contracts` | Filtre la liste et le détail sur un producteur donné |
| `[VOIR]` | `/coordinator/member-contracts?member=:memberId` | Charge le détail contractuel de l'Amapien sélectionné dans le panneau de droite |
| Cases à cocher des contrats disponibles | `/coordinator/member-contracts?member=:memberId` | Sélectionne un ou plusieurs contrats à affecter |
| `[AFFECTER LA SÉLECTION]` | `/coordinator/member-contracts?member=:memberId` | Attribue à l'Amapien sélectionné tous les contrats cochés |
| `[RETIRER]` | `/coordinator/member-contracts?member=:memberId` | Ouvre une confirmation avant retrait du contrat choisi |

### Règles d'affichage
- La liste des Amapiens affiche en priorité ceux qui correspondent aux filtres actifs
- Le panneau de détail n'affiche qu'un seul Amapien à la fois
- Les contrats déjà attribués n'apparaissent pas dans la liste des contrats disponibles à l'affectation
- Les contrats disponibles à l'affectation proviennent uniquement des contrats de saison déjà définis
- Les **contrats terminés** (date de dernière livraison passée) n'apparaissent **pas** dans la liste « Contrats disponibles à l'affectation »
- Les contrats terminés déjà attribués à l'Amapien restent listés dans les contrats attribués, accompagnés du badge **⚪ Terminé**
- Le coordinateur peut cocher plusieurs contrats avant de lancer l'action **[AFFECTER LA SÉLECTION]**
- Les contrats attribués actifs sont affichés avant les contrats terminés

## Confirmation et feedback

### Souscriptions par produit et taille de panier

Lors de l'affectation d'un contrat à un Amapien, ce dernier doit spécifier au moins **une souscription** (produit et taille de panier) parmi ceux offerts par le contrat.

**À l'expansion d'un contrat disponible** :

Lorsque l'utilisateur coche un contrat dans « Contrats disponibles à l'affectation », la ligne se déplie pour afficher les produits et tailles de panier disponibles (dérivés des tarifs du contrat) :

```
☑ 🥕 Panier légumes printemps
      ☐ Légumes de saison — Petit panier
      ☐ Légumes de saison — Grand panier
      ☐ Fruits de saison
      ☐ Herbes aromatiques
```

- Chaque sous-case correspond à un (produit, taille de panier) offert par le contrat.
- Chaque ligne affiche `{nom du produit} — {taille de panier}` (ou juste le nom si aucune taille).
- **Auto-présélection** : si le contrat n'offre qu'une seule option, celle-ci est précochée automatiquement.
- **Validation requise** : avant de cliquer **[AFFECTER LA SÉLECTION]**, au moins **une souscription** doit être cochée pour chaque contrat coché. Sinon, un message bloque l'affectation :

> « Sélectionnez au moins un produit pour chaque contrat coché. »

- **Garde défensive** : si un contrat n'a aucun tarif défini (section « Prix par produit » vide), la ligne affiche « Aucun produit défini pour ce contrat. » et la case à cocher est désactivée.

**Affichage des contrats attribués** :

Chaque carte de contrat attribué affiche un résumé des souscriptions de l'Amapien. Exemple :

```
🥕 Panier légumes printemps
🟢 Actif • 1 avr 2025 → 30 sept 2025
📦 Légumes de saison — Petit panier • Fruits de saison
[MODIFIER]  [RETIRER]
```

- Les souscriptions sélectionnées s'affichent sous la période, précédées de l'icône 📦 et séparées par une puce `•`.
- Un bouton **[MODIFIER]** permet d'éditer les souscriptions sans quitter l'écran (voir ci-dessous).

**Modification des souscriptions d'un contrat attribué** :

Le clic sur **[MODIFIER]** transforme la carte attribuée en **éditeur inline** :

```
🥕 Panier légumes printemps
🟢 Actif • 1 avr 2025 → 30 sept 2025
[x] Légumes de saison — Petit panier
[ ] Légumes de saison — Grand panier
[x] Fruits de saison
[ ] Herbes aromatiques
[ENREGISTRER]  [ANNULER]
```

- Les cases à cocher correspondent aux mêmes options que lors de l'affectation, pré-remplies selon les souscriptions actuelles de l'Amapien.
- Le clic sur **[ENREGISTRER]** valide les changements : le serveur accepte ou rejette selon que les souscriptions correspondent aux produits du contrat.
- Le clic sur **[ANNULER]** ferme l'éditeur sans sauvegarder.
- La même règle s'applique : **au moins une souscription** doit être cochée avant enregistrement.

### Panier partagé (*SHARED_BASKET*)

Plusieurs familles peuvent **se partager un seul panier** d'un contrat et le récupérer en alternance (une distribution chacune à tour de rôle) — par exemple deux familles sur un panier de légumes, chacune une semaine sur deux.

Chaque carte de contrat attribué affiche, sous les boutons **[MODIFIER]** / **[RETIRER]**, une ligne **Panier partagé** :

```
🥕 Panier légumes printemps
🟢 Actif • 2025                              [MODIFIER] [RETIRER]
🤝 Panier partagé avec Paul Martin           [PANIER PARTAGÉ]
```

- Quand l'Amapien n'est rattaché à aucun panier partagé : la ligne affiche « Panier partagé : non ».
- Quand il partage un panier : la ligne liste les autres familles (« 🤝 Panier partagé avec … »).

Le bouton **[PANIER PARTAGÉ]** ouvre une boîte de dialogue :

- Elle propose, à cocher, les **autres familles du contrat qui souscrivent au même produit et à la même taille de panier** (condition obligatoire — les souscriptions doivent être identiques).
- L'Amapien sélectionné récupère **la première distribution** ; les autres suivent à tour de rôle.
- Un rappel indique qu'**un panier partagé compte pour un seul panier physique** : le coordinateur doit ajuster le nombre de paniers de la distribution en conséquence.
- **[ENREGISTRER]** crée ou met à jour le partage (au moins une autre famille doit être cochée). **[SUPPRIMER LE PARTAGE]** (visible si un partage existe) le retire. **[ANNULER]** ferme sans rien changer.

Si aucune autre famille du contrat ne souscrit au même produit et à la même taille, la boîte de dialogue affiche : « Aucune autre famille de ce contrat ne souscrit au même produit et à la même taille de panier. »

#### Rejet serveur — panier partagé invalide
Si le serveur refuse un panier partagé (moins de deux familles, famille non rattachée au contrat, famille déjà dans un autre partage, ou souscriptions divergentes), un snackbar s'affiche :

> « Opération refusée : le panier partagé est invalide. »

### Retrait d'un contrat
Le bouton **[RETIRER]** ouvre une confirmation avec le message :

> « Retirer ce contrat de Marie Dupont ? »

La confirmation rappelle l'intitulé du contrat et sa période avant validation.

### Affectation réussie
Après une affectation, l'écran affiche un message de confirmation précisant le nombre de contrats ajoutés à l'Amapien sélectionné.

### Rejet serveur — contrat terminé
Si le serveur refuse l'inscription d'un Amapien à un contrat dont la date de dernière livraison est passée (cas hors-ligne : la mutation a été mise en file d'attente avant minuit puis rejetée lors de la synchronisation), un snackbar s'affiche :

> « Opération refusée : ce contrat est terminé. »

### Rejet serveur — souscription invalide
Si le serveur refuse une souscription (produit ou taille ne correspondant pas aux tarifs du contrat), un snackbar s'affiche :

> « Opération refusée : la souscription ne correspond pas aux produits du contrat. »

## États vides

### Aucun Amapien trouvé
Si la recherche ou les filtres ne renvoient aucun résultat :

> « Aucun Amapien ne correspond à ces critères. »

### Aucun Amapien sélectionné
Avant toute sélection, le panneau de détail affiche :

> « Sélectionnez un Amapien pour consulter et gérer ses contrats. »

### Aucun contrat attribué
Si l'Amapien sélectionné n'a encore aucun contrat :

> « Aucun contrat attribué pour le moment. »

### Aucun contrat disponible à l'affectation
Si tous les contrats pertinents sont déjà attribués :

> « Aucun autre contrat disponible pour cet Amapien. »

## Règles métier — contrats terminés

Un contrat est considéré comme **terminé** dès que sa date de dernière livraison est passée (état calculé, jamais stocké). Les règles applicables dans cet écran sont :

| Action | Autorisée sur un contrat terminé |
|--------|----------------------------------|
| Nouvelle inscription d'un Amapien | Non — refusée par le serveur |
| Retrait d'un Amapien (inscription existante) | Oui |
| Modification du statut d'une inscription existante (ex. passage à « Terminé » ou « Annulé ») | Oui |
| Affichage dans la liste des contrats disponibles à l'affectation | Non |
| Affichage dans les contrats attribués (déjà liés) | Oui, avec badge ⚪ Terminé |

## Statuts visibles

- **🟢 Actif** : contrat en cours
- **🔵 À venir** : contrat attribué mais pas encore démarré
- **⚪ Terminé** : contrat passé, affiché pour information (date de dernière livraison dépassée)
- **⚪ Aucun contrat** : Amapien sans contrat attribué

## Références

- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
- **Menu principal** : [`../common/screen-common-01-menu.md`](../common/screen-common-01-menu.md)
- **Tableau de bord coordinateur** : [`screen-coordinator-01-home.md`](screen-coordinator-01-home.md)
- **Contrats de saison** : [`screen-coordinator-09-contract-definition.md`](screen-coordinator-09-contract-definition.md)
- **Mes contrats (vue Amapien)** : [`../member/screen-member-04-contracts.md`](../member/screen-member-04-contracts.md)
