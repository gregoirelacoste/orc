---
id: ROADMAP-011
title: "Prompts dynamiques — injection de contexte courant"
priority: P2
type: feature
effort: M
tags: [prompts, orchestrator, intelligence]
created: 2026-03-24
updated: 2026-03-24
depends: []
epic: prompt-intelligence
---

## Contexte

Les prompts de phase utilisent des placeholders statiques (`{{VAR}}`).
En mode adoption, le contexte est plus riche : architecture existante,
conventions observées, historique des features précédentes.

## Spécification

Enrichir `render_phase()` pour injecter dynamiquement :
- Résumé de la feature précédente (context carry)
- État courant du projet (nb fichiers, tests, couverture)
- Conventions détectées au bootstrap (style de code, patterns)
- Liste des features restantes dans la roadmap
- Erreurs récurrentes des features précédentes

## Critères de validation

- [ ] Le prompt de la feature N+1 contient un résumé de la feature N
- [ ] Les conventions détectées sont injectées dans le prompt implement
- [ ] `render_phase()` reste compatible avec l'existant

## Notes

Attention à la taille du prompt — ne pas injecter trop de contexte.
Résumés courts (5-10 lignes max par section).
