---
permalink: /fr/labs/lab-03
title: "Labo 03 : IBM Equal Access — Analyse complète basée sur les politiques"
description: "Analyser des pages web à l'aide du vérificateur IBM Equal Access pour une analyse d'accessibilité basée sur les politiques."
---

# Labo 03 : IBM Equal Access — Analyse complète basée sur les politiques

| | |
|---|---|
| **Durée** | 30 minutes |
| **Niveau** | Intermédiaire |
| **Prérequis** | [Labo 01](lab-01.md) |

## Objectifs d'apprentissage

À la fin de ce labo, vous serez en mesure de :

- Expliquer en quoi IBM Equal Access diffère de axe-core en termes de couverture des règles et d'approche
- Exécuter une analyse IBM Equal Access sur une application de démonstration à l'aide du scanner
- Comparer les résultats IBM avec les résultats axe-core pour la même page
- Examiner un rapport combiné qui déduplique les résultats entre les moteurs

## Exercices

### Exercice 3.1 : Comprendre IBM Equal Access

Le scanner prend en charge deux moteurs d'accessibilité. Vous allez examiner comment IBM Equal Access complète axe-core.

1. Examinez la comparaison des moteurs :

   | Aspect | axe-core | IBM Equal Access |
   |--------|----------|------------------|
   | **Mainteneur** | Deque Systems | IBM |
   | **Nombre de règles** | ~90 règles | ~400+ règles |
   | **Orientation** | Tests de conformité WCAG | Évaluation basée sur les politiques (WCAG + exigences IBM) |
   | **Types de résultats** | Violation / Réussite / Incomplet | Violation / À examiner / Recommandation |
   | **Points forts** | Rapide, standard de l'industrie, faible taux de faux positifs | Couverture de règles plus large, personnalisation des politiques, conformité gouvernementale |

2. Différences clés à noter :
   - IBM Equal Access utilise le moteur **ACE (Accessibility Conformance Engine)** qui inclut des règles au-delà de WCAG, telles que les exigences spécifiques à IBM.
   - IBM catégorise les résultats en **Violation** (échec avéré), **À examiner** (problème potentiel nécessitant un jugement humain) et **Recommandation** (suggestion de bonne pratique).
   - Le package npm `accessibility-checker` du scanner fournit l'intégration du moteur IBM.

> [!NOTE]
> Les deux moteurs sont complémentaires. axe-core détecte les violations courantes avec une grande fiabilité, tandis qu'IBM Equal Access offre une couverture plus large et détecte des problèmes que axe-core pourrait manquer.

### Exercice 3.2 : Exécuter une analyse IBM sur l'application de démonstration 002

Vous allez analyser une application de démonstration à l'aide du moteur IBM Equal Access.

1. Assurez-vous que l'application de démonstration 002 est en cours d'exécution à l'adresse `http://localhost:8002`.

2. Ouvrez l'interface web du scanner à l'adresse `http://localhost:3000`.

3. Entrez l'URL de l'application de démonstration 002 et sélectionnez les options d'analyse. Si le scanner prend en charge la sélection du moteur, choisissez **IBM Equal Access** ou le mode **Combiné**.

4. Examinez les résultats. IBM Equal Access trouve généralement des problèmes supplémentaires que axe-core ne signale pas, tels que :
   - Des éléments qui **nécessitent un examen** pour l'opérabilité au clavier
   - Des recommandations consultatives pour l'utilisation d'ARIA
   - Des vérifications spécifiques aux politiques pour les interactions de formulaires

   ![Résultats de l'analyse IBM](../../images/lab-03/lab-03-ibm-scan-results.png)

5. Cliquez sur un résultat IBM spécifique pour afficher ses détails. Notez la différence dans les identifiants de règles — les règles IBM utilisent des identifiants comme `WCAG20_Html_HasLang` tandis que axe-core utilise `html-has-lang`.

   ![Détail d'une violation IBM](../../images/lab-03/lab-03-ibm-violation-detail.png)

### Exercice 3.3 : Comparer les résultats IBM et axe-core

Vous allez comparer les résultats des deux moteurs sur la même page.

1. Examinez la comparaison côte à côte pour l'application de démonstration 002 :

   | Catégorie | axe-core | IBM Equal Access |
   |-----------|----------|------------------|
   | Total des résultats | ~20–30 violations | ~40–60 violations + à examiner |
   | Vérification de la langue | `html-has-lang` | `WCAG20_Html_HasLang` |
   | Texte alternatif des images | `image-alt` | `WCAG20_Img_HasAlt` |
   | Contraste des couleurs | `color-contrast` | `IBMA_Color_Contrast_WCAG2AA` |
   | Étiquettes de formulaires | `label` | `WCAG20_Input_ExplicitLabel` |
   | Unique au moteur | Détection des pièges clavier | Éléments à examiner, éléments de recommandation |

   ![Tableau de comparaison](../../images/lab-03/lab-03-comparison-table.png)

2. Notez que certaines violations sont détectées par les deux moteurs sous des noms de règles différents. Le scanner normalise et déduplique ces résultats dans le rapport combiné.

3. Portez attention aux résultats qui apparaissent **uniquement** dans IBM Equal Access. Ceux-ci sont souvent liés à :
   - La validation des attributs ARIA
   - Les définitions de rôles des widgets
   - L'utilisation correcte de `tabindex`
   - L'ordre de lecture et la gestion du focus

### Exercice 3.4 : Examiner le rapport combiné

Le scanner peut fusionner les résultats des deux moteurs en un seul rapport dédupliqué.

1. Exécutez une analyse combinée (les deux moteurs) sur l'application de démonstration 002 via le CLI :

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8002 --format json --output results/demo-002-combined.json
   ```

2. Ouvrez `results/demo-002-combined.json` et examinez la structure. Le rapport combiné :
   - Liste chaque violation unique une seule fois, même si les deux moteurs l'ont détectée
   - Indique quel(s) moteur(s) ont signalé chaque résultat
   - Conserve le niveau d'impact le plus élevé lorsque les moteurs divergent

   ![Sortie du rapport combiné](../../images/lab-03/lab-03-combined-report.png)

3. Examinez le fonctionnement de la déduplication :

   ![Logique de déduplication](../../images/lab-03/lab-03-deduplication.png)

   - Les règles sont associées par leur critère de succès WCAG cible
   - Lorsque les deux moteurs trouvent la même violation sur le même élément, une seule entrée est créée
   - Les métadonnées spécifiques à chaque moteur sont conservées pour la traçabilité

> [!TIP]
> L'utilisation des deux moteurs ensemble offre la couverture la plus complète. Le faible taux de faux positifs de axe-core combiné à l'ensemble de règles plus large d'IBM détecte des violations que l'un ou l'autre moteur seul manquerait.

## Point de vérification

Avant de continuer, vérifiez que vous :

- [ ] Pouvez expliquer les différences entre axe-core et IBM Equal Access
- [ ] Avez exécuté une analyse IBM sur l'application de démonstration 002 et examiné les résultats
- [ ] Avez identifié au moins 2 résultats que IBM détecte mais pas axe-core
- [ ] Avez examiné un rapport combiné montrant les résultats dédupliqués des deux moteurs

## Prochaines étapes

Passez au [Labo 04 : Vérifications Playwright personnalisées — Inspection manuelle](lab-04.md).
