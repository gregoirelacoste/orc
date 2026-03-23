#!/bin/bash
set -euo pipefail

# ============================================================
# Autonome Agent — CLI de gestion des projets
# ============================================================
#
# Usage :
#   agent new <nom>                     Créer un projet
#   agent new <nom> --brief briefs/x.md Avec un brief existant
#   agent start <nom>                   Lancer en background
#   agent stop <nom>                    Arrêter proprement
#   agent restart <nom>                 Redémarrer
#   agent status                        Vue d'ensemble
#   agent status <nom>                  Détail d'un projet
#   agent logs <nom>                    Logs temps réel
#   agent logs <nom> --full             Log complet
#   agent update                        Mettre à jour le template
# ============================================================

# Résoudre le chemin du template (là où agent.sh est installé)
TEMPLATE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PROJECTS_DIR="$HOME/projects"
ENV_FILE="$TEMPLATE_DIR/.env"

# Charger les clés API
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

# ============================================================
# FONCTIONS UTILITAIRES
# ============================================================

die() { printf "${RED}Erreur : %s${NC}\n" "$1" >&2; exit 1; }

project_dir() {
  echo "$PROJECTS_DIR/$1"
}

# Vérifie qu'un projet existe
require_project() {
  local name="$1"
  local dir
  dir=$(project_dir "$name")
  [ -d "$dir" ] || die "Projet '$name' non trouvé. Voir : agent status"
}

# Vérifie si l'orchestrateur tourne pour un projet
is_running() {
  local name="$1"
  local dir
  dir=$(project_dir "$name")
  local pidfile="$dir/.pid"

  if [ -f "$pidfile" ]; then
    local pid
    pid=$(cat "$pidfile")
    if kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
    # PID mort, nettoyer
    rm -f "$pidfile"
  fi
  return 1
}

# ============================================================
# COMMANDE : new
# ============================================================

cmd_new() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : agent new <nom> [--brief briefs/x.md]"

  local dir
  dir=$(project_dir "$name")
  [ -d "$dir" ] && die "Le projet '$name' existe déjà ($dir)"

  shift
  local brief_file=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --brief)
        brief_file="${2:-}"
        [ -z "$brief_file" ] && die "--brief nécessite un chemin de fichier"
        shift 2
        ;;
      *) die "Option inconnue : $1" ;;
    esac
  done

  printf "${BOLD}Création du projet '%s'...${NC}\n\n" "$name"

  # Créer le workspace
  mkdir -p "$dir"
  cp "$TEMPLATE_DIR/orchestrator.sh" "$dir/"
  cp -r "$TEMPLATE_DIR/phases" "$dir/"
  cp -r "$TEMPLATE_DIR/skills-templates" "$dir/"
  cp "$TEMPLATE_DIR/BRIEF.template.md" "$dir/"
  cp "$TEMPLATE_DIR/config.default.sh" "$dir/config.sh"
  chmod +x "$dir/orchestrator.sh"
  mkdir -p "$dir/logs"

  # Créer project/ avec son propre git
  mkdir -p "$dir/project"
  ( cd "$dir/project" && git init -b main > /dev/null 2>&1 )

  # Structure research/
  mkdir -p "$dir/project/research/competitors" \
           "$dir/project/research/trends" \
           "$dir/project/research/user-needs" \
           "$dir/project/research/regulations" \
           "$dir/project/logs"

  # Skills
  mkdir -p "$dir/project/.claude/skills"
  cp "$dir/skills-templates/"*.md "$dir/project/.claude/skills/"

  printf "  ${GREEN}✓${NC} Workspace créé : %s\n" "$dir"

  if [ -n "$brief_file" ]; then
    # Résoudre le chemin du brief (relatif au template ou absolu)
    local resolved_brief=""
    if [ -f "$brief_file" ]; then
      resolved_brief="$brief_file"
    elif [ -f "$TEMPLATE_DIR/$brief_file" ]; then
      resolved_brief="$TEMPLATE_DIR/$brief_file"
    else
      die "Brief non trouvé : $brief_file"
    fi

    cp "$resolved_brief" "$dir/BRIEF.md"
    cp "$resolved_brief" "$dir/project/BRIEF.md"
    printf "  ${GREEN}✓${NC} Brief copié depuis %s\n" "$brief_file"
  else
    # Mode interactif — Claude rédige le brief
    printf "\n  ${CYAN}Claude va te poser des questions pour rédiger le brief...${NC}\n\n"

    local brief_skill
    brief_skill=$(cat "$dir/skills-templates/write-brief.md")

    ( cd "$dir" && claude "$brief_skill

---

L'utilisateur crée un projet appelé \"$name\".
Pose les questions une par une. Écris le résultat dans BRIEF.md." --max-turns 40 )

    if [ -f "$dir/BRIEF.md" ]; then
      cp "$dir/BRIEF.md" "$dir/project/BRIEF.md"
      printf "\n  ${GREEN}✓${NC} Brief rédigé\n"
    else
      printf "\n  ${YELLOW}⚠${NC} Brief non créé. Rédige-le manuellement :\n"
      printf "    ${CYAN}vim %s/BRIEF.md${NC}\n" "$dir"
    fi
  fi

  echo ""
  printf "${GREEN}Projet '%s' prêt.${NC}\n" "$name"
  printf "  Lancer : ${CYAN}agent start %s${NC}\n" "$name"
  printf "  Éditer la config : ${CYAN}vim %s/config.sh${NC}\n" "$dir"
  echo ""
}

