#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -f .env ]; then
  umask 077
  cp .env.example .env
fi
mkdir -p evidencias backups objetos
docker version >/dev/null
docker compose version
printf 'Execute docker compose up -d --wait db\n'
