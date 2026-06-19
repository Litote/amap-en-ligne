# Contrats de saison

## Description

Écran réservé au coordinateur permettant de définir et maintenir les contrats de saison (*CONTRACT*) utilisés ensuite pour l'affectation des contrats membre (*MEMBER_CONTRACT*).

Un contrat de saison est désormais défini par **producteur** (*ProducerAccount*) : il regroupe l'ensemble des produits du producteur avec leurs prix (optionnels) par taille de panier.

L'écran permet de :

- consulter rapidement les contrats existants ;
- créer un nouveau contrat ;
- modifier un contrat existant ;
- rattacher ou retirer des Amapiens directement depuis le détail du contrat, via une liste à cocher ;
- visualiser, pour chaque contrat, le producteur concerné (*ProducerAccount*), l'année de saison, la période, l'état et le nombre d'Amapiens rattachés.

## Wireframe ASCII

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                 📄 Contrats de saison                                       │
├──────────────────────────────────────────────────────────────────────────────┤
│  👤 Jean Morel • Coordinateur                                  📱 [Menu]    │
└──────────────────────────────────────────────────────────────────────────────┘
│                                                                              │
│  📊 Synthèse : 18 contrats • 12 actifs • 96 Amapiens rattachés              │
│                                                                              │
│  🔍 Rechercher un contrat : [________________________]   [➕ NOUVEAU CONTRAT]│
│  Filtres : [Année ▼] [Statut ▼] [Producteur ▼]                              │
│                                                                              │
│  ┌──────────────────────────────┬──────────────────────────────────────────┐ │
│  │  📚 Contrats                 │  ✏️ Contrat sélectionné                  │ │
│  │                              │                                          │ │
│  │  ┌────────────────────────┐  │  Producteur *                            │ │
│  │  │ 🥕 Légumes du Val      │  │  [Légumes du Val___________________▼]    │ │
│  │  │ 2026 • 24 livraisons   │  │                                          │ │
│  │  │ 01/04 → 30/09 • 🟢     │  │  Date de première livraison *           │ │
│  │  │ 31 Amapiens • [VOIR]   │  │  [2026-04-01_____________________________] │ │
│  │  └────────────────────────┘  │                                          │ │
│  │  ┌────────────────────────┐  │  Date de dernière livraison *            │ │
│  │  │ 🍞 Boulangerie Martin  │  │  [2026-09-30_____________________________] │ │
│  │  │ 2026 • 12 livraisons   │  │                                          │ │
│  │  │ 15/09 → 15/12 • 🔵     │  │  Année de saison *                      │ │
│  │  │ 12 Amapiens • [VOIR]   │  │  [2026________________________________]  │ │
│  │  └────────────────────────┘  │                                          │ │
│  │                              │  Nombre de livraisons *                  │ │
│  │                              │  [24_________________________________]   │ │
│  │                              │                                          │ │
│  │                              │  Prix par produit (optionnel)            │ │
│  │                              │  [x] Légumes de saison                   │ │
│  │                              │        Légumes de saison — Petit panier [120,00 €] │ │
│  │                              │        Légumes de saison — Grand panier [180,00 €] │ │
│  │                              │  [x] Pain artisanal                      │ │
│  │                              │        Pain artisanal       [  50,00 €] │ │
│  │                              │  [ ] Fromage de chèvre                   │ │
│  │                              │                                          │ │
│  │                              │  Statut *                                │ │
│  │                              │  [En préparation________________▼]       │ │
│  │                              │                                          │ │
│  │                              │  Modèle de livraison                     │ │
│  │                              │  [Aucun_________________________▼]       │ │
│  │                              │                                          │ │
│  │                              │  Coordinateurs référents                 │ │
│  │                              │  [Jean Morel ✕] [Claire Petit ✕] [+]    │ │
│  │                              │                                          │ │
│  │                              │  Amapiens rattachés (31)                 │ │
│  │                              │  🔍 Rechercher un amapien : [_________]  │ │
│  │                              │  [TOUT SÉLECTIONNER]                     │ │
│  │                              │  [x] Claire Petit          Actif         │ │
│  │                              │  [x] Paul Durand           Suspendu      │ │
│  │                              │  [ ] Sophie Bernard                      │ │
│  │                              │                                          │ │
│  │                              │  [🗑 SUPPRIMER]  [ENREGISTRER LE CONTRAT] │ │
│  └──────────────────────────────┴──────────────────────────────────────────┘ │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

