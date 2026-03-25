FEATURE À IMPLÉMENTER : {{FEATURE_NAME}}

### Avant de coder — inventaire obligatoire

Lis dans cet ordre :
1. **CODEBASE.md** — l'inventaire du projet. Identifie :
   - Les modules/utilities qui existent déjà et que tu peux réutiliser
   - Les patterns architecturaux en place (les suivre, pas en inventer de nouveaux)
   - Les APIs/services déjà intégrés (ne pas recréer un wrapper)
2. **.claude/skills/stack-conventions.md** — les conventions de la stack.
   Respecte-les. Si un anti-pattern est listé, ne le fais PAS.
3. Le code existant lié à cette feature
4. research/INDEX.md pour le contexte marché
5. La spec de cette feature dans ROADMAP.md
6. Les insights concurrents dans research/competitors/SYNTHESIS.md

### Anti-duplication — checklist AVANT de créer du code

Avant de créer une nouvelle fonction, un nouveau composant ou un nouveau helper :
- [ ] Vérifie dans CODEBASE.md qu'il n'existe pas déjà
- [ ] Vérifie dans stack-conventions.md que le pattern est cohérent
- [ ] Si une utility similaire existe → l'enrichir plutôt qu'en créer une nouvelle
- [ ] Si un composant proche existe → le rendre paramétrique plutôt que dupliquer
- [ ] Si tu crées quelque chose de nouveau et réutilisable → note-le pour CODEBASE.md

### Workflow

1. Crée une branche : feature/{{FEATURE_BRANCH}}
2. Implémente la feature en respectant CLAUDE.md et stack-conventions.md
3. Écris les tests correspondants
4. Lance le build — corrige si erreur
5. Lance les tests — corrige si erreur
6. Auto-review (utilise le skill review-own-code) :
   - Code dupliqué avec l'existant (vérifier dans CODEBASE.md)
   - Failles de sécurité (injection, XSS, secrets, auth)
   - Patterns incohérents avec stack-conventions.md
   - Performance (requêtes N+1, re-renders, chargements inutiles)
   - Over-engineering (ne crée pas d'abstraction pour un seul usage)
7. Commite de façon atomique avec un message descriptif

Si un concurrent fait mieux que notre spec sur cette feature,
adapte l'implémentation et note le changement dans ROADMAP.md.
