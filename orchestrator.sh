#!/bin/bash
set -euo pipefail

# ============================================================
# Agent Autonome Claude — Orchestrateur principal
# ============================================================
#
# Usage :
#   ./orchestrator.sh    — lance l'agent autonome (BRIEF.md requis)
#
# Ce script doit être lancé depuis un workspace créé par init.sh.
# Il crée project/ (si pas déjà fait) et pilote Claude en boucle.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# === COULEURS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# === COMPTEURS ===
FEATURE_COUNT=0
EPIC_FEATURE_COUNT=0
TOTAL_FAILURES=0

# === TRACKING TOKENS ===
TOKENS_FILE="$SCRIPT_DIR/logs/tokens.json"
TOTAL_INPUT_TOKENS=0
TOTAL_OUTPUT_TOKENS=0
TOTAL_COST_USD=0

# Coût par token (Claude Opus 4, en USD) — ajuster selon le modèle
COST_PER_INPUT_TOKEN=0.000015
COST_PER_OUTPUT_TOKEN=0.000075

# === FONCTIONS UTILITAIRES ===

log() {
  local level="$1" msg="$2"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  case "$level" in
    INFO)  echo -e "${CYAN}[$timestamp]${NC} ${GREEN}[INFO]${NC}  $msg" ;;
    WARN)  echo -e "${CYAN}[$timestamp]${NC} ${YELLOW}[WARN]${NC}  $msg" ;;
    ERROR) echo -e "${CYAN}[$timestamp]${NC} ${RED}[ERROR]${NC} $msg" ;;
    PHASE) echo -e "\n${CYAN}[$timestamp]${NC} ${BLUE}[═══════════════]${NC} $msg" ;;
    COST)  echo -e "${CYAN}[$timestamp]${NC} ${YELLOW}[\$]${NC}     $msg" ;;
  esac
  echo "[$timestamp] [$level] $msg" >> "$LOG_DIR/orchestrator.log"
}

# Initialise le fichier de tracking tokens
init_tokens() {
  if [ ! -f "$TOKENS_FILE" ]; then
    cat > "$TOKENS_FILE" << 'JSONEOF'
{
  "total_input_tokens": 0,
  "total_output_tokens": 0,
  "total_cost_usd": 0,
  "invocations": 0,
  "by_phase": {},
  "by_feature": {},
  "history": []
}
JSONEOF
  fi

  # Charger les totaux existants (reprise après crash)
  if command -v jq &> /dev/null && [ -f "$TOKENS_FILE" ]; then
    TOTAL_INPUT_TOKENS=$(jq -r '.total_input_tokens // 0' "$TOKENS_FILE")
    TOTAL_OUTPUT_TOKENS=$(jq -r '.total_output_tokens // 0' "$TOKENS_FILE")
    TOTAL_COST_USD=$(jq -r '.total_cost_usd // 0' "$TOKENS_FILE")
  fi
}

