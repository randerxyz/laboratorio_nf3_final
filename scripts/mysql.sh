#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# --interativo mantém TTY para SOURCE e as duas sessões dos experimentos.
if [ "${1:-}" = '--interativo' ]; then
 shift
 docker compose exec db sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot "$@"' sh "$@"
else
 docker compose exec -T db sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot "$@"' sh "$@"
fi
