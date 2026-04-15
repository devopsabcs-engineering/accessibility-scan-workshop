---
nav_exclude: true
lang: fr
permalink: /fr/labs/lab-06
title: "Labo 06 : Pipelines GitHub Actions et portes de contrôle de scan"
description: "Construisez des pipelines de scan automatisés avec une stratégie matricielle, l'authentification OIDC et des portes de qualité basées sur des seuils."
---

# Labo 06 : Pipelines GitHub Actions et portes de contrôle de scan

| | |
|---|---|
| **Durée** | 40 minutes |
| **Niveau** | Avancé |
| **Prérequis** | [Labo 05](lab-05.md), abonnement Azure (exercices 6.3–6.5) |

> [!TIP]
> Ce labo couvre le workflow **GitHub Actions**. Pour la variante
> Azure DevOps, voir [Labo 06-ado : Sécurité avancée ADO](lab-06-ado.md).

## Objectifs d'apprentissage

À la fin de ce labo, vous serez en mesure de :

- Examiner la structure du workflow CI et comprendre son pipeline de build/test/scan
- Comprendre la stratégie matricielle du workflow de scan pour analyser plusieurs applications
- Configurer l'authentification OIDC pour GitHub Actions vers Azure
- Initialiser les dépôts d'applications de démonstration à l'aide des scripts fournis
- Déclencher et surveiller les workflows de déploiement multi-applications
- Configurer des portes de contrôle basées sur des seuils pour imposer des scores d'accessibilité minimaux

## Exercices

### Exercice 6.1 : Examiner le workflow CI

Vous allez examiner le pipeline CI du scanner pour comprendre comment les tests d'accessibilité s'intègrent dans le processus de build.

1. Ouvrez `.github/workflows/ci.yml` dans votre éditeur.

2. Examinez la structure du workflow :

   ```yaml
   name: CI

   on:
     push:
       branches: [main]
     pull_request:
       branches: [main]

   jobs:
     lint:
       # ESLint checks...
     test:
       # Vitest unit tests...
     build:
       # Next.js production build...
     e2e:
       # Playwright end-to-end tests including self-scan...
   ```

3. Notez les étapes clés :

   | Étape | Objectif |
   |-------|----------|
   | **lint** | Exécute ESLint pour assurer la qualité du code et détecter les problèmes courants |
   | **test** | Exécute les tests unitaires Vitest pour les composants du scanner (moteur, analyseurs, formateurs) |
   | **build** | Crée un build de production Next.js pour vérifier la compilation |
   | **e2e** | Exécute les tests Playwright qui analysent les propres pages du scanner pour l'accessibilité |

   ![Structure du workflow CI](../../images/lab-06/lab-06-ci-workflow.png)

4. Le job `e2e` est particulièrement intéressant — il effectue un **auto-scan**, analysant la propre interface utilisateur du scanner pour détecter les violations d'accessibilité. Cela garantit que l'outil de scan lui-même respecte les normes WCAG.

### Exercice 6.2 : Examiner le workflow de scan

Vous allez examiner le workflow de scan multi-applications qui analyse les 5 applications de démonstration à l'aide d'une stratégie matricielle.

1. Ouvrez `.github/workflows/a11y-scan.yml` dans votre éditeur.

2. Examinez la stratégie matricielle :

   ```yaml
   strategy:
     matrix:
       include:
         - app: a11y-demo-app-001
           url: https://a11y-demo-app-001.azurewebsites.net
         - app: a11y-demo-app-002
           url: https://a11y-demo-app-002.azurewebsites.net
         # ... apps 003-005
   ```

3. Chaque job de la matrice :
   - Analyse l'application de démonstration déployée à son URL Azure
   - Génère une sortie SARIF
   - Téléverse les résultats vers l'onglet Sécurité via `codeql-action/upload-sarif`

   ![Stratégie matricielle du workflow de scan](../../images/lab-06/lab-06-scan-workflow.png)

4. Examinez le workflow `scan-all.yml` qui distribue les jobs de scan aux 5 dépôts associés :

   ```yaml
   # scan-all.yml dispatches the a11y-scan workflow
   # to each demo app repository
   ```

### Exercice 6.3 : Configurer l'authentification OIDC

> [!NOTE]
> Cet exercice nécessite un abonnement Azure (niveau journée complète uniquement).

Vous allez configurer des identifiants fédérés OpenID Connect (OIDC) pour que GitHub Actions puisse s'authentifier auprès d'Azure sans stocker de secrets.

1. Assurez-vous d'être connecté à Azure CLI :

   ```bash
   az login
   ```

2. Exécutez le script de configuration OIDC depuis le dépôt du scanner :

   ```powershell
   ./scripts/setup-oidc.ps1
   ```

