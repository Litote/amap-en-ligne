# Gérer les comptes de l'instance

## À quoi ça sert

Consulter l'ensemble des utilisateurs présents sur l'instance, toutes organisations
confondues, et agir sur leur compte : suspendre, réactiver ou supprimer.

## Y accéder

Depuis le tableau de bord, touchez **« Gestion des utilisateurs »** (ou
**[UTILISATEURS]** dans le menu).

## La liste des utilisateurs

La liste agrège les comptes de toutes les AMAP et de tous les producteurs. Vous pouvez :

- **rechercher** par nom, prénom ou e-mail ;
- filtrer par **AMAP**, par **producteur**, par **rôle** ou par **statut**.

```
┌──────────────────────────────────────────────┐
│ Rôle : [Tous][Owner][Admin][Coordinateur]…     │
│ Statut : [Tous][Actif][Invité][Suspendu]       │
│ Jean Dupont          [Actif] [Admin] [Coord] › │
│ jean@exemple.fr                                │
│   AMAP des Pins · Admin · Coordinateur         │
│ Marie Leblanc        [Actif] [Producteur]    › │
│   Producteur de : Ferme des Lilas              │
└──────────────────────────────────────────────┘
```

### Les rôles

| Rôle | Portée |
|------|--------|
| **Owner** (administrateur d'instance) | L'instance — rôle exclusif |
| **Admin** / **Coordinateur** / **Amapien** | Au sein d'une AMAP (cumulables) |
| **Producteur** | Un compte producteur — rôle exclusif |

### Les statuts

| Statut | Sens |
|--------|------|
| **Actif** | Compte activé, connexion autorisée |
| **Invité** | Invitation envoyée, pas encore activée |
| **Suspendu** | Connexion bloquée ; rôles et appartenances conservés |

## Consulter une fiche

Touchez une ligne pour ouvrir le **détail** de l'utilisateur : ses informations de
compte (en lecture seule) et ses appartenances (AMAP, producteur).

- Pour un utilisateur membre d'une AMAP, le bouton **[Modifier]** en face d'une
  appartenance permet d'ajuster ses **rôles** dans cette AMAP (au moins un rôle ; l'AMAP
  doit conserver au moins un admin), ou de le **[RETIRER DE L'AMAP]**.

## Suspendre, réactiver, supprimer

Dans la zone sensible de la fiche :

- **[SUSPENDRE LE COMPTE]** — bloque la connexion ; les rôles sont conservés. Le libellé
  devient **[RÉACTIVER LE COMPTE]** si le compte est déjà suspendu.
- **[SUPPRIMER DE L'INSTANCE]** — action destructive, derrière une confirmation
  renforcée.

> Vous ne pouvez pas suspendre ni supprimer **votre propre compte**.
> Vous ne pouvez pas supprimer le **dernier administrateur d'instance**, ni laisser une
> AMAP sans aucun admin : ces actions sont refusées avec un message explicite.

## Exporter

**[EXPORTER LA LISTE]** génère un export des utilisateurs selon la recherche et les
filtres actifs.

## Voir aussi

- [Inviter un autre administrateur](03-inviter-un-administrateur.md)
- [Valider les demandes de création](01-demandes-de-creation.md)
