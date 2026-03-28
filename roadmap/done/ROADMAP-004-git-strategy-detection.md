---
id: ROADMAP-004
title: "Détection et adaptation de la stratégie Git"
priority: P1
type: feature
effort: M
tags: [adoption, git, orchestrator]
created: 2026-03-24
updated: 2026-03-24
depends: [ROADMAP-001]
epic: adopt-mode
---

## Contexte

L'orchestrateur hardcode `git checkout main` et `git merge --no-ff`.
Un projet adopté peut utiliser des PRs, des branches protégées, des conventions
de nommage différentes, ou des commits conventionnels.

## Spécification

Fonction `detect_git_strategy()` :

1. **Branche par défaut** : `git symbolic-ref refs/remotes/origin/HEAD` ou fallback
2. **Stratégie merge** : si PRs existantes → `pull-request`, sinon → `direct-merge`
3. **Préfixe de branches** : scanner les branches remote (`feat/`, `feature/`, `features/`)
4. **Style de commits** : analyser les 20 derniers commits :
   - Conventional commits (`feat:`, `fix:`, etc.)
   - Bracketed (`[tag]`)
   - Freeform
5. **Protection de branches** : via `gh api` si disponible

Variables générées : `GIT_STRATEGY`, `DEFAULT_BRANCH`, `BRANCH_PREFIX`, `COMMIT_STYLE`

Fonction `finish_feature()` :
- `direct-merge` → `git merge --no-ff`
- `pull-request` → `git push -u` + `gh pr create` (pas de merge auto)

## Critères de validation

- [ ] Détecte correctement un repo PR-based (GitHub)
- [ ] Détecte le préfixe de branche `feat/` vs `feature/`
- [ ] Détecte les conventional commits
- [ ] `finish_feature` crée une PR quand `GIT_STRATEGY=pull-request`
- [ ] Fonctionne sans `gh` CLI (fallback `direct-merge`)

## Notes

Ne jamais `git push --force`. Ne jamais `git rebase` sur des branches partagées.
