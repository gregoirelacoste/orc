PHASE QA — Test fonctionnel réel après l'Epic {{EPIC_NUMBER}}

Vérifie que l'app fonctionne RÉELLEMENT, pas juste que les tests passent.
La commande dev server et le port sont fournis en fin de prompt.

---

### Étape 1 — Discovery des routes (max 20 routes)

Identifie les routes/pages de l'app en analysant le code :
- Frameworks web : cherche les déclarations de routes (Express app.get/post, Next.js pages/, Django urls.py, Flask @app.route, etc.)
- Liens dans les templates/composants
- Liste les routes trouvées (max 20, prioriser les pages utilisateur)

### Étape 2 — Health check (bash, curl)

Démarre le serveur dev avec la commande fournie en fin de prompt.
Attends qu'il soit prêt (retry curl sur la racine toutes les 2s, max 15s) :
```bash
for i in $(seq 1 8); do curl -sf http://localhost:{{PORT}}/ > /dev/null 2>&1 && break; sleep 2; done
```

Puis teste chaque route :
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:{{PORT}}/route
```

Classe : 2xx → OK | 5xx → BUG | 4xx → vérifier (auth = normal, 404 = bug)

### Étape 3 — Fix des erreurs serveur

Pour chaque erreur 5xx, par priorité (pages critiques d'abord) :
1. Lis les logs serveur (dernières 30 lignes)
2. Identifie la stack trace → fichier source
3. Corrige le bug
4. Re-curl → 200 ? → suivant
5. Si échec après 2 tentatives → note dans le rapport, passe au suivant

**Max 5 fixes.** Les erreurs restantes vont dans le rapport.

### Étape 4 — Test navigateur (si Playwright disponible)

Vérifie Playwright ET les navigateurs :
```bash
npx playwright --version 2>/dev/null && npx playwright install --dry-run 2>/dev/null
```

**Si disponible** : génère et exécute un script de test Playwright headless.

Scénarios à tester (basés sur les features de l'epic, lis .orc/ROADMAP.md) :
- Page d'accueil : se charge, contenu visible
- Navigation : liens principaux fonctionnent
- Formulaires : remplir + soumettre (si applicable)
- CRUD : créer/lire un élément (si applicable)
- Max 5 scénarios

Pour chaque scénario, vérifie le DOM (pas de screenshots — vérifie le contenu textuellement) :
```javascript
// Vérifier que la page a du contenu et pas d'erreur
const title = await page.title();
const body = await page.textContent('body');
const hasError = body.includes('500') || body.includes('Internal Server Error');
const hasContent = body.length > 100;
console.log(`${url}: title="${title}", hasContent=${hasContent}, hasError=${hasError}`);
```

**Si Playwright non disponible** : skip cette étape, note-le dans le rapport.

### Étape 5 — Cleanup + Rapport

Arrête le serveur dev :
```bash
# Kill le process sur le port
lsof -ti:{{PORT}} | xargs kill 2>/dev/null || true
```

Écris `.orc/logs/qa-report-{{EPIC_NUMBER}}.md` :

```markdown
## QA Report — Epic {{EPIC_NUMBER}}

### Routes testées
- [x] / — 200 OK
- [x] /api/items — 200 OK
- [ ] /admin — 500 (corrigé → 200)
- [ ] /api/export — 500 (non résolu : [raison])

### Tests navigateur
- [x] Page d'accueil : titre OK, contenu rendu
- [ ] Formulaire inscription : erreur dans le DOM

### Résumé
- Routes : X/Y OK (Z corrigées)
- Tests navigateur : A/B passés
- Problèmes non résolus : [liste]
```

---

RÈGLES :
- Fais les curls en bash, ne simule JAMAIS les résultats.
- Tronque les logs serveur à 30 lignes — ne lis pas tout le fichier.
- Max 20 routes testées, max 5 fixes, max 5 scénarios navigateur.
- Si le serveur ne démarre pas après 15s, signale-le et arrête-toi.
- Kill le serveur dev à la fin (même si tu as fini en erreur).
- Le critère c'est "l'utilisateur peut utiliser l'app", pas "le code est propre".
