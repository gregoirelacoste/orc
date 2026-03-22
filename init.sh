#!/bin/bash
set -euo pipefail

# ============================================================
# Agent Autonome Claude — Initialisation d'un nouveau projet
# ============================================================
#
# Usage :
#   ./init.sh                      — init interactif complet
#   ./init.sh --skip-brief         — init sans rédaction du brief (le rédiger manuellement)
#
# Ce script guide l'utilisateur à travers :
#   1. Nommage du projet
#   2. Configuration (config.sh)
#   3. Rédaction du BRIEF.md avec Claude (product director)
#   4. Préparation de la structure
#   5. Prêt à lancer ./orchestrator.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === COULEURS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SKIP_BRIEF=false
if [ "${1:-}" = "--skip-brief" ]; then
  SKIP_BRIEF=true
fi

# ============================================================
# EN-TÊTE
# ============================================================

clear
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                       ║${NC}"
echo -e "${BLUE}║   ${BOLD}🤖 Agent Autonome Claude${NC}${BLUE}                            ║${NC}"
echo -e "${BLUE}║   Initialisation d'un nouveau projet                  ║${NC}"
echo -e "${BLUE}║                                                       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================
# VÉRIFICATIONS
# ============================================================

echo -e "${CYAN}Vérifications...${NC}"

if ! command -v claude &> /dev/null; then
  echo -e "${RED}Claude Code CLI non trouvé.${NC}"
  echo "Installez-le : https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} Claude Code CLI"

if ! command -v git &> /dev/null; then
  echo -e "${RED}Git non trouvé.${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} Git"

if ! command -v gh &> /dev/null; then
  echo -e "  ${YELLOW}⚠${NC} GitHub CLI (gh) non trouvé — le repo distant devra être créé manuellement"
  HAS_GH=false
else
  echo -e "  ${GREEN}✓${NC} GitHub CLI (gh)"
  HAS_GH=true
fi

echo ""

# ============================================================
# ÉTAPE 1 — NOM DU PROJET
# ============================================================

echo -e "${BOLD}Étape 1/5 — Nom du projet${NC}"
echo ""
read -rp "  Nom du projet (ex: mon-app-immo) : " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}Nom requis.${NC}"
  exit 1
fi

# Slugify
PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

echo -e "  Nom normalisé : ${CYAN}$PROJECT_SLUG${NC}"
echo ""

# ============================================================
# ÉTAPE 2 — DESCRIPTION COURTE
# ============================================================

echo -e "${BOLD}Étape 2/5 — Description du projet${NC}"
echo ""
echo "  Décris ton projet en 1-2 phrases."
echo "  (Claude utilisera ça comme point de départ pour le brief)"
echo ""
read -rp "  > " PROJECT_DESCRIPTION

echo ""

# ============================================================
# ÉTAPE 3 — CONFIGURATION
# ============================================================

echo -e "${BOLD}Étape 3/5 — Configuration${NC}"
echo ""
echo "  Quel mode d'autonomie ?"
echo ""
echo -e "    ${GREEN}1${NC} — ${BOLD}Pilote automatique${NC} (100% autonome, aucune intervention)"
echo -e "    ${GREEN}2${NC} — ${BOLD}Copilote${NC} (Claude code, tu valides chaque merge)"
echo -e "    ${GREEN}3${NC} — ${BOLD}Supervisé${NC} (pause toutes les 3 features pour review)"
echo ""
read -rp "  Choix [1/2/3] (défaut: 1) : " MODE_CHOICE
MODE_CHOICE="${MODE_CHOICE:-1}"

case "$MODE_CHOICE" in
  1)
    PAUSE_N=0
    HUMAN_APPROVAL=false
    MODE_NAME="pilote automatique"
    ;;
  2)
    PAUSE_N=0
    HUMAN_APPROVAL=true
    MODE_NAME="copilote"
    ;;
  3)
    PAUSE_N=3
    HUMAN_APPROVAL=false
    MODE_NAME="supervisé"
    ;;
  *)
    PAUSE_N=0
    HUMAN_APPROVAL=false
    MODE_NAME="pilote automatique"
    ;;
esac

echo -e "  Mode : ${CYAN}$MODE_NAME${NC}"
echo ""

echo "  Activer la veille marché (recherche web) ?"
read -rp "  [O/n] : " RESEARCH_CHOICE
RESEARCH_CHOICE="${RESEARCH_CHOICE:-O}"
if [[ "$RESEARCH_CHOICE" =~ ^[Oo]$ ]]; then
  ENABLE_RESEARCH=true
