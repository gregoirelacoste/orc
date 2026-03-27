#!/bin/bash
# ============================================================
# orc-agent.sh — Gestion des projets (sourcé par orc.sh)
# ============================================================
#
# Fonctions : cmd_new, cmd_start, cmd_stop, cmd_restart,
#             cmd_status, cmd_logs, cmd_roadmap, cmd_update
#
# Variables attendues de orc.sh :
#   ORC_DIR, PROJECTS_DIR (via env ou défaut),
#   RED, GREEN, YELLOW, BLUE, CYAN, BOLD, DIM, NC, die()
# ============================================================

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"

# ============================================================
# UTILITAIRES
# ============================================================

project_dir() {
  echo "$PROJECTS_DIR/$1"
}

require_project() {
  local name="$1"
  local dir
  dir=$(project_dir "$name")
  [ -d "$dir" ] || die "Projet '$name' non trouvé. Voir : orc agent status"
}

is_running() {
  local name="$1"
  local dir
  dir=$(project_dir "$name")
  local pidfile="$dir/.orc/.pid"

  if [ -f "$pidfile" ]; then
    local pid
    pid=$(cat "$pidfile")
    if kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
    rm -f "$pidfile"
  fi
  return 1
}

# ============================================================
# COMMANDE : new
# ============================================================

