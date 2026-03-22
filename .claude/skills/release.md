---
name: release
description: Prépare et publie une nouvelle version de l'orchestrateur
user_invocable: true
---

## Process de release

### 1. Pré-release
- [ ] `bash -n orchestrator.sh && bash -n init.sh` — syntaxe OK
- [ ] Vérifier que ARCHITECTURE.md est à jour
- [ ] Vérifier que README.md est à jour
- [ ] Mettre à jour la version dans CLAUDE.md ("Version actuelle")

### 2. Versioning (semver)
- **patch** (v0.5.X) : bugfix, correction de typo dans les prompts
- **minor** (v0.X.0) : nouvelle phase, nouvelle feature de l'orchestrateur, nouveau skill
- **major** (vX.0.0) : changement breaking (format config, structure workspace)

### 3. Release
```bash
# Déterminer la version
git tag -l  # voir les tags existants

# Tagger
git tag vX.Y.Z -m "vX.Y.Z — description courte"
git push --tags
```

### 4. Post-release
- Si le format de config.default.sh a changé : documenter la migration
- Les workspaces existants gardent leur copie — le template change n'affecte pas les projets en cours
