# CLAUDE.md — Autonome Agent

## Projet

Autonome Agent est un **meta-outil** : un orchestrateur bash qui pilote Claude Code CLI en boucle autonome pour construire des produits logiciels de A à Z. C'est le projet de l'outil lui-même, pas un projet généré par l'outil.

## Stack

- **Bash** (bash 5+) — orchestrateur principal (`orchestrator.sh`, `init.sh`)
- **Markdown** — prompts des phases (`phases/*.md`), skills (`skills-templates/*.md`)
- **JSON** — tracking tokens (`logs/tokens.json`), état (`logs/state.json`)
- **jq** — parsing JSON (dépendance optionnelle, dégradation gracieuse si absent)
- **Claude Code CLI** — `claude -p` en mode non-interactif avec `--dangerously-skip-permissions`
- **GitHub CLI** (`gh`) — création de repos dans `init.sh`

## Architecture

```
autonome-agent/              ← CE REPO (template, jamais modifié par un projet)
├── orchestrator.sh          ← Boucle principale : bootstrap → research → strategy → feature loop → evolve
├── init.sh                  ← Wizard interactif : crée un workspace SÉPARÉ (../mon-projet/)
├── config.default.sh        ← Template de config (copié et personnalisé par init.sh)
├── phases/                  ← Prompts Markdown avec placeholders {{VAR}} pour chaque phase
├── skills-templates/        ← Skills copiées dans project/.claude/skills/ au bootstrap
├── BRIEF.template.md        ← Template de brief produit
├── ARCHITECTURE.md          ← Documentation complète du système
└── README.md                ← Mode d'emploi
```

**Le workspace créé par init.sh :**
```
../mon-projet/               ← Auto-contenu, indépendant du template
├── orchestrator.sh          ← Copie
├── config.sh                ← Personnalisé
├── BRIEF.md                 ← Brief produit
├── phases/, skills-templates/
├── logs/                    ← Logs orchestrateur + tokens.json + state.json
└── project/                 ← Code produit (son propre git)
```

## Commandes

- `bash -n orchestrator.sh` — vérifier la syntaxe sans exécuter
- `shellcheck orchestrator.sh` — lint statique (si shellcheck installé)
- Pas de test framework — la validation se fait par dry-run sur un projet réel

## Conventions

- **Bash strict mode** : `set -euo pipefail` en haut de chaque script
- **Pas de `cd` nu** : utiliser `run_in_project()` (subshell) pour exécuter dans project/
- **printf > echo -e** : pour la portabilité des couleurs
- **Chemins absolus** : `PROJECT_DIR` et `LOG_DIR` résolus au démarrage via `realpath`
- **Dégradation gracieuse** : si `jq` absent, le tracking tokens est désactivé (pas de crash)
- **Lockfile** : `.orchestrator.lock` avec PID pour empêcher l'exécution concurrente
- **Signal handling** : trap `EXIT INT TERM` pour cleanup (kill Claude, rm temp files, save state)
- **State persistence** : `state.json` sauvegardé après chaque feature pour reprise après crash

## Règles de modification

- **Ne jamais casser la reprise** : le script doit pouvoir reprendre à tout moment (guards sur CLAUDE.md, INDEX.md, ROADMAP.md)
- **Ne jamais hardcoder de valeurs** : tout doit être dans `config.default.sh`
- **Les phases sont des fichiers séparés** : modifier un prompt = modifier un fichier .md, pas le bash
- **Placeholders** : `{{VAR}}` dans les phases, substitués par `render_phase()`
- **Pas de données projet ici** : le template ne contient jamais de BRIEF.md ou config.sh spécifique
- **Tester la syntaxe** : `bash -n orchestrator.sh` avant chaque commit

## Patterns importants

### run_claude()
Point central — lance Claude en background, monitore le heartbeat, détecte les stalls, enforce le timeout, track les tokens. Toute modification ici impacte tout le système.

### render_phase()
Substitue `{{VAR}}` dans les prompts. Attention : la substitution bash `${content//pattern/replacement}` casse si `replacement` contient `/` ou `\`. Pour les outputs build/test, utiliser `write_fix_prompt()` à la place.

### Reprise après crash
Séquence de guards : `CLAUDE.md` existe ? → skip bootstrap. `INDEX.md` existe ? → skip research. Features non-cochées dans ROADMAP ? → skip strategy. `state.json` → restaure les compteurs.

## Version actuelle

v0.5.0 — Production-ready