cmd_new() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : orc agent new <nom> [--brief briefs/x.md] [--no-clarify]"

  local dir
  dir=$(project_dir "$name")
  shift
  local brief_file=""
  local no_clarify=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --brief)
        brief_file="${2:-}"
        [ -z "$brief_file" ] && die "--brief nécessite un chemin de fichier"
        shift 2
        ;;
      --no-clarify)
        no_clarify=true
        shift
        ;;
      *) die "Option inconnue : $1" ;;
    esac
  done

  # Reprise : si le dossier existe mais pas de BRIEF.md, on reprend
  local resume=false
  if [ -d "$dir" ]; then
    if [ -f "$dir/BRIEF.md" ]; then
      die "Le projet '$name' existe déjà avec un brief ($dir)"
    else
      printf "${YELLOW}Workspace incomplet détecté — reprise...${NC}\n\n"
      resume=true
    fi
  fi

  printf "${BOLD}Création du projet '%s'...${NC}\n\n" "$name"

  # Création/réparation du workspace (idempotent)
  mkdir -p "$dir"
  cp "$ORC_DIR/orchestrator.sh" "$dir/"
  cp -r "$ORC_DIR/phases" "$dir/"
  cp -r "$ORC_DIR/skills-templates" "$dir/"
  cp "$ORC_DIR/BRIEF.template.md" "$dir/"
  chmod +x "$dir/orchestrator.sh"
  mkdir -p "$dir/.orc/logs"
  [ -f "$dir/.orc/config.sh" ] || cp "$ORC_DIR/config.default.sh" "$dir/.orc/config.sh"

  mkdir -p "$dir/project"
  [ -d "$dir/project/.git" ] || ( cd "$dir/project" && git init -b main > /dev/null 2>&1 )

  mkdir -p "$dir/project/.orc/research/competitors" \
           "$dir/project/.orc/research/trends" \
           "$dir/project/.orc/research/user-needs" \
           "$dir/project/.orc/research/regulations" \
           "$dir/project/.orc/logs"

  mkdir -p "$dir/project/.claude/skills"
  cp "$dir/skills-templates/"*.md "$dir/project/.claude/skills/"

  if [ "$resume" = true ]; then
    printf "  ${GREEN}✓${NC} Workspace réparé : %s\n" "$dir"
  else
    printf "  ${GREEN}✓${NC} Workspace créé : %s\n" "$dir"
  fi

  if [ -n "$brief_file" ]; then
    local resolved_brief=""
    if [ -f "$brief_file" ]; then
      resolved_brief="$brief_file"
    elif [ -f "$ORC_DIR/$brief_file" ]; then
      resolved_brief="$ORC_DIR/$brief_file"
    else
      die "Brief non trouvé : $brief_file"
    fi

    cp "$resolved_brief" "$dir/BRIEF.md"
    printf "  ${GREEN}✓${NC} Brief copié depuis %s\n" "$brief_file"

    if [ "$no_clarify" = false ]; then
      printf "\n  ${CYAN}Claude va analyser le brief et poser des questions pour le clarifier...${NC}\n\n"

      local clarify_skill
      clarify_skill=$(cat "$dir/skills-templates/clarify-brief.md")

      ( cd "$dir" && claude --max-turns 40 -- "$clarify_skill

---

Le projet s'appelle \"$name\".
Le brief existant est dans BRIEF.md — lis-le et commence ton analyse.
Pose des questions pour clarifier les zones floues, puis enrichis le brief." )

      if [ -f "$dir/BRIEF.md" ]; then
        printf "\n  ${GREEN}✓${NC} Brief clarifié et enrichi\n"
      else
        printf "\n  ${YELLOW}⚠${NC} Brief non mis à jour. Le brief original est conservé.\n"
      fi
    fi

    cp "$dir/BRIEF.md" "$dir/project/.orc/BRIEF.md"
  else
    printf "\n  ${CYAN}Claude va te poser des questions pour rédiger le brief...${NC}\n\n"

    local brief_skill
    brief_skill=$(cat "$dir/skills-templates/write-brief.md")

    ( cd "$dir" && claude --max-turns 40 -- "$brief_skill

---

L'utilisateur crée un projet appelé \"$name\".
Pose les questions une par une. Écris le résultat dans BRIEF.md." )

    if [ -f "$dir/BRIEF.md" ]; then
      cp "$dir/BRIEF.md" "$dir/project/.orc/BRIEF.md"
      printf "\n  ${GREEN}✓${NC} Brief rédigé\n"
    else
      printf "\n  ${YELLOW}⚠${NC} Brief non créé. Rédige-le manuellement :\n"
      printf "    ${CYAN}vim %s/BRIEF.md${NC}\n" "$dir"
    fi
  fi

  echo ""
  printf "${GREEN}Projet '%s' prêt.${NC}\n" "$name"
  printf "  Lancer : ${CYAN}orc agent start %s${NC}\n" "$name"
  printf "  Config : ${CYAN}vim %s/.orc/config.sh${NC}\n" "$dir"
  echo ""
}

# ============================================================
# COMMANDE : start
# ============================================================

cmd_start() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : orc agent start <nom>"
  require_project "$name"

  local dir
  dir=$(project_dir "$name")

  if is_running "$name"; then
    local pid
    pid=$(cat "$dir/.orc/.pid")
    die "Déjà en cours (PID $pid). Voir : orc logs $name"
  fi

  [ -f "$dir/BRIEF.md" ] || die "Pas de BRIEF.md dans $dir. Crée-le d'abord."

  export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
  export GEMINI_API_KEY="${GEMINI_API_KEY:-}"

  # L'API key n'est pas requise si Claude Code CLI est authentifié (OAuth/login)
  if [ -z "$ANTHROPIC_API_KEY" ] && ! command -v claude &> /dev/null; then
    die "Claude Code CLI non trouvé et ANTHROPIC_API_KEY non configurée. Installer claude ou configurer la clé : orc admin key"
  fi

  # Injecter le modèle si configuré globalement
  local model_file="$ORC_DIR/.model"
  if [ -f "$model_file" ]; then
    export CLAUDE_MODEL
    CLAUDE_MODEL=$(cat "$model_file")
  fi

  mkdir -p "$dir/.orc/logs"
  nohup bash -c "cd \"$dir\" && exec ./orchestrator.sh" >> "$dir/.orc/logs/orchestrator.log" 2>&1 &
  local pid=$!
  echo "$pid" > "$dir/.orc/.pid"

  printf "${GREEN}Projet '%s' lancé${NC} (PID %s)\n" "$name" "$pid"
  printf "  Logs   : ${CYAN}orc logs %s${NC}\n" "$name"
  printf "  Status : ${CYAN}orc s %s${NC}\n" "$name"
  printf "  Stop   : ${CYAN}orc agent stop %s${NC}\n" "$name"
}

# ============================================================
# COMMANDE : stop
# ============================================================

