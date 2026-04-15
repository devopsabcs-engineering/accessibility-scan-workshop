---
nav_exclude: true
permalink: /fr/labs/lab-04
title: "Labo 04 : Vérifications Playwright personnalisées — Automatisation de l'inspection manuelle"
description: "Étendez la couverture du scanner avec des vérifications d'accessibilité personnalisées basées sur Playwright, au-delà des moteurs automatisés."
---

# Labo 04 : Vérifications Playwright personnalisées — Automatisation de l'inspection manuelle

| | |
|---|---|
| **Durée** | 35 minutes |
| **Niveau** | Intermédiaire |
| **Prérequis** | [Labo 01](lab-01.md) |

## Objectifs d'apprentissage

À la fin de ce labo, vous serez en mesure de :

- Expliquer pourquoi des vérifications personnalisées sont nécessaires au-delà d'axe-core et d'IBM Equal Access
- Examiner les vérifications personnalisées existantes dans le code source du scanner
- Comprendre comment Playwright teste la navigation au clavier et la gestion du focus
- Écrire une nouvelle vérification personnalisée pour détecter les éléments HTML obsolètes
- Exécuter le scanner mis à jour et vérifier que la nouvelle vérification produit des résultats

## Exercices

### Exercice 4.1 : Examiner le code source des vérifications personnalisées

Les moteurs automatisés comme axe-core ne peuvent pas détecter tous les problèmes d'accessibilité. Le scanner inclut des vérifications personnalisées basées sur Playwright pour les problèmes qui nécessitent une interaction avec le DOM ou une inspection visuelle.

1. Ouvrez le fichier source des vérifications personnalisées dans votre éditeur :

   ```text
   src/lib/scanner/custom-checks.ts
   ```

2. Examinez les vérifications existantes :

   | Fonction de vérification | Ce qu'elle détecte | Critère WCAG |
   |---------------|-----------------|----------------|
   | `checkAmbiguousLinkText` | Liens avec un texte vague comme « click here », « read more » ou « learn more » | 2.4.4 Fonction du lien |
   | `checkAriaCurrentPage` | Éléments de navigation sans `aria-current="page"` sur le lien actif | 1.3.1 Information et relations |
   | `checkEmphasisStrongSemantics` | Utilisation présentationnelle de `<b>` / `<i>` au lieu des balises sémantiques `<strong>` / `<em>` | 1.3.1 Information et relations |
   | `checkDiscountPriceAccessibility` | Prix barrés (`<del>` / `<s>`) sans contexte pour les lecteurs d'écran | 1.1.1 Contenu non textuel |
   | `checkStickyElementOverlap` | En-têtes ou pieds de page fixes qui pourraient chevaucher le contenu lors du défilement | 2.4.11 Focus non masqué |