# Parse la sortie JSON de Claude et extrait les tokens
# Usage: track_tokens "phase_name" "feature_name" "$json_output"
track_tokens() {
  local phase="$1"
  local feature="${2:-}"
  local json_output="$3"

  # Pas de jq = pas de tracking
  if ! command -v jq &> /dev/null; then
    return 0
  fi

  # Extraire les tokens depuis la sortie JSON
  local input_tokens output_tokens
  input_tokens=$(echo "$json_output" | jq -r '.usage.input_tokens // 0' 2>/dev/null || echo "0")
  output_tokens=$(echo "$json_output" | jq -r '.usage.output_tokens // 0' 2>/dev/null || echo "0")

  # Si pas de données d'usage, tenter le format alternatif
  if [ "$input_tokens" = "0" ] && [ "$output_tokens" = "0" ]; then
    input_tokens=$(echo "$json_output" | jq -r '.result.usage.input_tokens // 0' 2>/dev/null || echo "0")
    output_tokens=$(echo "$json_output" | jq -r '.result.usage.output_tokens // 0' 2>/dev/null || echo "0")
  fi

  [ "$input_tokens" = "null" ] && input_tokens=0
  [ "$output_tokens" = "null" ] && output_tokens=0

  if [ "$input_tokens" -eq 0 ] && [ "$output_tokens" -eq 0 ]; then
    return 0
  fi

  # Calculer le coût
  local cost
  cost=$(echo "$input_tokens $output_tokens $COST_PER_INPUT_TOKEN $COST_PER_OUTPUT_TOKEN" | \
    awk '{printf "%.4f", $1 * $3 + $2 * $4}')

  # Accumuler
  TOTAL_INPUT_TOKENS=$((TOTAL_INPUT_TOKENS + input_tokens))
  TOTAL_OUTPUT_TOKENS=$((TOTAL_OUTPUT_TOKENS + output_tokens))
  TOTAL_COST_USD=$(echo "$TOTAL_COST_USD $cost" | awk '{printf "%.4f", $1 + $2}')

  # Mettre à jour le fichier JSON
  local timestamp
  timestamp=$(date -Iseconds)

  jq \
    --argjson input "$input_tokens" \
    --argjson output "$output_tokens" \
    --argjson cost "$cost" \
    --argjson total_in "$TOTAL_INPUT_TOKENS" \
    --argjson total_out "$TOTAL_OUTPUT_TOKENS" \
    --argjson total_cost "$TOTAL_COST_USD" \
    --arg phase "$phase" \
    --arg feature "$feature" \
    --arg ts "$timestamp" \
    '
    .total_input_tokens = $total_in |
    .total_output_tokens = $total_out |
    .total_cost_usd = $total_cost |
    .invocations += 1 |
    .by_phase[$phase].input_tokens = ((.by_phase[$phase].input_tokens // 0) + $input) |
    .by_phase[$phase].output_tokens = ((.by_phase[$phase].output_tokens // 0) + $output) |
    .by_phase[$phase].cost_usd = ((.by_phase[$phase].cost_usd // 0) + $cost) |
    .by_phase[$phase].calls = ((.by_phase[$phase].calls // 0) + 1) |
    (if $feature != "" then
      .by_feature[$feature].input_tokens = ((.by_feature[$feature].input_tokens // 0) + $input) |
      .by_feature[$feature].output_tokens = ((.by_feature[$feature].output_tokens // 0) + $output) |
      .by_feature[$feature].cost_usd = ((.by_feature[$feature].cost_usd // 0) + $cost)
    else . end) |
    .history += [{
      "timestamp": $ts,
      "phase": $phase,
      "feature": $feature,
      "input_tokens": $input,
      "output_tokens": $output,
      "cost_usd": $cost
    }]
    ' "$TOKENS_FILE" > "${TOKENS_FILE}.tmp" && mv "${TOKENS_FILE}.tmp" "$TOKENS_FILE"

  log COST "tokens: +${input_tokens}in/+${output_tokens}out (\$${cost}) | Total: \$${TOTAL_COST_USD}"
}

# Affiche un résumé des coûts
print_cost_summary() {
  if ! command -v jq &> /dev/null || [ ! -f "$TOKENS_FILE" ]; then
    return 0
  fi

  local invocations total_in total_out total_cost
  invocations=$(jq -r '.invocations' "$TOKENS_FILE")
  total_in=$(jq -r '.total_input_tokens' "$TOKENS_FILE")
  total_out=$(jq -r '.total_output_tokens' "$TOKENS_FILE")
  total_cost=$(jq -r '.total_cost_usd' "$TOKENS_FILE")

  echo ""
  echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  CONSOMMATION TOKENS${NC}"
  echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
  echo -e "  Invocations Claude :  $invocations"
  echo -e "  Tokens input :        $total_in"
  echo -e "  Tokens output :       $total_out"
  echo -e "  Tokens total :        $((total_in + total_out))"
  echo -e "  ${YELLOW}Coût estimé :       \$${total_cost} USD${NC}"
  echo ""

  # Top 3 phases les plus coûteuses
  echo -e "  ${CYAN}Par phase :${NC}"
  jq -r '.by_phase | to_entries | sort_by(-.value.cost_usd) | .[:5][] | "    \(.key): $\(.value.cost_usd) (\(.value.calls) appels)"' "$TOKENS_FILE" 2>/dev/null || true
  echo ""

  # Top 3 features les plus coûteuses
  if jq -e '.by_feature | length > 0' "$TOKENS_FILE" > /dev/null 2>&1; then
    echo -e "  ${CYAN}Par feature :${NC}"
    jq -r '.by_feature | to_entries | sort_by(-.value.cost_usd) | .[:5][] | "    \(.key): $\(.value.cost_usd)"' "$TOKENS_FILE" 2>/dev/null || true
    echo ""
  fi
}

# Run Claude avec tracking de tokens et logs temps réel
# Usage: run_claude "prompt" [max_turns] [log_file] [phase_name] [feature_name]
run_claude() {
  local prompt="$1"
  local max_turns="${2:-$MAX_TURNS_PER_INVOCATION}"
  local log_file="${3:-/dev/null}"
  local phase_name="${4:-unknown}"
  local feature_name="${5:-}"

  local exit_code=0
  local tmp_json
  tmp_json=$(mktemp)
  local start_time
  start_time=$(date +%s)

  log INFO "→ Claude lancé [phase=$phase_name] [max_turns=$max_turns]..."

  # Lancer Claude : stream text en temps réel, capture JSON séparément
  # On utilise --output-format stream-json pour avoir du feedback en temps réel
  # Fallback : si stream-json échoue, utiliser json classique
  if [ "$VERBOSE" = true ]; then
    claude -p "$prompt" \
      --dangerously-skip-permissions \
      --max-turns "$max_turns" \
      --output-format json \
      -d "$PROJECT_DIR" > "$tmp_json" 2>&1 &
  else
    claude -p "$prompt" \
      --dangerously-skip-permissions \
      --max-turns "$max_turns" \
      --output-format json \
      -d "$PROJECT_DIR" > "$tmp_json" 2>&1 &
  fi

  local claude_pid=$!

  # Boucle de monitoring : affiche la progression pendant que Claude tourne
  local dots=0
  while kill -0 "$claude_pid" 2>/dev/null; do
    dots=$((dots + 1))
    local elapsed=$(( $(date +%s) - start_time ))
    local mins=$((elapsed / 60))
    local secs=$((elapsed % 60))

    # Afficher un heartbeat toutes les 15 secondes
    if [ $((dots % 3)) -eq 0 ]; then
      local size
      size=$(wc -c < "$tmp_json" 2>/dev/null || echo "0")
      printf "\r  ${CYAN}⏳ %s | %02d:%02d | %s bytes reçus${NC}   " \
        "$phase_name" "$mins" "$secs" "$size" >&2
    fi

    sleep 5
  done

  # Récupérer le code de sortie
  wait "$claude_pid" || exit_code=$?

  local end_time
  end_time=$(date +%s)
  local duration=$(( end_time - start_time ))
  local dur_mins=$((duration / 60))
  local dur_secs=$((duration % 60))

  # Nettoyer la ligne de progression
  printf "\r%80s\r" "" >&2

  log INFO "← Claude terminé [phase=$phase_name] [durée=${dur_mins}m${dur_secs}s] [exit=$exit_code]"

  # Lire la sortie JSON
  local json_output
  json_output=$(cat "$tmp_json")

  # Extraire le texte pour le log
  local text_output
  if command -v jq &> /dev/null; then
    text_output=$(echo "$json_output" | jq -r '.result // .message // .' 2>/dev/null || echo "$json_output")
  else
    text_output="$json_output"
  fi

  # Logger dans le fichier de log de la phase
  echo "$text_output" >> "$log_file"
  if [ "$VERBOSE" = true ]; then
    # Afficher les premières et dernières lignes pour savoir ce qui s'est passé
    local line_count
    line_count=$(echo "$text_output" | wc -l)
    if [ "$line_count" -gt 20 ]; then
      echo "$text_output" | head -5
      echo "  ... ($line_count lignes, voir $log_file pour le détail) ..."
      echo "$text_output" | tail -5
    else
      echo "$text_output"
    fi
  fi

  # Tracker les tokens
  track_tokens "$phase_name" "$feature_name" "$json_output"

  # Vérifier le budget max
  if [ -n "${MAX_BUDGET_USD:-}" ] && command -v awk &> /dev/null; then
    local over_budget
    over_budget=$(echo "$TOTAL_COST_USD $MAX_BUDGET_USD" | awk '{print ($1 > $2) ? "yes" : "no"}')
    if [ "$over_budget" = "yes" ]; then
      log ERROR "Budget dépassé ! \$${TOTAL_COST_USD} > \$${MAX_BUDGET_USD}"
      print_cost_summary
      rm -f "$tmp_json"
      exit 1
    fi
  fi

  rm -f "$tmp_json"
  return $exit_code
}

# Remplace les placeholders {{VAR}} dans un fichier phase
render_phase() {
  local phase_file="$1"
  shift
  local content
  content=$(cat "$SCRIPT_DIR/phases/$phase_file")

  while [ $# -gt 0 ]; do
    local key="${1%%=*}"
    local value="${1#*=}"
    content="${content//\{\{$key\}\}/$value}"
    shift
  done

  echo "$content"
}

# Lit la prochaine feature non cochée de la ROADMAP
next_feature() {
  grep -m1 '^\- \[ \]' "$PROJECT_DIR/ROADMAP.md" 2>/dev/null | sed 's/^- \[ \] //' || true
}

# Nom court pour les branches git
branch_name() {
  echo "$1" | sed 's/ |.*//;s/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | head -c 40
}

# Pause pour intervention humaine
human_pause() {
  local reason="$1"
  log PHASE "PAUSE HUMAINE — $reason"
  echo ""
  echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  PAUSE — Intervention humaine requise${NC}"
  echo -e "${YELLOW}  Raison : $reason${NC}"
  echo -e "${YELLOW}  Features complétées : $FEATURE_COUNT${NC}"
  echo -e "${YELLOW}  Coût actuel : \$${TOTAL_COST_USD} USD${NC}"
  echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  Commandes :"
  echo -e "    ${GREEN}c${NC} — continuer"
  echo -e "    ${GREEN}r${NC} — voir la roadmap"
  echo -e "    ${GREEN}l${NC} — voir les logs récents"
  echo -e "    ${GREEN}t${NC} — voir les tokens consommés"
  echo -e "    ${GREEN}q${NC} — quitter"
  echo ""

  while true; do
    read -rp "→ " choice
    case "$choice" in
      c|C) return 0 ;;
      r|R) cat "$PROJECT_DIR/ROADMAP.md" 2>/dev/null || echo "Pas de ROADMAP." ; echo "" ;;
      l|L) tail -30 "$LOG_DIR/orchestrator.log" 2>/dev/null ; echo "" ;;
      t|T) print_cost_summary ;;
      q|Q) log INFO "Arrêt demandé par l'utilisateur." ; print_cost_summary ; exit 0 ;;
      *) echo "Choix invalide." ;;
    esac
  done
}

# ============================================================
# VÉRIFICATIONS PRÉALABLES
# ============================================================

if ! command -v claude &> /dev/null; then
  echo -e "${RED}Erreur : 'claude' CLI non trouvé.${NC}"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}⚠ jq non trouvé — le tracking de tokens sera désactivé.${NC}"
  echo -e "  Installer : ${CYAN}sudo apt install jq${NC}"
fi

if [ ! -f "$SCRIPT_DIR/BRIEF.md" ]; then
  echo -e "${RED}Erreur : BRIEF.md non trouvé.${NC}"
  echo ""
  echo "  Ce script doit être lancé depuis un workspace créé par init.sh."
  echo "  Depuis le repo template, lancez :"
  echo -e "    ${CYAN}./init.sh mon-projet${NC}"
  exit 1
fi

mkdir -p "$LOG_DIR"
init_tokens

log PHASE "DÉMARRAGE DE L'AGENT AUTONOME"
log INFO "Config : MAX_FEATURES=$MAX_FEATURES | MAX_FIX=$MAX_FIX_ATTEMPTS | EPIC_SIZE=$EPIC_SIZE"
log INFO "Recherche : $ENABLE_RESEARCH | Approbation humaine : $REQUIRE_HUMAN_APPROVAL"
if [ -n "${MAX_BUDGET_USD:-}" ]; then
  log INFO "Budget max : \$${MAX_BUDGET_USD} USD"
fi
if [ "$TOTAL_COST_USD" != "0" ]; then
  log INFO "Reprise — coût cumulé : \$${TOTAL_COST_USD} USD"
fi

# ============================================================
# PHASE 0 — BOOTSTRAP
# ============================================================

if [ ! -f "$PROJECT_DIR/CLAUDE.md" ]; then
  log PHASE "PHASE 0 — BOOTSTRAP"

  if [ ! -d "$PROJECT_DIR/.git" ]; then
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR" && git init -b main > /dev/null 2>&1 && cd - > /dev/null
  fi

  if [ ! -f "$PROJECT_DIR/BRIEF.md" ]; then
    cp "$SCRIPT_DIR/BRIEF.md" "$PROJECT_DIR/BRIEF.md"
  fi

  mkdir -p "$PROJECT_DIR/research/competitors" \
           "$PROJECT_DIR/research/trends" \
           "$PROJECT_DIR/research/user-needs" \
           "$PROJECT_DIR/research/regulations" \
           "$PROJECT_DIR/logs"

  mkdir -p "$PROJECT_DIR/.claude/skills"
  for skill in "$SCRIPT_DIR/skills-templates/"*.md; do
    dest="$PROJECT_DIR/.claude/skills/$(basename "$skill")"
    [ ! -f "$dest" ] && cp "$skill" "$dest"
  done

  local_prompt=$(render_phase "00-bootstrap.md")
  run_claude "$local_prompt" 60 "$LOG_DIR/00-bootstrap.log" "bootstrap"

  log INFO "Bootstrap terminé."
else
  log INFO "Projet existant détecté (CLAUDE.md présent), reprise en cours..."
fi

# ============================================================
# PHASE 1 — RECHERCHE INITIALE
# ============================================================

if [ "$ENABLE_RESEARCH" = true ] && [ ! -f "$PROJECT_DIR/research/INDEX.md" ]; then
  log PHASE "PHASE 1 — RECHERCHE INITIALE"

  local_prompt=$(render_phase "01-research.md")
  run_claude "$local_prompt" "$MAX_TURNS_RESEARCH_INITIAL" "$LOG_DIR/01-research.log" "research-initial"

  log INFO "Recherche initiale terminée."
fi

# ============================================================
# PHASE 2 — STRATÉGIE
# ============================================================

if ! grep -q '^\- \[ \]' "$PROJECT_DIR/ROADMAP.md" 2>/dev/null; then
  log PHASE "PHASE 2 — STRATÉGIE"

  local_prompt=$(render_phase "02-strategy.md")
  run_claude "$local_prompt" 30 "$LOG_DIR/02-strategy.log" "strategy"

  log INFO "Roadmap générée."
fi

# ============================================================
# PHASE 3 — BOUCLE PRINCIPALE
# ============================================================

log PHASE "PHASE 3 — BOUCLE DE DÉVELOPPEMENT"

while [ $FEATURE_COUNT -lt $MAX_FEATURES ]; do

  feature_raw=$(next_feature)

  if [ -z "$feature_raw" ]; then
    log INFO "Roadmap vide — passage en phase d'évolution."
    break
  fi

  feature_name=$(echo "$feature_raw" | sed 's/ |.*//')
  feature_branch=$(branch_name "$feature_name")

  FEATURE_COUNT=$((FEATURE_COUNT + 1))
  EPIC_FEATURE_COUNT=$((EPIC_FEATURE_COUNT + 1))

  log PHASE "FEATURE #$FEATURE_COUNT : $feature_name"

  # --- Veille ciblée avant chaque epic ---
  if [ "$ENABLE_RESEARCH" = true ] && [ "$EPIC_FEATURE_COUNT" -eq 1 ]; then
    log INFO "Veille ciblée avant l'epic..."
    run_claude "$(cat <<EOF
VEILLE CIBLÉE avant la feature : $feature_name

1. Comment les concurrents gèrent cette fonctionnalité ? (WebSearch + WebFetch)
2. Best practices UX pour ce type de feature
3. APIs ou données publiques exploitables
4. Mets à jour research/ et ajuste les specs dans ROADMAP.md si nécessaire
EOF
    )" "$MAX_TURNS_RESEARCH_EPIC" "$LOG_DIR/research-epic-$FEATURE_COUNT.log" "research-epic" "$feature_name"
  fi

  # --- Implémentation ---
  log INFO "Implémentation en cours..."
  impl_prompt=$(render_phase "03-implement.md" \
    "FEATURE_NAME=$feature_name" \
    "FEATURE_BRANCH=$feature_branch")
  run_claude "$impl_prompt" "$MAX_TURNS_PER_INVOCATION" "$LOG_DIR/feature-$FEATURE_COUNT-impl.log" "implement" "$feature_name"

  # --- Test & Fix Loop ---
  attempt=0
  tests_passed=false

  while [ $attempt -lt $MAX_FIX_ATTEMPTS ]; do
    log INFO "Tests — tentative $((attempt + 1))/$MAX_FIX_ATTEMPTS"

    cd "$PROJECT_DIR"
    BUILD_OUTPUT=$($BUILD_COMMAND 2>&1) && BUILD_EXIT=0 || BUILD_EXIT=$?
    TEST_OUTPUT=$($TEST_COMMAND 2>&1) && TEST_EXIT=0 || TEST_EXIT=$?
    cd - > /dev/null

    if [ $BUILD_EXIT -eq 0 ] && [ $TEST_EXIT -eq 0 ]; then
      tests_passed=true
      log INFO "Build + tests OK !"
      break
    fi

    attempt=$((attempt + 1))

    if [ $attempt -lt $MAX_FIX_ATTEMPTS ]; then
      log WARN "Échec — correction en cours (tentative $attempt)..."
      fix_prompt=$(render_phase "04-test-fix.md" \
        "ATTEMPT=$attempt" \
        "MAX_FIX=$MAX_FIX_ATTEMPTS" \
        "BUILD_EXIT=$BUILD_EXIT" \
        "BUILD_OUTPUT=${BUILD_OUTPUT: -3000}" \
        "TEST_EXIT=$TEST_EXIT" \
        "TEST_OUTPUT=${TEST_OUTPUT: -3000}")
      run_claude "$fix_prompt" 30 "$LOG_DIR/feature-$FEATURE_COUNT-fix-$attempt.log" "fix" "$feature_name"
    fi
  done

  if [ "$tests_passed" = false ]; then
    log ERROR "Feature '$feature_name' abandonnée après $MAX_FIX_ATTEMPTS tentatives."
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
  fi

  # --- Reflect & Evolve ---
  log INFO "Rétrospective..."
  reflect_prompt=$(render_phase "05-reflect.md" \
    "FEATURE_NAME=$feature_name" \
    "TESTS_PASSED=$tests_passed" \
    "FIX_ATTEMPTS=$attempt" \
    "N=$FEATURE_COUNT")
  run_claude "$reflect_prompt" 20 "$LOG_DIR/feature-$FEATURE_COUNT-reflect.log" "reflect" "$feature_name"

  # --- Merge si OK ---
  if [ "$tests_passed" = true ]; then
    if [ "$REQUIRE_HUMAN_APPROVAL" = true ]; then
      human_pause "Approuver le merge de : $feature_name"
    fi

    cd "$PROJECT_DIR"
    current_branch=$(git branch --show-current 2>/dev/null || echo "")
    if [ -n "$current_branch" ] && [ "$current_branch" != "main" ]; then
      git checkout main 2>/dev/null && git merge --no-ff "$current_branch" -m "feat: $feature_name" 2>/dev/null || true
    fi
    cd - > /dev/null

    log INFO "Feature '$feature_name' mergée."
  fi

  # --- Reset compteur epic ---
  if [ "$EPIC_FEATURE_COUNT" -ge "$EPIC_SIZE" ]; then
    EPIC_FEATURE_COUNT=0
  fi

  # --- Méta-rétrospective toutes les N features ---
  if [ $((FEATURE_COUNT % META_RETRO_FREQUENCY)) -eq 0 ]; then
    log PHASE "MÉTA-RÉTROSPECTIVE — $FEATURE_COUNT features"
    retro_prompt=$(render_phase "06-meta-retro.md" "FEATURE_COUNT=$FEATURE_COUNT")
    run_claude "$retro_prompt" "$MAX_TURNS_RESEARCH_TREND" "$LOG_DIR/meta-retro-$FEATURE_COUNT.log" "meta-retro"
    log INFO "Méta-rétrospective terminée."
  fi

  # --- Pause humaine configurable ---
  if [ "$PAUSE_EVERY_N_FEATURES" -gt 0 ] && [ $((FEATURE_COUNT % PAUSE_EVERY_N_FEATURES)) -eq 0 ]; then
    human_pause "Checkpoint toutes les $PAUSE_EVERY_N_FEATURES features"
  fi

done

# ============================================================
# PHASE FINALE — ÉVOLUTION OU FIN
# ============================================================

if [ ! -f "$PROJECT_DIR/DONE.md" ]; then
  log PHASE "PHASE FINALE — ÉVOLUTION"
  evolve_prompt=$(render_phase "07-evolve.md")
  run_claude "$evolve_prompt" 30 "$LOG_DIR/07-evolve.log" "evolve"

  if [ ! -f "$PROJECT_DIR/DONE.md" ] && grep -q '^\- \[ \]' "$PROJECT_DIR/ROADMAP.md" 2>/dev/null; then
    log INFO "Nouvelles features ajoutées — relancement de la boucle."
    exec "$0"
  fi
fi

# ============================================================
# PHASE POST-PROJET — AUTO-AMÉLIORATION DE L'ORCHESTRATEUR
# ============================================================

if [ -n "${TEMPLATE_DIR:-}" ] && [ -d "$TEMPLATE_DIR/phases" ]; then
  log PHASE "AUTO-AMÉLIORATION DE L'ORCHESTRATEUR"

  run_claude "$(cat <<'IMPROVE'
PHASE AUTO-AMÉLIORATION DE L'ORCHESTRATEUR

Le projet est terminé. Analyse l'ensemble des logs pour améliorer
l'orchestrateur lui-même (pas le projet, l'OUTIL qui pilote les projets).

Lis :
1. Tous les fichiers logs/retrospective-*.md
2. Tous les fichiers logs/meta-retrospective-*.md
3. Le CLAUDE.md final (les règles que tu t'es auto-ajoutées)
4. Les skills dans .claude/skills/ (celles que tu as créées)

Analyse :
- Quels prompts de phase ont produit les meilleurs résultats ?
- Quels prompts ont dû être "contournés" ou étaient insuffisants ?
- Quels types d'erreurs l'orchestrateur n'a pas su gérer ?
- Quelles étapes manquent dans le workflow ?
- Les garde-fous étaient-ils bien calibrés ?

Produis un fichier `orchestrator-improvements.md` dans le dossier courant
avec cette structure :

## Améliorations proposées pour l'orchestrateur

### Phases à modifier
Pour chaque phase concernée :
- **Phase XX** : [problème constaté] → [amélioration proposée]
  ```markdown
  [nouveau contenu suggéré pour le prompt, ou diff]
  ```

### Nouvelles phases à ajouter
- [description de la phase] — [pourquoi elle manquait]

### Config à ajuster
- [paramètre] : [valeur actuelle] → [valeur recommandée] — [pourquoi]

### Nouvelles skills utiles
- [nom du skill] — [ce qu'il fait] — [pourquoi il serait utile pour les futurs projets]

### Garde-fous
- [garde-fou à ajouter/modifier] — [incident qui l'a motivé]

Sois concret et actionnable. Chaque suggestion doit pouvoir être
appliquée directement au repo template de l'orchestrateur.
IMPROVE
  )" 30 "$LOG_DIR/orchestrator-improvements.log" "self-improve"

  log INFO "Suggestions d'amélioration écrites dans project/orchestrator-improvements.md"
fi

# ============================================================
# BILAN FINAL
# ============================================================

log PHASE "TERMINÉ"
log INFO "Features complétées : $FEATURE_COUNT"
log INFO "Features en échec : $TOTAL_FAILURES"

if [ -f "$PROJECT_DIR/DONE.md" ]; then
  log INFO "Le projet est déclaré terminé. Voir project/DONE.md"
else
  log WARN "L'orchestrateur s'est arrêté (limite MAX_FEATURES=$MAX_FEATURES atteinte)."
fi

print_cost_summary

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Agent terminé.${NC}"
echo -e "${GREEN}  Features : $FEATURE_COUNT | Échecs : $TOTAL_FAILURES${NC}"
echo -e "${GREEN}  Coût total : \$${TOTAL_COST_USD} USD${NC}"
echo -e "${GREEN}  Logs : $LOG_DIR/${NC}"
echo -e "${GREEN}  Tokens : $TOKENS_FILE${NC}"
echo -e "${GREEN}  Projet : $PROJECT_DIR/${NC}"
if [ -f "$PROJECT_DIR/orchestrator-improvements.md" ]; then
  echo -e "${GREEN}  Améliorations : $PROJECT_DIR/orchestrator-improvements.md${NC}"
fi
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
