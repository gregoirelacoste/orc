---
id: ROADMAP-002
title: "Auto-détection de stack et commandes"
priority: P1
type: feature
effort: M
tags: [adoption, detection, orchestrator]
created: 2026-03-24
updated: 2026-03-24
depends: []
epic: adopt-mode
---

## Contexte

`config.default.sh` hardcode `npm run build` et `npx playwright test`.
Pour adopter un projet existant, il faut détecter automatiquement la stack
et les commandes appropriées.

## Spécification

Fonction `detect_stack()` avec détection hiérarchique :

1. **Fichiers marqueurs** (par ordre de priorité) :
   - `package.json` → Node.js (+ framework : Next.js, Nuxt, Vite, Angular)
   - `go.mod` → Go
   - `Cargo.toml` → Rust
   - `pyproject.toml` → Python (poetry/hatch/uv/pip)
   - `requirements.txt` / `setup.py` → Python legacy
   - `pom.xml` → Maven
   - `build.gradle(.kts)` → Gradle
   - `Gemfile` → Ruby
   - `Makefile` → Extraction des targets
2. **Package manager** : pnpm-lock.yaml, yarn.lock, bun.lockb
3. **Scripts package.json** : extraction via `jq` des scripts build/test/lint/dev
4. **Fallback Docker** : `Dockerfile` → `docker build`
5. **Monorepo** : workspaces npm/pnpm, Lerna, Turborepo, go.work

Retourne : `DETECTED_STACK`, `BUILD_COMMAND`, `TEST_COMMAND`, `LINT_COMMAND`, `DEV_COMMAND`

Fonction séparée `detect_monorepo()` : retourne `MONOREPO=true/false`, `MONOREPO_TYPE`

## Critères de validation

- [ ] Détecte correctement un projet Next.js avec pnpm
- [ ] Détecte correctement un projet Python avec poetry
- [ ] Détecte correctement un projet Go standard
- [ ] Détecte correctement un projet Rust avec cargo
- [ ] Fallback Makefile fonctionne
- [ ] Dégradation gracieuse si `jq` absent (Node.js)
- [ ] Monorepo détecté pour pnpm workspaces et Turborepo

## Notes

Sourceable dans `adopt.sh` et `orchestrator.sh`. Dégradation gracieuse obligatoire
conformément aux conventions du projet.
