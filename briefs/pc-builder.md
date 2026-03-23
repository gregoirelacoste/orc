# Brief — PC Builder

> Dis-nous ce que tu veux faire avec ton PC, on te dit quoi acheter, où, et au meilleur prix.

## Vision

### Le problème
Monter un PC est un casse-tête pour les non-initiés. Il faut choisir entre des dizaines de composants (CPU, GPU, RAM, carte mère, alimentation, boîtier, stockage, refroidissement), s'assurer qu'ils sont compatibles entre eux, respecter un budget, et trouver les meilleurs prix. Les sites existants (PCPartPicker) sont en anglais, orientés experts, et ne recommandent pas de config adaptée au besoin réel de l'utilisateur.

### La solution
PC Builder est un outil français qui part du **besoin** de l'utilisateur (gaming, bureautique, montage vidéo, streaming, dev, etc.) et de son **budget**, puis recommande une configuration complète et cohérente. Chaque composant est lié à un site marchand via affiliation. L'utilisateur peut créer un compte, sauvegarder ses configs, les comparer entre elles ou avec celles de la communauté (prix, performance, rapport qualité/prix). Le tout est soutenu par du contenu SEO auto-généré (guides, articles promos, landing pages par type de config).

### Pourquoi maintenant
- PCPartPicker n'a pas d'équivalent français de qualité
- Le marché du PC gaming en France est en croissance constante
- Les programmes d'affiliation des retailers français sont matures
- L'IA permet de générer du contenu SEO pertinent à grande échelle

### Ce que ce produit n'est PAS
- Pas un forum ou une communauté de discussion
- Pas un site de test/benchmark hardware (on utilise des données existantes)
- Pas un e-commerce (on redirige vers les marchands via affiliation)
- Pas un outil pour professionnels IT (cible : grand public et gamers)

## Utilisateurs

### Persona principal
- **Qui :** Homme/femme 18-35 ans, veut monter ou upgrader un PC, peu ou moyennement technique
- **Contexte d'usage :** À la maison, en phase de recherche/achat, souvent sur mobile d'abord puis desktop pour finaliser
- **Device principal :** Mobile-first, mais l'expérience desktop est cruciale pour le configurateur
- **Niveau technique :** Novice à intermédiaire — sait ce qu'est un GPU mais ne sait pas lequel choisir

### Parcours utilisateur type
1. Arrive via Google (guide SEO ou landing page "config gaming 1000€")
2. Utilise le configurateur : sélectionne son usage + budget
3. Reçoit une config recommandée avec prix et liens d'achat
4. Peut ajuster les composants, comparer les alternatives
5. Crée un compte pour sauvegarder, partager, ou comparer
6. Clique sur les liens d'affiliation pour acheter

## Marché

### Concurrents directs
| Concurrent | URL | Forces | Faiblesses | Notre différenciateur |
|---|---|---|---|---|
| PCPartPicker | pcpartpicker.com | Exhaustif, communauté, vérification compatibilité | En anglais, pas de recommandation auto, UX complexe | Français, recommandation par besoin, simplifié |
| Config-Gamer | config-gamer.fr | Français, configs pré-faites | Peu de personnalisation, pas interactif, contenu daté | Configurateur dynamique, prix temps réel |
| TopAchat Config | topachat.com/pages/configomatic | Français, intégré à un marchand | Limité à un seul marchand, pas de comparaison | Multi-marchands, comparaison prix |
| Pangoly | pangoly.com | Vérification compatibilité | En anglais, pas de reco, UX basique | Français, IA de recommandation |

### Modèle économique
100% affiliation. Revenus via les clics/achats sur les liens marchands.

Programmes d'affiliation cibles (par priorité) :
1. **Amazon Partenaires** (PA-API 5.0) — catalogue le plus large, API disponible, commission 1-7%
2. **LDLC / Materiel.net** (via Awin ou Effiliation) — spécialistes hardware FR, commissions ~3-5%
3. **TopAchat** (groupe LDLC, via même réseau) — bons prix, audience gamer
4. **Rue du Commerce** (via CJ Affiliate) — catalogue large
5. **CDiscount** (via Awin) — prix agressifs, gros volume

Stratégie : afficher le meilleur prix tous marchands confondus, avec lien affilié pour chacun.

## Fonctionnalités

### MVP — 10 features

