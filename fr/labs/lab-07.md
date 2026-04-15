---
nav_exclude: true
permalink: /fr/labs/lab-07
title: "Labo 07 : Flux de remédiation avec les agents Copilot"
description: "Utilisez les agents GitHub Copilot pour détecter, prioriser et corriger automatiquement les violations d'accessibilité."
---

# Labo 07 : Flux de remédiation avec les agents Copilot

| | |
|---|---|
| **Durée** | 45 minutes |
| **Niveau** | Avancé |
| **Prérequis** | [Labo 06](lab-06.md), accès à GitHub Copilot |

> [!TIP]
> Ce labo couvre les flux de remédiation **basés sur GitHub**. Pour la variante
> avec pipeline Azure DevOps, consultez [Labo 07-ado : Pipelines YAML ADO](lab-07-ado.md).

## Objectifs d'apprentissage

À la fin de ce labo, vous serez en mesure de :

- Examiner l'agent A11yDetector et comprendre son flux analyse-score-priorisation
- Invoquer l'agent de détection sur une application de démonstration et interpréter sa sortie
- Examiner l'agent A11yResolver et comprendre son approche de correction basée sur des modèles
- Appliquer les correctifs de remédiation proposés par l'agent de résolution
- Créer une pull request de remédiation avec des preuves avant/après
- Relancer l'analyse pour vérifier que le score d'accessibilité s'améliore après les correctifs

## Exercices

### Exercice 7.1 : Examiner l'agent A11yDetector

Le scanner comprend deux agents Copilot qui fonctionnent ensemble : un **détecteur** qui identifie et priorise les violations, et un **résolveur** qui propose et applique les correctifs.

1. Ouvrez `.github/agents/a11y-detector.agent.md` dans votre éditeur.

2. Examinez la définition de l'agent. Le flux du détecteur :

   | Étape | Action |
   |-------|--------|
   | 1 | Analyse l'URL cible à l'aide du moteur d'analyse |
   | 2 | Calcule un score d'accessibilité (0–100) |
   | 3 | Identifie les 10 principales violations par gravité et fréquence |
   | 4 | Associe chaque violation à son critère de succès WCAG 2.2 |
   | 5 | Produit un rapport de remédiation priorisé |
   | 6 | Transmet à l'agent A11yResolver pour les correctifs |

3. Notez le **modèle de transfert** — le détecteur invoque le résolveur via le système d'agents de Copilot, en transmettant le rapport de violations comme contexte. Cette séparation permet à chaque agent de se spécialiser :
   - **Détecteur** : Expert en règles WCAG, analyse et priorisation
   - **Résolveur** : Expert en modèles de correction HTML/CSS/ARIA

### Exercice 7.2 : Lancer l'analyse de détection

Vous allez invoquer l'agent de détection sur l'application de démonstration 001 pour produire un rapport de violations priorisé.

1. Ouvrez **GitHub Copilot Chat** dans VS Code (ou votre interface Copilot préférée).

2. Invoquez l'agent de détection :

   ```text
   @a11y-detector Scan http://localhost:8001 and produce a prioritized violation report
   ```

3. Le détecteur exécute l'analyse et retourne un rapport qui comprend :
   - **Score global** — Le score d'accessibilité de la page
   - **Top 10 des violations** — Classées par impact × fréquence
   - **Correspondance WCAG** — Chaque violation liée à son critère de succès
   - **Priorité de remédiation** — Quelles violations corriger en premier pour une amélioration maximale du score

   ![Rapport de sortie du détecteur](../../images/lab-07/lab-07-detector-output.png)

4. Examinez la priorisation. Les violations sont classées par impact :
   - Les violations **critiques** (lang manquant, pièges clavier) sont de priorité maximale
   - Les violations **sérieuses** (texte alternatif manquant, contraste insuffisant) suivent
   - Les violations **modérées** et **mineures** sont de priorité inférieure

> [!TIP]
> Corriger les 3 à 5 principales violations critiques/sérieuses produit généralement la plus grande amélioration du score. Concentrez-vous d'abord sur les éléments à fort impact.

### Exercice 7.3 : Examiner l'agent A11yResolver

Vous allez examiner l'agent de résolution qui propose des correctifs de code pour les violations détectées.

1. Ouvrez `.github/agents/a11y-resolver.agent.md` dans votre éditeur.