| Contrôle | Cible | Comportement |
|----------|-------|--------------|
| `[Menu]` | menu principal | Ouvre le menu partagé ([Menu principal](../common/screen-common-01-menu.md)) |
| Champ `Rechercher un contrat` | `/coordinator/contracts` | Filtre la liste par producteur ou année sans quitter l'écran |
| Filtre `[Année ▼]` | `/coordinator/contracts` | Restreint la liste à une année de saison donnée |
| Filtre `[Statut ▼]` | `/coordinator/contracts` | Filtre les contrats selon leur état visible : en préparation, actif, à venir, terminé |
| Filtre `[Producteur ▼]` | `/coordinator/contracts` | Filtre les contrats selon le producteur concerné |
| `[➕ NOUVEAU CONTRAT]` | `/coordinator/contracts?mode=new` | Ouvre le formulaire en mode création, avec tous les champs vides |
| `[VOIR]` | `/coordinator/contracts/:contractId` | Charge le contrat sélectionné dans le panneau de droite |
| Sélecteur `Producteur` | `/coordinator/contracts/:contractId` | Permet de choisir le producteur concerné par le contrat ; met à jour la section « Prix par produit » avec les produits et tailles de panier du producteur sélectionné |
| Sélecteur `Statut` | `/coordinator/contracts/:contractId` | Permet de choisir l'état du contrat parmi *En préparation* (`IN_PREPARATION`, défaut à la création), *Actif* (`ACTIVE`) et *Terminé* (`ENDED`). Un contrat *En préparation* n'est pas visible pour les Amapiens — seuls les coordinateurs le voient. |
| Sélecteur `Modèle de livraison` | `/coordinator/contracts/:contractId` | Sélecteur optionnel permettant de lier un template de livraison (*DELIVERY_TEMPLATE*) au contrat. L'option « Aucun » indique l'absence de template. Si un template est lié, il est utilisé lors de la génération automatique des livraisons hebdomadaires. |
| Champ `Date de première livraison` | `/coordinator/contracts/:contractId` | Permet de saisir la date de début du contrat ; l'année de saison est recalculée automatiquement si elle n'a pas été saisie manuellement |
| Champ `Date de dernière livraison` | `/coordinator/contracts/:contractId` | Permet de saisir la date de fin du contrat ; le nombre de livraisons est recalculé automatiquement si il n'a pas été saisi manuellement |
| Champ `Année de saison` | `/coordinator/contracts/:contractId` | Permet de saisir ou corriger l'année de référence du contrat (pré-remplie à partir de la date de première livraison) |
| Champ `Nombre de livraisons` | `/coordinator/contracts/:contractId` | Permet de saisir ou corriger le nombre total de livraisons prévues (pré-rempli automatiquement à partir des dates) |
| Section `Prix par produit` | `/coordinator/contracts/:contractId` | Permet de saisir un prix optionnel par produit et par taille de panier pour le producteur sélectionné ; les lignes sont générées dynamiquement selon les produits du producteur. Chaque produit est précédé d'une **case à cocher** déterminant s'il fait partie du contrat : un produit décoché masque ses champs de prix et n'est pas inclus dans le contrat à l'enregistrement. Au choix du producteur, tous les produits sont cochés par défaut ; en modification, sont cochés les produits ayant au moins un prix (*PRODUCT_PRICE*) enregistré — un contrat sans aucun prix défini affiche tous les produits cochés. Décocher puis recocher un produit sans enregistrer restaure les prix saisis. |
| Sélecteur `Coordinateurs référents` | `/coordinator/contracts/:contractId` | Ajoute ou retire un ou plusieurs coordinateurs référents — liste informative ; aucun préchargement automatique sur les futures livraisons (*DELIVERY*) |
| Champ `Rechercher un amapien` | `/coordinator/contracts/:contractId` | Filtre la liste « Amapiens rattachés » par nom ou email, sans modifier la sélection |
| Case à cocher d'un Amapien | `/coordinator/contracts/:contractId` | Cocher rattache l'Amapien à l'enregistrement ; décocher un Amapien déjà rattaché ouvre une boîte de dialogue de confirmation expliquant les conséquences du retrait |
| `[TOUT SÉLECTIONNER]` | `/coordinator/contracts/:contractId` | Coche d'un coup tous les Amapiens visibles (après filtre) non encore cochés ; ne décoche jamais personne |
| `[🗑 SUPPRIMER]` | `/coordinator/contracts` | Affiche une boîte de dialogue de confirmation. Après confirmation, supprime définitivement le contrat et revient à la liste. Désactivé si le contrat est rattaché à des Amapiens actifs. |
| `[ENREGISTRER LE CONTRAT]` | `/coordinator/contracts/:contractId` ou `/coordinator/contracts` | Enregistre la création ou les modifications du contrat affiché |

