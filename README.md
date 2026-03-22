# Agent Autonome Claude

Un agent Claude Code 100% autonome qui construit un produit de A à Z : veille marché, roadmap, développement, tests, corrections, et auto-amélioration — avec intervention humaine configurable.

## Prérequis

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installé et authentifié
- Git
- [GitHub CLI](https://cli.github.com/) (`gh`) — optionnel, pour créer le repo distant automatiquement

## Démarrage rapide

```bash
# 1. Cloner
git clone git@github.com:gregoirelacoste/autonome-agent.git mon-projet
cd mon-projet

# 2. Initialiser (interactif)
./init.sh

# 3. Lancer l'agent autonome
./orchestrator.sh
```

C'est tout. `init.sh` te guide pour tout le reste.

## Que fait `init.sh` ?

L'assistant d'initialisation en 5 étapes :

| Étape | Ce qui se passe |
|---|---|
| **1. Nom** | Nomme ton projet |
| **2. Description** | Décris l'idée en 1-2 phrases |
| **3. Configuration** | Choisis le mode d'autonomie + options |
| **4. Structure** | Crée `project/` avec son propre git, skills, dossiers research |
| **5. Brief** | Claude te pose ~22 questions en mode product director et rédige le `BRIEF.md` |

Options :
```bash
./init.sh                # Init complet avec rédaction du brief
./init.sh --skip-brief   # Init sans brief (le rédiger manuellement)
```

## Que fait `orchestrator.sh` ?

Pilote Claude en boucle autonome à travers ces phases :

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

Chaque phase est un prompt stocké dans `phases/`. Claude peut aussi modifier ses propres instructions (`CLAUDE.md`), créer de nouveaux skills, et faire évoluer la roadmap.

## Modes d'autonomie

| Mode | Comportement | Quand l'utiliser |
|---|---|---|
| **Pilote auto** | 100% autonome, aucune intervention | Projets exploratoires, prototypes |
| **Copilote** | Claude code, tu valides chaque merge | Projets avec standards de qualité |
| **Supervisé** | Pause toutes les N features | Quand tu veux garder le contrôle |

Configurable dans `config.sh` ou via `init.sh`.

## Structure des fichiers

```
autonome-agent/                  ← Repo orchestrateur (ce repo)
├── init.sh                      ← Assistant d'initialisation
├── orchestrator.sh              ← Script principal
├── config.sh                    ← Configuration (garde-fous, modes, etc.)
├── BRIEF.md                     ← Brief produit (généré par init.sh)
├── BRIEF.template.md            ← Template si rédaction manuelle
├── ARCHITECTURE.md              ← Documentation détaillée du système
│
├── phases/                      ← Prompts de chaque phase
│   ├── 00-bootstrap.md
│   ├── 01-research.md
│   ├── 02-strategy.md
│   ├── 03-implement.md
│   ├── 04-test-fix.md
│   ├── 05-reflect.md
│   ├── 06-meta-retro.md
│   └── 07-evolve.md
│
├── skills-templates/            ← Skills copiées dans le projet au bootstrap
│   ├── write-brief.md
│   ├── implement-feature.md
│   ├── fix-tests.md
│   ├── research.md
│   └── review-own-code.md
│
├── logs/                        ← Logs de l'orchestrateur
│
└── project/                     ← Repo du projet généré (git séparé)
    ├── .git/                    ← Son propre historique
    ├── BRIEF.md                 ← Copie de l'ancre (immuable)
    ├── CLAUDE.md                ← Auto-généré, auto-amélioré par Claude
    ├── ROADMAP.md               ← Auto-généré, évolue avec le projet
    ├── .claude/skills/          ← Auto-générées/améliorées par Claude
    ├── research/                ← Veille marché
    ├── logs/                    ← Rétrospectives par feature
    ├── src/                     ← Code applicatif
    └── e2e/                     ← Tests Playwright
```

## Configuration

Tout se règle dans `config.sh` :

```bash
# Garde-fous
MAX_FIX_ATTEMPTS=5              # Tentatives de fix par feature (puis abandon)
MAX_FEATURES=50                 # Arrêt après N features
MAX_TURNS_PER_INVOCATION=50     # Limite tokens par appel Claude

# Rythme
EPIC_SIZE=3                     # Features par epic avant veille ciblée
META_RETRO_FREQUENCY=5          # Méta-rétro toutes les N features

# Intervention humaine
PAUSE_EVERY_N_FEATURES=0        # 0 = jamais, N = pause toutes les N features
REQUIRE_HUMAN_APPROVAL=false    # true = valider chaque merge manuellement

# Recherche web
ENABLE_RESEARCH=true            # Activer la veille marché
MAX_TURNS_RESEARCH_INITIAL=80   # Budget recherche initiale

# Commandes techniques
BUILD_COMMAND="npm run build"
TEST_COMMAND="npx playwright test"
```

## Auto-amélioration

L'agent s'améliore au fil du projet :

- **CLAUDE.md** — Ajoute des règles quand il découvre des pièges, nettoie aux méta-rétros
- **Skills** — Crée de nouveaux workflows quand il détecte des patterns répétés
- **ROADMAP.md** — Ajoute des features découvertes, repriorise après la veille
- **Recherche** — Veille concurrentielle et tendances intégrée au cycle de dev

```
Feature 1 :  erreurs basiques → ajoute 3 règles au CLAUDE.md
Feature 3 :  même erreur E2E  → crée un skill fix-e2e.md
Feature 5 :  méta-rétro       → nettoie CLAUDE.md, affine les skills
Feature 10 : dette détectée   → ajoute un refactoring à la roadmap
```

## Surveiller l'avancement

```bash
# Logs en temps réel
tail -f logs/orchestrator.log

# Compter les features terminées
grep -c '\[x\]' project/ROADMAP.md

# Voir la roadmap
cat project/ROADMAP.md

# Voir les rétrospectives
ls project/logs/
```

## FAQ

**Le projet project/ est-il dans le même repo git ?**
Non. `project/` a son propre git indépendant. Le `.gitignore` de l'orchestrateur l'exclut. Tu peux push `project/` vers son propre repo distant.

**Je peux reprendre après un crash ?**
Oui. L'orchestrateur détecte un `project/` existant et reprend où il en était (features non cochées dans la ROADMAP).

**Combien ça coûte en tokens ?**
~50-100K tokens par feature complète (veille + impl + tests + reflect). Un projet de 30 features ~= 2-3M tokens.

**Je peux modifier le brief en cours de route ?**
Le BRIEF.md est conçu pour être immuable (c'est l'ancre). Si tu veux changer la direction, modifie plutôt la ROADMAP.md directement.

**Je peux personnaliser les prompts ?**
Oui, édite les fichiers dans `phases/`. Chaque phase est un prompt Markdown indépendant avec des placeholders `{{VAR}}`.

## Documentation complète

Voir [ARCHITECTURE.md](ARCHITECTURE.md) pour le détail de chaque phase, les garde-fous, et les limites du système.
