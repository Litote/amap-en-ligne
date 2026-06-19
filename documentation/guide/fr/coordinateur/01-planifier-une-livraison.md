# Planifier une livraison

## À quoi ça sert

Créer une nouvelle livraison : date, horaires, contrats présents et besoins en
bénévoles. Un **modèle de livraison** peut pré-remplir la plupart des champs.

## Créer une livraison

1. Depuis votre tableau de bord, touchez **[➕ NOUVEAU CRÉNEAU]**.
2. Choisissez la **date de livraison**.
3. Si votre AMAP a défini des modèles de livraison, sélectionnez-en un dans **Template**.
   Si un modèle par défaut existe, il est déjà sélectionné. Le modèle pré-remplit les
   horaires, le nombre de bénévoles et l'éventuel créneau anticipé.
4. Vérifiez ou ajustez les **horaires** (début et fin).
5. Indiquez le nombre de **bénévoles requis** (minimum et maximum).
6. Cochez les **contrats présents** sur cette livraison — chaque case indique le nom
   du contrat et son producteur ; les contrats actifs à la date choisie sont tous
   cochés par défaut. La liste **« Produits présents »** se limite aux produits des
   contrats cochés.
7. Ajoutez éventuellement des **instructions spéciales**.
8. Touchez **[CRÉER CRÉNEAU]**.

```
┌──────────────────────────────────────────────┐
│ ➕ Nouveau créneau                              │
│   📅 Date : [31/01/2025]                        │
│   📄 Template : [Livraison standard ▼]          │
│   🕐 Horaires : Début [18:00]  Fin [20:00]      │
│   👥 Bénévoles : Min [5]  Max [8]               │
│   🌿 Contrats présents :                         │
│      ✅ Légumes de saison — Maraîcher Bio        │
│      ☐ Œufs fermiers — Œufs Fermiers             │
│   Produits présents :                            │
│      ✅ Tomates   ✅ Salades                     │
│   📝 Instructions spéciales : […]                │
│   [CRÉER CRÉNEAU]                               │
└──────────────────────────────────────────────┘
```

## À propos du modèle de livraison

- Le modèle ne fait que **pré-remplir** : vous pouvez tout ajuster pour cette livraison.
- Si vous modifiez vous-même le **nombre de bénévoles minimum**, un changement de
  modèle ne l'écrasera plus.
- L'option **« Aucun »** laisse les horaires entièrement libres.
- Les modèles sont créés par l'**administrateur de l'AMAP** (voir le
  [Guide de l'Administrateur d'AMAP](../admin-amap/03-modeles-de-livraison.md)). Vous ne
  pouvez pas les créer ni les modifier depuis cet écran.

## Le créneau anticipé

Si le modèle choisi prévoit un **créneau anticipé** (arrivée plus tôt pour réceptionner
les produits), ses champs s'affichent en lecture seule : heure d'arrivée anticipée,
explication visible par les amapiens et nombre maximum de volontaires.

Le lien **« Modifier pour cette livraison uniquement »** permet d'ajuster ces valeurs
pour cette livraison **sans modifier le modèle**.

## Confirmer une livraison : au moins un coordinateur par produit

Une livraison peut être créée sans coordinateur (elle est alors **planifiée**). En
revanche, elle ne peut pas passer à l'état **confirmée** tant qu'un produit n'a pas au
moins un coordinateur.

Si vous tentez de confirmer une livraison sans coordinateur sur un produit, le message
suivant s'affiche : « Cette livraison ne peut pas être confirmée : aucun coordinateur
sur le(s) contrat(s) … ». Affectez d'abord un coordinateur (voir
[La coordination par contrat](06-coordination-par-contrat.md)).

## Voir aussi

- [Gérer les bénévoles et les créneaux](02-benevoles-et-creneaux.md)
- [La coordination par contrat](06-coordination-par-contrat.md)
