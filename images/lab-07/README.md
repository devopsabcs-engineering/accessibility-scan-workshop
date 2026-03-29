<!-- markdownlint-disable-file -->
# Lab 07: Remediation Workflows with Copilot Agents — Screenshot Inventory

Screenshots referenced by [Lab 07](../../labs/lab-07.md).

| Filename | Description | Method | Phase |
|----------|-------------|--------|-------|
| lab-07-detector-output.png | A11yDetector output report | freeze | 1 |
| lab-07-resolver-fixes.png | A11yResolver proposed fixes | freeze | 1 |
| lab-07-remediation-pr.png | Remediation pull request | playwright | 3 |
| lab-07-before-after.png | Before/after score comparison | playwright | 3 |
| lab-07-score-improvement.png | Score improvement chart | playwright | 3 |

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
