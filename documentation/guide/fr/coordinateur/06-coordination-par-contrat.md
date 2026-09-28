# La coordination par contrat

## À quoi ça sert

Répartir la responsabilité d'une livraison **par produit**. Par exemple, un coordinateur
prend en charge les légumes et un autre le pain. Pour chaque livraison, chaque produit
reçoit la liste des coordinateurs qui s'en occupent.

## Le principe

- Tout coordinateur de l'AMAP peut **se porter coordinateur** d'un produit sur une
  livraison, même s'il n'est pas « référent » de ce contrat.
- Une livraison ne peut pas être **confirmée** tant qu'un de ses produits n'a aucun
  coordinateur.
- Les états avancés (en cours, terminée, annulée) ne sont plus soumis à cette
  vérification.

## Se porter coordinateur depuis le tableau de bord

Lorsqu'une prochaine livraison manque d'un coordinateur, sa carte affiche une alerte et
un bouton :

```
┌──────────────────────────────────────────────┐
│  Mercredi 24 janvier • 18h00                   │
│  👥 Coordinateurs : 🥕 Jean Morel · 🍞 —       │
│     ⚠️ Coordinateur manquant : Pain artisanal  │
│     [ME PORTER COORDINATEUR]                   │
└──────────────────────────────────────────────┘
```

1. Touchez **[ME PORTER COORDINATEUR]**.
2. Choisissez le produit sur lequel vous positionner.
3. Vous êtes ajouté comme coordinateur de ce produit pour cette livraison.

## Se porter coordinateur lors de la création / modification d'un créneau

Le formulaire de créneau comporte un bloc **« Coordinateurs par contrat »** : pour
chaque produit, vous voyez les coordinateurs déjà affectés et un bouton
**[ME PORTER COORDINATEUR]**.

- La croix **✕** à côté d'un nom retire un coordinateur. En tant que coordinateur (non
  administrateur), vous ne pouvez retirer que **vous-même**, et seulement tant que la
  livraison n'est pas en cours.
- Si vous êtes **administrateur**, l'option **[+ Ajouter un coordinateur]** vous permet
  d'affecter n'importe quel coordinateur de l'AMAP.

## Messages possibles

| Situation | Message |
|-----------|---------|
| Confirmation impossible (un produit sans coordinateur) | « Cette livraison ne peut pas être confirmée : aucun coordinateur sur le(s) contrat(s) … » |
| Retrait d'un autre coordinateur que soi (non-admin) | « Seul un admin peut retirer un autre coordinateur. » |
| Auto-affectation sur une livraison clôturée ou annulée | « Cette livraison n'est plus active. » |

## Voir aussi

- [Planifier une livraison](01-planifier-une-livraison.md)
- [Définir les contrats de saison](03-contrats-de-saison.md) (coordinateurs référents)
