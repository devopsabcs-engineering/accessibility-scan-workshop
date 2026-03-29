<!-- markdownlint-disable-file -->
# Lab 02: axe-core — Automated Accessibility Testing — Screenshot Inventory

Screenshots referenced by [Lab 02](../../labs/lab-02.md).

| Filename | Description | Method | Phase |
|----------|-------------|--------|-------|
| lab-02-web-ui-scan.png | Web UI scan in progress | playwright | 2 |
| lab-02-scan-results.png | Scan results overview | playwright | 2 |
| lab-02-violation-detail.png | Violation detail view | playwright | 2 |
| lab-02-cli-output.png | CLI scan output | freeze | 1 |
| lab-02-api-response.png | API response JSON | freeze | 1 |
| lab-02-multi-app-comparison.png | Multi-app scan comparison | playwright | 2 |

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