### Règles d'affichage

- La liste affiche en priorité les contrats correspondant aux filtres actifs.
- Chaque contrat visible présente au minimum : producteur, année de saison, période, état et nombre d'Amapiens rattachés.
- Le contrat sélectionné reste surligné dans la liste tant que son détail est affiché.
- Le panneau de droite bascule entre **mode création** et **mode édition** sans changer de page.
- La section « Amapiens rattachés (N) » liste tous les Amapiens de l'AMAP, triés par nom : cochés = rattachés au contrat. Le compteur N reflète la sélection courante. Chaque Amapien déjà rattaché affiche le statut de son inscription (*MEMBER_CONTRACT*) : Actif, Suspendu, Terminé, Annulé ou Absent.
- Décocher puis recocher un Amapien déjà rattaché sans enregistrer restaure son inscription d'origine (date, statut, souscriptions) — rien n'est perdu tant que le contrat n'est pas enregistré.
- Si l'AMAP ne compte aucun Amapien, la section affiche : « Aucun amapien dans cette AMAP. »

## Création et modification

### Création d'un contrat

Le coordinateur clique sur **[➕ NOUVEAU CONTRAT]**, renseigne les champs du formulaire puis valide avec **[ENREGISTRER LE CONTRAT]**.

Procédure détaillée :

1. Cliquer sur **[➕ NOUVEAU CONTRAT]**.
2. Choisir le **producteur** dans le sélecteur — la section « Prix par produit » se met à jour avec les produits du producteur sélectionné.
3. Renseigner la **date de première livraison** et la **date de dernière livraison** — l'année de saison et le nombre de livraisons sont calculés automatiquement et peuvent être ajustés manuellement.
4. Choisir le **statut** du contrat (défaut : *En préparation*). Un contrat *En préparation* n'est pas visible par les Amapiens tant que son statut n'est pas changé.
5. Choisir éventuellement un **modèle de livraison** dans le sélecteur (option « Aucun » par défaut).
6. Décocher éventuellement les **produits à exclure du contrat** (tous cochés par défaut — au moins un produit doit rester coché), puis saisir optionnellement les **prix par produit** (et par taille de panier si le produit en propose plusieurs).
7. Ajouter éventuellement des **coordinateurs référents**.
8. Cocher éventuellement les **Amapiens à rattacher** — d'un coup via **[TOUT SÉLECTIONNER]** ou un par un.
9. Cliquer sur **[ENREGISTRER LE CONTRAT]**.

Après enregistrement, le nouveau contrat apparaît immédiatement dans la liste avec son état visible et son compteur d'Amapiens rattachés initialisé au nombre d'Amapiens cochés (`0` si aucun).

### Dialogue de génération des livraisons hebdomadaires

Après la sauvegarde d'un **nouveau** contrat dont les dates `minDeliveryDate` et `maxDeliveryDate` permettent de générer au moins une livraison, une boîte de dialogue s'affiche automatiquement :

> « Créer les N livraisons hebdomadaires correspondantes ? »
> [Non] [Créer]

- **[Non]** : ferme la boîte de dialogue sans créer de livraisons ; le contrat est déjà enregistré.
- **[Créer]** : génère une livraison par semaine entre `minDeliveryDate` et `maxDeliveryDate`. Si une livraison existe déjà à la même date dans l'organisation, le contrat est lié à cette livraison existante plutôt qu'une nouvelle livraison n'est créée. Le modèle de livraison (*DELIVERY_TEMPLATE*) lié au contrat est appliqué à chaque livraison créée, s'il en existe un.

### Modification d'un contrat existant

Le coordinateur sélectionne un contrat existant via **[VOIR]**, modifie les champs utiles puis valide avec **[ENREGISTRER LE CONTRAT]**.

Si le contrat est déjà rattaché à un ou plusieurs Amapiens, le nombre d'Amapiens concernés reste visible pendant toute l'édition.

### Rattacher et retirer des Amapiens

La section « Amapiens rattachés (N) » permet d'affecter plusieurs Amapiens d'un coup, sans passer par l'écran [Contrat par Amapien](screen-coordinator-08-member-contracts.md) (qui reste la vue par Amapien) :

- **Cocher** un Amapien le rattache au contrat lors de l'enregistrement, avec une inscription au statut « Actif ».
- **Décocher** un Amapien déjà rattaché ouvre une boîte de dialogue de confirmation :

