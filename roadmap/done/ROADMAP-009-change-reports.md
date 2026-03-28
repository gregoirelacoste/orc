---
id: ROADMAP-009
title: "Rapports de changements par feature"
priority: P2
type: feature
effort: S
tags: [monitoring, adoption, safety]
created: 2026-03-24
updated: 2026-03-24
depends: [ROADMAP-005]
epic: cli-monitoring
---

## Contexte

L'humain a besoin de comprendre ce que l'agent a fait sur chaque feature
sans lire les logs bruts. Un rapport markdown structuré par feature
donne une vue claire et archivable.

## Spécification

Après chaque feature, générer `logs/change-report-NNN.md` :
- Nom de la feature, branche, date
- Fichiers modifiés (stat)
- Fichiers ajoutés/supprimés
- Liste des commits
- Résultat build + test (dernières lignes)
- Métriques : lignes ajoutées/supprimées, nombre de fichiers

Consultable via `agent report <nom> [N]` (dernier rapport ou rapport N).

## Critères de validation

- [ ] Un rapport généré automatiquement par feature
- [ ] Lisible en texte brut (markdown)
- [ ] Consultable via CLI

## Notes

Complète les preflight checks (ROADMAP-005) — le rapport est généré
que le merge soit accepté ou non.
