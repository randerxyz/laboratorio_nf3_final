#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p backups
arquivo="backups/loja_$(date -u +%Y%m%dT%H%M%SZ).sql"
docker compose exec -T db sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysqldump -uroot --single-transaction --no-tablespaces --set-gtid-purged=OFF loja_cerrado' > "$arquivo.tmp"
mv "$arquivo.tmp" "$arquivo"
sha256sum "$arquivo" > "$arquivo.sha256"
printf '%s\n' "$arquivo" > backups/ultimo.txt
printf 'Backup: %s\n' "$arquivo"
