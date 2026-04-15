---
permalink: /fr/labs/lab-02
title: "Labo 02 : axe-core — Tests d'accessibilité automatisés"
description: "Analyser des pages web à la recherche de violations WCAG à l'aide d'axe-core via l'interface web du scanner, la CLI et l'API."
---

# Labo 02 : axe-core — Tests d'accessibilité automatisés

| | |
|---|---|
| **Durée** | 35 minutes |
| **Niveau** | Intermédiaire |
| **Prérequis** | [Labo 01](lab-01.md) |

## Objectifs d'apprentissage

À la fin de ce labo, vous serez en mesure de :

- Analyser une page web à la recherche de violations d'accessibilité à l'aide de l'interface web du scanner
- Interpréter les résultats d'analyse, y compris les violations, les succès, les vérifications incomplètes et les niveaux d'impact
- Exécuter des analyses d'accessibilité via la CLI avec une sortie JSON
- Appeler l'API du scanner de manière programmatique pour analyser une URL
- Comparer les résultats d'analyse entre plusieurs applications de démonstration

## Exercices

### Exercice 2.1 : Analyse via l'interface web

Vous utiliserez l'interface web du scanner pour exécuter votre première analyse d'accessibilité automatisée.

1. Assurez-vous que le scanner est en cours d'exécution à l'adresse `http://localhost:3000` (démarré dans le Labo 00, Exercice 0.5).

2. Assurez-vous que l'application de démonstration 001 est en cours d'exécution à l'adresse `http://localhost:8001` (démarrée dans le Labo 01, Exercice 1.2).

3. Ouvrez le scanner à l'adresse `http://localhost:3000` dans votre navigateur.

4. Entrez l'URL de l'application de démonstration dans le formulaire d'analyse :

   ```text
   http://host.docker.internal:8001
   ```

   > [!NOTE]
   > Si votre scanner s'exécute via Docker, utilisez `http://host.docker.internal:8001` pour atteindre l'application de démonstration. Si les deux s'exécutent nativement (sans Docker), utilisez `http://localhost:8001`.

