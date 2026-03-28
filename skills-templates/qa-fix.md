---
name: qa-fix
description: "Teste l'app réellement (curl + navigateur), corrige les erreurs, vérifie le DOM"
user_invocable: true
---

Tu es un **testeur QA**. Ton job : vérifier que l'app fonctionne pour de vrai, pas juste que les tests passent.

---

## Étape 1 — Discovery

Trouve les routes/pages de l'app (max 20, prioriser les pages utilisateur) :
- Lis les fichiers de routing (Express routes, Next.js pages/, Django urls.py, etc.)
- Lis les composants de navigation (menu, sidebar, liens)
- Liste toutes les URLs à tester

## Étape 2 — Démarre le serveur

Lis `DEV_COMMAND` et `DEV_PORT` dans `.orc/config.sh` si disponible.
Sinon, déduis la commande de la stack (npm run dev, python manage.py runserver, etc.).

Attends que le serveur soit prêt (retry curl toutes les 2s, max 15s) :
```bash
for i in $(seq 1 8); do curl -sf http://localhost:$PORT/ > /dev/null 2>&1 && break; sleep 2; done
```

## Étape 3 — Health check (curl, toutes les routes)

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/route
```

Pour chaque route. Classe : 2xx → OK | 5xx → à corriger | 4xx → vérifier

## Étape 4 — Fix les erreurs

Pour chaque 5xx, par ordre de priorité :
1. Lis les logs serveur (dernières 30 lignes)
2. Identifie la cause (stack trace → fichier source)
3. Corrige
4. Re-curl → vérifie que c'est 200
5. Si 2 tentatives échouent → passe au suivant

## Étape 5 — Tests navigateur (si Playwright dispo)

```bash
npx playwright --version 2>/dev/null && echo "Playwright OK"
```

Si disponible, génère un script Playwright headless pour les parcours clés :
- Navigation entre les pages principales
- Formulaires : remplir et soumettre
- CRUD : créer, lire, modifier, supprimer

Vérifie le DOM pour chaque scénario (pas de screenshots — vérifie textuellement) :
```javascript
const body = await page.textContent('body');
const hasError = body.includes('500') || body.includes('Internal Server Error');
console.log(`${url}: hasContent=${body.length > 100}, hasError=${hasError}`);
```

Max 5 scénarios.

## Étape 6 — Cleanup + Rapport

Arrête le serveur :
```bash
lsof -ti:$PORT | xargs kill 2>/dev/null || true
```

Affiche un résumé clair :
```
Routes : 15/18 OK (3 corrigées)
Tests navigateur : 4/5 passés
Problèmes restants :
  - /api/export → timeout (cause probable : query N+1)
  - Formulaire contact → erreur CSRF
```

---

## Règles

- **Fais les curls pour de vrai.** Ne simule jamais les résultats.
- Tronque les logs à 30 lignes — pas besoin de tout lire.
- Max 20 routes, max 5 fixes, max 5 scénarios navigateur.
- Priorité : pages utilisateur > pages admin > API secondaires.
- Si le serveur ne démarre pas après 15s, diagnostique et corrige.
- **Kill le serveur à la fin** (même si tu as fini en erreur).
