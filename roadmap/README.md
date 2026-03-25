# Roadmap — Format & Conventions

## Structure

```
roadmap/
├── backlog/        # Idées, non priorisées
├── planned/        # Priorisées, prêtes à implémenter
├── in-progress/    # En cours de développement
├── done/           # Terminées (archivées)
└── README.md       # Ce fichier
```

Le **statut** d'un item est déterminé par son **dossier**, pas par un champ dans le fichier.

## Format d'un item

Chaque item est un fichier `.md` avec un frontmatter YAML :

```markdown
---
id: ROADMAP-042
title: Titre court et descriptif
priority: P1
type: feature
effort: M
tags: [adoption, git, security]
created: 2026-03-24
updated: 2026-03-24
depends: [ROADMAP-010, ROADMAP-011]
epic: orchestrator-evolution
---

## Contexte

Pourquoi cet item existe, quel problème il résout.

## Spécification

Ce qui doit être fait concrètement.

## Critères de validation

- [ ] Critère 1
- [ ] Critère 2

## Notes

Réflexions, découvertes, liens utiles.
```

## Système de tags

### Priorité (`priority`)

| Tag  | Signification | Délai attendu |
|------|--------------|---------------|
| `P0` | Critique — bloque le système | Immédiat |
| `P1` | Haute — prochaine itération | Court terme |
| `P2` | Moyenne — planifiée | Moyen terme |
| `P3` | Basse — nice-to-have | Quand possible |

### Type (`type`)

| Tag | Description |
|-----|-------------|
| `feature` | Nouvelle fonctionnalité |
| `bugfix` | Correction de bug |
| `refactor` | Restructuration sans changement fonctionnel |
| `infra` | Infrastructure, CI/CD, déploiement |
| `dx` | Developer experience, outillage |
| `security` | Sécurité, garde-fous |
| `docs` | Documentation |
| `research` | Recherche, exploration, spike |

### Effort (`effort`)

| Tag | Estimation |
|-----|-----------|
| `XS` | < 1h, changement trivial |
| `S` | 1-4h, bien défini |
| `M` | 4h-2j, quelques fichiers |
| `L` | 2-5j, plusieurs composants |
| `XL` | > 5j, feature majeure |

### Tags libres (`tags`)

Tags thématiques pour le filtrage : `adoption`, `git`, `cli`, `monitoring`,
`prompts`, `safety`, `orchestrator`, `skills`, etc.

### Epic (`epic`)

Regroupe des items liés. Exemples : `orchestrator-evolution`, `adopt-mode`,
`cli-monitoring`, `prompt-intelligence`.

## Conventions

- **Nommage fichier** : `ROADMAP-NNN-slug-court.md` (ex: `ROADMAP-001-adopt-mode.md`)
- **ID unique** : `ROADMAP-NNN`, incrémental
- **Déplacer, pas éditer** : changer de statut = `mv roadmap/planned/X.md roadmap/in-progress/`
- **Réflexions de features** : les découvertes pendant l'implémentation créent de nouveaux items dans `backlog/`
- **Jamais supprimer** : un item terminé va dans `done/`, jamais supprimé
- **Un fichier = un item** : pas de listes dans un seul fichier

## CLI

Consulter la roadmap via `agent roadmap` :

```bash
agent roadmap                        # Vue compacte (toutes priorités)
agent roadmap --detail               # Vue détaillée avec contexte
agent roadmap --full                 # Vue exhaustive (specs + critères)
agent roadmap --priority P0          # Filtrer par priorité
agent roadmap --tag adoption         # Filtrer par tag
agent roadmap --epic adopt-mode      # Filtrer par epic
agent roadmap --type feature         # Filtrer par type
agent roadmap --status planned       # Filtrer par statut (dossier)
```
