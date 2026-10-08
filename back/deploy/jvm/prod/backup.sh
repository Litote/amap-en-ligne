#!/usr/bin/env sh
# Dumps the whole Postgres database (application data + GoTrue `auth` schema) of a self-hosted
# instance into backups/, keeping the last RETENTION_DAYS days:
#
#   ./backup.sh
#
# Schedule it daily from the host's crontab, e.g.:
#   15 3 * * * /opt/amap-en-ligne/back/deploy/jvm/prod/backup.sh >> /var/log/amap-backup.log 2>&1
#
# Restore into an empty stack (fresh postgres volume):
#   docker compose up -d postgres
#   gunzip -c backups/amap-YYYYMMDD-HHMMSS.sql.gz | docker compose exec -T postgres psql -q -U postgres -d postgres > /dev/null
#   docker compose up -d
#
# Copy backups/ off the host as well (rclone, scp…): a dump on the same disk is no backup.
set -eu

cd "$(dirname "$0")"

RETENTION_DAYS="${RETENTION_DAYS:-14}"
mkdir -p backups
target="backups/amap-$(date +%Y%m%d-%H%M%S).sql.gz"

docker compose exec -T postgres pg_dump -U postgres -d postgres --clean --if-exists | gzip > "${target}.tmp"
mv "${target}.tmp" "$target"
chmod 600 "$target"

find backups -name 'amap-*.sql.gz' -mtime +"$RETENTION_DAYS" -delete
echo "Backup written: $target"