**F1 — Configurateur par besoin**
- L'utilisateur sélectionne un profil d'usage : Gaming, Bureautique, Montage vidéo/3D, Streaming, Développement
- Il définit un budget (slider ou champs : 500€ → 3000€+)
- Le système recommande une config complète et cohérente
- Comportement attendu : résultat en < 3 secondes, composants compatibles entre eux
- Critères d'acceptance : les configs recommandées sont pertinentes pour l'usage et le budget
- Cas limites : budget trop bas pour l'usage demandé → message explicatif + config minimale

**F2 — Base de données composants**
- Composants : CPU, GPU, RAM, carte mère, alimentation, boîtier, stockage SSD/HDD, ventirad/AIO
- Pour chaque composant : nom, marque, specs techniques, image, prix par marchand, lien affilié
- Source des données : Amazon PA-API 5.0 en priorité, scraping pour les autres marchands
- Mise à jour des prix : au moins quotidienne
- Critères d'acceptance : au moins 50 composants par catégorie au lancement
- Cas limites : composant en rupture de stock → le marquer, ne pas le recommander

**F3 — Vérification de compatibilité**
- Socket CPU ↔ carte mère
- Type RAM ↔ carte mère (DDR4/DDR5)
- Format carte mère ↔ boîtier (ATX, mATX, ITX)
- Puissance alimentation ↔ TDP total estimé
- Longueur GPU ↔ espace boîtier
- Critères d'acceptance : aucune config incompatible ne peut être sauvegardée
- Cas limites : données manquantes → avertissement plutôt que blocage

**F4 — Page config avec comparaison de prix**
- Affiche la config complète avec chaque composant
- Pour chaque composant : prix chez chaque marchand avec lien affilié
- Met en avant le meilleur prix
- Prix total de la config
- Critères d'acceptance : les liens d'affiliation fonctionnent, les prix sont à jour
- Cas limites : prix indisponible chez un marchand → ne pas afficher ce marchand

**F5 — Comptes utilisateurs**
- Inscription / connexion (email + mot de passe, ou OAuth Google)
- Sauvegarder des configurations
- Voir ses configs sauvegardées sur son profil
- Critères d'acceptance : inscription en < 30 secondes, configs persistées en DB
- Cas limites : utilisateur non connecté peut utiliser le configurateur mais pas sauvegarder

**F6 — Comparateur de configs**
- Comparer 2-3 configurations côte à côte
- Comparaison par : prix total, performance estimée par usage, rapport qualité/prix
- Peut comparer ses propres configs entre elles ou avec des configs publiques
- Critères d'acceptance : tableau comparatif clair, différences mises en surbrillance
- Cas limites : configs avec des composants très différents → quand même comparer

**F7 — Pages guides SEO auto-générées**
- Pages statiques générées automatiquement pour chaque profil d'usage × tranche de budget
- Exemple : "Meilleure config gaming à 1000€ en 2026", "PC montage vidéo pas cher"
- Contenu : intro, config recommandée, explication de chaque choix, liens d'achat
- Critères d'acceptance : contenu unique et pertinent, balises SEO (title, meta, h1-h3, schema.org)
- Mis à jour automatiquement quand les prix/composants changent
- Cas limites : ne pas générer de page si pas assez de composants disponibles pour la tranche

**F8 — Blog promos et bons plans**
- Articles auto-générés sur les promotions en cours (baisse de prix détectée)
- Format : "Bon plan : [Composant] à [prix] au lieu de [ancien prix] sur [marchand]"
- Publication automatique quand une baisse de prix significative (>10%) est détectée
- Critères d'acceptance : articles publiés dans l'heure suivant la détection, liens affiliés
- Cas limites : promo terminée → retirer l'article ou le marquer comme expiré

**F9 — Landing pages configs mises en avant**
- Pages dédiées pour des configs types populaires ("La config gaming RTX 5070", "Le PC bureautique ultime")
- Mises en avant sur la page d'accueil
- Curatées automatiquement en fonction de la popularité et des marges d'affiliation
- Critères d'acceptance : au moins 5 landing pages au lancement, design soigné
- Cas limites : composant phare en rupture → remplacer automatiquement

**F10 — Dashboard et analytics basiques**
- Page admin : nombre de clics affiliés par marchand, configs les plus populaires
- Tracking des clics sur les liens d'affiliation (compteur interne avant redirect)
- Critères d'acceptance : dashboard fonctionnel, données en temps réel
- Cas limites : pas de données au démarrage → afficher un état vide propre

