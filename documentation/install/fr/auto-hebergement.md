# Héberger sa propre instance AMAP en ligne

Ce guide explique comment installer une instance complète d'AMAP en ligne (application web,
serveur, authentification, base de données) sur **n'importe quel serveur Linux** avec Docker.

Pour un pas-à-pas chez un hébergeur précis, voir aussi :

- [Infomaniak (VPS Lite)](infomaniak.md)

> L'instance installée est autonome : elle a ses propres comptes, ses propres AMAP et ses
> propres données. Elle n'a pas besoin de l'instance officielle pour fonctionner.

---

## 1. Ce qu'il faut

| Besoin | Détail |
|--------|--------|
| Un serveur Linux 64 bits (x86_64) | 2 Go de RAM recommandés (1 Go + 2 Go de swap au strict minimum), 20 Go de disque, Ubuntu/Debian récent. |
| Docker | Docker Engine 24+ avec le plugin `docker compose`. |
| Un nom de domaine | Par ex. `amap.mon-asso.fr`, dont on peut modifier le DNS. |
| Un compte email d'envoi (SMTP) | Une adresse type `noreply@mon-asso.fr` et ses identifiants SMTP, port 587 avec STARTTLS. |
| Ports ouverts | 80 et 443 (HTTP/HTTPS) depuis Internet, 22 pour l'administration SSH. |

Aucun JDK ni Flutter n'est nécessaire : les images Docker sont fournies prêtes à l'emploi.

## 2. Comment c'est organisé

Tout tient sur une seule machine et un seul nom de domaine :

```
Internet :443 ─► caddy     certificat HTTPS Let's Encrypt automatique
                   └─► web     application web + aiguillage
                         ├─ /v1/*, /.well-known/*  ─► api     (serveur AMAP en ligne)
                         └─ /auth/*                ─► gotrue  (connexion, mots de passe)
                 postgres   base de données (jamais exposée sur Internet)
```

| Conteneur | Image | Rôle |
|-----------|-------|------|
| `caddy` | `caddy` | Termine le HTTPS, obtient et renouvelle seul le certificat. |
| `web` | `ghcr.io/litote/amap-en-ligne-web` | Sert l'application web et redirige vers l'API et l'authentification. |
| `api` | `ghcr.io/litote/amap-en-ligne-api` | Le serveur AMAP en ligne. Crée et met à jour lui-même le schéma de la base. |
| `gotrue` | `supabase/gotrue` | Comptes, connexion, réinitialisation des mots de passe. |
| `postgres` | `postgres:16` | Les données (AMAP, contrats, livraisons… et les comptes). |

Les fichiers d'installation sont dans le dépôt, dossier
[`back/deploy/jvm/prod/`](../../../back/deploy/jvm/prod/).

## 3. Installation

### 3.1 Récupérer les fichiers

```bash
sudo git clone --depth 1 https://github.com/Litote/amap-en-ligne.git /opt/amap-en-ligne
sudo chown -R "$USER" /opt/amap-en-ligne
cd /opt/amap-en-ligne/back/deploy/jvm/prod
```

### 3.2 Générer les secrets et remplir la configuration

```bash
cp .env.example .env
./generate-secrets.sh >> .env
chmod 600 .env
nano .env
```

`generate-secrets.sh` ajoute le mot de passe de la base, la clé de signature des sessions et
la clé d'administration de l'authentification. **Ne le relancez pas** sur une instance déjà
démarrée (les sessions seraient invalidées et le mot de passe de la base ne correspondrait plus).

Variables à renseigner dans `.env` :

