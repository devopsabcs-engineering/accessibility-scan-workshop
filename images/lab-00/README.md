<!-- markdownlint-disable-file -->
# Lab 00: Prerequisites and Environment Setup — Screenshot Inventory

Screenshots referenced by [Lab 00](../../labs/lab-00-setup.md).

| Filename | Description | Method | Phase |
|----------|-------------|--------|-------|
| lab-00-node-version.png | Node.js version output | freeze | 1 |
| lab-00-docker-version.png | Docker version output | freeze | 1 |
| lab-00-gh-version.png | GitHub CLI version output | freeze | 1 |
| lab-00-az-version.png | Azure CLI version output | freeze | 1 |
| lab-00-pwsh-version.png | PowerShell version output | freeze | 1 |
| lab-00-freeze-version.png | Charm freeze version output | freeze | 1 |
| lab-00-scanner-home.png | Scanner home page at localhost:3000 | playwright | 2 |

## Capture Methods

| Method | Tool | Command |
|--------|------|---------|
| freeze | Charm freeze | `freeze --execute "command" --output file.png` |
| freeze-file | Charm freeze | `freeze --output file.png --show-line-numbers path/to/file` |
| playwright | Playwright | `npx playwright screenshot --url URL --output file.png` |

## Phases

| Phase | Environment | Prerequisites |
|-------|------------|---------------|
| 1 | Local only | Tools installed, scanner repo cloned |
| 2 | Azure-deployed | Demo apps running (local or Azure) |
| 3 | GitHub web UI | GitHub authentication, scans uploaded |
