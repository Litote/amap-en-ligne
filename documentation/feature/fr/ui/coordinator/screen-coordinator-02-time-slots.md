# Gestion des livraisons (Coordinateur)

## Description
Interface de création et modification des créneaux de livraison avec paramétrage des besoins en bénévoles. Lors de la création d'une nouvelle livraison, le template de livraison (*DELIVERY_TEMPLATE*) par défaut de l'organisation est sélectionné automatiquement s'il existe ; à défaut, le premier template disponible est sélectionné.

Cet écran est notamment ouvert depuis l'action `[➕ NOUVELLE LIVRAISON]` du dashboard via la route `/coordinator/time-slots/new`.

## Wireframe ASCII
```
┌─────────────────────────────────────────────────────────────┐
│                    ⚙️ Gestion des livraisons                 │
├─────────────────────────────────────────────────────────────┤
│  [← Retour Dashboard]                        [💾 Sauvegarder]│
└─────────────────────────────────────────────────────────────┘
│                                                             │
│  ➕ Nouvelle livraison                                       │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  📅 Date de livraison:                                 │ │
│  │     [📅 31/01/2025 ▼]                                  │ │
│  │                                                         │ │
│  │  📄 Template:                                           │ │
│  │     [Livraison avec réception anticipée ▼]             │ │
│  │     (sélectionné automatiquement par défaut)            │ │
│  │     (Aucun / Livraison standard / ...)                  │ │
│  │                                                         │ │
│  │  🕐 Horaires:                                           │ │
│  │     Début: [18:00 ▼]  Fin: [20:00 ▼]                  │ │
│  │                                                         │ │
│  │  ┄┄┄┄┄ Créneau anticipé ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ │ │
│  │  🕐 Heure d'arrivée anticipée: [17:00]  (du template)  │ │
│  │  💬 Explication: "Réception des légumes du maraîcher"  │ │
│  │  👥 Max volontaires anticipés: [2]                      │ │
│  │     [Modifier pour cette livraison uniquement]          │ │
│  │                                                         │ │
│  │  👥 Bénévoles requis:                                   │ │
│  │     Minimum: [5 ▼]  (prérempli depuis le template)      │ │
│  │     Maximum: [8 ▼]                                      │ │
│  │     Si modifié manuellement, reste inchangé             │ │
│  │     lors d'un changement de template                    │ │
│  │                                                         │ │
│  │  🌿 Contrats présents:                                  │ │
│  │     (contrats dont la date est dans leur plage          │ │
│  │      et qui ne sont pas effectivement terminés)         │ │
│  │     ✅ Légumes de saison — Maraîcher Bio                │ │
│  │     ✅ Œufs fermiers — Œufs Fermiers                    │ │
│  │     ☐ Pain hebdo — Pain Artisanal                       │ │
│  │                                                         │ │
│  │  Produits présents:                                     │ │
│  │     (produits des contrats cochés uniquement)           │ │
│  │     ✅ Tomates        ✅ Œufs                           │ │
│  │                                                         │ │
│  │  👥 Coordinateurs par contrat:                          │ │
│  │     🥕 Légumes de saison                                │ │
│  │        Aucun coordinateur · [ME PORTER COORDINATEUR]    │ │
│  │     🍞 Pain artisanal                                   │ │
│  │        Jean Morel ✕ · [ME PORTER COORDINATEUR]          │ │
│  │     (vue ADMIN : [+ Ajouter un coordinateur ▼])         │ │
│  │                                                         │ │
│  │  📝 Instructions spéciales:                             │ │
│  │     ┌─────────────────────────────────────────────────┐ │ │
│  │     │ Prévoir contenants supplémentaires pour        │ │ │
│  │     │ les nouvelles conserves de saison...           │ │ │
│  │     └─────────────────────────────────────────────────┘ │ │
│  │                                                         │ │
│  │     [CRÉER LIVRAISON]                                  │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  📋 Livraisons existantes                                    │
│  (regroupées par section : En cours · À venir · Passées)    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  En cours                                               │ │
│  │  📅 17 Jan • 18h-20h  👥 2/5  🔴 CRITIQUE              │ │
│  │                         [MODIFIER]  [SUIVRE]            │ │
│  │                                                         │ │
│  │  À venir                                                │ │
│  │  📅 24 Jan • 18h-20h  👥 3/5  ⚠️ À surveiller          │ │
│  │                         [MODIFIER]  [SUIVRE]            │ │
│  │  📅 31 Jan • 18h-20h  👥 0/5  ⭕ Nouveau               │ │
│  │                         [MODIFIER]  [SUIVRE]            │ │
│  │                                                         │ │
│  │  Passées                                                │ │
│  │  📅 10 Jan • 18h-20h  👥 5/5  ✅ Complet               │ │
│  │                         [MODIFIER]  [SUIVRE]            │ │
│  └─────────────────────────────────────────────────────────┘ │
│  (balayer une carte vers la gauche pour la supprimer)       │
│                                                             │
│ [📊 STATISTIQUES] [📧 COMMUNICATION] [⚙️ PARAMÈTRES]       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

### Actions principales - Nouvelle livraison
- **[📅 Date picker]** : Sélection de la date de livraison
- **[Template dropdown]** : Sélection d'un template de livraison (*DELIVERY_TEMPLATE*) parmi les templates définis par l'admin de l'organisation ; si un template par défaut existe pour l'organisation, il est déjà sélectionné à l'ouverture du formulaire — sinon le premier template disponible est présélectionné. L'option « Aucun » laisse les horaires et le créneau anticipé entièrement libres. Le coordinateur ne peut pas créer ni modifier de template depuis cet écran.
- **[Horaires dropdown]** : Configuration des heures de début/fin (préremplies depuis le template si un template est sélectionné)
- **[Créneau anticipé]** : Affiché en lecture seule si un template avec créneau anticipé est sélectionné ; un lien « Modifier pour cette livraison uniquement » permet de surcharger les valeurs pour cette livraison uniquement, sans altérer le template source
- **[Bénévoles dropdown]** : Définition des besoins min/max en bénévoles ; le minimum est prérempli depuis le nombre de bénévoles souhaité du template sélectionné tant que le coordinateur ne l'a pas modifié manuellement
- **[Cases contrats]** : Sélection des contrats (*CONTRACT*) proposables à la date de livraison choisie. Un contrat est proposé si **la date de livraison est comprise dans sa plage [minDeliveryDate, maxDeliveryDate] ET si le contrat n'est pas effectivement terminé** (ni statut `ENDED`, ni `maxDeliveryDate` dans le passé). Les contrats avec le statut *En préparation* (`IN_PREPARATION`) restent proposables dès lors que leur plage de dates le permet. Chaque case affiche le nom du contrat et celui de son producteur (*ProducerAccount*). À la création, tous les contrats proposables sont cochés par défaut ; en modification, les contrats des livraisons-contrats (*DELIVERY_CONTRACT*) existantes sont cochés. La liste « Produits présents » est restreinte aux produits référencés par les prix (*PRODUCT_PRICE*) des contrats cochés ; un contrat sans aucun prix défini propose tous les produits de son producteur. Si aucun contrat proposable n'existe pour l'organisation, la section contrats est masquée et tous les produits de l'organisation restent proposés.
- **[Coordinateurs par contrat]** : Bloc d'affectation des coordinateurs (*COORDINATOR*) pour chaque livraison-contrat (*DELIVERY_CONTRACT*) de la livraison. Les livraisons-contrats sont dérivées des contrats (*CONTRACT*) cochés lors de l'enregistrement : à la création, chaque contrat actif coché produit une livraison-contrat en statut `PENDING`, sans coordinateur ; en modification, les livraisons-contrats existantes sont conservées telles quelles (coordinateurs, créneaux, statut) tant que leur contrat reste coché, et celles des contrats décochés sont retirées. À la création, le bloc affiche en aperçu les contrats qui seront liés, chacun « Aucun coordinateur » — aucun préchargement depuis les coordinateurs référents du contrat (*CONTRACT*).
  - **[ME PORTER COORDINATEUR]** (visible par tout coordinateur) : ajoute l'utilisateur connecté à la liste des coordinateurs du contrat-livraison. Disponible si la livraison est active (statut différent de `COMPLETED` / `CANCELLED`).
  - **✕** à côté d'un nom : retire un coordinateur. Pour un coordinateur non-ADMIN, le bouton n'est actif que sur sa propre entrée et tant que la livraison n'est pas `IN_PROGRESS`.
  - **[+ Ajouter un coordinateur ▼]** (visible uniquement par ADMIN) : ouvre un sélecteur listant tous les coordinateurs (*COORDINATOR*) de l'AMAP et permet d'en affecter n'importe lequel.
- **[Zone texte Instructions]** : Consignes spéciales pour la livraison
- **[CRÉER LIVRAISON]** : Validation et création de la nouvelle livraison

### Actions principales - Gestion existants
La liste des livraisons existantes réunit **toutes** les livraisons (création, modification et suivi depuis un seul écran). Elle est regroupée en trois sections affichées dans cet ordre, chacune masquée si elle est vide :
- **En cours** : livraisons au statut `IN_PROGRESS`.
- **À venir** : livraisons actives (non `IN_PROGRESS`) dont la date est postérieure à maintenant.
- **Passées** : toutes les autres (date passée, `COMPLETED`, `CANCELLED`).

Chaque carte propose deux actions :
- **[MODIFIER]** : ouvre le formulaire d'édition de la livraison existante.
- **[SUIVRE]** : ouvre l'écran de suivi en direct ([Écran 4](screen-coordinator-04-delivery-tracking.md)) — présences bénévoles et récupération des paniers.

La suppression d'une livraison se fait en **balayant la carte vers la gauche** (geste de suppression).

Dans la liste des livraisons existantes, l'indicateur `👥 N/M` correspond aux inscriptions actuelles sur bénévolat sur la livraison, rapportées au nombre de bénévoles requis pour cette livraison.

### Actions globales
- **[← Retour Dashboard]** : Retour au dashboard coordination ([Écran 1](screen-coordinator-01-home.md))
- **[💾 Sauvegarder]** : Sauvegarde des modifications en cours
- **[📊 STATISTIQUES]** : Accès aux analytics des livraisons
- **[📧 COMMUNICATION]** : Outils de communication membre
- **[⚙️ PARAMÈTRES]** : Configuration globale des livraisons

### États des livraisons
- **🔴 CRITIQUE** : Moins de 50% des bénévoles requis
- **⚠️ À surveiller** : Entre 50% et 80% des bénévoles
- **⭕ Nouveau** : Livraison créée mais pas encore publiée
- **✅ Complet** : Tous les bénévoles requis confirmés

## Formulaire de création

### Champs obligatoires
- **Date de livraison** : Sélection dans un calendrier
- **Horaires** : Heures de début et fin (par défaut 18h-20h, ou préremplies depuis le template)
- **Bénévoles minimum** : Nombre requis pour assurer la livraison ; prérempli depuis le nombre de bénévoles souhaité du template sélectionné
- **Contrats** : Sélection parmi les contrats (*CONTRACT*) proposables à la date choisie (plage de dates compatible ET non effectivement terminés) ; tous cochés par défaut à la création

### Champs optionnels
- **Template** : Sélecteur du modèle de livraison (*DELIVERY_TEMPLATE*) à appliquer (liste des templates définis par l'admin + option « Aucun »). Si l'organisation a défini un template par défaut, il est sélectionné automatiquement à l'ouverture du formulaire de création ; sinon le premier template disponible est présélectionné. La sélection d'un template préremplie les horaires standard, le minimum de bénévoles et, si le template en comporte un, le créneau anticipé. Le coordinateur ne peut pas créer ni modifier de template depuis cet écran — les templates sont gérés exclusivement par l'admin ([Écran admin 5](../admin/screen-admin-05-delivery-template.md)).
- **Créneau anticipé** : Visible en lecture seule si le template sélectionné définit un créneau anticipé (*EARLY_SLOT*). Les champs affichés sont :
  - Heure d'arrivée anticipée (antérieure à l'heure de début standard)
  - Explication (texte visible par les Amapiens)
  - Nombre maximum de volontaires pour ce créneau anticipé
  L'action « Modifier pour cette livraison uniquement » passe ces champs en édition sans modifier le template source.
- **Bénévoles maximum** : Limite supérieure d'inscription
- **Contrats additionnels** : Œufs, Pain, Fromage selon les contrats actifs disponibles
- **Instructions spéciales** : Consignes particulières pour cette livraison

### Comportement du préremplissage des bénévoles
- Tant que le coordinateur n'a pas modifié manuellement le champ **Bénévoles minimum**, ce champ suit le nombre de bénévoles souhaité du template sélectionné
- Dès que le coordinateur saisit manuellement une autre valeur dans **Bénévoles minimum**, un changement ultérieur de template n'écrase plus cette valeur

### Matérialisation des créneaux bénévoles
Les amapiens ne peuvent s'inscrire que sur un créneau (*MEMBER_SLOT*) existant — le serveur interdit la création de créneau à un appelant `VOLUNTEER`. Chaque enregistrement du formulaire (création ou modification) par un coordinateur/admin matérialise donc les créneaux par défaut **lorsque la livraison n'en possède encore aucun**, sur sa première livraison-contrat (*DELIVERY_CONTRACT*) :
- un créneau `STANDARD` ouvert, de l'horaire de la livraison jusqu'à l'heure de fin du template sélectionné (à défaut : deux heures après le début), avec la capacité du champ **Bénévoles minimum** ;
- un créneau `EARLY` ouvert si le template définit un créneau anticipé (*EARLY_SLOT*), de l'heure d'arrivée anticipée à la fin standard, avec la capacité maximale du créneau anticipé.

Les livraisons générées automatiquement à la création d'un contrat (génération hebdomadaire) portent les mêmes créneaux par défaut. Les identifiants de créneau restent vides côté client — le serveur les alloue à la première écriture.

### Validation des données
- **Cohérence horaires** : Fin postérieure au début
- **Cohérence créneau anticipé** : L'heure d'arrivée anticipée est strictement antérieure à l'heure de début standard
- **Capacité bénévoles** : Minimum >= 1, Maximum >= Minimum
- **Unicité date** : Pas de doublon sur la même date
- **Contrats logiques** : Vérification de la cohérence des sélections
- **Au moins un coordinateur par contrat à la confirmation** : la transition d'une livraison de `PLANNED` à `CONFIRMED` n'est pas autorisée tant qu'au moins une livraison-contrat (*DELIVERY_CONTRACT*) n'a pas reçu de coordinateur. La création initiale en statut `PLANNED` reste possible sans coordinateur — l'affectation peut se faire ensuite via `[ME PORTER COORDINATEUR]`.

### Erreurs métier

| Situation | Message affiché |
|-----------|-----------------|
| Tentative de confirmation alors qu'un ou plusieurs contrats n'ont pas de coordinateur | « Cette livraison ne peut pas être confirmée : aucun coordinateur sur le(s) contrat(s) <noms>. » |
| Tentative de retrait d'un autre coordinateur que soi-même (coordinateur non-ADMIN) | « Seul un admin peut retirer un autre coordinateur. » |
| Tentative d'auto-affectation sur une livraison déjà clôturée ou annulée | « Cette livraison n'est plus active. » |
| Tentative de liaison d'un contrat effectivement terminé à une nouvelle livraison (rejet serveur hors-ligne) | « Opération refusée : ce contrat est terminé. » (`CONTRACT_ENDED`) |

> **Contrat effectivement terminé** : un contrat est effectivement terminé si son champ `statut` vaut `ENDED` OU si sa date de dernière livraison est strictement antérieure à la date du jour. Le serveur refuse toute nouvelle livraison liée à un tel contrat. La modification d'une livraison passée déjà liée reste autorisée.

## Références

### Documentation liée
- **Spécifications UI** : `../spec-ui.md` - Section "Gestion des livraisons"
- **Dashboard coordination** : Écran 1 pour le retour et navigation
- **Gestion des templates** : [`../admin/screen-admin-05-delivery-template.md`](../admin/screen-admin-05-delivery-template.md) — création et modification des templates de livraison (*DELIVERY_TEMPLATE*) par l'admin
