---
id: ROADMAP-003
title: "Orchestrateur — Support du mode adoption"
priority: P1
type: feature
effort: M
tags: [adoption, orchestrator]
created: 2026-03-24
updated: 2026-03-24
depends: [ROADMAP-001, ROADMAP-002]
epic: adopt-mode
---

## Contexte

L'orchestrateur doit détecter `ADOPT_MODE=true` dans config.sh et adapter
son comportement : pas de `git init`, pas de création de structure, bootstrap
en mode lecture seule.

## Spécification

Modifications dans `orchestrator.sh` :

1. **Phase 0 (bootstrap)** : si `ADOPT_MODE=true` :
   - Skip `git init` et `mkdir -p`
   - Créer branche `$STAGING_BRANCH` (isolation)
   - Copier les skills sans écraser les existants
   - Utiliser `phases/00-bootstrap-adopt.md` au lieu de `00-bootstrap.md`
2. **Phase 1 (research)** : skip si `ENABLE_RESEARCH=false` (défaut en adoption)
3. **Git workflow** : respecter `GIT_STRATEGY`, `BRANCH_PREFIX`, `COMMIT_STYLE`
4. **Merge/PR** : `finish_feature()` selon `GIT_STRATEGY` (direct-merge ou pull-request)
5. **Guards** : adapter les guards de reprise pour le mode adoption

Nouvelle phase : `phases/00-bootstrap-adopt.md` — lit et documente sans modifier.

## Critères de validation

- [ ] `ADOPT_MODE=true` skip le `git init`
- [ ] La branche staging est créée automatiquement
- [ ] Les skills existants dans `.claude/skills/` ne sont pas écrasés
- [ ] Le bootstrap-adopt ne modifie aucun fichier du projet (sauf CLAUDE.md)
- [ ] La reprise après crash fonctionne en mode adoption

## Notes

Le bootstrap-adopt doit produire un CLAUDE.md qui documente l'architecture
existante — c'est la base pour que les phases suivantes fonctionnent.