| Variable | Exemple | Rôle |
|----------|---------|------|
| `DOMAIN` | `amap.mon-asso.fr` | Nom de domaine de l'instance, sans `https://`. |
| `INSTANCE_NAME` | `AMAP de Mon Village` | Nom affiché dans l'application et comme expéditeur des emails. |
| `IMAGE_TAG` | `1.4.0` | Version installée. Fixez une version : avec `latest`, chaque `docker compose pull` mettrait à jour l'instance. |
| `SMTP_HOST` / `SMTP_PORT` | `smtp.mon-hebergeur.fr` / `587` | Serveur d'envoi des emails. |
| `SMTP_USERNAME` / `SMTP_PASSWORD` | `noreply@mon-asso.fr` / … | Identifiants SMTP. |
| `SMTP_FROM_EMAIL` | `noreply@mon-asso.fr` | Adresse d'expéditeur (doit être autorisée par le serveur SMTP). |
| `SMTP_TLS` | `true` | STARTTLS ; laisser `true` sauf relais local sans chiffrement. |

Variables facultatives (à laisser **commentées** si non utilisées — une valeur vide compte
comme renseignée) :

| Variable | Rôle |
|----------|------|
| `INSTANCE_TERMS_URL` | Adresse des conditions générales d'utilisation (par défaut `https://DOMAIN/cgu.html`, voir § 5). |
| `INSTANCE_GUIDE_URL` | Lien vers le guide utilisateur affiché dans l'écran d'aide. |
| `INSTANCE_VISIBLE` | `false` pour ne pas apparaître dans la liste publique des serveurs. |
| `JAVA_OPTS` | Mémoire du serveur (`-Xmx512m` par défaut, adapté à 2 Go de RAM). |
| `FCM_CREDENTIALS_FILE` | Notifications push mobiles (compte de service Firebase). |
| `ANDROID_*`, `IOS_*` | Liens d'application Android / iOS. |

### 3.3 Faire pointer le domaine vers le serveur

Chez le gestionnaire du domaine, créez un enregistrement **A** (et **AAAA** si le serveur a une
adresse IPv6) pour `DOMAIN` vers l'adresse IP du serveur. Attendez que la résolution soit
effective (`dig +short amap.mon-asso.fr`) **avant** le premier démarrage : Let's Encrypt en a
besoin pour délivrer le certificat.

