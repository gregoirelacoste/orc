---
id: ROADMAP-007
title: "Phase 00-bootstrap-adopt.md — Analyse sans modification"
priority: P1
type: feature
effort: S
tags: [adoption, prompts, phases]
created: 2026-03-24
updated: 2026-03-24
depends: [ROADMAP-001]
epic: adopt-mode
---

## Contexte

Le bootstrap classique (`00-bootstrap.md`) crée un projet from scratch.
En mode adoption, il faut un prompt qui lit et documente le projet existant
sans toucher au code.

## Spécification

Créer `phases/00-bootstrap-adopt.md` :

1. Lire TOUT le code source pour comprendre l'architecture
2. Lire les fichiers de config (CI, linter, formatter, Docker)
3. Créer/mettre à jour `CLAUDE.md` avec :
   - Description du projet (déduite du code)
   - Architecture existante documentée
   - Commandes disponibles (build, test, lint, dev)
   - Conventions de code OBSERVÉES
   - Dépendances principales et leur rôle
   - Règles strictes : ne jamais casser les tests existants
4. NE PAS toucher aux fichiers existants (lecture seule)
5. Si ROADMAP.md existe, ne pas le remplacer
6. Commit : `chore: autonome agent adoption — initial analysis`

## Critères de validation

- [ ] Le prompt ne contient aucune instruction de création de fichier (sauf CLAUDE.md)
- [ ] Le CLAUDE.md généré documente fidèlement l'architecture existante
- [ ] Aucun fichier du projet n'est modifié (vérifiable via `git diff`)

## Notes

Ce prompt est le plus critique du mode adoption : il conditionne la qualité
de tout le travail ultérieur de l'agent.
