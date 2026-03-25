PHASE RÉTROSPECTIVE — Feature terminée : {{FEATURE_NAME}}
Tests passés : {{TESTS_PASSED}} | Tentatives de fix : {{FIX_ATTEMPTS}}

Si un fichier logs/human-feedback-*.md existe pour une feature récente,
lis-le attentivement. Le feedback humain est PRIORITAIRE sur tes propres observations.

Analyse cette itération et améliore tes connaissances du projet :

### 1. CODEBASE.md — Inventaire vivant (OBLIGATOIRE)

Mets à jour CODEBASE.md avec ce que tu as créé/modifié :
- **Modules & Exports** — nouvelles fonctions, classes, composants exportés
- **Utilities & Helpers** — tout ce qui est réutilisable (ne pas dupliquer ensuite !)
- **External Integrations** — nouvelles APIs/services intégrés
- **Data Models** — nouveaux modèles, types, interfaces partagées
- **Architecture Decisions** — si tu as fait un choix technique, note POURQUOI

Format pour chaque entrée :
`- nom() dans chemin/fichier.ext — description courte de ce que ça fait`

### 2. stack-conventions.md — Conventions de stack

Mets à jour `.claude/skills/stack-conventions.md` avec :
- Nouveaux patterns découverts spécifiques à la stack
- Nouveaux anti-patterns identifiés (si tu as fait une erreur, note-la)
- Nouvelles utilities créées (pour ne pas les dupliquer)
- Optimisations de performance appliquées
- Patterns de sécurité validés pour ce projet

### 3. CLAUDE.md — Règles apprises

Ajoute des règles si tu as rencontré des pièges récurrents.
Supprime des règles qui ne servent plus.
Section dédiée : "## Règles apprises (auto-générées)"

### 4. Skills

Si tu as répété un pattern manuellement plus de 2 fois,
crée un skill dans .claude/skills/.
Si un skill existant était inadapté, mets-le à jour.

### 5. ROADMAP.md

Coche la feature terminée.
Si l'implémentation t'a révélé de nouvelles dépendances,
features nécessaires, bugs ou améliorations :
- Crée un item dans `roadmap/backlog/` en suivant le format
  défini dans le skill `roadmap-item.md`
- Chaque item = un fichier ROADMAP-NNN-slug.md avec frontmatter YAML
- Assigne une priorité (P0-P3), un type, un effort estimé, des tags
- Référence la feature courante dans la section Contexte

### 6. Architecture & Sécurité

- Si tu as dû contourner l'architecture, note-le dans CODEBASE.md (section Architecture Decisions)
- Si ça s'accumule, ajoute une tâche de refactoring à la roadmap
- Note les vérifications de sécurité effectuées (auth, validation, injection, secrets)

### 7. Rétrospective

Écris un résumé dans logs/retrospective-{{N}}.md :
- Ce qui a bien marché
- Ce qui a posé problème
- Code réutilisé vs créé (mesure de l'anti-duplication)
- Ce qui a été ajouté/modifié dans les instructions
- Temps estimé vs réel (nombre de turns)

Ne modifie PAS le code applicatif dans cette phase.
Uniquement CODEBASE.md, les skills, CLAUDE.md, la roadmap et les logs.
