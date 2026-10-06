# Planifier une livraison

## À quoi ça sert

Créer une nouvelle livraison : date, horaires, contrats présents et besoins en
bénévoles. Un **modèle de livraison** peut pré-remplir la plupart des champs.

> **Astuce** : à la création d'un contrat de saison, l'application propose de créer
> d'un coup toutes ses livraisons hebdomadaires (voir
> [Créer les livraisons du contrat](03-contrats-de-saison.md#créer-les-livraisons-du-contrat)).
> Cette page décrit la création d'une livraison à l'unité.

## Créer une livraison

1. Ouvrez le **[Menu]**, puis **[Gestion des livraisons]**, et touchez le bouton
   **Ajouter livraison** (« + »). Vous pouvez aussi toucher **[➕ NOUVEAU CRÉNEAU]**
   depuis votre tableau de bord. L'écran s'intitule **« Nouvelle livraison »**.
2. Touchez **« Sélectionner une date »** pour choisir le jour, puis
   **« Sélectionner l'heure »** pour l'heure de la livraison.
3. Si votre AMAP a défini des modèles de livraison, sélectionnez-en un dans **Modèle de
   livraison (facultatif)**. Si un modèle par défaut existe, il est déjà sélectionné. Le
   modèle pré-remplit les horaires, le nombre de bénévoles et l'éventuel créneau anticipé.
4. Dans **Horaires des créneaux**, vérifiez ou ajustez l'**heure d'arrivée des
   bénévoles** et l'**heure de fin** (« Selon le modèle » tant que vous n'y touchez pas).
5. Indiquez les **Bénévoles minimum requis**.
6. Cochez les **contrats présents** sur cette livraison (« 🌿 Contrats présents ») —
   chaque case indique le nom du contrat et son producteur ; les contrats actifs à la
   date choisie sont tous cochés par défaut. La liste **« Produits présents »** se limite
   aux produits des contrats cochés. Si aucun contrat ne couvre la date, un message
   vous invite à vérifier les dates des contrats dans « Gestion des contrats ».
7. Ajoutez éventuellement des **Instructions (facultatif)**.
8. Touchez **[Enregistrer]**.

```
┌──────────────────────────────────────────────
│ Nouvelle livraison
│   📅 samedi 31 janvier 2026
│   🕐 18:00
│   Modèle de livraison (facultatif) : [Standard ▼]
│   Horaires des créneaux
│     Heure d'arrivée : [17:30]  Heure de fin [20:00]
│   Bénévoles minimum requis : [5]
│   🌿 Contrats présents :
│      ✅ Légumes de saison — Maraîcher Bio
│      ☐ Œufs fermiers — Œufs Fermiers
│   Produits présents :
│      ✅ Tomates   ✅ Salades
│   Instructions (facultatif) : […]
│   [Enregistrer]
└──────────────────────────────────────────────
```

Le bloc « Bénévoles minimum requis » et les créneaux de bénévolat n'apparaissent que si
l'un des contrats cochés est un **contrat principal** (voir
[Contrats de saison](03-contrats-de-saison.md)).

## À propos du modèle de livraison

- Le modèle ne fait que **pré-remplir** : vous pouvez tout ajuster pour cette livraison,
  sans modifier le modèle.
- Si vous modifiez vous-même le **nombre de bénévoles minimum**, un changement de
  modèle ne l'écrasera plus.
- L'option **« Aucun modèle »** laisse les horaires entièrement libres.
- Les modèles sont créés par l'**administrateur de l'AMAP** (voir le
  [Guide de l'Administrateur d'AMAP](../admin-amap/03-modeles-de-livraison.md)). Vous ne
  pouvez pas les créer ni les modifier depuis cet écran.

## Le créneau anticipé

Un **créneau anticipé** correspond à une arrivée plus tôt pour réceptionner les produits.
Il est repris du modèle choisi, ou peut être défini directement sur la livraison avec
l'interrupteur **« Créneau anticipé »**. Ses champs sont modifiables pour cette livraison
seulement (le modèle n'est jamais modifié) :

- **Arrivée (créneau anticipé)** ;
- **Bénévoles max (créneau anticipé)** ;
- **Explication (créneau anticipé, facultatif)**, visible par les amapiens.

## Confirmer une livraison : au moins un coordinateur par produit

Une livraison peut être créée sans coordinateur (elle est alors **planifiée**). En
revanche, elle ne peut pas passer à l'état **confirmée** tant qu'un produit n'a pas au
moins un coordinateur.

Si vous tentez de confirmer une livraison sans coordinateur sur un produit, le message
suivant s'affiche : « Cette livraison ne peut pas être confirmée : aucun coordinateur
sur le(s) contrat(s) … ». Affectez d'abord un coordinateur (voir
[La coordination par contrat](06-coordination-par-contrat.md)).

## Décrire la composition du panier

Depuis **Modifier la livraison**, le bouton **[Composition du panier]** permet d'indiquer
aux amapiens ce que contient leur panier cette semaine. Pour chaque produit et chaque
taille de panier, touchez **[Ajouter]** :

- si le producteur a défini un **catalogue de composants** (producteur avec compte),
  choisissez les composants dans la liste (avec leur icône) ;
- sinon — par exemple pour un **producteur sans compte** — saisissez le composant
  vous-même : un **nom** (obligatoire, ex. « Courge butternut ») et, si vous le
  souhaitez, un **poids** (ex. « 500 g », « 1 pièce »).

Vous pouvez ensuite ajuster le poids de chaque composant ou le retirer, puis touchez
**[Enregistrer]**. Les amapiens voient la composition sur leur planning, dans la
section repliable **« Composition du panier »** de la livraison.

Un **producteur avec compte** peut aussi composer lui-même le panier de ses produits,
depuis son application. Si vous modifiez tous les deux le même panier, la dernière
modification enregistrée l'emporte ; enregistrer la livraison pour une autre raison (un
créneau, par exemple) n'efface pas une composition saisie entre-temps par le producteur.

## Voir aussi

- [Gérer les bénévoles et les créneaux](02-benevoles-et-creneaux.md)
- [La coordination par contrat](06-coordination-par-contrat.md)
