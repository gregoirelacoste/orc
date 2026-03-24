---
id: ROADMAP-008
title: "CLI agent watch — Monitoring temps réel en mode TUI"
priority: P2
type: feature
effort: M
tags: [cli, monitoring, dx]
created: 2026-03-24
updated: 2026-03-24
depends: [ROADMAP-006]
epic: cli-monitoring
---

## Contexte

Sur VPS, `agent logs` fait du `tail -f` brut. Un mode watch structuré
permettrait de voir en temps réel : feature en cours, phase, tokens consommés,
temps écoulé, dernier commit.

## Spécification

`agent watch <nom>` — rafraîchissement toutes les 5s :
- Header : nom du projet, status, PID, uptime
- Barre de progression : feature N/M
- Phase courante (bootstrap/research/implement/test/reflect)
- Tokens : input/output, coût estimé
- Dernières 10 lignes de log filtrées (phases et erreurs uniquement)
- Derniers commits (3)

Implémenté en bash pur avec `tput` pour le positionnement curseur.

## Critères de validation

- [ ] Rafraîchissement sans flickering (clear partiel, pas total)
- [ ] Fonctionne via SSH sans dépendance externe
- [ ] Ctrl+C quitte proprement

## Notes

Alternative : utiliser `watch -n5 agent status <nom>` comme v1 rapide.