else
  ENABLE_RESEARCH=false
fi

echo ""
echo "  Nombre max de features avant arrêt ?"
read -rp "  [défaut: 50] : " MAX_FEAT
MAX_FEAT="${MAX_FEAT:-50}"

echo ""

# ============================================================
# ÉTAPE 4 — CRÉATION DE LA STRUCTURE
# ============================================================

echo -e "${BOLD}Étape 4/5 — Création de la structure${NC}"
echo ""

# Mettre à jour config.sh
sed -i "s|PROJECT_NAME=\"\"|PROJECT_NAME=\"$PROJECT_SLUG\"|" "$SCRIPT_DIR/config.sh"
sed -i "s|PAUSE_EVERY_N_FEATURES=0|PAUSE_EVERY_N_FEATURES=$PAUSE_N|" "$SCRIPT_DIR/config.sh"
sed -i "s|REQUIRE_HUMAN_APPROVAL=false|REQUIRE_HUMAN_APPROVAL=$HUMAN_APPROVAL|" "$SCRIPT_DIR/config.sh"
sed -i "s|ENABLE_RESEARCH=true|ENABLE_RESEARCH=$ENABLE_RESEARCH|" "$SCRIPT_DIR/config.sh"
sed -i "s|MAX_FEATURES=50|MAX_FEATURES=$MAX_FEAT|" "$SCRIPT_DIR/config.sh"

echo -e "  ${GREEN}✓${NC} config.sh mis à jour"

# Créer le dossier project/ avec son propre git
mkdir -p "$SCRIPT_DIR/project"
cd "$SCRIPT_DIR/project"
git init -b main > /dev/null 2>&1
cd "$SCRIPT_DIR"

echo -e "  ${GREEN}✓${NC} project/ initialisé (git indépendant)"

# Créer la structure research/
mkdir -p "$SCRIPT_DIR/project/research/competitors" \
         "$SCRIPT_DIR/project/research/trends" \
         "$SCRIPT_DIR/project/research/user-needs" \
         "$SCRIPT_DIR/project/research/regulations" \
         "$SCRIPT_DIR/project/logs"

echo -e "  ${GREEN}✓${NC} Structure research/ créée"

# Copier les skills templates
mkdir -p "$SCRIPT_DIR/project/.claude/skills"
cp "$SCRIPT_DIR/skills-templates/"*.md "$SCRIPT_DIR/project/.claude/skills/"

echo -e "  ${GREEN}✓${NC} Skills copiées dans project/.claude/skills/"

# Créer le dossier logs de l'orchestrateur
mkdir -p "$SCRIPT_DIR/logs"

echo -e "  ${GREEN}✓${NC} Dossier logs/ prêt"
echo ""

# ============================================================
# ÉTAPE 5 — RÉDACTION DU BRIEF
# ============================================================

echo -e "${BOLD}Étape 5/5 — Rédaction du BRIEF.md${NC}"
echo ""

if [ "$SKIP_BRIEF" = true ]; then
  echo -e "  ${YELLOW}Mode --skip-brief${NC} : copie du template."
  cp "$SCRIPT_DIR/BRIEF.template.md" "$SCRIPT_DIR/BRIEF.md"
  sed -i "s/\[Nom du projet\]/$PROJECT_NAME/" "$SCRIPT_DIR/BRIEF.md"
  echo -e "  ${GREEN}✓${NC} BRIEF.md créé depuis le template"
  echo ""
  echo -e "  ${YELLOW}N'oublie pas de le remplir avant de lancer l'orchestrateur :${NC}"
  echo -e "  ${CYAN}vim BRIEF.md${NC}"
else
  echo -e "  Claude va te poser des questions pour rédiger un brief produit complet."
  echo -e "  Réponds à chaque question. Il rédigera le BRIEF.md à la fin."
  echo ""
  echo -e "  ${YELLOW}Appuie sur Entrée pour démarrer...${NC}"
  read -r

  brief_skill=$(cat "$SCRIPT_DIR/skills-templates/write-brief.md")

  # Mode interactif (pas de --yes) pour le dialogue
  claude "$(cat <<EOF
$brief_skill

---

L'utilisateur veut créer un projet appelé "$PROJECT_NAME".
Il l'a décrit ainsi : "$PROJECT_DESCRIPTION"