cmd_stop() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : orc agent stop <nom>"
  require_project "$name"

  local dir
  dir=$(project_dir "$name")

  if ! is_running "$name"; then
    printf "${YELLOW}Projet '%s' n'est pas en cours.${NC}\n" "$name"
    return 0
  fi

  local pid
  pid=$(cat "$dir/.orc/.pid")

  printf "Arrêt de '%s' (PID %s)..." "$name" "$pid"

  kill "$pid" 2>/dev/null || true

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

  rm -f "$dir/.orc/.pid"
  printf " ${GREEN}arrêté.${NC}\n"
}

# ============================================================
# COMMANDE : restart
# ============================================================

cmd_restart() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : orc agent restart <nom>"
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

    local feat_count="0" max_feat="?" failures="0"
    if [ -f "$proj_dir/.orc/state.json" ]; then
      feat_count=$(jq -r '.feature_count // 0' "$proj_dir/.orc/state.json" 2>/dev/null || echo "0")
      failures=$(jq -r '.total_failures // 0' "$proj_dir/.orc/state.json" 2>/dev/null || echo "0")
    fi
    if [ -f "$proj_dir/.orc/config.sh" ]; then
      max_feat=$(grep -oP 'MAX_FEATURES=\K\d+' "$proj_dir/.orc/config.sh" 2>/dev/null || echo "?")
    fi

    local cost="\$0.00"
    if [ -f "$proj_dir/.orc/tokens.json" ]; then
      local raw_cost
      raw_cost=$(jq -r '.total_cost_usd // 0' "$proj_dir/.orc/tokens.json" 2>/dev/null || echo "0")
      cost="\$$raw_cost"
    fi

    local remaining="—"
    if [ -f "$proj_dir/project/.orc/ROADMAP.md" ]; then
      local todo
      todo=$(grep -c '^\- \[ \]' "$proj_dir/project/.orc/ROADMAP.md" 2>/dev/null || echo "0")
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
    printf "\n  ${DIM}Aucun projet. Créer : ${CYAN}orc agent new mon-projet${NC}\n"
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

  if [ -f "$dir/project/DONE.md" ]; then
    printf "  Status : ${GREEN}terminé${NC}\n"
  elif is_running "$name"; then
    local pid
    pid=$(cat "$dir/.orc/.pid")
    printf "  Status : ${CYAN}en cours${NC} (PID %s)\n" "$pid"
  else
    printf "  Status : ${YELLOW}arrêté${NC}\n"
  fi

  if [ -f "$dir/.orc/state.json" ]; then
    local feat fail
    feat=$(jq -r '.feature_count // 0' "$dir/.orc/state.json" 2>/dev/null)
    fail=$(jq -r '.total_failures // 0' "$dir/.orc/state.json" 2>/dev/null)
    printf "  Features : %s | Échecs : %s\n" "$feat" "$fail"
  fi

  if [ -f "$dir/.orc/tokens.json" ]; then
    local cost invocations tokens_in tokens_out
    cost=$(jq -r '.total_cost_usd // 0' "$dir/.orc/tokens.json" 2>/dev/null)
    invocations=$(jq -r '.invocations // 0' "$dir/.orc/tokens.json" 2>/dev/null)
    tokens_in=$(jq -r '.total_input_tokens // 0' "$dir/.orc/tokens.json" 2>/dev/null)
    tokens_out=$(jq -r '.total_output_tokens // 0' "$dir/.orc/tokens.json" 2>/dev/null)
    printf "  Coût : \$%s (%s invocations, %s in / %s out)\n" "$cost" "$invocations" "$tokens_in" "$tokens_out"
  fi

  # Modèle
  local model_file="$ORC_DIR/.model"
  if [ -f "$model_file" ]; then
    printf "  Modèle : %s\n" "$(cat "$model_file")"
  fi

  if [ -f "$dir/project/.orc/ROADMAP.md" ]; then
    local done_count todo
    done_count=$(grep -c '^\- \[x\]' "$dir/project/.orc/ROADMAP.md" 2>/dev/null || echo "0")
    todo=$(grep -c '^\- \[ \]' "$dir/project/.orc/ROADMAP.md" 2>/dev/null || echo "0")
    printf "  Roadmap : %s faites, %s restantes\n" "$done_count" "$todo"
  fi

  if [ -f "$dir/.orc/logs/orchestrator.log" ]; then
    echo ""
    printf "  ${DIM}── Dernières lignes du log ──${NC}\n"
    tail -8 "$dir/.orc/logs/orchestrator.log" 2>/dev/null | sed 's/^/  /'
  fi

  echo ""
}

