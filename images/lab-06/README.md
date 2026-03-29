<!-- markdownlint-disable-file -->
# Lab 06: GitHub Actions Pipelines and Scan Gates — Screenshot Inventory

Screenshots referenced by [Lab 06](../../labs/lab-06.md).

| Filename | Description | Method | Phase |
|----------|-------------|--------|-------|
| lab-06-ci-workflow.png | CI workflow YAML structure | freeze-file | 1 |
| lab-06-scan-workflow.png | Scan workflow matrix strategy | freeze-file | 1 |
| lab-06-oidc-setup.png | OIDC setup script output | freeze | 1 |
| lab-06-actions-runs.png | GitHub Actions runs page | playwright | 3 |
| lab-06-matrix-jobs.png | Matrix jobs running | playwright | 3 |
| lab-06-deploy-status.png | Deploy status page | playwright | 3 |
| lab-06-threshold-config.png | Threshold configuration | freeze-file | 1 |

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
