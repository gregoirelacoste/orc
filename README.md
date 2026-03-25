# Agent Autonome Claude

Un agent Claude Code 100% autonome qui construit un produit de A à Z : veille marché, roadmap, développement, tests, corrections, et auto-amélioration — avec intervention humaine configurable.

## Prérequis

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installé et authentifié
- Git
- [GitHub CLI](https://cli.github.com/) (`gh`) — optionnel, pour créer le repo distant

## Démarrage rapide

```bash
# 1. Cloner le template
git clone git@github.com:gregoirelacoste/orc.git
cd orc

# 2. Initialiser un projet (crée un workspace séparé)
./init.sh pc-builder

# 3. Aller dans le workspace et lancer
cd ../pc-builder
./orchestrator.sh
```

## Comment ça marche

### `init.sh` crée un workspace séparé

```
orc/                         ← ce repo (template, jamais modifié)
│
└── ./init.sh mon-projet
         │
         ▼
../mon-projet/               ← workspace auto-contenu
├── BRIEF.md                 ← brief produit (rédigé avec Claude)
├── orchestrator.sh          ← copié depuis le template
├── phases/                  ← copié depuis le template
├── skills-templates/        ← copié depuis le template
├── .orc/                    ← état orchestrateur (config, logs, state)
│
└── project/                 ← le code produit (son propre repo git)
    ├── .git/
    ├── CLAUDE.md            ← auto-généré et auto-amélioré
    ├── ROADMAP.md           ← auto-généré, évolue avec le projet
    ├── .claude/skills/      ← auto-générées par Claude
    ├── research/            ← veille marché
    ├── src/                 ← code applicatif
    └── e2e/                 ← tests Playwright
```

Le template reste propre. Chaque projet a son workspace isolé.
Le code produit dans `project/` a son propre git et peut être pushé vers GitHub.

### `init.sh` — le wizard en 5 étapes

| Étape | Ce qui se passe |
|---|---|
| **1. Nom** | Nomme ton projet |
| **2. Description** | Décris l'idée en 1-2 phrases |
| **3. Configuration** | Mode d'autonomie + options |
| **4. Structure** | Crée le workspace avec tout le nécessaire |
| **5. Brief** | Claude product director pose ~22 questions et rédige le BRIEF.md |

```bash
./init.sh                          # interactif complet
./init.sh mon-projet               # avec nom
./init.sh mon-projet --skip-brief  # sans rédaction assistée du brief
```

### `orchestrator.sh` — la boucle autonome

```
BRIEF.md (immuable)
    │
    ▼
BOOTSTRAP ──▶ RECHERCHE INITIALE ──▶ STRATÉGIE & ROADMAP
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │ BOUCLE x N   │
                                    │              │
                                    │ Veille ciblée │
                                    │ Implement     │
                                    │ Test & Fix    │
                                    │ Reflect       │
                                    └──────┬───────┘
                                           │
                                  toutes les N features
                                           │
                                           ▼
                                    MÉTA-RÉTROSPECTIVE
                                    Veille tendances
                                    Repriorisation
                                           │
                                           ▼
                                    Nouvelle itération...
```

## Modes d'autonomie

| Mode | Comportement | Quand l'utiliser |
|---|---|---|
| **Pilote auto** | 100% autonome | Prototypes, exploration |
| **Copilote** | Claude code, tu valides chaque merge | Projets avec standards qualité |
| **Supervisé** | Pause toutes les N features | Quand tu veux garder le contrôle |

## Auto-amélioration

L'agent améliore ses propres instructions au fil du projet :

- **CLAUDE.md** — Ajoute des règles quand il découvre des pièges
- **Skills** — Crée de nouveaux workflows quand un pattern se répète
- **ROADMAP.md** — Ajoute/repriorise des features après la veille
- **Recherche** — Veille concurrentielle intégrée au cycle de dev

## Configuration

Tout dans `config.sh` du workspace :

```bash
MAX_FIX_ATTEMPTS=5              # Tentatives de fix par feature
MAX_FEATURES=50                 # Arrêt après N features
EPIC_SIZE=3                     # Features par epic
META_RETRO_FREQUENCY=5          # Méta-rétro toutes les N features
PAUSE_EVERY_N_FEATURES=0        # 0 = jamais
REQUIRE_HUMAN_APPROVAL=false    # Valider chaque merge
ENABLE_RESEARCH=true            # Veille marché
BUILD_COMMAND="npm run build"   # Commande build
TEST_COMMAND="npx playwright test"
```

## Surveiller l'avancement

```bash
tail -f logs/orchestrator.log                     # logs temps réel
grep -c '\[x\]' project/ROADMAP.md                # features terminées
cat project/ROADMAP.md                            # roadmap
cat project/logs/retrospective-*.md               # rétrospectives
```

## FAQ

**Le workspace est-il un repo git ?**
Non. Seul `project/` à l'intérieur a son propre git. Le workspace est de l'outillage local.

**Je peux lancer plusieurs projets ?**
Oui. Chaque `./init.sh nom-projet` crée un workspace indépendant.

**Je peux reprendre après un crash ?**
Oui. L'orchestrateur détecte un projet existant et reprend (features non cochées dans ROADMAP).

**Combien ça coûte ?**
~50-100K tokens par feature. Un projet de 10 features ~= 500K-1M tokens.

**Je peux modifier les prompts ?**
Oui. Édite les fichiers dans `phases/` du workspace. Chaque phase est un prompt Markdown avec des placeholders `{{VAR}}`.

## Documentation

Voir [ARCHITECTURE.md](ARCHITECTURE.md) pour le détail complet de chaque phase.