Pour que les emails n'arrivent pas en spam, vérifiez aussi que le domaine d'envoi a des
enregistrements SPF, DKIM et DMARC (en général fournis par l'hébergeur de la messagerie).

### 3.4 Démarrer

```bash
docker compose up -d
docker compose ps        # tous les services doivent être "healthy" / "running"
```

Le premier démarrage prend une à deux minutes (création de la base, certificat HTTPS).
Vérifiez ensuite :

```bash
curl https://amap.mon-asso.fr/.well-known/amap-en-ligne.json   # description de l'instance
curl https://amap.mon-asso.fr/auth/health                       # authentification
```

et ouvrez `https://amap.mon-asso.fr` dans un navigateur.

### 3.5 Créer le compte administrateur de l'instance

Le premier compte, « propriétaire » de l'instance, se crée en ligne de commande :

```bash
./create-owner.sh vous@mon-asso.fr Prénom Nom
```

Le script demande le mot de passe (au moins 12 caractères, une minuscule, une majuscule et un
chiffre). Connectez-vous ensuite sur l'application web avec cet email : vous pouvez alors
valider les demandes de création d'AMAP et de comptes producteurs.

Le script peut être relancé sans risque, par exemple pour réinitialiser ce mot de passe.

## 4. Exploitation

### Mettre à jour

```bash
cd /opt/amap-en-ligne && git pull                 # fichiers d'installation à jour
cd back/deploy/jvm/prod
nano .env                                         # nouvelle valeur de IMAGE_TAG
docker compose pull && docker compose up -d
```

La base est migrée automatiquement au démarrage. Faites une sauvegarde avant chaque mise à jour.

### Sauvegarder

```bash
./backup.sh
```

crée `backups/amap-AAAAMMJJ-HHMMSS.sql.gz` (base complète, comptes inclus) et supprime les
sauvegardes de plus de 14 jours. Pour une sauvegarde quotidienne à 3 h 15 :

```bash
crontab -e
# ajouter :
15 3 * * * /opt/amap-en-ligne/back/deploy/jvm/prod/backup.sh >> /var/log/amap-backup.log 2>&1
```

**Copiez aussi les sauvegardes hors du serveur** (rclone, scp…) : une sauvegarde sur le même
disque ne protège pas d'une panne du serveur. Gardez aussi une copie du fichier `.env` en lieu
sûr : sans lui, une sauvegarde ne peut pas être remise en service telle quelle.

Chaque AMAP peut en plus exporter ses propres données depuis l'écran « Préférences » de son
administrateur (export / import d'organisation), utile pour déménager une AMAP d'une instance
à une autre.

### Restaurer

Sur une instance vide (nouveau serveur, ou après `docker compose down -v`) avec le même `.env` :

```bash
docker compose up -d postgres
gunzip -c backups/amap-AAAAMMJJ-HHMMSS.sql.gz | docker compose exec -T postgres psql -q -U postgres -d postgres > /dev/null
docker compose up -d
```

### Consulter les journaux

```bash
docker compose logs -f api       # ou gotrue, web, caddy, postgres
```

## 5. Personnaliser

- **Conditions générales d'utilisation** : l'image fournit un modèle à compléter (mentions
  légales, responsable des données, hébergeur…). Pour le remplacer :

  ```bash
  mkdir -p instance
  docker compose cp web:/usr/share/nginx/html/cgu.html instance/cgu.html
  nano instance/cgu.html
  ```

  puis décommentez les lignes `volumes:` du service `web` dans `docker-compose.yml` et relancez
  `docker compose up -d`. Vous pouvez aussi publier vos CGU ailleurs et renseigner
  `INSTANCE_TERMS_URL`.
- **Guide utilisateur** : `INSTANCE_GUIDE_URL`.
- **Notifications push** : déposez le fichier JSON du compte de service Firebase sur le serveur,
  montez-le dans le service `api` et renseignez `FCM_CREDENTIALS_FILE`.

## 6. Sans Docker Compose (PaaS, Kubernetes…)

Les mêmes images peuvent tourner sur une autre plateforme. Il faut reproduire :

| Service | Image | Points d'attention |
|---------|-------|--------------------|
| Base | `postgres:16` | Créer le schéma `auth` avant le premier démarrage de l'authentification (`back/deploy/jvm/postgres-init/01-schemas.sql`). |
| Authentification | `supabase/gotrue:v2.158.1` | Variables `GOTRUE_*` du `docker-compose.yml` ; `GOTRUE_JWT_EXP=900`. |
| Serveur | `ghcr.io/litote/amap-en-ligne-api` | `.env` + `POSTGRES_URL`, `INSTANCE_API_URL`, `INSTANCE_WEB_URL`, `GOTRUE_JWT_ISSUER`, `GOTRUE_ADMIN_API_URL`. |
| Web | `ghcr.io/litote/amap-en-ligne-web` | Doit joindre `api:8080` et `gotrue:9999` sous ces noms (voir `nginx.conf`). |

Contraintes à respecter :

- l'application web, `/v1`, `/.well-known` et `/auth` doivent être servis sur **le même
  domaine** : l'application web trouve son serveur à partir de sa propre adresse ;
- l'authentification doit être joignable publiquement **exactement** à l'adresse
  `GOTRUE_JWT_ISSUER` (`https://DOMAIN/auth`), qui est aussi celle publiée par l'instance ;
- les liens des emails de l'authentification doivent garder le préfixe `/auth`
  (`GOTRUE_MAILER_URLPATHS_*=/auth/verify`).

## 7. Limites connues

- **Applications mobiles** : elles ne proposent pour l'instant que les serveurs intégrés à
  l'application. Une nouvelle instance est utilisable tout de suite depuis le **navigateur**
  (ordinateur ou téléphone), pas encore depuis les applications Android / iOS publiées.
- **Liens d'application** (ouvrir un lien d'email directement dans l'application mobile) :
  inactifs tant que les variables `ANDROID_*` / `IOS_*` ne sont pas renseignées.
- **Révocation des droits** : un changement de rôle prend effet au plus tard 15 minutes après
  (durée de vie d'une session avant renouvellement).
