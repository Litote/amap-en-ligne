# Configurer l'AMAP

## À quoi ça sert

Tenir à jour l'identité de votre AMAP, personnaliser les messages d'alerte envoyés aux
membres, et sauvegarder ou restaurer les données de l'AMAP.

## Les informations de l'AMAP

Ouvrez le **[Menu]**, puis **[Configuration de l'organisation]**. Renseignez ou modifiez :

- le **nom de l'organisation** (obligatoire) ;
- l'**e-mail de contact** (obligatoire) ;
- le **fuseau horaire** (obligatoire), qui détermine le « jour de la livraison » ;
- la **langue par défaut** (obligatoire) ;
- le **site web** (facultatif).

Touchez **[ENREGISTRER LES MODIFICATIONS]** : le message « Modifications enregistrées. »
confirme la prise en compte.

## Personnaliser les alertes

Ouvrez le **[Menu]**, puis **[Préférences]** : la carte **« Personnalisation des
alertes »** est réservée aux administrateurs de l'AMAP. Pour chaque alerte, vous pouvez
remplacer le **titre** et le **corps** du message :

| Alerte | Quand elle est envoyée |
|--------|------------------------|
| Créneau annulé | Un créneau de bénévolat est annulé |
| Horaire de créneau modifié | L'horaire d'une livraison ou d'un créneau change |
| Manque de bénévoles (3 jours avant) | Une livraison manque encore de bénévoles |
| Besoin urgent de bénévoles (la veille) | Le manque persiste la veille |
| Nouvelle demande d'échange de panier | Un membre reçoit une demande d'échange |
| Échange de panier accepté / refusé | Réponse à une demande d'échange |
| Nouvelle demande d'adhésion | Une personne demande à rejoindre l'AMAP |

- Laissez un champ **vide** pour garder le message par défaut (affiché sous le champ).
- Le texte saisi est envoyé **tel quel** : n'y mettez pas de marqueurs entre accolades
  `{…}`, ils ne seraient pas remplacés et l'application les refuse.

Touchez **[ENREGISTRER LES ALERTES]** pour valider.

## Sauvegarder et restaurer l'AMAP

Toujours dans **[Préférences]**, la carte **« Sauvegarde & migration »** permet de :

- **[EXPORTER L'AMAP]** : télécharger un fichier de sauvegarde (`.json`) contenant les
  données de l'AMAP (membres, contrats, livraisons, catalogues des producteurs associés…) ;
- **[IMPORTER UNE SAUVEGARDE]** : restaurer un fichier de sauvegarde dans une AMAP
  **vide**, par exemple pour migrer vers un autre serveur.

À savoir :

- L'import est refusé si l'AMAP n'est pas vide (« Import impossible : l'AMAP cible n'est
  pas vide. ») ou si le fichier est invalide ou incompatible.
- Les membres importés n'ont pas encore de compte : une **invitation** est créée pour
  chacun d'eux, que vous pouvez envoyer ou relancer depuis **[Utilisateurs]**. À
  l'activation, la personne retrouve ses données (contrats, historique).
- Une personne dont l'adresse e-mail est déjà celle d'un **administrateur de
  l'instance** n'est pas importée : un message vous le signale à la fin de l'import.

## Voir aussi

- [Gérer les membres](01-gestion-des-membres.md)
- [Mes notifications et préférences](../amapien/05-notifications-preferences.md)