### V2 (pas dans le MVP)
- Système de notation/avis par les utilisateurs sur les configs
- Notifications de baisse de prix sur une config sauvegardée
- Mode "upgrade" : analyser une config existante et suggérer des améliorations
- Intégration benchmark (scores 3DMark, Cinebench) pour des estimations de performance réelles
- Partage social (Twitter, Reddit) des configs
- Programme de parrainage

### Hors scope (ne PAS implémenter)
- Pas de vente directe (on n'est pas un e-commerce)
- Pas de forum/commentaires (complexité de modération)
- Pas de configurations laptop (uniquement tours desktop)
- Pas de périphériques (écran, clavier, souris) dans le MVP
- Pas d'app mobile native (PWA suffit)

## Stack technique

### Imposé
- **Next.js 16** avec App Router — cohérence avec nos autres projets, SSR pour le SEO
- **Vercel** — hébergement, edge functions, ISR pour les pages SEO
- **TypeScript** — typage strict

### Suggéré (l'IA peut adapter)
- **Base de données** — PostgreSQL (Neon ou Supabase) pour les données relationnelles (composants, configs, users)
- **Auth** — NextAuth.js / Auth.js avec providers Email + Google
- **ORM** — Prisma ou Drizzle
- **Tailwind CSS v4** — styling
- **API prix** — Amazon PA-API 5.0 + scraping via Cheerio pour les autres
- **Génération contenu SEO** — Gemini 2.5 Flash pour les textes de guides/articles
- **Cron** — Vercel Cron Jobs pour la mise à jour des prix et la génération d'articles

### APIs externes
- **Amazon Product Advertising API 5.0** — prix, dispo, liens affiliés — https://webservices.amazon.fr/paapi5/documentation
- **Awin API** — liens affiliés LDLC, Materiel.net, CDiscount — https://wiki.awin.com/
- **Google Gemini API** — génération de contenu SEO — nécessite `GEMINI_API_KEY`

### Données
- **Composants PC** : ~500-1000 produits, specs techniques, prix multi-marchands
- **Configurations** : combinaisons de composants créées par les users ou auto-générées
- **Utilisateurs** : email, hash mot de passe, configs sauvegardées
- **Articles SEO** : contenu généré, metadata, date de publication
- **Tracking** : clics affiliés (composant, marchand, timestamp)
- **RGPD** : consentement cookies obligatoire (tracking affilié), mentions légales

## Design & UX

### Ambiance visuelle
- Dark mode par défaut (audience gamer/tech)
- Accents de couleur vifs (bleu électrique, violet) sur fond sombre
- Visuels de composants PC, illustrations techniques
- Inspirations : PCPartPicker (structure), Razer.com (ambiance), NZXT BLD (simplicité)

### Langue
Français uniquement

### Principes UX prioritaires
1. **Simplicité > exhaustivité** — l'utilisateur novice ne doit jamais être perdu
2. **Mobile-first** — consultation sur mobile, configuration détaillée sur desktop
3. **Résultat immédiat** — une config recommandée en 3 clics maximum
4. **Transparence** — expliquer pourquoi chaque composant est recommandé
5. **Prix toujours visible** — jamais de surprise, prix total affiché en permanence

## Contraintes

### Budget
10 features, pas de limite de tokens stricte mais rester raisonnable.

### Légal / Réglementaire
- Mentions légales obligatoires (site d'affiliation)
- Mention "liens affiliés" visible sur les pages produit (obligation légale FR)
- Bandeau cookies RGPD (tracking clics affiliés)
- CGU pour les comptes utilisateurs

### Performance
- LCP < 2.5s sur les pages SEO (critique pour le référencement)
- Config recommandée affichée en < 3s
- Pages SEO en ISR (Incremental Static Regeneration) pour les perfs

## Critères de succès

Le produit est "fini" quand :
1. Un utilisateur peut décrire son besoin, recevoir une config, et cliquer pour acheter — en < 2 minutes
2. Au moins 5 pages guides SEO sont indexées par Google
3. Les liens d'affiliation fonctionnent et trackent les clics
4. Un utilisateur peut créer un compte et sauvegarder/comparer des configs
5. Le blog publie automatiquement des articles quand un bon plan est détecté
