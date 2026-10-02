# Gérer les membres

## À quoi ça sert

Ajouter de nouveaux membres à votre AMAP, leur attribuer des rôles (amapien,
coordinateur, administrateur), relancer les invitations et gérer les comptes existants.

## Y accéder

Ouvrez le **[Menu]**, puis **[UTILISATEURS]** (ou l'accès rapide « Utilisateurs » du
tableau de bord).

## Ajouter un membre

1. Dans **« Nouveau membre »**, renseignez le **prénom**, le **nom** et l'**e-mail**
   (le téléphone est optionnel).
2. Cochez les **rôles** à attribuer :
   - **Amapien** (membre standard) ;
   - **Coordinateur** (accès gestion) ;
   - **Admin** (accès complet — visible uniquement si vous êtes vous-même admin).
3. Laissez cochée **« Envoyer l'invitation par email »**.
4. Touchez **[AJOUTER MEMBRE]**.

La personne reçoit un e-mail d'invitation pour activer son compte (lien valable
7 jours).

### Inviter plusieurs personnes à la fois

Le bloc **« Invitation groupée »** permet de coller une liste au format
`prénom,nom,email` (une par ligne), de choisir les rôles, puis de toucher
**[TRAITER LES INVITATIONS]**. Un récapitulatif indique les invitations envoyées et les
éventuelles erreurs.

## La liste des membres

Chaque membre affiche son nom, son e-mail, ses rôles et son statut. Utilisez la
recherche et les filtres pour retrouver une personne.

```
┌──────────────────────────────────────────────┐
│  👤 Marie Martin        📧 marie.m@email.com   │
│     🟢 Coordinateur • Actif       [MODIFIER]   │
│  👤 Julie Legrand       📧 julie.l@email.com   │
│     🟡 Invitation envoyée le 28/12 [RELANCER]  │
└──────────────────────────────────────────────┘
```

### Les statuts

| Indicateur | Signification |
|------------|---------------|
| 🟢/🔵/🟣 **rôle • Actif** | Compte actif (l'icône reflète le ou les rôles) |
| 🟡 **Invitation envoyée** | En attente d'activation — possibilité de relance |
| 🔴 **Compte suspendu** | Accès temporairement désactivé |

## Relancer une invitation

Sur un membre en attente d'activation, touchez **[RELANCER]** : un nouvel e-mail
d'activation est envoyé.

## Modifier un membre

Touchez **[MODIFIER]** pour ouvrir la fiche du membre. Vous pouvez :

- corriger ses informations (prénom, nom, téléphone) ;
- ajuster ses **rôles** (plusieurs rôles possibles simultanément).

Touchez **[SAUVEGARDER]**.

## Supprimer un membre

Sur la ligne du membre, touchez l'icône 🗑 **Supprimer le membre**, puis confirmez avec
**[SUPPRIMER]**. L'icône n'apparaît pas sur votre propre ligne.

Ce que fait la suppression :

- le membre **ne peut plus se connecter** : son compte est supprimé ;
- ses **nom, prénom, e-mail et téléphone sont effacés** de sa fiche ;
- son **historique est conservé** sans son nom (contrats, paniers, participations), pour
  que les comptes de l'AMAP restent justes ;
- il reçoit un e-mail l'informant de la suppression.

La suppression est **définitive**. Pour une absence ou une pause, préférez la
suspension. Vous pourrez réinviter la même adresse plus tard : la personne repartira
d'un compte neuf, sans son ancien historique.

> Certaines traces ne sont pas effacées automatiquement (nom recopié sur les feuilles
> d'émargement passées, ancienne invitation, notifications déjà reçues). Pour une
> demande d'effacement complet, contactez l'administrateur de votre instance.

## Règles importantes sur les rôles

- Un membre peut **cumuler** plusieurs rôles (par exemple coordinateur **et** admin).
- Seul un **admin** peut attribuer ou retirer le rôle **Admin**.
- Une AMAP doit **toujours conserver au moins un admin** : il est impossible de
  rétrograder ou de supprimer le dernier admin. L'action est alors bloquée avec un
  message explicite.
- Après un changement de rôle, les nouvelles permissions peuvent prendre un court délai
  avant d'être pleinement effectives.

## Voir aussi

- [Gérer les producteurs](02-gestion-des-producteurs.md)
- [Guide du Coordinateur](../coordinateur/README.md)