> « Retirer cet amapien du contrat ? Son inscription (date, statut, souscriptions) sera définitivement supprimée à l'enregistrement. » — [ANNULER] / [RETIRER]

- Décocher un Amapien coché pendant la session (pas encore enregistré) ne demande aucune confirmation.
- Les coches et retraits ne sont appliqués qu'au clic sur **[ENREGISTRER LE CONTRAT]** — fermer l'écran sans enregistrer abandonne les changements.

### Souscriptions par produit et taille de panier

Quand un Amapien s'inscrit à un contrat, il ne peut retenir généralement qu'une variante de taille de panier par produit, pas l'intégralité des produits du contrat. Pour chaque Amapien coché, une liste de souscriptions s'affiche en retrait :

**Affichage :**

```
[x] Claire Petit
      [x] Légumes de saison — Petit panier
      [ ] Légumes de saison — Grand panier
      [x] Pain artisanal
      [ ] Fromage de chèvre
```

- Les cases à cocher dépliées correspondent aux produits inclus du contrat (ceux cochés en section « Prix par produit ») × les tailles de panier déclarées par le producteur.
- Chaque ligne affiche `{nom du produit} — {taille de panier}` (ou juste le nom si aucune taille).
- Déploiement **inline** sans ouverture d'écran secondaire.

**Comportements :**

- **Au clic sur un Amapien** (si pas encore enregistré et sans souscriptions mémorisées) : si le contrat n'offre qu'une seule option, celle-ci est **précochée automatiquement** (commodité UX). Sinon, aucune présélection.
- **Lors de l'édition d'un contrat existant** : les souscriptions de chaque Amapien déjà rattaché sont **restaurées à la sauvegarde précédente** — elles ne changent que si l'utilisateur coche/décoche manuellement.
- **Restriction : souscription obligatoire** — un Amapien coché doit avoir **au moins une souscription** (au moins une case cochée). Si un Amapien n'a aucune souscription sélectionnée, le bouton **[ENREGISTRER LE CONTRAT]** affiche l'erreur (snackbar) : 

> « Sélectionnez au moins un produit pour {prénom nom}. »

L'enregistrement reste bloqué jusqu'à ce que chaque Amapien coché ait au moins une souscription.

- **Adaptation à la structure du contrat** : si un produit coché dans « Prix par produit » est ensuite décoché avant enregistrement, les souscriptions correspondantes sont **automatiquement retirées** au save (intersection produits inclus ∩ souscriptions sélectionnées). Si cette opération vide les souscriptions d'un Amapien, le save est bloqué avec le message d'erreur ci-dessus.
- **Au décochage–recochage d'un Amapien** dans la session (sans save) : les souscriptions mémorisées sont restaurées — aucune perte.

## Validations et erreurs de cohérence métier

### Validations de formulaire

| Situation | Message affiché |
|-----------|-----------------|
| Aucun producteur sélectionné | « Sélectionnez un producteur. » |
| Aucun produit coché pour le contrat | « Sélectionnez au moins un produit pour ce contrat. » |
| Année de saison vide | « Renseignez l'année de saison. » |
| Date de dernière livraison antérieure à la date de première livraison | « La date de fin doit être postérieure ou égale à la date de début. » |
| Nombre de livraisons vide, nul ou négatif | « Le nombre de livraisons doit être supérieur à 0. » |
| Un Amapien coché n'a aucune souscription sélectionnée | « Sélectionnez au moins un produit pour {prénom nom}. » |
| Un Amapien a une souscription qui ne correspond pas aux produits actuels du contrat | « Opération refusée : la souscription ne correspond pas aux produits du contrat. » (serveur) |

### Messages métier

| Situation | Message affiché |
|-----------|-----------------|
| Enregistrement réussi après création | « Le contrat a été créé. » |
| Enregistrement réussi après modification | « Le contrat a été mis à jour. » |
| Suppression réussie | « Le contrat a été supprimé. » |
| Modification d'un contrat déjà rattaché à des Amapiens | « Ce contrat est déjà rattaché à 31 Amapiens. Vérifiez l'impact de vos modifications avant de confirmer. » |
| Tentative d'inscription d'un Amapien à un contrat effectivement terminé (rejet serveur) | « Opération refusée : ce contrat est terminé. » (`CONTRACT_ENDED`) |
| Auto-souscription d'un Amapien à un contrat en statut *En préparation* (rejet serveur) | « Opération non autorisée sur ce contrat. » (`FORBIDDEN`) |
| Échec d'enregistrement | « Le contrat n'a pas pu être enregistré. Réessayez. » |

