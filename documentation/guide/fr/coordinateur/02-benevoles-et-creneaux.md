# Gérer les bénévoles et les créneaux

## À quoi ça sert

Suivre les créneaux existants, voir le nombre de bénévoles inscrits, modifier ou
supprimer un créneau, et relancer les membres lorsqu'il manque des bénévoles.

## Y accéder

Ouvrez le **[Menu]**, puis **[Gestion des livraisons]**.

## La liste des créneaux

Chaque créneau affiche sa date, ses horaires, le nombre de bénévoles inscrits sur le
nombre requis, et un indicateur d'état :

```
┌──────────────────────────────────────────────┐
│ 📋 Créneaux existants                           │
│   17 Jan • 18h-20h  👥 2/5  🔴 CRITIQUE         │
│      [MODIFIER] [SUPPRIMER] [RELANCER]          │
│   24 Jan • 18h-20h  👥 3/5  ⚠️ À surveiller     │
│      [MODIFIER] [SUPPRIMER] [ENVOYER RAPPEL]    │
│   31 Jan • 18h-20h  👥 0/5  ⭕ Nouveau          │
│      [MODIFIER] [SUPPRIMER] [PUBLIER]           │
└──────────────────────────────────────────────┘
```

### Les états d'un créneau

| Indicateur | Signification |
|------------|---------------|
| 🔴 **CRITIQUE** | Moins de la moitié des bénévoles requis |
| ⚠️ **À surveiller** | Entre la moitié et 80 % des bénévoles |
| ⭕ **Nouveau** | Créneau créé mais pas encore publié |
| ✅ **Complet** | Tous les bénévoles requis sont inscrits |

## Les actions sur un créneau

- **[MODIFIER]** — ajuster la date, les horaires, les bénévoles requis, les producteurs.
- **[SUPPRIMER]** — supprimer le créneau (avec confirmation).
- **[PUBLIER]** — rendre visible un créneau nouvellement créé.
- **[RELANCER]** / **[ENVOYER RAPPEL]** — solliciter les membres pour un créneau qui
  manque de bénévoles.

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