Commence par reformuler ce que tu as compris, puis pose les questions
manquantes pour compléter le brief. Pose les questions une par une ou
par petit groupe thématique pour ne pas submerger l'utilisateur.

IMPORTANT : Écris le résultat final dans BRIEF.md (à la racine, pas dans project/).
EOF
  )" --max-turns 40 -d "$SCRIPT_DIR"

  echo ""
  if [ -f "$SCRIPT_DIR/BRIEF.md" ]; then
    echo -e "  ${GREEN}✓${NC} BRIEF.md rédigé"
    # Copier dans project/ aussi
    cp "$SCRIPT_DIR/BRIEF.md" "$SCRIPT_DIR/project/BRIEF.md"
    echo -e "  ${GREEN}✓${NC} Copié dans project/"
  else
    echo -e "  ${YELLOW}⚠${NC} BRIEF.md non créé. Tu peux :"
    echo -e "    - Relancer : ${CYAN}./orchestrator.sh --brief${NC}"
    echo -e "    - Ou rédiger manuellement : ${CYAN}cp BRIEF.template.md BRIEF.md${NC}"
  fi
fi

echo ""

# ============================================================
# REPO GITHUB (optionnel)
# ============================================================

if [ "$HAS_GH" = true ]; then
  echo -e "${BOLD}Bonus — Créer un repo GitHub pour le projet ?${NC}"
  echo ""
  echo "  Cela créera un repo distant pour project/ (le code produit)."
  read -rp "  [o/N] : " GH_CHOICE
  GH_CHOICE="${GH_CHOICE:-N}"

  if [[ "$GH_CHOICE" =~ ^[Oo]$ ]]; then
    echo ""
    read -rp "  Visibilité [public/private] (défaut: private) : " GH_VISIBILITY
    GH_VISIBILITY="${GH_VISIBILITY:-private}"

    cd "$SCRIPT_DIR/project"

    # Commit initial pour pouvoir push
    git add -A > /dev/null 2>&1 || true
    git commit -m "chore: initial project structure" --allow-empty > /dev/null 2>&1 || true

    REPO_URL=$(gh repo create "$PROJECT_SLUG" \
      --"$GH_VISIBILITY" \
      --source=. \
      --push \
      --description "$PROJECT_DESCRIPTION" 2>&1 | head -1)

    cd "$SCRIPT_DIR"

    echo -e "  ${GREEN}✓${NC} Repo créé : ${CYAN}$REPO_URL${NC}"
  fi
fi

echo ""

# ============================================================
# RÉCAPITULATIF
# ============================================================

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ${BOLD}Projet initialisé !${NC}${BLUE}                                    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Projet :${NC}       $PROJECT_NAME"
echo -e "  ${BOLD}Mode :${NC}         $MODE_NAME"
echo -e "  ${BOLD}Recherche :${NC}    $ENABLE_RESEARCH"
echo -e "  ${BOLD}Max features :${NC} $MAX_FEAT"
echo ""
echo -e "  ${BOLD}Fichiers :${NC}"
echo -e "    BRIEF.md        $([ -f "$SCRIPT_DIR/BRIEF.md" ] && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}à rédiger${NC}")"
echo -e "    config.sh       ${GREEN}✓${NC} configuré"
echo -e "    project/        ${GREEN}✓${NC} git initialisé"
echo ""
echo -e "  ${BOLD}Prochaines étapes :${NC}"

if [ ! -f "$SCRIPT_DIR/BRIEF.md" ]; then
  echo -e "    ${CYAN}1.${NC} Rédiger le brief : ${CYAN}./orchestrator.sh --brief${NC}"
  echo -e "    ${CYAN}2.${NC} Relire : ${CYAN}cat BRIEF.md${NC}"
  echo -e "    ${CYAN}3.${NC} Lancer : ${CYAN}./orchestrator.sh${NC}"
else
  echo -e "    ${CYAN}1.${NC} Relire le brief : ${CYAN}cat BRIEF.md${NC}"
  echo -e "    ${CYAN}2.${NC} Ajuster si besoin : ${CYAN}vim BRIEF.md${NC}"
  echo -e "    ${CYAN}3.${NC} Lancer l'agent : ${CYAN}./orchestrator.sh${NC}"
fi

echo ""
echo -e "  Pour lancer en arrière-plan :"
echo -e "    ${CYAN}nohup ./orchestrator.sh > logs/orchestrator.log 2>&1 &${NC}"
echo -e "    ${CYAN}tail -f logs/orchestrator.log${NC}"
echo ""
