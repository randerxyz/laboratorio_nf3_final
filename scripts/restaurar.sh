#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
arquivo=${1:?Uso: bash scripts/restaurar.sh backups/arquivo.sql}
sha256sum -c "$arquivo.sha256"
inicio=$(date +%s)
alvo="loja_restore_$(date -u +%Y%m%d%H%M%S)_${RANDOM}"
bash scripts/mysql.sh -e "CREATE DATABASE ${alvo} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
bash scripts/mysql.sh "$alvo" < "$arquivo"
bash scripts/mysql.sh "$alvo" -e 'SELECT COUNT(*) clientes FROM CLIENTE; SELECT COUNT(*) itens FROM ITEM; SELECT SUM(qtd*preco) total FROM ITEM;'
printf 'Base restaurada: %s; tempo SQL: %ss\n' "$alvo" "$(( $(date +%s)-inicio ))"