# ============================================================
# COMMANDE : start
# ============================================================

cmd_start() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : agent start <nom>"
  require_project "$name"

  local dir
  dir=$(project_dir "$name")

  if is_running "$name"; then
    local pid
    pid=$(cat "$dir/.pid")
    die "Déjà en cours (PID $pid). Voir : agent logs $name"
  fi

  [ -f "$dir/BRIEF.md" ] || die "Pas de BRIEF.md dans $dir. Crée-le d'abord."

  # Exporter les clés API
  export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
  export GEMINI_API_KEY="${GEMINI_API_KEY:-}"

  [ -z "$ANTHROPIC_API_KEY" ] && die "ANTHROPIC_API_KEY non configurée. Relancez deploy.sh."

  # Lancer en background
  ( cd "$dir" && nohup ./orchestrator.sh >> logs/orchestrator.log 2>&1 & echo $! > .pid )

  local pid
  pid=$(cat "$dir/.pid")

  printf "${GREEN}Projet '%s' lancé${NC} (PID %s)\n" "$name" "$pid"
  printf "  Logs : ${CYAN}agent logs %s${NC}\n" "$name"
  printf "  Status : ${CYAN}agent status %s${NC}\n" "$name"
  printf "  Stop : ${CYAN}agent stop %s${NC}\n" "$name"
}

# ============================================================
# COMMANDE : stop
# ============================================================

cmd_stop() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : agent stop <nom>"
  require_project "$name"

  local dir
  dir=$(project_dir "$name")

  if ! is_running "$name"; then
    printf "${YELLOW}Projet '%s' n'est pas en cours.${NC}\n" "$name"
    return 0
  fi

  local pid
  pid=$(cat "$dir/.pid")

  printf "Arrêt de '%s' (PID %s)..." "$name" "$pid"

  # SIGTERM — l'orchestrateur gère le cleanup
  kill "$pid" 2>/dev/null || true

  # Attendre max 30s
  local waited=0
  while [ $waited -lt 30 ] && kill -0 "$pid" 2>/dev/null; do
    sleep 1
    waited=$((waited + 1))
    printf "."
  done

  if kill -0 "$pid" 2>/dev/null; then
    printf " ${YELLOW}force kill${NC}"
    kill -9 "$pid" 2>/dev/null || true
  fi

  rm -f "$dir/.pid"
  printf " ${GREEN}arrêté.${NC}\n"
}

# ============================================================
# COMMANDE : restart
# ============================================================

cmd_restart() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : agent restart <nom>"
  cmd_stop "$name"
  sleep 1
  cmd_start "$name"
}

# ============================================================
# COMMANDE : status
# ============================================================

