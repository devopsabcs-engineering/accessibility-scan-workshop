<!-- markdownlint-disable-file -->
# Lab 03: IBM Equal Access — Comprehensive Policy Scanning — Screenshot Inventory

Screenshots referenced by [Lab 03](../../labs/lab-03.md).

| Filename | Description | Method | Phase |
|----------|-------------|--------|-------|
| lab-03-ibm-scan-results.png | IBM Equal Access scan results | playwright | 2 |
| lab-03-ibm-violation-detail.png | IBM violation detail view | playwright | 2 |
| lab-03-comparison-table.png | axe-core vs IBM comparison table | freeze | 1 |
| lab-03-combined-report.png | Combined report output | playwright | 2 |
| lab-03-deduplication.png | Deduplication logic visualization | freeze-file | 1 |

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