2. Examinez le tableau des modèles de correction du résolveur :

   | Violation | Modèle de correction |
   |-----------|----------------------|
   | Attribut `lang` manquant | Ajouter `lang="en"` à l'élément `<html>` |
   | Texte alternatif manquant | Ajouter des attributs `alt` descriptifs aux images |
   | Contraste de couleur insuffisant | Mettre à jour les couleurs CSS pour atteindre un ratio de 4.5:1 pour le texte normal |
   | Étiquettes de formulaire manquantes | Ajouter des éléments `<label>` associés via `for`/`id` |
   | Hiérarchie des titres | Restructurer les titres pour suivre un ordre logique (h1 → h2 → h3) |
   | Piège clavier | Supprimer ou corriger le JavaScript qui intercepte les événements clavier |
   | Navigation par raccourci manquante | Ajouter un lien de navigation par raccourci comme premier élément focalisable |
   | Liens ambigus | Remplacer « cliquez ici » par un texte de lien descriptif |
   | En-têtes de tableau manquants | Ajouter des éléments `<th>` avec des attributs `scope` |
   | Éléments obsolètes | Remplacer `<marquee>` et `<font>` par du CSS |

3. Le résolveur fait référence à `.github/instructions/a11y-remediation.instructions.md` pour des recettes de correction détaillées. Chaque recette comprend des exemples de code avant/après et le critère WCAG qu'elle traite.

### Exercice 7.4 : Appliquer les correctifs de remédiation

Vous allez utiliser l'agent de résolution pour proposer et appliquer des correctifs à l'application de démonstration 001.

1. Invoquez l'agent de résolution dans Copilot Chat :

   ```text
   @a11y-resolver Fix the top 5 violations in a11y-demo-app-001/static/index.html
   ```

2. Le résolveur propose des modifications de code ciblées. Examinez chaque correctif proposé :

   - **Ajouter `lang="en"`** à la balise `<html>`
   - **Ajouter un élément `<title>`** avec un titre de page descriptif
   - **Ajouter des attributs `alt`** à tous les éléments `<img>`
   - **Remplacer `<div class="btn">`** par des éléments `<button>`
   - **Supprimer le piège clavier** JavaScript

   ![Correctifs proposés par le résolveur](../../images/lab-07/lab-07-resolver-fixes.png)

3. Acceptez les correctifs proposés. Le résolveur modifie `a11y-demo-app-001/static/index.html` avec les changements.

4. Vérifiez que les correctifs semblent corrects en examinant le diff dans votre éditeur.

### Exercice 7.5 : Créer une PR de remédiation

Vous allez valider les correctifs et créer une pull request documentant l'état avant/après.

1. Créez une branche de fonctionnalité pour la remédiation :

   ```bash
   git checkout -b fix/a11y-demo-001-top-violations
   ```

2. Indexez et validez les modifications :

   ```bash
   git add a11y-demo-app-001/static/index.html
   git commit -m "fix: remediate top 5 WCAG violations in demo app 001"
   ```

3. Poussez la branche :

   ```bash
   git push -u origin fix/a11y-demo-001-top-violations
   ```

4. Créez une pull request :

   ```bash
   gh pr create \
     --title "fix: remediate top 5 WCAG violations in demo app 001" \
     --body "## Changes

   Fixes the top 5 accessibility violations detected by the A11yDetector agent:

   1. Added \`lang=\"en\"\` to \`<html>\` element (WCAG 3.1.1)
   2. Added descriptive \`<title>\` element (WCAG 2.4.2)
   3. Added \`alt\` attributes to all images (WCAG 1.1.1)
   4. Replaced div buttons with semantic \`<button>\` elements (WCAG 4.1.2)
   5. Removed keyboard trap JavaScript (WCAG 2.1.2)

   ## Before / After

   | Metric | Before | After |
   |--------|--------|-------|
   | Score | ~25 | ~55 |
   | Critical violations | 3 | 0 |
   | Serious violations | 8 | 3 |
   "
   ```

   ![Pull request de remédiation](../../images/lab-07/lab-07-remediation-pr.png)

### Exercice 7.6 : Vérifier l'amélioration du score

Vous allez relancer l'analyse de l'application de démonstration 001 après avoir appliqué les correctifs pour confirmer que le score d'accessibilité s'est amélioré.

