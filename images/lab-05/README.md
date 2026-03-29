<!-- markdownlint-disable-file -->
# Lab 05: SARIF Output and GitHub Security Tab — Screenshot Inventory

Screenshots referenced by [Lab 05](../../labs/lab-05.md).

| Filename | Description | Method | Phase |
|----------|-------------|--------|-------|
| lab-05-sarif-output.png | SARIF output file content | freeze-file | 1 |
| lab-05-sarif-structure.png | SARIF structure diagram | freeze-file | 1 |
| lab-05-security-tab.png | GitHub Security tab alerts | playwright | 3 |
| lab-05-alert-detail.png | Alert detail view in Security tab | playwright | 3 |
| lab-05-filter-severity.png | Filter by severity in Security tab | playwright | 3 |
| lab-05-triage-view.png | Triage view in Security tab | playwright | 3 |

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
