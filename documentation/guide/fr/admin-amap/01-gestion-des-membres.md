# Gérer les membres

## À quoi ça sert

Ajouter de nouveaux membres à votre AMAP, leur attribuer des rôles (amapien,
coordinateur, administrateur), relancer les invitations et gérer les comptes existants.

## Y accéder

Ouvrez le **[Menu]**, puis **[Utilisateurs]** (ou l'accès rapide « Utilisateurs » du
tableau de bord). L'écran s'intitule **« Gestion des membres »**.

## Inviter un membre

1. Touchez le bouton rond **[Inviter un membre]** (icône de personne avec un « + »), en
   bas à droite de l'écran.
2. Renseignez le **prénom**, le **nom** et l'**e-mail** (tous obligatoires).
3. Cochez au moins un **rôle** à attribuer :
   - **Amapien** (membre standard) ;
   - **Coordinateur** (accès gestion) ;
   - **Admin** (accès complet — visible uniquement si vous êtes vous-même admin).
4. Touchez **[Inviter]**.

La personne reçoit un e-mail d'invitation pour activer son compte (lien valable
7 jours). Une seule invitation en attente est possible par adresse e-mail (les
majuscules et minuscules ne comptent pas) : si l'adresse a déjà une invitation en
attente, l'application vous le signale.

## La liste des membres

Chaque ligne affiche le nom, l'e-mail, les rôles et l'état du membre. Utilisez la
barre **« Rechercher un membre… »** et les filtres pour retrouver une personne :

| Filtre | Ce qu'il affiche |
|--------|------------------|
| **Tous** | Les membres actifs et les invitations en attente |
| **Admin**, **Coordinateur**, **Amapien** | Les personnes ayant ce rôle |
| **Invitations passées** | Les invitations annulées ou expirées |
| **Anciens utilisateurs** | Les comptes suspendus |

### Les statuts

| Indicateur | Signification |
|------------|---------------|
| Pastilles de **rôle** | Compte actif, avec le ou les rôles de la personne |
| **Invité** | En attente d'activation — possibilité de relance |
| Compte suspendu | Accès désactivé (visible via le filtre « Anciens utilisateurs ») |

Pour une invitation, la ligne indique la date de création ou de la dernière relance.

## Relancer une invitation

- **Une personne** : sur sa ligne, touchez **[Relancer]** : un nouvel e-mail d'activation
  est envoyé. L'icône 🗑 **Supprimer l'invitation** annule l'invitation.
- **Tout le monde à la fois** : lorsque des membres ne se sont pas encore connectés, un
  bandeau « N membre(s) ne se sont pas encore connectés. » apparaît en haut de la liste.
  Touchez **[Demander la connexion]**. Vous pouvez personnaliser le **titre** et le
  **corps** du message (champs facultatifs ; laissés vides, le message par défaut est
  utilisé ; **[Repartir de l'alerte par défaut]** efface vos modifications), puis
  touchez **[Renvoyer]**. Le lien d'activation est toujours ajouté au message.

## Modifier les rôles d'un membre

Sur la ligne du membre, touchez l'icône ⚙ **Modifier les rôles**. Cochez ou décochez
**Amapien**, **Coordinateur** et **Admin** (plusieurs rôles possibles simultanément),
puis touchez **[Enregistrer]**.

Les informations personnelles (nom, e-mail, téléphone) ne se modifient pas depuis cet
écran : chaque membre les met à jour lui-même depuis **[Préférences]**, et l'e-mail de
connexion ne peut pas être changé.

## Supprimer un membre

Sur la ligne du membre, touchez l'icône 🗑 **Supprimer le membre** (« Supprimer ce membre ? »),
puis confirmez avec **[SUPPRIMER]**. L'icône n'apparaît pas sur votre propre ligne.

Ce que fait la suppression :

- le membre **ne peut plus se connecter** : son compte est supprimé ;
- ses **nom, prénom, e-mail et téléphone sont effacés** de sa fiche ;
- son **historique est conservé** sans son nom (contrats, paniers, participations), pour
  que les comptes de l'AMAP restent justes ;
- il reçoit un e-mail l'informant de la suppression.

La suppression est **définitive**. Vous pourrez réinviter la même adresse plus tard : la personne repartira
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
