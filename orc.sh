#!/bin/bash
set -euo pipefail

# ============================================================
# orc — CLI unifiée Autonome Agent
# ============================================================
#
# Point d'entrée unique pour tout contrôler :
#
#   orc agent <cmd>     Gestion des projets (new, start, stop, status, logs)
#   orc roadmap [opts]  Suivi de la roadmap (compact, detail, full + filtres)
#   orc admin <cmd>     Administration (config, model, budget, keys, version)
#   orc help            Aide contextuelle
#
# ============================================================

ORC_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ORC_VERSION="0.6.0"

# Charger les clés API
ENV_FILE="$ORC_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

# === COULEURS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

die() { printf "${RED}Erreur : %s${NC}\n" "$1" >&2; exit 1; }

# ============================================================
# HELP
# ============================================================

orc_help() {
  echo ""
  printf "${BOLD}orc${NC} — Autonome Agent CLI v%s\n" "$ORC_VERSION"
  echo ""
  printf "  ${BOLD}Projets :${NC}\n"
  printf "    ${CYAN}orc agent new <nom>${NC}               Créer un projet\n"
  printf "    ${CYAN}orc agent start <nom>${NC}             Lancer en background\n"
  printf "    ${CYAN}orc agent stop <nom>${NC}              Arrêter proprement\n"
  printf "    ${CYAN}orc agent status${NC}                  Vue d'ensemble\n"
  printf "    ${CYAN}orc agent status <nom>${NC}            Détail d'un projet\n"
  printf "    ${CYAN}orc agent logs <nom>${NC}              Logs temps réel\n"
  echo ""
  printf "  ${BOLD}Roadmap :${NC}\n"
  printf "    ${CYAN}orc roadmap${NC}                       Vue compacte\n"
  printf "    ${CYAN}orc roadmap --detail${NC}              + contexte, dépendances\n"
  printf "    ${CYAN}orc roadmap --full${NC}                + specs, critères\n"
  printf "    ${CYAN}orc roadmap --priority P1${NC}         Filtrer par priorité\n"
  printf "    ${CYAN}orc roadmap --tag adoption${NC}        Filtrer par tag\n"
  echo ""
  printf "  ${BOLD}Administration :${NC}\n"
  printf "    ${CYAN}orc admin config${NC}                  Voir la config globale\n"
  printf "    ${CYAN}orc admin config set KEY VAL${NC}      Modifier une config\n"
  printf "    ${CYAN}orc admin model${NC}                   Modèle Claude actuel\n"
  printf "    ${CYAN}orc admin model set <model>${NC}       Changer le modèle\n"
  printf "    ${CYAN}orc admin budget${NC}                  Coûts tous projets\n"
  printf "    ${CYAN}orc admin key${NC}                     Voir les clés API\n"
  printf "    ${CYAN}orc admin key set <key>${NC}           Configurer clé Anthropic\n"
  printf "    ${CYAN}orc admin version${NC}                 Version + vérifications\n"
  printf "    ${CYAN}orc admin update${NC}                  Mettre à jour le template\n"
  echo ""
  printf "  ${DIM}Raccourcis : 'orc s' = 'orc agent status', 'orc r' = 'orc roadmap'${NC}\n"
  echo ""
}

# ============================================================
# DISPATCH
# ============================================================

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
  agent|a)
    source "$ORC_DIR/orc-agent.sh"
    agent_dispatch "$@"
    ;;
  roadmap|r)
    source "$ORC_DIR/orc-agent.sh"
    cmd_roadmap "$@"
    ;;
  admin)
    source "$ORC_DIR/orc-admin.sh"
    admin_dispatch "$@"
    ;;
  # Raccourcis directs pour les commandes les plus fréquentes
  status|s)
    source "$ORC_DIR/orc-agent.sh"
    cmd_status "$@"
    ;;
  logs|l)
    source "$ORC_DIR/orc-agent.sh"
    cmd_logs "$@"
    ;;
  help|-h|--help)
    orc_help
    ;;
  version|-v|--version)
    printf "orc v%s\n" "$ORC_VERSION"
    ;;
  *)
    # Tenter comme sous-commande agent par défaut
    source "$ORC_DIR/orc-agent.sh"
    agent_dispatch "$COMMAND" "$@" 2>/dev/null || {
      die "Commande inconnue : $COMMAND. Voir : orc help"
    }
    ;;
esac
