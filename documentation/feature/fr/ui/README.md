# Interface utilisateur

Ce dossier regroupe les spécifications UI en français, structurées par profil.

## Structure actuelle

### Racine `ui/` (écrans non authentifiés)
- `screen-01-home.md` : accueil public
- `screen-02-login.md` : connexion
- `screen-03-organization-creation.md` : création d'organisation
- `screen-04-forgot-password.md` : récupération de mot de passe (code OTP)
- `screen-05-reset-password.md` : réinitialisation via lien magique (web uniquement)
- `screen-06-activation.md` : activation de compte organisateur
- `spec-ui.md` : conventions UI globales
- `charte-graphique.md` : identité visuelle, palette, typographie, voix et ton

### `ui/common/` (composants partagés)
- `screen-common-01-menu.md` : menu principal
- `screen-common-02-user-preferences.md` : préférences utilisateur
- `screen-common-03-delivery-description.md` : description d'une livraison (vue producteur et coordinateur)
- `screen-common-04-dashboard.md` : tableau de bord unifié multi-rôles (VOLUNTEER / COORDINATOR / ADMIN)

### `ui/member/` (membres)
- `screen-member-01-home.md` : accueil membre
- `screen-member-02-delivery-plan.md` : planning des livraisons
- `screen-member-03-history.md` : historique des participations
- `screen-member-04-contracts.md` : consultation des contrats de l'amapien

### `ui/coordinator/` (coordinateurs)
- `screen-coordinator-01-home.md` : tableau de bord coordinateur
- `screen-coordinator-02-time-slots.md` : Gestion des livraisons
- `screen-coordinator-03-attendance-sheets.md` : génération des feuilles d'émargement
- `screen-coordinator-04-delivery-tracking.md` : suivi de livraison en temps réel
- `screen-coordinator-05-post-delivery-sync.md` : synchronisation post-livraison
- `screen-coordinator-06-basket-exchange.md` : échanges de paniers entre membres
- `screen-coordinator-07-delivery-template.md` : renvoi vers la gestion des templates de livraison
- `screen-coordinator-08-member-contracts.md` : affectation des contrats aux amapiens
- `screen-coordinator-09-contract-definition.md` : définition et modification des contrats de saison

### `ui/admin/` (administration AMAP)
- `screen-admin-01-home.md` : accueil admin
- `screen-admin-03-user-management.md` : gestion des utilisateurs
- `screen-admin-04-producer-management.md` : gestion des producteurs

### `ui/owner/` (administration instance)
- `screen-owner-01-home.md` : accueil owner
- `screen-owner-02-organization-requests.md` : validation des demandes d'organisation
- `screen-owner-03-user-management.md` : gestion des utilisateurs de l'instance
- `screen-owner-04-invite-owner.md` : invitation d'un nouvel administrateur (Owner)
- `screen-owner-05-producer-requests.md` : validation des demandes de compte producteur

### `ui/producer/` (producteurs)
- `screen-producer-01-home.md` : accueil producteur
- `screen-producer-02-product-catalog.md` : catalogue de types de produits (création, édition, suppression)

## Conventions

- Convention de nommage : `screen-[profil]-[numéro]-[slug].md`
- Liens internes : toujours en chemin relatif
- Toute création/renommage d'écran doit être répercutée ici
