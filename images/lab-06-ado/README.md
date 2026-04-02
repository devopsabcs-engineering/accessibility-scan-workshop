<!-- markdownlint-disable-file -->
# Lab 06-ado: ADO Advanced Security and SARIF Integration — Screenshot Inventory

Screenshots referenced by [Lab 06-ado](../../labs/lab-06-ado.md).

| Filename | Description | Method | Phase |
|----------|-------------|--------|-------|
| lab-06-ado-sarif-file.png | SARIF file JSON content | freeze-file | 1 |
| lab-06-ado-advsec-settings.png | ADO Advanced Security settings panel | authenticated-playwright | 4 |
| lab-06-ado-advsec-enable.png | Enable Advanced Security confirmation | authenticated-playwright | 4 |
| lab-06-ado-pipeline-yaml.png | a11y-scan-advancedsecurity.yml content | freeze-file | 1 |
| lab-06-ado-pipeline-run.png | Pipeline execution run view | authenticated-playwright | 4 |
| lab-06-ado-pipeline-logs.png | Pipeline logs showing SARIF upload | authenticated-playwright | 4 |
| lab-06-ado-advsec-overview.png | Advanced Security Overview dashboard | authenticated-playwright | 4 |
| lab-06-ado-advsec-alerts.png | Alerts listed by severity | authenticated-playwright | 4 |
| lab-06-ado-comparison.png | Side-by-side GH Security vs ADO AdvSec | composite | 4 |

## Capture Methods

| Method | Tool | Description |
|--------|------|-------------|
| freeze-file | Charm freeze | Offline file content rendered via Playwright |
| authenticated-playwright | Playwright | Playwright with ADO auth state |
| composite | Multiple | Multiple screenshots combined |

## Phases

| Phase | Environment | Prerequisites |
|-------|------------|---------------|
| 1 | Local only | Tools installed, scanner repo cloned |
| 4 | ADO web UI | ADO authentication and Advanced Security enabled |
