#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[entrypoint] $*"
}

fail() {
  echo "[entrypoint][ERROR] $*" >&2
  exit 1
}

require_env() {
  local var_name="$1"
  if [[ -z "${!var_name:-}" ]]; then
    fail "La variable d'environnement ${var_name} est requise mais absente."
  fi
}

map_clevercloud_postgresql_env() {
  export DISCOURSE_DB_HOST="${DISCOURSE_DB_HOST:-${POSTGRESQL_ADDON_HOST:-}}"
  export DISCOURSE_DB_PORT="${DISCOURSE_DB_PORT:-${POSTGRESQL_ADDON_PORT:-}}"
  export DISCOURSE_DB_NAME="${DISCOURSE_DB_NAME:-${POSTGRESQL_ADDON_DB:-}}"
  export DISCOURSE_DB_USERNAME="${DISCOURSE_DB_USERNAME:-${POSTGRESQL_ADDON_USER:-}}"
  export DISCOURSE_DB_PASSWORD="${DISCOURSE_DB_PASSWORD:-${POSTGRESQL_ADDON_PASSWORD:-}}"
}

map_clevercloud_redis_env() {
  export DISCOURSE_REDIS_HOST="${DISCOURSE_REDIS_HOST:-${REDIS_HOST:-}}"
  export DISCOURSE_REDIS_PORT="${DISCOURSE_REDIS_PORT:-${REDIS_PORT:-}}"
  export DISCOURSE_REDIS_PASSWORD="${DISCOURSE_REDIS_PASSWORD:-${REDIS_PASSWORD:-}}"
}

wait_for_postgres() {
  local host="$1"
  local port="$2"
  local dbname="$3"
  local user="$4"
  local password="$5"
  local max_attempts="${6:-20}"

  log "Vérification PostgreSQL ${host}:${port}..."
  export PGPASSWORD="${password}"

  local attempt=1
  while [[ $attempt -le $max_attempts ]]; do
    if pg_isready -h "${host}" -p "${port}" -d "${dbname}" -U "${user}" >/dev/null 2>&1; then
      log "PostgreSQL OK"
      return 0
    fi

    log "PostgreSQL indisponible (${attempt}/${max_attempts})..."
    sleep 2
    attempt=$((attempt + 1))
  done

  fail "PostgreSQL inaccessible"
}

wait_for_redis() {
  local host="$1"
  local port="$2"
  local password="${3:-}"
  local max_attempts="${4:-20}"

  log "Vérification Redis ${host}:${port}..."

  local attempt=1
  while [[ $attempt -le $max_attempts ]]; do
    if [[ -n "${password}" ]]; then
      redis-cli -h "${host}" -p "${port}" -a "${password}" ping >/dev/null 2>&1 && return 0
    else
      redis-cli -h "${host}" -p "${port}" ping >/dev/null 2>&1 && return 0
    fi

    log "Redis indisponible (${attempt}/${max_attempts})..."
    sleep 2
    attempt=$((attempt + 1))
  done

  fail "Redis inaccessible"
}

main() {
  log "Démarrage"

  map_clevercloud_postgresql_env
  map_clevercloud_redis_env

  require_env "DISCOURSE_DB_HOST"
  require_env "DISCOURSE_DB_PORT"
  require_env "DISCOURSE_DB_NAME"
  require_env "DISCOURSE_DB_USERNAME"
  require_env "DISCOURSE_DB_PASSWORD"

  require_env "DISCOURSE_REDIS_HOST"
  require_env "DISCOURSE_REDIS_PORT"

  export PORT="${PORT:-8080}"
  export RAILS_ENV="${RAILS_ENV:-production}"

  wait_for_postgres \
    "$DISCOURSE_DB_HOST" \
    "$DISCOURSE_DB_PORT" \
    "$DISCOURSE_DB_NAME" \
    "$DISCOURSE_DB_USERNAME" \
    "$DISCOURSE_DB_PASSWORD"

  wait_for_redis \
    "$DISCOURSE_REDIS_HOST" \
    "$DISCOURSE_REDIS_PORT" \
    "${DISCOURSE_REDIS_PASSWORD:-}"

  log "Bootstrap OK"

  exec "$@"
}

main "$@"
