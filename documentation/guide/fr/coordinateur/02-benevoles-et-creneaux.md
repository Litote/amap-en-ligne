# Gérer les bénévoles et les créneaux

## À quoi ça sert

Suivre les livraisons et leurs créneaux, voir le nombre de bénévoles inscrits, modifier ou
supprimer une livraison ou un créneau, et savoir comment les membres sont relancés lorsqu'il
manque des bénévoles.

## Y accéder

Ouvrez le **[Menu]**, puis **[Gestion des livraisons]**.

## La liste des livraisons

Les livraisons sont regroupées en trois sections : **En cours**, **À venir** et
**Passées**. Chaque ligne affiche la date, les horaires, le nombre de bénévoles inscrits
sur le nombre requis (« 2/5 bénévoles », ou « Aucun bénévole requis »), les produits
présents et un indicateur d'état :

```
┌──────────────────────────────────────────────
│ À venir
│   17 Jan • 18h-20h  2/5 bénévoles  🟠 Critique
│      Produits : Légumes + Œufs
│      [MODIFIER] [SUIVRE]
│   24 Jan • 18h-20h  5/5 bénévoles  🔵 Complet
│      [MODIFIER] [SUIVRE]
└──────────────────────────────────────────────
```

### Les états d'une livraison

| Indicateur | Signification |
|------------|---------------|
| 🟢 **Ouvert** | Des places restent à pourvoir, sans urgence (ou aucun bénévole requis) |
| 🟠 **Critique** | Moins de la moitié des bénévoles requis, et la livraison a lieu dans 3 jours ou moins |
| 🔵 **Complet** | Tous les bénévoles requis sont inscrits |
| ⚪ **Fermé** | Livraison terminée ou annulée |
| 🔴 **Annulé** | Créneau annulé |

Le compteur ne tient compte que des créneaux des **contrats principaux** ; les
coordinateurs de la livraison n'y sont pas comptés.

## Les actions sur une livraison

- **[MODIFIER]** — ouvre le formulaire « Modifier la livraison » : date, horaires, contrats
  présents, bénévoles requis, créneaux, coordinateurs. Un bouton **Supprimer la
  livraison** y est aussi disponible.
- **[SUIVRE]** — ouvre le suivi en direct (voir
  [Le jour de la livraison](05-jour-de-livraison.md)).

## Les rappels aux bénévoles

Il n'y a pas d'envoi manuel de rappel : lorsqu'une livraison manque de bénévoles,
l'application envoie **automatiquement** une alerte aux membres de l'AMAP qui ne sont ni
inscrits ni coordinateurs de la livraison — trois jours avant, puis la veille si le
besoin persiste. Chaque membre peut désactiver ces alertes dans ses préférences. Les
administrateurs peuvent personnaliser le texte de ces alertes.

## Annuler ou supprimer un créneau bénévole

Dans le formulaire de modification d'une livraison, la section
**🕐 Créneaux bénévoles** liste chaque créneau avec ses horaires et son nombre
d'inscrits, et propose deux actions :

- **[ANNULER]** — annule le créneau (avec confirmation). Les inscriptions des
  bénévoles sont automatiquement annulées et chaque inscrit reçoit une
  notification. Le créneau reste affiché avec le badge **ANNULÉ** ; il ne peut
  plus être rouvert et plus personne ne peut s'y inscrire.
- **[SUPPRIMER]** — supprime définitivement le créneau (avec confirmation).
  Cette action n'est possible que si **aucun bénévole n'est inscrit** ; sinon le
  bouton est désactivé. En cas de course (une inscription arrivée entre-temps),
  le serveur refuse la suppression et l'application vous en informe.

### Modifier l'horaire d'une livraison avec des inscrits

Modifier la date ou l'heure d'une livraison dont des bénévoles sont déjà
inscrits reste possible : une confirmation vous indique combien d'inscrits
seront notifiés du changement d'horaire. Les inscriptions sont conservées.

## Voir aussi

- [Planifier une livraison](01-planifier-une-livraison.md)
- [Le jour de la livraison](05-jour-de-livraison.md)
