# Roadmap — Autonome Agent

## Historique (fait)

### v0.1.0 — Prototype
- [x] Architecture conceptuelle complète (ARCHITECTURE.md)
- [x] Orchestrateur bash avec boucle feature (implement → test → fix → reflect)
- [x] 8 prompts de phases (bootstrap → evolve)
- [x] 4 skills templates (implement, fix-tests, research, review-own-code)
- [x] Config externalisée (config.sh)

### v0.2.0 — Brief & Skills
- [x] Skill write-brief : Claude product director (22 questions structurées)
- [x] Mode --brief dans l'orchestrateur

### v0.3.0 — Séparation template/workspace
- [x] init.sh : wizard interactif en 5 étapes
- [x] Workspace créé dans un dossier séparé (pas dans le template)
- [x] config.default.sh (template) vs config.sh (projet)
- [x] README.md complet
- [x] Mode --brief déplacé dans init.sh

### v0.4.0 — Observabilité
- [x] Token tracking (logs/tokens.json) avec breakdown par phase et feature
- [x] Estimation de coût en temps réel
- [x] MAX_BUDGET_USD : hard stop si budget dépassé
- [x] Phase self-improve : suggestions d'amélioration post-projet

### v0.5.0 — Production-ready
- [x] Signal handling (trap EXIT/INT/TERM, kill Claude proprement)
- [x] Lockfile anti-exécution concurrente
- [x] State persistence (state.json, reprise après crash)
- [x] Watchdog stall detection (warning après 2min sans données)
- [x] CLAUDE_TIMEOUT : kill après N secondes
- [x] run_in_project() : subshells au lieu de cd/cd-
- [x] human_pause skip en mode nohup
- [x] git checkout main entre les features
- [x] write_fix_prompt() pour les outputs build/test (contourne render_phase)
- [x] printf au lieu de echo -e
- [x] Validation entiers pour le tracking tokens
- [x] Tags de version (v0.1.0 → v0.5.0)

---

## Backlog (à faire)

### v0.6.0 — Robustesse & DX
- [ ] Synchroniser ARCHITECTURE.md avec l'état réel (noms de variables, flow, phases)
- [ ] Ajouter un mode `--dry-run` : simuler le flow sans lancer Claude (debug)
- [ ] Ajouter un mode `--status` : afficher l'état du projet (features, tokens, coût)
- [ ] Ajouter un mode `--resume` explicite (vs détection auto)
- [ ] Gérer le cas "toutes les features cochées mais pas de DONE.md" (boucle infinie potentielle entre strategy et evolve)
- [ ] Tests automatisés : script de test qui simule un flow complet avec un mock de Claude
- [ ] shellcheck clean (corriger tous les warnings)

### v0.7.0 — Intelligence des prompts
- [ ] Améliorer render_phase : utiliser `envsubst` ou un vrai template engine pour éviter les problèmes de caractères spéciaux
- [ ] Prompt dynamique : injecter l'état courant (features faites, échecs, coût) dans chaque prompt
- [ ] Context carry : résumer la feature précédente dans le prompt de la suivante (contre le context reset)
- [ ] Phase de quality gate optionnelle entre implement et test (lint, type-check)

### v0.8.0 — Multi-projet
- [ ] Commande `status --all` : voir l'état de tous les workspaces
- [ ] Remontée automatique des orchestrator-improvements.md vers le template
- [ ] Versioning du workspace : savoir quelle version du template a été utilisée
- [ ] Commande `upgrade` : mettre à jour un workspace existant avec le dernier template

### Idées (non priorisé)
- [ ] Notifications (Slack/webhook) quand une feature est mergée ou quand le projet est bloqué
- [ ] Dashboard web local pour visualiser les tokens, la roadmap, les logs
- [ ] Support d'autres LLM CLI (pas que Claude)
- [ ] Mode "pair" : deux instances Claude qui review le code l'une de l'autre
- [ ] Intégration GitHub Actions : lancer l'orchestrateur en CI
