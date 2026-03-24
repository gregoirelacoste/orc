---
id: ROADMAP-010
title: "Notifications CLI — alertes feature terminée/erreur"
priority: P3
type: feature
effort: S
tags: [cli, monitoring, notifications]
created: 2026-03-24
updated: 2026-03-24
depends: [ROADMAP-006]
epic: cli-monitoring
---

## Contexte

Sur VPS, l'humain ne surveille pas en permanence. Il faut un mécanisme
de notification léger quand un événement important survient.

## Spécification

Mécanisme basé sur des fichiers d'événements :
- `logs/events/` — un fichier par événement horodaté
- `agent events <nom>` — liste les N derniers événements
- `agent events <nom> --since 1h` — événements de la dernière heure
- Hook optionnel : exécuter un script à chaque événement (webhook, ntfy.sh, etc.)

Types d'événements : feature_started, feature_completed, feature_failed,
build_failed, test_failed, merge_blocked, budget_warning, agent_stopped.

## Critères de validation

- [ ] Événements écrits dans `logs/events/`
- [ ] `agent events` affiche les événements formatés
- [ ] Hook optionnel fonctionne (script externe)

## Notes

ntfy.sh est un bon candidat pour push notifications sur mobile depuis un VPS.
Pas de dépendance dure — le hook est optionnel.