5. Cliquez sur **Scan** et attendez que les résultats apparaissent.

   ![Analyse via l'interface web en cours](../../images/lab-02/lab-02-web-ui-scan.png)

### Exercice 2.2 : Interpréter les résultats d'analyse

Vous apprendrez à lire et comprendre la sortie de l'analyse.

1. Examinez la page des résultats d'analyse. Le scanner affiche les résultats dans plusieurs catégories :

   | Catégorie | Description |
   |-----------|-------------|
   | **Violations** | Règles échouées — problèmes d'accessibilité confirmés |
   | **Succès** | Règles réussies — aucun problème détecté |
   | **Incomplet** | Règles nécessitant une vérification manuelle |
   | **Non applicable** | Règles qui ne s'appliquent pas au contenu de la page |

2. Concentrez-vous sur la section **Violations**. Chaque violation comprend :

   - **Identifiant de règle** — L'identifiant de la règle axe-core (par exemple, `image-alt`, `color-contrast`)
   - **Impact** — Niveau de gravité : critique, sérieux, modéré ou mineur
   - **Description** — Ce que la règle vérifie
   - **Critères WCAG** — Le critère de succès WCAG auquel la règle correspond
   - **Éléments concernés** — Éléments HTML ayant déclenché la violation

   ![Aperçu des résultats d'analyse](../../images/lab-02/lab-02-scan-results.png)

3. Cliquez sur une violation spécifique pour développer ses détails. Notez le sélecteur CSS et l'extrait HTML pour chaque élément concerné.

   ![Vue détaillée d'une violation](../../images/lab-02/lab-02-violation-detail.png)

4. Examinez la distribution des niveaux d'impact. L'application de démonstration 001 produit généralement :
   - **Critique** : Attribut lang manquant, pièges clavier
   - **Sérieux** : Texte alternatif manquant, contraste insuffisant, libellés de formulaire manquants
   - **Modéré** : Hiérarchie des titres, en-têtes de tableau manquants
   - **Mineur** : Éléments obsolètes

### Exercice 2.3 : Analyse via la CLI

Vous exécuterez la même analyse depuis la ligne de commande avec une sortie JSON.

1. Ouvrez un terminal à la racine du dépôt du scanner.

2. Exécutez la commande d'analyse CLI :

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --format json
   ```

3. Examinez la sortie JSON dans votre terminal. La structure comprend :

   ```json
   {
     "url": "http://localhost:8001",
     "score": 25,
     "violations": [...],
     "passes": [...],
     "incomplete": [...]
   }
   ```

4. Enregistrez la sortie dans un fichier pour une analyse ultérieure :

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --format json --output results/demo-001.json
   ```

   ![Sortie de l'analyse CLI](../../images/lab-02/lab-02-cli-output.png)

> [!TIP]
> L'option `--format` prend en charge `json`, `sarif` et `junit`. Vous explorerez la sortie SARIF en détail dans le Labo 05.

### Exercice 2.4 : Analyse via l'API

Vous appellerez l'API REST du scanner pour démontrer l'analyse programmatique.

1. Avec le scanner en cours d'exécution à l'adresse `http://localhost:3000`, envoyez une requête POST :

   ```bash
   curl -X POST http://localhost:3000/api/scan \
     -H "Content-Type: application/json" \
     -d '{"url":"http://localhost:8001"}'
   ```

   Sur PowerShell :

   ```powershell
   Invoke-RestMethod -Uri "http://localhost:3000/api/scan" `
     -Method Post `
     -ContentType "application/json" `
     -Body '{"url":"http://localhost:8001"}'
   ```

2. L'API retourne une réponse JSON avec la même structure que la sortie CLI.

   ![Réponse de l'API](../../images/lab-02/lab-02-api-response.png)

3. Notez le champ `score` dans la réponse. Il s'agit du score d'accessibilité sur une échelle de 0 à 100 que le scanner calcule en fonction du ratio violations/succès.

### Exercice 2.5 : Comparer les résultats entre les applications de démonstration

Vous analyserez plusieurs applications de démonstration et comparerez leurs nombres de violations.

1. Démarrez les applications de démonstration restantes si elles ne sont pas déjà en cours d'exécution :

   ```bash
   docker build -t a11y-demo-app-002 ./a11y-demo-app-002
   docker run -d --name a11y-002 -p 8002:8080 a11y-demo-app-002

   docker build -t a11y-demo-app-003 ./a11y-demo-app-003
   docker run -d --name a11y-003 -p 8003:8080 a11y-demo-app-003

   docker build -t a11y-demo-app-004 ./a11y-demo-app-004
   docker run -d --name a11y-004 -p 8004:8080 a11y-demo-app-004

   docker build -t a11y-demo-app-005 ./a11y-demo-app-005
   docker run -d --name a11y-005 -p 8005:8080 a11y-demo-app-005
   ```

2. Analysez chaque application via la CLI et comparez les résultats :

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --format json --output results/demo-001.json
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8002 --format json --output results/demo-002.json
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8003 --format json --output results/demo-003.json
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8004 --format json --output results/demo-004.json
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8005 --format json --output results/demo-005.json
   ```

3. Comparez les nombres de violations. Tendance attendue :

   | Application | Score attendu | Différences notables |
   |-------------|--------------|----------------------|
   | 001 | Bas (~25) | Violations de référence |
   | 002 | Le plus bas (~20) | Violations supplémentaires liées à l'interface à onglets et à la carte d'images |
   | 003 | Bas (~25) | Similaire à 001 |
   | 004 | Bas (~25) | Similaire à 001 |
   | 005 | Bas (~25) | Similaire à 001 |

   ![Comparaison multi-applications](../../images/lab-02/lab-02-multi-app-comparison.png)

> [!NOTE]
> L'application 002 (C# / ASP.NET) présente généralement le plus de violations car elle inclut une interface à onglets personnalisée inaccessible et une carte d'images sans texte alternatif, en plus de toutes les violations partagées par les autres applications.

## Point de vérification

Avant de continuer, vérifiez que :

- [ ] Vous avez analysé l'application de démonstration 001 via l'interface web et examiné les résultats
- [ ] Vous pouvez expliquer la différence entre les violations, les succès et les vérifications incomplètes
- [ ] Vous avez exécuté avec succès une analyse CLI avec la sortie JSON enregistrée dans un fichier
- [ ] Vous avez appelé l'API du scanner et reçu une réponse JSON
- [ ] Vous avez analysé au moins 2 applications de démonstration et comparé leurs nombres de violations

## Prochaines étapes

Passez au [Labo 03 : IBM Equal Access — Analyse complète de conformité aux politiques](lab-03.md).