cmd_status() {
  local name="${1:-}"

  if [ -n "$name" ]; then
    cmd_status_detail "$name"
    return
  fi

  # Vue d'ensemble de tous les projets
  mkdir -p "$PROJECTS_DIR"

  local has_projects=false

  printf "\n${BOLD}%-20s %-10s %-12s %-8s %-10s %s${NC}\n" \
    "PROJET" "STATUS" "FEATURES" "ÉCHECS" "COÛT" "ROADMAP"
  printf "%-20s %-10s %-12s %-8s %-10s %s\n" \
    "────────────────────" "──────────" "────────────" "────────" "──────────" "──────────"

  for proj_dir in "$PROJECTS_DIR"/*/; do
    [ -d "$proj_dir" ] || continue
    has_projects=true

    local proj_name
    proj_name=$(basename "$proj_dir")

    # Status
    local status status_color
    if [ -f "$proj_dir/project/DONE.md" ]; then
      status="done"
      status_color="$GREEN"
    elif is_running "$proj_name"; then
      status="running"
      status_color="$CYAN"
    else
      status="stopped"
      status_color="$YELLOW"
    fi

    # Features
    local feat_count="0" max_feat="?" failures="0"
    if [ -f "$proj_dir/logs/state.json" ]; then
      feat_count=$(jq -r '.feature_count // 0' "$proj_dir/logs/state.json" 2>/dev/null || echo "0")
      failures=$(jq -r '.total_failures // 0' "$proj_dir/logs/state.json" 2>/dev/null || echo "0")
    fi
    if [ -f "$proj_dir/config.sh" ]; then
      max_feat=$(grep -oP 'MAX_FEATURES=\K\d+' "$proj_dir/config.sh" 2>/dev/null || echo "?")
    fi

    # Coût
    local cost="\$0.00"
    if [ -f "$proj_dir/logs/tokens.json" ]; then
      local raw_cost
      raw_cost=$(jq -r '.total_cost_usd // 0' "$proj_dir/logs/tokens.json" 2>/dev/null || echo "0")
      cost="\$$raw_cost"
    fi

    # Roadmap
    local remaining="—"
    if [ -f "$proj_dir/project/ROADMAP.md" ]; then
      local todo
      todo=$(grep -c '^\- \[ \]' "$proj_dir/project/ROADMAP.md" 2>/dev/null || echo "0")
      if [ "$todo" -eq 0 ] && [ "$status" = "done" ]; then
        remaining="terminé"
      else
        remaining="${todo} restantes"
      fi
    fi

    printf "%-20s ${status_color}%-10s${NC} %-12s %-8s %-10s %s\n" \
      "$proj_name" "$status" "${feat_count}/${max_feat}" "$failures" "$cost" "$remaining"
  done

  if [ "$has_projects" = false ]; then
    printf "\n  ${DIM}Aucun projet. Créer : ${CYAN}agent new mon-projet${NC}\n"
  fi

  echo ""
}

cmd_status_detail() {
  local name="$1"
  require_project "$name"

  local dir
  dir=$(project_dir "$name")

  echo ""
  printf "${BOLD}Projet : %s${NC}\n" "$name"
  printf "  Dossier : %s\n" "$dir"

  # Status
  if [ -f "$dir/project/DONE.md" ]; then
    printf "  Status : ${GREEN}terminé${NC}\n"
  elif is_running "$name"; then
    local pid
    pid=$(cat "$dir/.pid")
    printf "  Status : ${CYAN}en cours${NC} (PID %s)\n" "$pid"
  else
    printf "  Status : ${YELLOW}arrêté${NC}\n"
  fi

  # State
  if [ -f "$dir/logs/state.json" ]; then
    local feat fail
    feat=$(jq -r '.feature_count // 0' "$dir/logs/state.json" 2>/dev/null)
    fail=$(jq -r '.total_failures // 0' "$dir/logs/state.json" 2>/dev/null)
    printf "  Features : %s | Échecs : %s\n" "$feat" "$fail"
  fi

  # Tokens
  if [ -f "$dir/logs/tokens.json" ]; then
    local cost invocations tokens_in tokens_out
    cost=$(jq -r '.total_cost_usd // 0' "$dir/logs/tokens.json" 2>/dev/null)
    invocations=$(jq -r '.invocations // 0' "$dir/logs/tokens.json" 2>/dev/null)
    tokens_in=$(jq -r '.total_input_tokens // 0' "$dir/logs/tokens.json" 2>/dev/null)
    tokens_out=$(jq -r '.total_output_tokens // 0' "$dir/logs/tokens.json" 2>/dev/null)
    printf "  Coût : \$%s (%s invocations, %s in / %s out)\n" "$cost" "$invocations" "$tokens_in" "$tokens_out"
  fi

  # Roadmap
  if [ -f "$dir/project/ROADMAP.md" ]; then
    local done todo
    done=$(grep -c '^\- \[x\]' "$dir/project/ROADMAP.md" 2>/dev/null || echo "0")
    todo=$(grep -c '^\- \[ \]' "$dir/project/ROADMAP.md" 2>/dev/null || echo "0")
    printf "  Roadmap : %s faites, %s restantes\n" "$done" "$todo"
  fi

  # Dernières lignes du log
  if [ -f "$dir/logs/orchestrator.log" ]; then
    echo ""
    printf "  ${DIM}── Dernières lignes du log ──${NC}\n"
    tail -8 "$dir/logs/orchestrator.log" 2>/dev/null | sed 's/^/  /'
  fi

  echo ""
}

# ============================================================
# COMMANDE : logs
# ============================================================

cmd_logs() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : agent logs <nom> [--full]"
  require_project "$name"

  local dir
  dir=$(project_dir "$name")
  local logfile="$dir/logs/orchestrator.log"

  [ -f "$logfile" ] || die "Pas de log trouvé pour '$name'"

  shift
  if [ "${1:-}" = "--full" ]; then
    less +G "$logfile"
  else
    tail -f "$logfile"
  fi
}

# ============================================================
# COMMANDE : update
# ============================================================

cmd_update() {
  printf "${BOLD}Mise à jour du template...${NC}\n"

  if [ -d "$TEMPLATE_DIR/.git" ]; then
    git -C "$TEMPLATE_DIR" pull --ff-only
    printf "${GREEN}Template mis à jour.${NC}\n"
    printf "${DIM}Note : les workspaces existants ne sont pas affectés.${NC}\n"
  else
    die "$TEMPLATE_DIR n'est pas un repo git."
  fi
}

# ============================================================
# COMMANDE : help
# ============================================================

cmd_help() {
  echo ""
  printf "${BOLD}Autonome Agent — CLI${NC}\n"
  echo ""
  printf "  ${CYAN}agent new <nom>${NC}                     Créer un projet\n"
  printf "  ${CYAN}agent new <nom> --brief briefs/x.md${NC} Avec un brief existant\n"
  printf "  ${CYAN}agent start <nom>${NC}                   Lancer en background\n"
  printf "  ${CYAN}agent stop <nom>${NC}                    Arrêter proprement\n"
  printf "  ${CYAN}agent restart <nom>${NC}                 Redémarrer\n"
  printf "  ${CYAN}agent status${NC}                        Vue d'ensemble\n"
  printf "  ${CYAN}agent status <nom>${NC}                  Détail d'un projet\n"
  printf "  ${CYAN}agent logs <nom>${NC}                    Logs temps réel\n"
  printf "  ${CYAN}agent logs <nom> --full${NC}             Log complet\n"
  printf "  ${CYAN}agent update${NC}                        Mettre à jour le template\n"
  printf "  ${CYAN}agent help${NC}                          Cette aide\n"
  echo ""
}

# ============================================================
# DISPATCH
# ============================================================

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
  new)     cmd_new "$@" ;;
  start)   cmd_start "$@" ;;
  stop)    cmd_stop "$@" ;;
  restart) cmd_restart "$@" ;;
  status)  cmd_status "$@" ;;
  logs)    cmd_logs "$@" ;;
  update)  cmd_update ;;
  help|-h|--help) cmd_help ;;
  *) die "Commande inconnue : $COMMAND. Voir : agent help" ;;
esac
