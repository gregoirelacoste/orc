---
id: ROADMAP-012
title: "CLI agent adopt — Intégration adopt.sh dans agent.sh"
priority: P2
type: feature
effort: S
tags: [cli, adoption]
created: 2026-03-24
updated: 2026-03-24
depends: [ROADMAP-001]
epic: adopt-mode
---

## Contexte

`adopt.sh` est un script standalone. Il doit être intégré dans la CLI
`agent.sh` comme sous-commande pour une expérience unifiée.

## Spécification

```bash
agent adopt /path/to/project              # Adopter un projet local
agent adopt https://github.com/user/repo  # Cloner et adopter
agent adopt . --auto                      # Non-interactif
```

Appelle `adopt.sh` en interne, puis enregistre le workspace dans
`$PROJECTS_DIR` pour que `agent status`, `agent start`, etc. fonctionnent.

## Critères de validation

- [ ] `agent adopt` crée le workspace et l'enregistre
- [ ] `agent status` affiche le projet adopté
- [ ] `agent start <nom>` fonctionne sur un projet adopté

## Notes

Le workspace adopté utilise un symlink — `agent status` doit résoudre
le chemin réel pour afficher les infos correctes.