### Règle de suppression

| Condition | Comportement |
|-----------|--------------|
| Le contrat a au moins un Amapien actif (statut ≠ `CANCELLED`) | Le bouton `[🗑 SUPPRIMER]` est désactivé. La suppression est refusée par le serveur avec `CONFLICT`. |
| Le contrat n'a aucun Amapien actif | La suppression est autorisée après confirmation dans la boîte de dialogue. |

## États vides

### Aucun contrat défini

Si aucun contrat n'existe encore :

> « Aucun contrat de saison n'est encore défini. Créez votre premier contrat. »

### Aucun résultat

Si la recherche ou les filtres ne renvoient aucun résultat :

> « Aucun contrat ne correspond à ces critères. »

### Aucun contrat sélectionné

Avant toute sélection, le panneau de droite affiche :

> « Sélectionnez un contrat existant ou créez-en un nouveau. »

### Aucun Amapien dans l'AMAP

Si l'AMAP ne compte encore aucun Amapien, la section « Amapiens rattachés » affiche :

> « Aucun amapien dans cette AMAP. »

### Aucun Amapien ne correspond à la recherche

Si le filtre « Rechercher un amapien » ne renvoie aucun résultat :

> « Aucun Amapien ne correspond à ces critères. »

### Aucun coordinateur référent renseigné

Si aucun coordinateur référent n'est associé au contrat, l'écran affiche :

> « Aucun coordinateur référent renseigné. »

### Rôle de la liste « Coordinateurs référents »

La liste sert d'**information** : elle indique les coordinateurs qui se spécialisent sur ce contrat (légumes, pain, fruits, etc.) et facilite leur identification dans les listes.

Elle **n'est pas copiée automatiquement** sur les livraisons-contrats (*DELIVERY_CONTRACT*) à venir. L'affectation d'un coordinateur à une livraison précise se fait dans l'écran de Gestion des livraisons ([Écran 2](screen-coordinator-02-time-slots.md)) ou directement depuis le tableau de bord ([Écran 1](screen-coordinator-01-home.md)) via l'action `[ME PORTER COORDINATEUR]`.

Le fait d'apparaître dans cette liste ne donne ni n'enlève aucun droit : tout coordinateur (*COORDINATOR*) de l'AMAP peut se porter coordinateur d'une livraison-contrat, même s'il n'est pas dans la liste référente.

## Contrat terminé

Un contrat de saison est **effectivement terminé** (*isEffectivelyEnded*) dès lors que l'une des deux conditions suivantes est vraie :
- son champ `statut` a été manuellement positionné à *Terminé* (`ENDED`) ; ou
- sa date de dernière livraison est strictement antérieure à la date du jour.

Les deux conditions déclenchent les mêmes blocages :

- Toute nouvelle inscription d'un Amapien à un contrat effectivement terminé est refusée par le serveur (`CONTRACT_ENDED`).
- Toute liaison d'un contrat effectivement terminé à une nouvelle livraison est refusée par le serveur (`CONTRACT_ENDED`).
- Il reste possible de retirer un Amapien d'un contrat terminé, de modifier le statut d'une inscription existante (passage à « Terminé » ou « Annulé »), et de modifier une livraison passée déjà liée au contrat.
- Dans la section « Amapiens rattachés (N) », les cases des Amapiens **non rattachés** sont désactivées et le message « Contrat terminé — aucune nouvelle inscription possible. » est affiché ; décocher (retirer) un Amapien rattaché reste possible.

## Statuts visibles

Le **statut affiché** d'un contrat combine son champ `statut` (*ContractStatus*) et ses dates :

- **🟠 En préparation** : statut `IN_PREPARATION` — le contrat n'est pas encore visible pour les Amapiens.
- **🟢 Actif** : statut `ACTIVE` et période en cours (date de dernière livraison = aujourd'hui ou future).
- **🔵 À venir** : statut `ACTIVE` mais la période n'a pas encore commencé.
- **⚪ Terminé** : statut `ENDED` OU date de dernière livraison passée.

## Références

- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
- **Menu principal** : [`../common/screen-common-01-menu.md`](../common/screen-common-01-menu.md)
- **Tableau de bord coordinateur** : [`screen-coordinator-01-home.md`](screen-coordinator-01-home.md)
- **Contrat par Amapien** : [`screen-coordinator-08-member-contracts.md`](screen-coordinator-08-member-contracts.md)
- **Mes contrats (vue Amapien)** : [`../member/screen-member-04-contracts.md`](../member/screen-member-04-contracts.md)
