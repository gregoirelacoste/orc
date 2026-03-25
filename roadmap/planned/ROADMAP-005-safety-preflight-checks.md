---
id: ROADMAP-005
title: "Garde-fous adoption — Preflight checks & blast radius"
priority: P0
type: security
effort: L
tags: [adoption, safety, security, orchestrator]
created: 2026-03-24
updated: 2026-03-24
depends: [ROADMAP-003]
epic: adopt-mode
---

## Contexte

Un agent autonome sur un projet en production peut causer des dégâts réels.
Il faut plusieurs couches de sécurité pour empêcher les régressions,
les suppressions massives, et les modifications de fichiers critiques.

## Spécification

### Couche 1 : Branche staging (isolation)
- Tout le travail sur `autonome/staging`, jamais directement sur main/master
- Features branchées depuis staging

### Couche 2 : Preflight checks avant chaque merge
- Build passe
- TOUS les tests passent (pas juste les nouveaux)
- Lint passe (warning, pas bloquant)
- Pas de fichiers sensibles modifiés (`.env`, `credentials`, `key.pem`, etc.)
- Pas de suppressions massives (> 500 deletions ET ratio > 3:1 deletions/additions)
- Pas de modification CI sans approbation

### Couche 3 : Blast radius limits
- `MAX_FILES_PER_FEATURE=30` — alerte si dépassé
- `MAX_LINES_CHANGED_PER_FEATURE=500` — alerte si dépassé
- `PROTECTED_PATHS` — liste de globs interdits à l'agent

### Couche 4 : Rollback automatique
- Sauvegarder le SHA avant chaque merge
- Post-merge : relancer les tests
- Si tests cassés → `git reset --hard $LAST_GOOD_SHA`

### Couche 5 : Mode dry-run
- `DRY_RUN=true` → simule les merges, log le diff, ne modifie rien

### Couche 6 : Change reports
- Rapport markdown généré avant chaque merge/PR
- Fichiers modifiés, ajoutés, supprimés, commits, statut build/test

## Critères de validation

- [ ] Les tests de l'existant sont relancés après chaque merge
- [ ] Un rollback automatique se déclenche si tests cassés post-merge
- [ ] Les fichiers protégés ne sont jamais modifiés
- [ ] Le mode dry-run ne modifie aucun fichier
- [ ] Les suppressions massives sont bloquées
- [ ] Un change report est généré pour chaque feature

## Notes

P0 car tout le mode adoption est inutile sans garde-fous solides.
Tag de sauvegarde `pre-autonome-adopt-<date>` créé à l'adoption.
