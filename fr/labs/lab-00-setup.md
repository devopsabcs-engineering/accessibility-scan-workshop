---
nav_exclude: true
permalink: /fr/labs/lab-00-setup
title: "Lab 00 : Prérequis et configuration de l'environnement"
description: "Configurez votre environnement avec tous les outils nécessaires pour l'analyse d'accessibilité WCAG 2.2."
---

# Lab 00 : Prérequis et configuration de l'environnement

> [!NOTE]
> Cet atelier fait partie du [Agentic Accelerator Framework](https://github.com/devopsabcs-engineering/agentic-accelerator-framework).

| | |
|---|---|
| **Durée** | 30 minutes |
| **Niveau** | Débutant |
| **Prérequis** | Aucun |

## Objectifs d'apprentissage

À la fin de ce lab, vous serez en mesure de :

- Forker et cloner le dépôt `accessibility-scan-demo-app`
- Installer les outils requis (Node.js, Docker, GitHub CLI, Azure CLI, PowerShell 7+, Charm freeze)
- Vérifier toutes les installations d'outils avec des contrôles de version
- Installer les dépendances du scanner et les navigateurs Playwright
- Démarrer le scanner d'accessibilité localement et confirmer son fonctionnement

## Exercices

### Exercice 0.1 : Forker et cloner les dépôts

Vous allez forker le dépôt du scanner afin d'avoir votre propre copie pour travailler.

1. Ouvrez un terminal (PowerShell 7+).

2. Forkez et clonez le dépôt du scanner à l'aide de GitHub CLI :

   ```bash
   gh repo fork devopsabcs-engineering/accessibility-scan-demo-app --clone
   ```

3. Accédez au répertoire cloné :

   ```bash
   cd accessibility-scan-demo-app
   ```

4. Vérifiez que le remote pointe vers votre fork :

   ```bash
   git remote -v
   ```

   Vous devriez voir votre nom d'utilisateur GitHub dans l'URL `origin`.

5. Forkez et clonez le dépôt de l'atelier :

   ```bash
   gh repo fork devopsabcs-engineering/accessibility-scan-workshop --clone
   ```

> [!TIP]
> Si vous n'avez pas encore installé GitHub CLI, vous l'installerez dans l'exercice suivant. Vous pouvez également forker via l'interface web GitHub et cloner manuellement avec `git clone`.

### Exercice 0.2 : Installer les outils requis

Vous allez installer les outils utilisés tout au long de l'atelier.

1. **Node.js 20+** — Téléchargez depuis [nodejs.org](https://nodejs.org/) ou installez via un gestionnaire de paquets :

   ```powershell
   # Windows
   winget install OpenJS.NodeJS.LTS
   ```

   ```bash
   # macOS
   brew install node@20
   ```

2. **Docker Desktop** — Téléchargez depuis [docker.com](https://www.docker.com/products/docker-desktop/) ou installez via un gestionnaire de paquets :

   ```powershell
   # Windows
   winget install Docker.DockerDesktop
   ```

3. **GitHub CLI** — Installez le CLI `gh` :

   ```powershell
   # Windows
   winget install GitHub.cli
   ```

   ```bash
   # macOS
   brew install gh
   ```

4. **Azure CLI** — Installez `az` :

   ```powershell
   # Windows
   winget install Microsoft.AzureCLI
   ```

   ```bash
   # macOS
   brew install azure-cli
   ```

5. **PowerShell 7+** — Installez la dernière version de PowerShell :

   ```powershell
   # Windows
   winget install Microsoft.PowerShell
   ```

   ```bash
   # macOS
   brew install powershell/tap/powershell
   ```

6. **Charm freeze** — Installez l'outil de capture d'écran de terminal :

   ```powershell
   # Windows
   winget install charmbracelet.freeze
   ```

   ```bash
   # macOS
   brew install charmbracelet/tap/freeze
   ```

> [!TIP]
> Sous Windows, exécutez ces commandes dans un terminal PowerShell avec élévation de privilèges. Redémarrez votre terminal après l'installation afin que les outils soient disponibles dans votre PATH.

### Exercice 0.3 : Vérifier les versions des outils

Vous allez exécuter des contrôles de version pour confirmer que chaque outil est correctement installé.

1. **Node.js :**

   ```bash
   node --version
   ```

   Sortie attendue : `v20.x.x` ou supérieure.

   ![Sortie de la version Node.js](../../images/lab-00/lab-00-node-version.png)

2. **Docker :**

   ```bash
   docker --version
   ```

   Sortie attendue : `Docker version 2x.x.x` ou supérieure.

   ![Sortie de la version Docker](../../images/lab-00/lab-00-docker-version.png)

3. **GitHub CLI :**

   ```bash
   gh --version
   ```

   ![Sortie de la version GitHub CLI](../../images/lab-00/lab-00-gh-version.png)

4. **Azure CLI :**

   ```bash
   az --version
   ```

   ![Sortie de la version Azure CLI](../../images/lab-00/lab-00-az-version.png)

5. **PowerShell :**

   ```powershell
   $PSVersionTable.PSVersion
   ```

   Sortie attendue : `7.x.x` ou supérieure.

   ![Sortie de la version PowerShell](../../images/lab-00/lab-00-pwsh-version.png)

6. **Charm freeze :**

   ```bash
   freeze --version
   ```

   ![Sortie de la version Charm freeze](../../images/lab-00/lab-00-freeze-version.png)

> [!CAUTION]
> Si un outil échoue au contrôle de version, résolvez le problème d'installation avant de continuer. Les labs suivants dépendent de la disponibilité de tous les outils.

### Exercice 0.4 : Installer les dépendances du scanner

Vous allez installer les dépendances Node.js et le navigateur Playwright requis par le scanner.

1. Accédez à la racine du dépôt du scanner :

   ```bash
   cd accessibility-scan-demo-app
   ```

2. Installez les dépendances Node.js :

   ```bash
   npm install
   ```

3. Installez le navigateur Chromium de Playwright :

   ```bash
   npx playwright install --with-deps chromium
   ```

> [!NOTE]
> Le téléchargement du navigateur Playwright fait environ 150 Mo. Ce navigateur est utilisé par le scanner pour afficher les pages et exécuter les vérifications d'accessibilité.

### Exercice 0.5 : Démarrer le scanner localement

Vous allez démarrer le scanner d'accessibilité et vérifier son fonctionnement.

1. Démarrez le scanner à l'aide du script de démarrage local :

   ```powershell
   ./start-local.ps1
   ```

   Le script lance le serveur de développement Next.js sur le port 3000.

2. Ouvrez votre navigateur et accédez à :

   ```text
   http://localhost:3000
   ```

3. Vérifiez que la page d'accueil du scanner se charge avec le formulaire d'analyse visible.

   ![Page d'accueil du scanner](../../images/lab-00/lab-00-scanner-home.png)

4. Laissez le scanner en cours d'exécution pour les labs suivants.

> [!TIP]
> Si le port 3000 est déjà utilisé, arrêtez le processus en conflit ou exécutez d'abord `./stop-local.ps1`. Vous pouvez également démarrer le scanner avec Docker en utilisant `./start-local.ps1 -Mode docker`.

## Point de vérification

Avant de continuer, vérifiez :

- [ ] Dépôt forké et cloné localement
- [ ] Les 6 outils installés et retournant une sortie de version (Node.js, Docker, gh, az, pwsh, freeze)
- [ ] `npm install` terminé sans erreurs
- [ ] Navigateur Chromium de Playwright installé
- [ ] Scanner en cours d'exécution à `http://localhost:3000`

## Étapes suivantes

Passez au [Lab 01 : Explorer les applications de démonstration et les violations WCAG](lab-01.md).
