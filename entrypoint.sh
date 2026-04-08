#!/usr/bin/env bash
set -Eeuo pipefail

APP_HOME="/var/www/discourse"
cd "${APP_HOME}"

log() {
  echo "[entrypoint] $*"
}

fail() {
  echo "[entrypoint][ERROR] $*" >&2
  exit 1
}

require_env() {
  local var="$1"
  [[ -z "${!var:-}" ]] && fail "Variable requise absente: ${var}"
}

# ---- Mapping Clever Cloud (optionnel) ----

map_postgres() {
  export DISCOURSE_DB_HOST="${DISCOURSE_DB_HOST:-${POSTGRESQL_ADDON_HOST:-}}"
  export DISCOURSE_DB_PORT="${DISCOURSE_DB_PORT:-${POSTGRESQL_ADDON_PORT:-}}"
  export DISCOURSE_DB_NAME="${DISCOURSE_DB_NAME:-${POSTGRESQL_ADDON_DB:-}}"
  export DISCOURSE_DB_USERNAME="${DISCOURSE_DB_USERNAME:-${POSTGRESQL_ADDON_USER:-}}"
  export DISCOURSE_DB_PASSWORD="${DISCOURSE_DB_PASSWORD:-${POSTGRESQL_ADDON_PASSWORD:-}}"
}

map_redis() {
  export DISCOURSE_REDIS_HOST="${DISCOURSE_REDIS_HOST:-${REDIS_HOST:-}}"
  export DISCOURSE_REDIS_PORT="${DISCOURSE_REDIS_PORT:-${REDIS_PORT:-}}"
  export DISCOURSE_REDIS_PASSWORD="${DISCOURSE_REDIS_PASSWORD:-${REDIS_PASSWORD:-}}"
}

# ---- Secrets ----

ensure_secret() {
  if [[ -z "${SECRET_KEY_BASE:-}" ]]; then
    fail "SECRET_KEY_BASE doit être défini dans Clever Cloud"
  fi
}

# ---- Préparation FS ----

prepare_fs() {
  mkdir -p /shared/log/rails /shared/tmp /shared/uploads /shared/backups tmp/pids
  rm -f tmp/pids/server.pid
}

main() {
  log "Initialisation"

  export RAILS_ENV="${RAILS_ENV:-production}"
  export DISCOURSE_ENV="${DISCOURSE_ENV:-production}"
  export PORT="${PORT:-8080}"

  map_postgres
  map_redis

  require_env DISCOURSE_HOSTNAME
  require_env DISCOURSE_DEVELOPER_EMAILS
  require_env DISCOURSE_DB_HOST
  require_env DISCOURSE_DB_NAME
  require_env DISCOURSE_DB_USERNAME
  require_env DISCOURSE_DB_PASSWORD
  require_env DISCOURSE_REDIS_HOST

  ensure_secret
  prepare_fs

  log "Lancement bootstrap"
  /usr/local/bin/bootstrap

  exec "$@"
}

main "$@"
