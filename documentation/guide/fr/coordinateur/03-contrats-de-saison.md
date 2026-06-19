# Définir les contrats de saison

## À quoi ça sert

Définir les **contrats de saison** proposés par l'AMAP : un **producteur**, ses produits
avec leurs prix optionnels par taille de panier, une période et un nombre de livraisons.
Ces contrats servent ensuite de base pour engager les amapiens (voir
[Affecter les contrats aux amapiens](04-contrats-des-amapiens.md)).

## Y accéder

Ouvrez le **[Menu]**, puis **[CONTRATS DE SAISON]**.

## L'écran

À gauche, la liste des contrats existants ; à droite, le formulaire du contrat
sélectionné (ou en création).

```
┌───────────────────────────┬──────────────────────────────────────┐
│ 📚 Contrats                │ ✏️ Contrat sélectionné                │
│  🥕 Légumes du Val         │  Producteur *        [ … ▼]          │
│  2026 • 24 livraisons      │  Date de 1re livraison * [2026-04-01] │
│  01/04 → 30/09 • 🟢        │  Date de dernière livraison * [2026-09-30] │
│  31 Amapiens • [VOIR]      │  Année de saison *   [2026]          │
│                            │  Nombre de livraisons * [24]         │
│                            │  Prix par produit (optionnel)        │
│                            │   ☑ Légumes                          │
│                            │      Légumes — Petit  [120,00 €]     │
│                            │      Légumes — Grand  [180,00 €]     │
│                            │   ☐ Fromage de chèvre                │
│                            │  Coordinateurs référents […]         │
│                            │  Amapiens rattachés (31)             │
│                            │   🔍 Rechercher  [TOUT SÉLECTIONNER] │
│                            │   ☑ Claire Petit          Actif      │
│                            │   ☐ Sophie Bernard                   │
│                            │  [ANNULER] [ENREGISTRER]             │
└───────────────────────────┴──────────────────────────────────────┘
```

## Créer un contrat

1. Touchez **[➕ NOUVEAU CONTRAT]**.
2. Choisissez le **producteur** — la section « Prix par produit » affiche automatiquement ses produits et leurs tailles de panier, tous cochés.
3. Renseignez la **date de première livraison** et la **date de dernière livraison** — l'année de saison et le nombre de livraisons sont calculés automatiquement et peuvent être ajustés.
4. Décochez éventuellement les **produits à exclure du contrat** (au moins un produit doit rester coché), puis saisissez optionnellement les **prix par produit** (et par taille de panier si le produit en propose plusieurs). Décocher un produit masque ses prix sans les effacer : recochez-le pour les retrouver.
5. Ajoutez éventuellement des **coordinateurs référents** (voir ci-dessous).
6. Cochez éventuellement les **amapiens à rattacher** (voir ci-dessous).
7. Touchez **[ENREGISTRER LE CONTRAT]**.

Le nouveau contrat apparaît dans la liste, avec un compteur d'amapiens rattachés égal au
nombre d'amapiens cochés (zéro si aucun).

## Modifier un contrat

1. Touchez **[VOIR]** sur le contrat à modifier.
2. Ajustez les champs nécessaires.
3. Touchez **[ENREGISTRER LE CONTRAT]**.

> Si le contrat est déjà rattaché à des amapiens, leur nombre reste affiché pendant
> l'édition. L'application vous invite à vérifier l'impact de vos modifications avant de
> confirmer.

## Rattacher des amapiens en une fois

La section **« Amapiens rattachés (N) »** du formulaire liste tous les amapiens de
l'AMAP : les cases cochées correspondent aux amapiens rattachés au contrat.

- **Cochez** un ou plusieurs amapiens — ou touchez **[TOUT SÉLECTIONNER]** pour cocher
  d'un coup tous les amapiens affichés (la recherche permet de restreindre la liste
  d'abord). Les rattachements sont appliqués à l'enregistrement du contrat.
- **Décochez** un amapien déjà rattaché pour le retirer : une confirmation vous rappelle
  que son inscription (date, statut, souscriptions) sera définitivement supprimée à
  l'enregistrement. Tant que vous n'avez pas enregistré, recocher l'amapien restaure son
  inscription d'origine.

> Sur un contrat **⚪ Terminé**, il n'est plus possible de cocher de nouveaux amapiens ;
> en retirer un reste possible.

Pour une vue par amapien (tous ses contrats au même endroit), utilisez plutôt
[Affecter les contrats aux amapiens](04-contrats-des-amapiens.md).

## Les coordinateurs référents

Vous pouvez associer un ou plusieurs **coordinateurs référents** à un contrat (par
exemple un binôme « légumes » et un coordinateur « pain »).

> Cette liste est **purement informative** : elle aide à identifier qui se spécialise
> sur quel produit. Elle ne donne aucun droit particulier et **n'affecte pas
> automatiquement** ces coordinateurs aux futures livraisons. L'affectation à une
> livraison précise se fait séparément (voir
> [La coordination par contrat](06-coordination-par-contrat.md)).

## Les états d'un contrat

| Indicateur | Signification |
|------------|---------------|
| 🟢 **Actif** | La période est en cours |
| 🔵 **À venir** | Le contrat est défini mais n'a pas encore commencé |
| ⚪ **Terminé** | La période est passée |

## Voir aussi

- [Affecter les contrats aux amapiens](04-contrats-des-amapiens.md)
- [La coordination par contrat](06-coordination-par-contrat.md)
