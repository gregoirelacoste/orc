PHASE ALIGNMENT — Rapport d'alignement entre le brief, le code et la roadmap

Le cycle de développement vient de se terminer. Avant de repartir, produis un rapport d'alignement pour l'humain.

1. Lis .orc/BRIEF.md (la vision originale)
2. Lis .orc/ROADMAP.md (features faites ✓ et à venir ☐)
3. Lis .orc/logs/maturity-score.md (le dernier score) si présent
4. Lis .orc/logs/acceptance-*.md (les derniers rapports) si présents
5. Lis .orc/codebase/INDEX.md (état actuel du code)

Écris le rapport dans .orc/logs/alignment-report-{{CYCLE}}.md :

```markdown
# Rapport d'alignement — Cycle {{CYCLE}}

## Ce qui est fait
- [liste des features cochées, regroupées par thème]
- Score de maturité actuel : X/30

## Ce qui reste prévu
- [liste des features non-cochées dans ROADMAP]

## Écarts avec le brief
- [points du brief pas encore couverts]
- [features implémentées qui ne correspondent pas au brief]
- [hypothèses prises par l'IA qui mériteraient validation]

## Propositions pour le prochain cycle
- [3-5 features recommandées avec justification brief]

## Questions pour l'humain
1. La direction générale est-elle toujours la bonne ?
2. Parmi les features prévues, y en a-t-il à retirer ou réordonner ?
3. Y a-t-il un besoin nouveau non couvert par le brief ?
4. Quel est ton critère de "suffisant" pour ce projet ?
5. Feedback libre sur ce que tu as vu jusqu'ici ?
```

RÈGLES :
- Sois factuel et concis. Pas de flatterie.
- Les écarts doivent être honnêtes — si l'IA a dévié du brief, dis-le.
- Les propositions doivent CHACUNE citer la section du brief qu'elles servent.
- Max 2 pages. L'humain doit pouvoir lire ça en 2 minutes.