3. Notez le modèle de fonction de vérification. Chaque fonction :
   - Prend un objet Playwright `Page`
   - Retourne un `CustomCheckResult` ou `null` (null si aucune violation n'est trouvée)
   - Utilise `page.evaluate()` pour interroger le DOM
   - Inclut le niveau d'impact, le texte d'aide et les sélecteurs des éléments concernés

   ![Code source des vérifications personnalisées](../../images/lab-04/lab-04-custom-checks-source.png)

### Exercice 4.2 : Exécuter le scanner avec les vérifications personnalisées

Vous allez exécuter une analyse qui inclut les vérifications personnalisées et examiner les résultats supplémentaires.

1. Analysez l'application de démonstration 001 avec le scanner (les vérifications personnalisées s'exécutent automatiquement) :

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --format json --output results/demo-001-custom.json
   ```

2. Ouvrez `results/demo-001-custom.json` et recherchez les résultats avec le préfixe `custom-` dans leurs identifiants de règle. Ce sont les résultats des vérifications personnalisées.

3. Vous devriez voir des résultats pour :
   - **Texte de lien ambigu** — L'application de démonstration 001 utilise des liens « click here » partout
   - **aria-current manquant** — La barre de navigation ne marque pas la page active

   ![Résultats des vérifications personnalisées](../../images/lab-04/lab-04-custom-check-results.png)

> [!NOTE]
> Les vérifications personnalisées complètent les moteurs automatisés. axe-core vérifie `link-name` (si un lien possède un texte accessible), tandis que la vérification personnalisée `checkAmbiguousLinkText` va plus loin en signalant les liens qui ont du texte mais dont le texte n'est pas suffisamment descriptif.

### Exercice 4.3 : Comprendre les tests de navigation au clavier

De nombreux problèmes d'accessibilité n'apparaissent que lors de l'interaction au clavier. Vous allez examiner comment le scanner teste l'accessibilité au clavier.

1. Les applications de démonstration incluent un piège clavier délibéré. L'application de démonstration 001 contient ce JavaScript :

   ```javascript
   document.addEventListener('keydown', function(e) {
     if (e.key === 'Tab') { }
   });
   ```

   Cela intercepte la touche `Tab` et ne fait rien, piégeant les utilisateurs du clavier sur la page.

2. De plus, tous les éléments interactifs (boutons) sont implémentés comme des éléments `<div>` avec des gestionnaires `onclick` au lieu d'éléments `<button>` :

   ```html
   <!-- Inaccessible -->
   <div class="btn" onclick="bookFlight()">Book Now</div>

   <!-- Accessible -->
   <button onclick="bookFlight()">Book Now</button>
   ```

3. Les vérifications personnalisées du scanner peuvent détecter certains problèmes de clavier en :
   - Évaluant si les éléments interactifs ont des rôles appropriés
   - Vérifiant la présence de `tabindex` sur les éléments non interactifs utilisés comme contrôles
   - Détectant les écouteurs d'événements qui suppriment le comportement clavier par défaut

   ![Tests de navigation au clavier](../../images/lab-04/lab-04-keyboard-test.png)

> [!TIP]
> Pour les tests manuels au clavier, appuyez sur `Tab` pour avancer, `Maj+Tab` pour reculer, `Entrée` pour activer les boutons et les liens, et `Espace` pour basculer les cases à cocher et les boutons. Chaque élément interactif doit être accessible et utilisable uniquement au clavier.

### Exercice 4.4 : Écrire une nouvelle vérification personnalisée

Vous allez créer une vérification personnalisée pour détecter les éléments `<marquee>`, qui sont obsolètes et causent des violations WCAG 2.3.1.

1. Ouvrez `src/lib/scanner/custom-checks.ts` dans votre éditeur.

2. Ajoutez une nouvelle fonction de vérification avant la fonction `runCustomChecks` :

   ```typescript
   async function checkDeprecatedMarquee(page: Page): Promise<CustomCheckResult | null> {
     const marquees = await page.evaluate(() => {
       const elements = document.querySelectorAll('marquee');
       if (elements.length === 0) return null;
       return Array.from(elements).map((el) => ({
         selector: 'marquee',
         html: el.outerHTML.substring(0, 200),
       }));
     });

     if (!marquees) return null;

     return {
       id: 'custom-deprecated-marquee',
       impact: 'serious',
       description: 'Page contains deprecated <marquee> elements that cause distracting motion',
       help: 'Remove <marquee> elements and use CSS animations with prefers-reduced-motion support instead',
       helpUrl: 'https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html',
       wcag: ['2.2.2', '2.3.1'],
       nodes: marquees.map((m) => ({
         target: [m.selector],
         html: m.html,
       })),
     };
   }
   ```

   ![Code de la nouvelle vérification personnalisée](../../images/lab-04/lab-04-new-check-code.png)

3. Ajoutez la nouvelle vérification au tableau de vérifications de la fonction `runCustomChecks` :

   ```typescript
   const checks = [
     checkAmbiguousLinkText,
     checkAriaCurrentPage,
     checkEmphasisStrongSemantics,
     checkDiscountPriceAccessibility,
     checkStickyElementOverlap,
     checkDeprecatedMarquee,  // Add this line
   ];
   ```

4. Enregistrez le fichier.

### Exercice 4.5 : Exécuter le scanner mis à jour

Vous allez vérifier que votre nouvelle vérification personnalisée détecte l'élément `<marquee>` dans l'application de démonstration 001.

1. Exécutez le scanner sur l'application de démonstration 001 :

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --format json --output results/demo-001-marquee.json
   ```

2. Recherchez `custom-deprecated-marquee` dans la sortie :

   ```bash
   grep "custom-deprecated-marquee" results/demo-001-marquee.json
   ```

   Sur PowerShell :

   ```powershell
   Select-String -Path results/demo-001-marquee.json -Pattern "custom-deprecated-marquee"
   ```

3. La vérification devrait détecter l'élément `<marquee>` que l'application de démonstration 001 utilise pour sa bannière défilante.

   ![Résultats de la nouvelle vérification](../../images/lab-04/lab-04-new-check-results.png)

> [!WARNING]
> Annulez vos modifications dans `custom-checks.ts` après cet exercice si vous ne souhaitez pas conserver la vérification personnalisée, ou validez la modification dans votre fork. Les labos suivants utilisent le code original du scanner.

## Point de vérification

Avant de continuer, vérifiez que :

- [ ] Vous avez examiné les vérifications personnalisées existantes dans `custom-checks.ts`
- [ ] Vous avez exécuté une analyse et identifié les résultats des vérifications personnalisées dans la sortie
- [ ] Vous pouvez expliquer pourquoi les vérifications personnalisées complètent les moteurs automatisés
- [ ] Vous avez écrit et testé avec succès une nouvelle vérification personnalisée pour les éléments `<marquee>`
- [ ] La nouvelle vérification a produit des résultats lors de l'analyse de l'application de démonstration 001

## Prochaines étapes

Passez au [Labo 05 : Sortie SARIF et onglet Sécurité GitHub](lab-05.md).
