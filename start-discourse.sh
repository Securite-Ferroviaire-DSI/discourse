#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[start-discourse] $*"
}

run_migrations_if_enabled() {
  if [[ "${DISCOURSE_RUN_MIGRATIONS}" == "true" ]]; then
    log "Exécution des migrations..."
    bundle exec rake db:migrate
    log "Migrations terminées."
  else
    log "Migrations désactivées."
  fi
}

precompile_assets_if_enabled() {
  if [[ "${DISCOURSE_PRECOMPILE_ASSETS}" == "true" ]]; then
    log "Précompilation des assets..."
    bundle exec rake assets:precompile
    log "Précompilation terminée."
  else
    log "Précompilation des assets désactivée."
  fi
}

main() {
  log "Démarrage applicatif"
  log "Environment: RAILS_ENV=${RAILS_ENV}, NODE_ENV=${NODE_ENV}, PORT=${PORT}"

  run_migrations_if_enabled
  precompile_assets_if_enabled

  log "Lancement du serveur Rails sur 0.0.0.0:${PORT}"
  exec bundle exec rails server -b 0.0.0.0 -p "${PORT}" -e "${RAILS_ENV}"
}

main "$@"
