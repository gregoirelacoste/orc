---
id: ROADMAP-001
title: "adopt.sh — Script d'adoption de projet existant"
priority: P1
type: feature
effort: L
tags: [adoption, cli, orchestrator]
created: 2026-03-24
updated: 2026-03-24
depends: []
epic: adopt-mode
---

## Contexte

Actuellement, l'orchestrateur ne sait que créer des projets from scratch via `init.sh`.
Le mode adoption permet de piloter un projet existant (repo git local ou URL GitHub)
sans casser son historique, son CI, ou ses conventions.

## Spécification

Script `adopt.sh` avec le flow :

1. **Résoudre la source** : chemin local, `.`, ou URL GitHub (clone si besoin)
2. **Vérifier pré-requis** : repo git, working tree propre
3. **Diagnostic complet** :
   - Stack auto-détectée (Node/Go/Rust/Python/Java/Ruby/Makefile/Docker)
   - Package manager détecté (npm/pnpm/yarn/bun)
   - Monorepo détecté (workspaces, Lerna, Turborepo, go.work)
   - CI/CD existant (GitHub Actions, GitLab CI, Jenkins, etc.)
   - Branche par défaut, conventions de commits, préfixe de branches
   - Vérification que build/test actuels fonctionnent
4. **Créer workspace** : symlink vers project/ (pas copie)
5. **Générer config.sh** : commandes auto-détectées, sécurité renforcée (`REQUIRE_HUMAN_APPROVAL=true`)
6. **Générer BRIEF.md** : pré-rempli avec le diagnostic, objectifs à compléter
7. **Phase bootstrap-adopt** : lit et documente sans modifier le code

Usage :
```bash
./adopt.sh /path/to/project
./adopt.sh https://github.com/user/repo
./adopt.sh .
./adopt.sh /path/to/project --auto   # non-interactif
```

## Critères de validation

- [ ] Détection correcte de stack pour Node, Python, Go, Rust au minimum
- [ ] Le workspace créé fonctionne avec `orchestrator.sh`
- [ ] Le projet existant n'est jamais modifié pendant l'adoption (symlink uniquement)
- [ ] `config.sh` généré avec les bonnes commandes build/test
- [ ] Le flag `ADOPT_MODE=true` est respecté par l'orchestrateur
- [ ] `bash -n adopt.sh` passe sans erreur

## Notes

Le symlink `project/ -> /path/to/existing` est crucial : `run_in_project()` opère
directement sur le vrai repo, gardant la connexion au remote.
