---
name: add-phase
description: Ajoute une nouvelle phase au workflow de l'orchestrateur
user_invocable: true
---

## Process pour ajouter une phase

### 1. Créer le fichier prompt
- Fichier : `phases/XX-nom.md` (XX = numéro séquentiel)
- Contenu : prompt Markdown avec placeholders `{{VAR}}` si besoin
- Garder le prompt focalisé sur UNE responsabilité

### 2. Intégrer dans orchestrator.sh
- Ajouter l'appel `run_claude` avec le bon `render_phase`
- Définir un guard pour la reprise (quel fichier/condition indique que cette phase est déjà faite ?)
- Passer le bon `phase_name` pour le tracking tokens
- Placer au bon endroit dans le flow (avant/après quelle phase existante ?)

### 3. Documenter
- Mettre à jour ARCHITECTURE.md avec la description de la phase
- Mettre à jour README.md si le flow visible change

### 4. Tester
- `bash -n orchestrator.sh`
- Vérifier la reprise : que se passe-t-il si le script crash pendant cette phase ?
