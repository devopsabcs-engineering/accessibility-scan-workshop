<!-- markdownlint-disable-file -->
# Lab 01: Explore the Demo Apps and WCAG Violations — Screenshot Inventory

Screenshots referenced by [Lab 01](../../labs/lab-01.md).

| Filename | Description | Method | Phase |
|----------|-------------|--------|-------|
| lab-01-demo-app-001.png | Demo app 001 home page (Travel Booking) | playwright | 2 |
| lab-01-demo-app-002.png | Demo app 002 home page (E-Commerce) | playwright | 2 |
| lab-01-demo-app-003.png | Demo app 003 home page (Learning Platform) | playwright | 2 |
| lab-01-demo-app-004.png | Demo app 004 home page (Recipe Site) | playwright | 2 |
| lab-01-demo-app-005.png | Demo app 005 home page (Fitness Tracker) | playwright | 2 |
| lab-01-violations-popup.png | Popup modal violation in demo app 001 | playwright | 2 |
| lab-01-devtools-audit.png | Chrome DevTools accessibility audit | playwright | 2 |
| lab-01-wcag-mapping.png | WCAG POUR principle mapping | freeze-file | 1 |

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