# ============================================================
# COMMANDE : logs
# ============================================================

cmd_logs() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : orc logs <nom> [--full]"
  require_project "$name"

  local dir
  dir=$(project_dir "$name")
  local logfile="$dir/.orc/logs/orchestrator.log"

  [ -f "$logfile" ] || die "Pas de log trouvé pour '$name'"

  shift
  if [ "${1:-}" = "--full" ]; then
    less +G "$logfile"
  else
    # Afficher le contexte récent puis suivre en temps réel
    local total
    total=$(wc -l < "$logfile")
    if [ "$total" -gt 30 ]; then
      printf "${DIM}── %s dernières lignes ──${NC}\n" "30"
      tail -30 "$logfile"
      printf "${DIM}── suivi en temps réel (Ctrl+C pour quitter) ──${NC}\n\n"
    fi
    tail -f "$logfile"
  fi
}

# ============================================================
# COMMANDE : update
# ============================================================

cmd_update() {
  printf "${BOLD}Mise à jour du template...${NC}\n"

  if [ -d "$ORC_DIR/.git" ]; then
    git -C "$ORC_DIR" pull --ff-only
    printf "${GREEN}Template mis à jour.${NC}\n"
    printf "${DIM}Note : les workspaces existants ne sont pas affectés.${NC}\n"
  else
    die "$ORC_DIR n'est pas un repo git."
  fi
}

# ============================================================
# COMMANDE : roadmap
# ============================================================

# Parse le frontmatter YAML d'un fichier roadmap item
parse_frontmatter() {
  local file="$1"
  local field="$2"
  awk -v field="$field" '
    /^---$/ { block++; next }
    block == 1 {
      if ($0 ~ "^" field ":") {
        sub("^" field ":[[:space:]]*", "")
        gsub(/^"|"$/, "")
        print
        exit
      }
    }
    block >= 2 { exit }
  ' "$file"
}

parse_tags() {
  local file="$1"
  awk '
    /^---$/ { block++; next }
    block == 1 && /^tags:/ {
      sub(/^tags:[[:space:]]*\[/, "")
      sub(/\][[:space:]]*$/, "")
      gsub(/,[ ]*/, ",")
      print
      exit
    }
    block >= 2 { exit }
  ' "$file"
}

parse_depends() {
  local file="$1"
  awk '
    /^---$/ { block++; next }
    block == 1 && /^depends:/ {
      sub(/^depends:[[:space:]]*\[/, "")
      sub(/\][[:space:]]*$/, "")
      gsub(/,[ ]*/, ",")
      print
      exit
    }
    block >= 2 { exit }
  ' "$file"
}

extract_section() {
  local file="$1"
  local section="$2"
  local max_lines="${3:-999}"
  awk -v section="$section" -v max="$max_lines" '
    /^---$/ { block++; next }
    block < 2 { next }
    $0 ~ "^## " section { found=1; next }
    found && /^## / { exit }
    found { count++; if (count <= max) print }
  ' "$file"
}

priority_color() {
  case "$1" in
    P0) printf "${RED}" ;;
    P1) printf "${YELLOW}" ;;
    P2) printf "${BLUE}" ;;
    P3) printf "${DIM}" ;;
    *)  printf "${NC}" ;;
  esac
}

status_symbol() {
  case "$1" in
    in-progress) printf "${CYAN}●${NC}" ;;
    planned)     printf "○" ;;
    backlog)     printf "${DIM}◌${NC}" ;;
    done)        printf "${GREEN}✓${NC}" ;;
    *)           printf "?" ;;
  esac
}

sort_items() {
  sort -t'|' -k1,1 -k2,2r
}

effort_sort_key() {
  case "$1" in
    XL) echo "5" ;;
    L)  echo "4" ;;
    M)  echo "3" ;;
    S)  echo "2" ;;
    XS) echo "1" ;;
    *)  echo "0" ;;
  esac
}

