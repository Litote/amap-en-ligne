# Définir les contrats de saison

## À quoi ça sert

Définir les **contrats de saison** proposés par l'AMAP : un **producteur**, ses produits
avec leurs prix optionnels par taille de panier, une période et un nombre de livraisons.
Ces contrats servent ensuite de base pour engager les amapiens (voir
[Affecter les contrats aux amapiens](04-contrats-des-amapiens.md)).

## Y accéder

Ouvrez le **[Menu]**, puis **[Gestion des contrats]**.

## L'écran

À gauche, la liste des contrats existants ; à droite, le formulaire du contrat
sélectionné (ou en création).

```
┌───────────────────────────┬──────────────────────────────────────
│ 📚 Contrats                │ ✏️ Contrat sélectionné
│ [➕ NOUVEAU CONTRAT]        │  Nom du contrat *     [Légumes du Val]
│  Légumes du Val          › │  Producteur *         [ … ▼]
│  Maraîcher Bio • 2026 •    │  Statut               [Actif ▼]
│  31 amapiens               │  Modèle de livraison  [Standard ▼]
│                            │  Contrat principal    [●]
│                            │  Date de première livraison * [2026-04-01]
│                            │  Date de dernière livraison * [2026-09-30]
│                            │  Année de saison *    [2026]
│                            │  Nombre de livraisons * [24]
│                            │  Prix par produit (optionnel)
│                            │   ☑ Légumes
│                            │      Petit  [120,00 €]
│                            │      Grand  [180,00 €]
│                            │   ☐ Fromage de chèvre
│                            │  Coordinateurs référents […]
│                            │  Amapiens rattachés (31)
│                            │   🔍 Rechercher  [TOUT SÉLECTIONNER]
│                            │   ☑ Claire Petit
│                            │   ☐ Sophie Bernard
│                            │  [🗑 SUPPRIMER] [ENREGISTRER LE CONTRAT]
└───────────────────────────┴──────────────────────────────────────
```

## Créer un contrat

1. Touchez **[➕ NOUVEAU CONTRAT]**.
2. Renseignez le **Nom du contrat** (par exemple « Légumes du Val »).
3. Choisissez le **producteur** — la section « Prix par produit » affiche automatiquement
   ses produits et leurs tailles de panier, tous cochés.
4. Choisissez le **Statut** du contrat (voir [Les états d'un contrat](#les-états-dun-contrat)) :
   **En préparation** par défaut, le temps de le construire ; passez-le à **Actif** pour
   l'ouvrir aux amapiens.
5. Choisissez éventuellement un **Modèle de livraison** : il servira à créer les
   livraisons du contrat (voir ci-dessous).
6. Activez **« Contrat principal »** si ce contrat mobilise des bénévoles (par exemple les
   légumes). Seuls les contrats principaux génèrent des créneaux bénévoles et comptent
   dans le besoin « N/M bénévoles » des livraisons ; les contrats secondaires (œufs,
   fruits…) ne demandent que le coordinateur. La bascule est désactivée par défaut.
7. Renseignez la **date de première livraison** et la **date de dernière livraison** —
   l'année de saison et le nombre de livraisons sont calculés automatiquement et peuvent
   être ajustés.
8. Décochez éventuellement les **produits à exclure du contrat** (au moins un produit doit
   rester coché), puis saisissez optionnellement les **prix par produit** (et par taille
   de panier si le produit en propose plusieurs). Décocher un produit masque ses prix sans
   les effacer : recochez-le pour les retrouver.
9. Ajoutez les **coordinateurs référents** (voir ci-dessous).
10. Cochez éventuellement les **amapiens à rattacher** (voir ci-dessous).
11. Touchez **[ENREGISTRER LE CONTRAT]**.

Le nouveau contrat apparaît dans la liste, avec un compteur d'amapiens rattachés égal au
nombre d'amapiens cochés (zéro si aucun).

## Créer les livraisons du contrat

Juste après la création d'un contrat, l'application propose de créer ses livraisons
**d'un coup**, une par semaine entre la date de première et la date de dernière
livraison : « Créer les livraisons hebdomadaires ? ».

- Les semaines où une livraison existe déjà à la même date, le contrat est simplement
  **ajouté à cette livraison** (« Lier les livraisons existantes ? » si aucune livraison
  n'est à créer).
- L'heure des nouvelles livraisons est celle du modèle de livraison choisi (ou, à
  défaut, du modèle par défaut de l'AMAP) ; sans modèle, 18h00.
- Touchez **[Créer]** (ou **[Lier]**) pour accepter, ou **[Non]** pour planifier les
  livraisons vous-même (voir [Planifier une livraison](01-planifier-une-livraison.md)).

Vous pouvez ensuite ajuster chaque livraison individuellement.

## Modifier un contrat

1. Touchez le contrat à modifier dans la liste.
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

> Seuls les **coordinateurs référents** d'un contrat peuvent ensuite être désignés
> coordinateur de ce contrat sur une livraison. Être référent **n'affecte pas
> automatiquement** aux futures livraisons : l'affectation à une livraison précise se
> fait séparément (voir [La coordination par contrat](06-coordination-par-contrat.md)).
> Pensez donc à renseigner cette liste avant de planifier les livraisons.

## Les états d'un contrat

| Indicateur | Signification |
|------------|---------------|
| **En préparation** | Contrat en cours de construction : visible des seuls coordinateurs ; les amapiens ne le voient pas et ne peuvent pas s'y inscrire eux-mêmes. Ses livraisons apparaissent « 🚧 Contrat inactif » aux coordinateurs. |
| 🟢 **Actif** | Le contrat est ouvert et sa période est en cours |
| 🔵 **À venir** | Le contrat est ouvert mais sa première livraison n'est pas encore passée |
| ⚪ **Terminé** | Le statut a été passé à « Terminé », ou la date de dernière livraison est dépassée |

Le statut **En préparation / Actif / Terminé** se choisit dans le formulaire ; « À venir »
et « Terminé » se déduisent aussi des dates.

## Voir aussi

- [Affecter les contrats aux amapiens](04-contrats-des-amapiens.md)
- [La coordination par contrat](06-coordination-par-contrat.md)