1. Reconstruisez l'application de démonstration avec les correctifs :

   ```bash
   docker build -t a11y-demo-app-001 ./a11y-demo-app-001
   docker stop a11y-001
   docker rm a11y-001
   docker run -d --name a11y-001 -p 8001:8080 a11y-demo-app-001
   ```

2. Lancez le scanner sur l'application mise à jour :

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --format json --output results/demo-001-after.json
   ```

3. Comparez les résultats avant et après :

   ```powershell
   $before = Get-Content results/demo-001.json | ConvertFrom-Json
   $after = Get-Content results/demo-001-after.json | ConvertFrom-Json
   Write-Host "Before: $($before.score)  After: $($after.score)"
   ```

   ![Comparaison des scores avant/après](../../images/lab-07/lab-07-before-after.png)

4. Le score devrait montrer une amélioration significative. Corriger les 5 principales violations augmente généralement le score de 20 à 30 points.

   ![Graphique d'amélioration du score](../../images/lab-07/lab-07-score-improvement.png)

> [!TIP]
> Pour atteindre un score supérieur à 90, des correctifs supplémentaires sont nécessaires au-delà du top 5 : améliorer le contraste des couleurs dans l'ensemble, ajouter des étiquettes de formulaire, corriger la hiérarchie des titres et ajouter une navigation par raccourci. L'agent A11yResolver peut être invoqué de manière itérative pour traiter les violations restantes.

## Point de vérification

Avant de terminer l'atelier, vérifiez :

- [ ] Examiné la définition de l'agent A11yDetector et compris son flux analyse-score-priorisation
- [ ] Lancé le détecteur et reçu un rapport de violations priorisé
- [ ] Examiné la définition de l'agent A11yResolver et son tableau de modèles de correction
- [ ] Appliqué au moins 3 correctifs de remédiation à l'application de démonstration 001
- [ ] Créé une pull request avec une documentation avant/après
- [ ] Relancé l'analyse et confirmé que le score d'accessibilité s'est amélioré

## Félicitations

Vous avez terminé les 8 labos de l'atelier Accessibility Scan Workshop. Voici un résumé de ce que vous avez appris :

| Labo | Ce que vous avez appris |
|------|-------------------------|
| **Labo 00** | Mise en place de l'environnement de développement avec Node.js, Docker et les outils d'analyse |
| **Labo 01** | Exploration des 5 applications de démonstration et correspondance de leurs violations avec les principes POUR du WCAG |
| **Labo 02** | Exécution d'analyses axe-core via l'interface web, le CLI et l'API pour détecter les violations WCAG |
| **Labo 03** | Utilisation d'IBM Equal Access pour une analyse plus large basée sur les politiques et comparaison avec axe-core |
| **Labo 04** | Extension de la couverture avec des vérifications Playwright personnalisées pour les problèmes que les moteurs automatisés manquent |
| **Labo 05** | Génération de la sortie SARIF et téléversement des résultats vers l'onglet Sécurité de GitHub |
| **Labo 06** | Construction de pipelines automatisés avec stratégie matricielle, authentification OIDC et seuils de blocage |
| **Labo 06-ado** | Configuration d'ADO Advanced Security avec intégration SARIF (parcours ADO) |
| **Labo 07** | Utilisation des agents Copilot pour détecter, prioriser et corriger les violations d'accessibilité |
| **Labo 07-ado** | Construction de pipelines YAML ADO pour l'analyse automatisée de l'accessibilité (parcours ADO) |

Vous disposez désormais des compétences nécessaires pour mettre en œuvre une plateforme complète d'analyse de l'accessibilité qui :

- **Analyse les pages web** à l'aide de plusieurs moteurs (axe-core, IBM Equal Access, vérifications Playwright personnalisées)
- **Produit une sortie SARIF unifiée** pour tous les moteurs d'analyse
- **S'intègre à l'onglet Sécurité de GitHub** ou à **ADO Advanced Security** pour une gestion centralisée des alertes
- **Applique des seuils d'accessibilité** dans les pipelines CI/CD avec des niveaux configurables
- **Automatise la remédiation** à l'aide d'agents Copilot alimentés par l'IA
- **S'exécute automatiquement** selon un calendrier et à la demande via GitHub Actions ou les pipelines ADO
