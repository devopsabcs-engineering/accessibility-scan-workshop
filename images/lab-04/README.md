<!-- markdownlint-disable-file -->
# Lab 04: Custom Playwright Checks — Manual Inspection Automation — Screenshot Inventory

Screenshots referenced by [Lab 04](../../labs/lab-04.md).

| Filename | Description | Method | Phase |
|----------|-------------|--------|-------|
| lab-04-custom-checks-source.png | Custom checks source code | freeze-file | 1 |
| lab-04-custom-check-results.png | Custom check results | freeze | 1 |
| lab-04-keyboard-test.png | Keyboard navigation testing | playwright | 2 |
| lab-04-new-check-code.png | New custom check code | freeze-file | 1 |
| lab-04-new-check-results.png | New check results output | freeze | 1 |

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