cmd_roadmap() {
  local verbosity="compact"
  local filter_priority="" filter_tag="" filter_epic="" filter_type="" filter_status=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --detail)    verbosity="detail"; shift ;;
      --full)      verbosity="full"; shift ;;
      --priority)  filter_priority="${2:-}"; shift 2 ;;
      --tag)       filter_tag="${2:-}"; shift 2 ;;
      --epic)      filter_epic="${2:-}"; shift 2 ;;
      --type)      filter_type="${2:-}"; shift 2 ;;
      --status)    filter_status="${2:-}"; shift 2 ;;
      -h|--help)   cmd_roadmap_help; return ;;
      *) die "Option inconnue : $1. Voir : orc roadmap --help" ;;
    esac
  done

  local roadmap_dir="$ORC_DIR/roadmap"
  [ -d "$roadmap_dir" ] || die "Dossier roadmap/ non trouvé dans $ORC_DIR"

  local count_p0=0 count_p1=0 count_p2=0 count_p3=0 count_total=0

  local items_data=""
  for status_dir in in-progress planned backlog done; do
    local dir="$roadmap_dir/$status_dir"
    [ -d "$dir" ] || continue

    if [ -n "$filter_status" ] && [ "$filter_status" != "$status_dir" ]; then
      continue
    fi

    for item_file in "$dir"/ROADMAP-*.md; do
      [ -f "$item_file" ] || continue

      local item_id item_title item_priority item_type item_effort item_tags item_epic

      item_id=$(parse_frontmatter "$item_file" "id")
      item_title=$(parse_frontmatter "$item_file" "title")
      item_priority=$(parse_frontmatter "$item_file" "priority")
      item_type=$(parse_frontmatter "$item_file" "type")
      item_effort=$(parse_frontmatter "$item_file" "effort")
      item_tags=$(parse_tags "$item_file")
      item_epic=$(parse_frontmatter "$item_file" "epic")

      if [ -n "$filter_priority" ] && [ "$item_priority" != "$filter_priority" ]; then
        continue
      fi
      if [ -n "$filter_tag" ]; then
        if ! echo ",$item_tags," | grep -qi ",$filter_tag,"; then
          continue
        fi
      fi
      if [ -n "$filter_epic" ] && [ "$item_epic" != "$filter_epic" ]; then
        continue
      fi
      if [ -n "$filter_type" ] && [ "$item_type" != "$filter_type" ]; then
        continue
      fi

      case "$item_priority" in
        P0) count_p0=$((count_p0 + 1)) ;;
        P1) count_p1=$((count_p1 + 1)) ;;
        P2) count_p2=$((count_p2 + 1)) ;;
        P3) count_p3=$((count_p3 + 1)) ;;
      esac
      count_total=$((count_total + 1))

      local ekey
      ekey=$(effort_sort_key "$item_effort")
      items_data+="${item_priority}|${ekey}|${status_dir}|${item_file}|${item_id}|${item_title}|${item_priority}|${item_type}|${item_effort}|${item_tags}|${item_epic}"$'\n'
    done
  done

  if [ "$count_total" -eq 0 ]; then
    printf "\n${DIM}Aucun item dans la roadmap.${NC}\n\n"
    return
  fi

  echo ""
  printf "${BOLD}ROADMAP — orc${NC}"
  printf "         ${RED}P0: %d${NC} | ${YELLOW}P1: %d${NC} | ${BLUE}P2: %d${NC} | ${DIM}P3: %d${NC}\n" \
    "$count_p0" "$count_p1" "$count_p2" "$count_p3"
  printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

  local sorted_items
  sorted_items=$(echo "$items_data" | grep -v '^$' | sort_items)

  local current_status=""
  while IFS='|' read -r _prio _ekey status filepath item_id item_title priority item_type effort tags epic; do
    [ -z "$status" ] && continue

    if [ "$status" != "$current_status" ]; then
      current_status="$status"
      local status_label count_in_status
      case "$status" in
        in-progress) status_label="EN COURS" ;;
        planned)     status_label="PLANIFIÉ" ;;
        backlog)     status_label="BACKLOG" ;;
        done)        status_label="TERMINÉ" ;;
        *)           status_label="$status" ;;
      esac
      count_in_status=$(echo "$sorted_items" | grep -c "|${status}|" 2>/dev/null || echo "0")
      echo ""
      printf " ${BOLD}%s${NC} (%d)\n" "$status_label" "$count_in_status"
    fi

    local sym pcolor
    sym=$(status_symbol "$status")
    pcolor=$(priority_color "$priority")

    printf "  %b ${pcolor}%-12s${NC} [%s/%s] %-42s ${DIM}%s${NC}\n" \
      "$sym" "$item_id" "$priority" "$effort" "$item_title" "$tags"

    if [ "$verbosity" = "detail" ] || [ "$verbosity" = "full" ]; then
      local context
      context=$(extract_section "$filepath" "Contexte" 3)
      if [ -n "$context" ]; then
        echo "$context" | while IFS= read -r line; do
          printf "    ${DIM}%s${NC}\n" "$line"
        done
      fi

      local deps
      deps=$(parse_depends "$filepath")
      if [ -n "$deps" ] && [ "$deps" != "[]" ]; then
        printf "    ${DIM}Dépend de : %s${NC}\n" "$deps"
      fi

      if [ -n "$epic" ] && [ "$epic" != '""' ]; then
        printf "    ${DIM}Epic : %s${NC}\n" "$epic"
      fi

      local created updated
      created=$(parse_frontmatter "$filepath" "created")
      updated=$(parse_frontmatter "$filepath" "updated")
      if [ -n "$created" ]; then
        printf "    ${DIM}Créé : %s | MàJ : %s${NC}\n" "$created" "${updated:-$created}"
      fi
      echo ""
    fi

    if [ "$verbosity" = "full" ]; then
      local spec
      spec=$(extract_section "$filepath" "Spécification")
      if [ -n "$spec" ]; then
        printf "    ${BOLD}Spécification :${NC}\n"
        echo "$spec" | while IFS= read -r line; do
          printf "    %s\n" "$line"
        done
        echo ""
      fi

      local criteria
      criteria=$(extract_section "$filepath" "Critères de validation")
      if [ -n "$criteria" ]; then
        printf "    ${BOLD}Critères :${NC}\n"
        echo "$criteria" | while IFS= read -r line; do
          printf "    %s\n" "$line"
        done
        echo ""
      fi

      local notes
      notes=$(extract_section "$filepath" "Notes")
      if [ -n "$notes" ]; then
        printf "    ${DIM}Notes : %s${NC}\n" "$(echo "$notes" | head -3 | tr '\n' ' ')"
        echo ""
      fi

      printf "    ──────────────────────────────────────────────────────\n"
    fi

  done <<< "$sorted_items"

  echo ""

  local active_filters=""
  [ -n "$filter_priority" ] && active_filters+="priority=$filter_priority "
  [ -n "$filter_tag" ] && active_filters+="tag=$filter_tag "
  [ -n "$filter_epic" ] && active_filters+="epic=$filter_epic "
  [ -n "$filter_type" ] && active_filters+="type=$filter_type "
  [ -n "$filter_status" ] && active_filters+="status=$filter_status "
  if [ -n "$active_filters" ]; then
    printf "${DIM}Filtres actifs : %s${NC}\n\n" "$active_filters"
  fi
}

