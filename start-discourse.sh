#!/usr/bin/env bash
set -Eeuo pipefail

APP_HOME="/var/www/discourse"
cd "${APP_HOME}"

log() {
  echo "[start] $*"
}

cleanup() {
  log "Arrêt en cours..."
  if [[ -n "${SIDEKIQ_PID:-}" ]]; then
    kill -TERM "${SIDEKIQ_PID}" 2>/dev/null || true
    wait "${SIDEKIQ_PID}" 2>/dev/null || true
  fi
}

trap cleanup SIGTERM SIGINT

main() {
  log "Démarrage Sidekiq"
  bundle exec sidekiq -e production &
  SIDEKIQ_PID=$!

  log "Démarrage Puma sur port ${PORT}"
  exec bundle exec puma \
    -e production \
    -b "tcp://0.0.0.0:${PORT}" \
    -w "${WEB_CONCURRENCY}" \
    -t "${RAILS_MAX_THREADS}:${RAILS_MAX_THREADS}"
}

main "$@"
