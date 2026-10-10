# Suppression de compte — ce qui se passe réellement

Ce document décrit le comportement **effectif** d'une suppression de compte, tel
qu'implémenté (serveur et application). Il sert de référence pour répondre à une
demande d'effacement (RGPD) et pour savoir ce qui reste en base après l'opération.

> Une suppression est **irréversible** : aucun bouton ne permet de la défaire.

## Qui peut supprimer quoi

| Compte supprimé | Qui peut supprimer | Où | Refus |
|-----------------|--------------------|----|-------|
| Membre d'AMAP (*Member*) | L'**Admin** de son AMAP | Gestion des membres (`/members`), icône 🗑 « Supprimer le membre » | Son propre compte (`SELF_ACTION_FORBIDDEN`), le dernier Admin de l'AMAP (`LAST_ADMIN`), un membre d'une autre AMAP (`NOT_FOUND`) |
| Membre d'AMAP (*Member*) | Un **Owner** d'instance | Gestion des utilisateurs (`/owner/users`), [SUPPRIMER DE L'INSTANCE] | Son propre compte, le dernier Admin d'une AMAP |
| Owner d'instance (*Owner*) | Un autre **Owner** | Gestion des utilisateurs (`/owner/users`) | Son propre compte, le dernier Owner (`LAST_OWNER`) |
| Producteur (*ProducerAccount*) | Un **Owner** | Gestion des utilisateurs (`/owner/users`) | — |

Un Amapien, un coordinateur ou un producteur ne peut supprimer **aucun** compte, pas
même le sien : la demande est refusée par le serveur (`FORBIDDEN`). Pour être supprimé,
un membre s'adresse à l'Admin de son AMAP.

Un compte n'appartient qu'à **une seule AMAP** : supprimer un membre supprime donc la
personne de l'instance, pas seulement de l'AMAP.

## Suppression d'un membre d'AMAP

### Ce qui est fait

1. **Le compte de connexion est supprimé** chez le fournisseur d'authentification
   (Cognito ou GoTrue) : la personne ne peut plus se connecter ni rafraîchir sa
   session. L'opération est « au mieux » : un échec est journalisé mais n'annule pas
   la suppression. Un membre importé qui n'a jamais activé son compte n'a pas de compte
   de connexion : cette étape est alors sans effet.
2. **La fiche membre est anonymisée**, pas effacée : prénom, nom, e-mail et téléphone
   sont vidés et le statut passe à « suspendu ». La fiche apparaît ensuite dans le
   filtre « Anciens utilisateurs » sous le nom « (aucun nom) ».
3. **Une entrée d'audit** (*AccountDeletionLog*) est écrite : empreinte SHA-256 de
   l'identifiant du compte (l'identifiant lui-même n'est pas conservé), type de compte
   (membre d'AMAP), date, identifiant de l'auteur de la suppression et son rôle
   (`OWNER` ou `ADMIN`).
4. **Des e-mails sont envoyés** : à la personne supprimée (« Votre compte AMAP en ligne
   a été supprimé ») et aux Owners de l'instance (notification d'audit sans donnée
   personnelle du membre, avec l'e-mail de l'auteur).

Un membre créé hors ligne et jamais synchronisé (identifiant `tmp_*`) est simplement
effacé.

### Ce qui est conservé, et pourquoi

La fiche anonymisée garde son **identifiant technique**, ses **rôles**, ses
**abonnements aux contrats** et ses **inscriptions passées**. Les contrats, livraisons
et échanges de paniers continuent de la référencer : l'historique de l'AMAP (paniers
distribués, participations, statistiques) reste cohérent.

Dans les livraisons (*DELIVERY*) de l'AMAP :

- **livraisons à venir** (ni terminées ni annulées, aujourd'hui ou plus tard) : ses
  inscriptions bénévoles (*MemberRegistration*) sont retirées — les places sont libérées —
  et il n'est plus coordinateur des livraisons-contrats (*DELIVERY_CONTRACT*) ; une
  livraison qui se retrouve sans coordinateur affiche l'alerte « Coordinateur manquant » ;
- **historique** (livraisons passées, terminées ou annulées) : ses inscriptions restent
  comptées (compteurs, classement, statistiques) mais perdent le nom et l'e-mail recopiés ;
  les écrans coordinateur et les feuilles d'émargement affichent « Membre supprimé ».

Dans les échanges de paniers (*BASKET_EXCHANGE*) en cours : son offre encore ouverte est
annulée et les demandes en attente sur cette offre sont refusées ; ses propres demandes en
attente sur les offres des autres sont retirées. Les échanges conclus restent dans
l'historique.

Ses invitations passées (*MemberInvitation* activées ou annulées, retrouvées par l'e-mail,
sans tenir compte des majuscules) perdent aussi prénom, nom, e-mail et texte d'e-mail
personnalisé ; l'écran des membres les affiche « Invitation anonymisée ». Une invitation
encore en attente pour la même adresse est une nouvelle demande : elle est conservée.

### Ce qui n'est pas effacé aujourd'hui

Ces données personnelles restent en base après la suppression. Une demande d'effacement
complet impose de les traiter à la main tant que l'application ne le fait pas :

| Donnée | Où | Contenu restant |
|--------|----|-----------------|
| Notifications | Fil privé du membre (*Notification*) | Notifications déjà reçues |
| Appareils | *DeviceToken* | Jetons de notification push des appareils du membre |
| E-mails envoyés | Boîtes des destinataires | Tout e-mail déjà envoyé (échanges de paniers, feuilles d'émargement…) |

L'e-mail envoyé à la personne indique pourtant « Vos données personnelles ont été
anonymisées » : c'est vrai pour sa fiche, pas pour les éléments ci-dessus.

### Délai d'effet

Les droits sont lus dans le jeton d'accès. Un jeton déjà émis reste valable jusqu'à son
expiration (15 minutes sur le déploiement AWS) : pendant ce court délai, une application déjà ouverte
peut encore synchroniser. Le renouvellement du jeton, lui, échoue immédiatement.

### Après la suppression

L'adresse e-mail est libérée : l'Admin peut réinviter la même personne, qui obtiendra un
**nouveau** compte et une **nouvelle** fiche, sans lien avec l'ancienne (abonnements et
historique ne sont pas récupérés).

## Suppression d'un Owner d'instance

- Le compte de connexion est supprimé (au mieux).
- La fiche *Owner* est **effacée** (pas d'anonymisation : un Owner n'a pas d'historique
  d'AMAP à préserver).
- Une entrée d'audit est écrite (type `OWNER`, auteur = l'Owner qui supprime).
- E-mails : à la personne supprimée et aux Owners.
- Reste en base : l'invitation d'Owner (*OwnerInvitation*) avec prénom, nom et e-mail.

## Suppression d'un producteur

- Tous les comptes de connexion rattachés au producteur sont supprimés (au mieux).
- Le compte producteur (*ProducerAccount*) est **conservé** mais désactivé : nom,
  coordonnées de contact, catalogue de produits et rattachements aux AMAP restent en
  place. Il peut être rattaché plus tard à un autre utilisateur.
- Une entrée d'audit est écrite par compte de connexion supprimé (type `PRODUCER`) ; à
  défaut de compte, une seule entrée basée sur l'identifiant du producteur.
- E-mails : au producteur et aux Owners.

Les informations d'un producteur sont des données d'entreprise : elles ne sont pas
anonymisées. Les retirer impose une modification manuelle de la fiche.

## Ce qu'une suppression n'est pas

- **Suspendre** un compte bloque la connexion mais garde tout (fiche, rôles) : c'est
  réversible (« Réactiver »). À préférer pour une absence ou un départ temporaire.
- **Supprimer une invitation** en attente annule seulement l'invitation : aucune fiche
  membre n'existe encore.
- Retirer un membre d'un **contrat** se fait depuis la gestion des contrats, sans
  toucher à son compte.

## Références

- Écran admin : [`ui/admin/screen-admin-03-user-management.md`](ui/admin/screen-admin-03-user-management.md)
- Écran owner : [`ui/owner/screen-owner-03-user-management.md`](ui/owner/screen-owner-03-user-management.md)
- Implémentation : `MemberService.applyDelete` / `MemberLifecycleSideEffects.onDeleted`
  (`back/service/member`), `OwnerService.delete` (`back/service/owner`),
  `ProducerAccountLifecycleService.delete` (`back/service/producer-account`)
