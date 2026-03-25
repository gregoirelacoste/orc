Tu démarres un nouveau projet autonome.

0. Si le dossier `learnings/` contient des fichiers, lis-les.
   Ce sont les apprentissages des projets précédents.
   Intègre les règles et pièges pertinents dans ton CLAUDE.md initial.
   Ne copie pas aveuglément — adapte au contexte de CE projet.

1. Lis BRIEF.md pour comprendre le contexte, la vision et les contraintes.

2. Initialise le projet technique :
   - Structure de dossiers adaptée à la stack demandée
   - package.json / dépendances de base
   - Configuration (tsconfig, eslint, playwright, etc.)
   - .gitignore

3. Crée CLAUDE.md avec :
   - Description du projet
   - Commandes disponibles (dev, build, test, lint)
   - Architecture choisie et pourquoi
   - Conventions de code
   - Règles strictes (build doit passer, tests obligatoires, etc.)
   - Section "## Conventions de stack" avec les patterns spécifiques
     à la stack choisie (React, Astro, Java, etc.)
   - Section "## Anti-patterns" avec les erreurs classiques de cette stack

4. Crée CODEBASE.md — l'inventaire vivant du projet :
   ```markdown
   # Codebase Inventory
   > Ce fichier est mis à jour automatiquement après chaque feature.
   > Consulte-le AVANT de coder pour éviter la duplication.

   ## Modules & Exports
   (sera rempli au fil des features)

   ## Utilities & Helpers
   (fonctions réutilisables — NE PAS dupliquer, utiliser l'existant)

   ## External Integrations
   (APIs, services tiers, SDKs intégrés)

   ## Data Models
   (schémas DB, types, interfaces partagées)

   ## Architecture Decisions
   (choix techniques et leur justification)
   ```

5. Crée les skills de base dans .claude/skills/ :
   - implement-feature.md (workflow d'implémentation)
   - fix-tests.md (workflow de correction de tests)
   - research.md (workflow de veille)
   - review-own-code.md (auto-review avant commit)
   - stack-conventions.md (rempli avec les conventions de la stack choisie)

5. Crée un ROADMAP.md initial vide (sera rempli après la recherche) :
   ```
   # Roadmap
   > Sera structurée après la phase de recherche initiale.
   ```

6. Initialise stack-conventions.md avec les patterns de la stack :
   - Si React/Next.js : hooks patterns, server/client components, state management
   - Si Astro : islands architecture, content collections, SSG vs SSR
   - Si Java/Spring : dependency injection, repository pattern, DTOs
   - Si Python/Django : models, views, serializers, middleware
   - Adapte au contexte du BRIEF, pas de conventions génériques inutiles

7. Commite : "chore: bootstrap project structure"
