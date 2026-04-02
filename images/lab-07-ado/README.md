<!-- markdownlint-disable-file -->
# Lab 07-ado: ADO YAML Pipelines for Accessibility Scanning — Screenshot Inventory

Screenshots referenced by [Lab 07-ado](../../labs/lab-07-ado.md).

| Filename | Description | Method | Phase |
|----------|-------------|--------|-------|
| lab-07-ado-pipeline-basics.png | ci.yml pipeline structure | freeze-file | 1 |
| lab-07-ado-scan-matrix.png | a11y-scan.yml matrix strategy | freeze-file | 1 |
| lab-07-ado-variable-groups.png | Variable groups in ADO portal | authenticated-playwright | 4 |
| lab-07-ado-schedule-syntax.png | Schedule trigger YAML | freeze | 1 |
| lab-07-ado-environments.png | Environments list in ADO | authenticated-playwright | 4 |
| lab-07-ado-approval-gate.png | Approval gate configuration | authenticated-playwright | 4 |
| lab-07-ado-templates-dir.png | Templates directory listing | freeze | 1 |
| lab-07-ado-template-params.png | Template parameters YAML | freeze-file | 1 |
| lab-07-ado-scan-run.png | Scan pipeline run view | authenticated-playwright | 4 |
| lab-07-ado-deploy-stages.png | Multi-stage deployment view | authenticated-playwright | 4 |
| lab-07-ado-workitem-link.png | AB# work item linked from commit | authenticated-playwright | 4 |

## Capture Methods

| Method | Tool | Description |
|--------|------|-------------|
| freeze-file | Charm freeze | Offline file content rendered via Playwright |
| freeze | Charm freeze | Offline terminal/text content rendered via Playwright |
| authenticated-playwright | Playwright | Playwright with ADO auth state |

## Phases

| Phase | Environment | Prerequisites |
|-------|------------|---------------|
| 1 | Local only | Tools installed, scanner repo cloned |
| 4 | ADO web UI | ADO authentication and pipelines configured |