3. Le script effectue 5 étapes :
   - **Inscription d'application** — Crée ou récupère une application Azure AD nommée `a11y-scanner-github-actions`
   - **Identifiants fédérés** — Crée des identifiants OIDC pour le dépôt du scanner et chaque dépôt d'application de démonstration
   - **Principal de service** — Crée ou récupère le principal de service
   - **Attribution de rôle** — Accorde le rôle `Contributor` sur l'abonnement
   - **Résumé** — Affiche l'ID client, l'ID de locataire et l'ID d'abonnement

   ![Sortie de la configuration OIDC](../../images/lab-06/lab-06-oidc-setup.png)

4. Configurez les valeurs obtenues en tant que secrets du dépôt GitHub :

   ```bash
   gh secret set AZURE_CLIENT_ID --body "<client-id>"
   gh secret set AZURE_TENANT_ID --body "<tenant-id>"
   gh secret set AZURE_SUBSCRIPTION_ID --body "<subscription-id>"
   ```

### Exercice 6.4 : Initialiser les dépôts d'applications de démonstration

> [!NOTE]
> Cet exercice nécessite un abonnement Azure (niveau journée complète uniquement).

Vous allez créer les 5 dépôts d'applications de démonstration à partir des répertoires de modèles.

1. Exécutez le script d'initialisation :

   ```powershell
   ./scripts/bootstrap-demo-apps.ps1
   ```

2. Le script crée 5 dépôts publics sous votre compte GitHub :
   - `a11y-demo-app-001` à `a11y-demo-app-005`
   - Chaque dépôt reçoit le code du répertoire de modèle correspondant
   - Les secrets OIDC, les sujets et les environnements sont configurés automatiquement

3. Vérifiez que les dépôts ont été créés :

   ```bash
   gh repo list --limit 10 | grep a11y-demo-app
   ```

### Exercice 6.5 : Déclencher le workflow de déploiement global

> [!NOTE]
> Cet exercice nécessite un abonnement Azure (niveau journée complète uniquement).

Vous allez déployer les 5 applications de démonstration sur Azure.

1. Déclenchez le workflow de déploiement global :

   ```bash
   gh workflow run deploy-all.yml
   ```

2. Surveillez la progression du déploiement :

   ```bash
   gh run watch
   ```

   ![Page des exécutions GitHub Actions](../../images/lab-06/lab-06-actions-runs.png)

3. Le workflow de déploiement global distribue le CI/CD à chaque dépôt d'application de démonstration. Chaque application est déployée dans son propre groupe de ressources Azure (`rg-a11y-demo-001` à `rg-a11y-demo-005`).

   ![Jobs de la matrice en cours d'exécution](../../images/lab-06/lab-06-matrix-jobs.png)

4. Après le déploiement, vérifiez que les applications sont accessibles :

   ```bash
   curl -s -o /dev/null -w "%{http_code}" https://a11y-demo-app-001.azurewebsites.net
   ```

   ![Statut du déploiement](../../images/lab-06/lab-06-deploy-status.png)

> [!IMPORTANT]
> Les applications de démonstration sont déployées sur Azure App Service et engendrent des coûts réels. Exécutez le workflow de démontage ou supprimez les groupes de ressources après avoir terminé l'atelier.

### Exercice 6.6 : Configurer les portes de seuil

Vous allez configurer des seuils de score de scan pour imposer des normes d'accessibilité minimales.

1. Examinez la configuration des seuils du scanner. Le CLI prend en charge un indicateur `--threshold` :

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --threshold 70
   ```

   La commande se termine avec un code non nul si le score est inférieur au seuil, ce qui fait échouer le pipeline.

2. Créez ou mettez à jour un workflow qui utilise le seuil comme porte de qualité :

   ```yaml
   - name: Scan for accessibility
     run: |
       npx ts-node src/cli/commands/scan.ts \
         --url ${{ matrix.url }} \
         --threshold 70 \
         --format sarif \
         --output results/${{ matrix.app }}.sarif
   ```

3. Lorsque le score de scan est inférieur au seuil, l'étape échoue et le workflow est marqué comme échoué. Cela empêche le déploiement d'applications qui ne respectent pas la norme d'accessibilité minimale.

   ![Configuration des seuils](../../images/lab-06/lab-06-threshold-config.png)

> [!TIP]
> Commencez avec un seuil bas (par exemple, 30) pour les applications existantes présentant de nombreuses violations, et augmentez-le progressivement à mesure que les violations sont corrigées. Un seuil de 70 est un objectif raisonnable pour les applications en production.

## Point de vérification

Avant de continuer, vérifiez :

- [ ] Examiné la structure du workflow CI et compris le modèle d'auto-scan
- [ ] Compris la stratégie matricielle dans le workflow de scan
- [ ] (Journée complète) Configuré l'authentification OIDC pour GitHub Actions
- [ ] (Journée complète) Initialisé les dépôts d'applications de démonstration à l'aide du script
- [ ] (Journée complète) Déclenché et surveillé un workflow de déploiement global
- [ ] Compris comment les portes de seuil imposent des scores d'accessibilité minimaux

## Prochaines étapes

Passez au [Labo 07 : Workflows de remédiation avec les agents Copilot](lab-07.md).