# ============================================================
# COMMANDE : roadmap projet
# ============================================================

cmd_project_roadmap() {
  local name="${1:-}"
  [ -z "$name" ] && die "Usage : orc roadmap <projet>"
  require_project "$name"

  local dir
  dir=$(project_dir "$name")
  local roadmap_file="$dir/project/.orc/ROADMAP.md"

  if [ ! -f "$roadmap_file" ]; then
    die "Pas de ROADMAP.md pour '$name' (le projet n'a peut-être pas encore démarré)"
  fi

  local done_count todo_count
  done_count=$(grep -c '^\- \[x\]' "$roadmap_file" 2>/dev/null || echo "0")
  todo_count=$(grep -c '^\- \[ \]' "$roadmap_file" 2>/dev/null || echo "0")

  echo ""
  printf "${BOLD}ROADMAP — %s${NC}" "$name"
  printf "         ${GREEN}%s faites${NC} | ${CYAN}%s restantes${NC}\n" "$done_count" "$todo_count"
  printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  echo ""

  # Afficher les features avec coloration
  while IFS= read -r line; do
    if [[ "$line" =~ ^-\ \[x\] ]]; then
      printf "  ${GREEN}%s${NC}\n" "$line"
    elif [[ "$line" =~ ^-\ \[\ \] ]]; then
      printf "  ${CYAN}%s${NC}\n" "$line"
    elif [[ "$line" =~ ^## ]]; then
      printf "\n ${BOLD}%s${NC}\n" "$line"
    elif [[ "$line" =~ ^# ]]; then
      : # skip title, we have our own header
    elif [ -n "$line" ]; then
      printf "  %s\n" "$line"
    fi
  done < "$roadmap_file"

  echo ""
  printf "${DIM}Fichier : %s${NC}\n\n" "$roadmap_file"
}

cmd_roadmap_help() {
  echo ""
  printf "${BOLD}orc roadmap — Suivi des roadmaps${NC}\n"
  echo ""
  printf "  ${BOLD}Projet :${NC}\n"
  printf "  ${CYAN}orc roadmap <projet>${NC}              Roadmap d'un projet (ROADMAP.md)\n"
  echo ""
  printf "  ${BOLD}Template orc :${NC}\n"
  printf "  ${CYAN}orc roadmap${NC}                       Vue compacte (roadmap orc)\n"
  printf "  ${CYAN}orc roadmap --detail${NC}              + contexte, dépendances\n"
  printf "  ${CYAN}orc roadmap --full${NC}                + specs, critères\n"
  echo ""
  printf "  ${BOLD}Filtres (roadmap orc) :${NC}\n"
  printf "  ${CYAN}--priority P0|P1|P2|P3${NC}           Par priorité\n"
  printf "  ${CYAN}--tag <tag>${NC}                      Par tag\n"
  printf "  ${CYAN}--epic <epic>${NC}                    Par epic\n"
  printf "  ${CYAN}--type <type>${NC}                    Par type (feature, bugfix, etc.)\n"
  printf "  ${CYAN}--status <status>${NC}                Par statut (planned, in-progress, etc.)\n"
  echo ""
  printf "  ${DIM}Filtres combinables : orc roadmap --priority P1 --tag adoption${NC}\n"
  echo ""
}

# ============================================================
# COMMANDE : help agent
# ============================================================

cmd_agent_help() {
  echo ""
  printf "${BOLD}orc agent — Gestion des projets${NC}\n"
  echo ""
  printf "  ${CYAN}orc agent new <nom>${NC}               Créer un projet\n"
  printf "  ${CYAN}orc agent new <nom> --brief x.md${NC}  Avec un brief existant\n"
  printf "  ${CYAN}orc agent start <nom>${NC}             Lancer en background\n"
  printf "  ${CYAN}orc agent stop <nom>${NC}              Arrêter proprement\n"
  printf "  ${CYAN}orc agent restart <nom>${NC}           Redémarrer\n"
  printf "  ${CYAN}orc agent status${NC}                  Vue d'ensemble\n"
  printf "  ${CYAN}orc agent status <nom>${NC}            Détail d'un projet\n"
  printf "  ${CYAN}orc agent logs <nom>${NC}              Logs temps réel\n"
  printf "  ${CYAN}orc agent logs <nom> --full${NC}       Log complet\n"
  printf "  ${CYAN}orc agent update${NC}                  Mettre à jour le template\n"
  echo ""
}

# ============================================================
# DISPATCH AGENT
# ============================================================

agent_dispatch() {
  local subcmd="${1:-help}"
  shift || true

  case "$subcmd" in
    new)     cmd_new "$@" ;;
    start)   cmd_start "$@" ;;
    stop)    cmd_stop "$@" ;;
    restart) cmd_restart "$@" ;;
    status)  cmd_status "$@" ;;
    logs)    cmd_logs "$@" ;;
    update)  cmd_update ;;
    help|-h|--help) cmd_agent_help ;;
    *) die "Commande inconnue : agent $subcmd. Voir : orc agent help" ;;
  esac
}
