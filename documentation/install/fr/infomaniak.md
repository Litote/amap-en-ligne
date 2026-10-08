# Héberger une instance chez Infomaniak (VPS Lite)

Ce guide complète le [guide d'auto-hébergement](auto-hebergement.md) avec ce qui est propre à
Infomaniak. Les étapes communes (configuration, démarrage, compte administrateur, sauvegardes,
mises à jour) y renvoient.

## Quelle offre choisir ?

L'option la moins chère qui convient est un **VPS Lite** de taille **S** (1 vCPU, 2 Go de RAM,
40 Go de disque), autour de 6 € par mois (tarif indicatif, à vérifier sur
[infomaniak.com](https://www.infomaniak.com/fr/hebergement/vps-lite)). La taille XS (1 Go) est
trop juste pour faire tourner ensemble la base, l'authentification et le serveur.

À prévoir en plus :

- un **nom de domaine** (environ 10 à 15 € par an), géré dans le DNS Infomaniak ;
- une **adresse email d'envoi** sur ce domaine (offre *Service Mail* d'Infomaniak) ;
- en option, un espace de sauvegarde hors du serveur (kDrive ou Swiss Backup).

## 1. Commander et préparer le VPS

1. Dans le Manager Infomaniak, commandez un **VPS Lite S** avec l'image **Ubuntu 24.04 LTS** et
   ajoutez votre **clé SSH publique** à la commande.
2. Dans la section **Pare-feu** du VPS, autorisez en entrée les ports **22** (SSH),
   **80** (HTTP) et **443** (HTTPS, TCP et UDP).
3. Connectez-vous avec l'utilisateur indiqué dans le Manager (en général `ubuntu`) :

   ```bash
   ssh ubuntu@<adresse-ip-du-vps>
   ```

4. Ajoutez 2 Go de swap (sécurité en cas de pic de mémoire) :

   ```bash
   sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
   sudo mkswap /swapfile && sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

5. Activez les mises à jour de sécurité automatiques, puis installez Docker :

   ```bash
   sudo apt update && sudo apt install -y unattended-upgrades git
   sudo dpkg-reconfigure -plow unattended-upgrades
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker "$USER"   # puis se déconnecter / reconnecter
   ```

## 2. Configurer le domaine

Dans le Manager, **Domaines → votre domaine → Zone DNS** :

- ajoutez un enregistrement **A** pour le sous-domaine choisi (par ex. `amap`) vers l'adresse
  IPv4 du VPS ;
- ajoutez un enregistrement **AAAA** vers son adresse IPv6 si le VPS en a une.

Vérifiez depuis le VPS avec `dig +short amap.mon-asso.fr` avant de démarrer l'instance.

## 3. Créer l'adresse d'envoi des emails

1. Dans le Manager, ouvrez le **Service Mail** du domaine et créez une adresse, par exemple
   `noreply@mon-asso.fr`, avec un mot de passe dédié.
2. Les enregistrements SPF et DKIM sont ajoutés par Infomaniak quand le domaine et la messagerie
   y sont tous deux gérés ; vérifiez-les dans la zone DNS (DMARC peut être ajouté à la main).
3. Notez les valeurs à reporter dans le fichier `.env` :

   ```
   SMTP_HOST=mail.infomaniak.com
   SMTP_PORT=587
   SMTP_TLS=true
   SMTP_USERNAME=noreply@mon-asso.fr
   SMTP_PASSWORD=<mot de passe de l'adresse>
   SMTP_FROM_EMAIL=noreply@mon-asso.fr
   ```

## 4. Installer l'instance

Suivez le [guide d'auto-hébergement](auto-hebergement.md) à partir de l'étape
**3.1 Récupérer les fichiers**, avec les valeurs SMTP ci-dessus. La mémoire par défaut
(`JAVA_OPTS=-Xmx512m`) convient au VPS Lite S.

## 5. Sauvegardes hors du VPS

Les sauvegardes quotidiennes de `backup.sh` restent sur le disque du VPS : copiez-les ailleurs.
Avec **kDrive** (inclus dans de nombreuses offres Infomaniak), via WebDAV et rclone :

```bash
sudo apt install -y rclone
rclone config   # nouveau remote "kdrive" de type WebDAV :
                #   url    = https://<identifiant-kdrive>.connect.kdrive.infomaniak.com
                #   vendor = other, user = email du compte, mot de passe = mot de passe d'application
crontab -e
# ajouter, après la ligne de backup.sh :
45 3 * * * rclone copy /opt/amap-en-ligne/back/deploy/jvm/prod/backups kdrive:amap-backups --max-age 48h
```

L'identifiant kDrive et la création d'un mot de passe d'application sont expliqués dans l'aide
Infomaniak (« Se connecter à kDrive via WebDAV »). **Swiss Backup** fonctionne de la même façon
(remote rclone de type S3 ou Swift).

Pensez aussi à garder une copie du fichier `.env` dans un endroit sûr (gestionnaire de mots de
passe, par exemple).
