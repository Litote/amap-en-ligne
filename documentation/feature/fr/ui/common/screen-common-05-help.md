# Aide

## Description

Écran statique d'aide, accessible à tous les utilisateurs connectés quel que soit leur rôle. Il centralise les ressources d'assistance disponibles, les contacts utiles, une foire aux questions courte et le numéro de version de l'application.

| Attribut | Valeur |
|----------|--------|
| Route | `/help` |
| Titre AppBar | **Aide** |
| Acteurs | Tous les rôles connectés (VOLUNTEER, COORDINATOR, ADMIN, OWNER, PRODUCER) |

## Wireframe ASCII

```
┌─────────────────────────────────────────────────────────────┐
│  ←  Aide                                        [Menu]      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Consulter le guide d'utilisation                    │   │
│  │                                                      │   │
│  │  Le guide complet est organisé par rôle et couvre    │   │
│  │  toutes les fonctionnalités de l'application.        │   │
│  │                                                      │   │
│  │       [OUVRIR LE GUIDE D'UTILISATION ↗]              │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Besoin d'aide ?                                     │   │
│  │                                                      │   │
│  │  Pour toute question sur votre compte, vos           │   │
│  │  contrats ou le fonctionnement au quotidien,         │   │
│  │  contactez l'administrateur de votre AMAP.           │   │
│  │                                                      │   │
│  │  Si le problème touche au serveur, adressez-vous     │   │
│  │  à l'administrateur de l'instance.                   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  Questions fréquentes                                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Je n'ai pas reçu l'e-mail d'activation          ›  │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  J'ai oublié mon mot de passe                    ›  │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  L'application affiche « Serveur injoignable »   ›  │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  Je ne vois aucun contrat dans « Mes contrats »  ›  │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  Pas de bouton pour m'inscrire comme bénévole    ›  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ──────────────────────────────────────────────────────    │
│                                                             │
│  À propos                                                   │
│  Version v<version> (build <numéro>)                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Navigation et interactions

| Contrôle | Comportement |
|----------|-------------|
| **← (retour)** | Retour à l'écran précédent |
| **[Menu]** | Ouvre le menu de navigation |
| **[OUVRIR LE GUIDE D'UTILISATION ↗]** | Ouvre le guide utilisateur complet dans le navigateur par défaut de l'appareil (lien externe) |
| **Entrée FAQ (›)** | Déplie ou replie la réponse à la question correspondante (comportement accordéon, une seule entrée ouverte à la fois) |

### Contenu de la FAQ

Cinq entrées extensibles, dans cet ordre :

| Question | Résumé de la réponse affichée une fois dépliée |
|----------|------------------------------------------------|
| Je n'ai pas reçu l'e-mail d'activation ou d'invitation | L'e-mail peut mettre quelques minutes à arriver ; vérifier le dossier de courrier indésirable. Le lien a une durée limitée (en général 7 jours) — s'il a expiré, demander à l'administrateur de renvoyer l'invitation. |
| J'ai oublié mon mot de passe | Sur l'écran de connexion, toucher « Mot de passe oublié ? » et saisir son e-mail. Un code à 6 chiffres valable 1 heure est envoyé. |
| L'application affiche « Serveur injoignable » | Problème réseau ou serveur temporairement indisponible. Les données restent consultables hors connexion et les actions sont mémorisées localement — elles seront envoyées au retour du réseau. Ne pas se déconnecter avant le rétablissement de la connexion. |
| Je ne vois aucun contrat dans « Mes contrats » | Les contrats sont créés et attribués par le coordinateur. Si l'écran est vide, contacter le coordinateur. |
| Il n'y a pas de bouton pour m'inscrire comme bénévole sur une livraison | Le créneau peut être complet, annulé, ou pas encore ouvert. Se renseigner auprès du coordinateur si la situation persiste. |

### Section « À propos »

Affiche le numéro de version du build installé sous la forme `v<version> (build <numéro>)`, identique au dialogue « À propos » accessible depuis l'[écran d'accueil public](../screen-01-home.md). Cette information est utile pour signaler un problème à l'administrateur.

## Références

- **Contenu source** : [`../../../../guide/fr/aide.md`](../../../../guide/fr/aide.md)
- **Guide d'utilisation complet** : [`../../../../guide/fr/README.md`](../../../../guide/fr/README.md)
- **Menu de navigation** : [`screen-common-01-menu.md`](screen-common-01-menu.md)
- **Écran d'accueil public (pattern « À propos »)** : [`../screen-01-home.md`](../screen-01-home.md)
- **Spécifications UI** : [`../spec-ui.md`](../spec-ui.md)
