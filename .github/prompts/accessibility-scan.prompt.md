---
description: "Run an accessibility scan against the demo web applications and analyze the results."
---

## Run Accessibility Scan

Run the accessibility scanner against the demo app repositories and analyze the findings.

### Steps

1. **Run axe-core** against each demo app:

   ```bash
   npx @axe-core/cli http://localhost:3001 --save reports/axe-results.json
   ```

   Or using Playwright with axe-core:

   ```bash
   npx playwright test --project=axe-scan
   ```

2. **Run IBM Equal Access** against each demo app:

   ```bash
   npx accessibility-checker http://localhost:3001 --output reports/
   ```

3. **Run custom Playwright checks** for keyboard navigation and dynamic content:

   ```bash
   npx playwright test --project=custom-checks
   ```

4. **Convert results to SARIF** for GitHub Security tab integration:

   ```bash
   node src/converters/axe-to-sarif.js reports/axe-results.json reports/axe-results.sarif
   node src/converters/ibm-to-sarif.js reports/ibm-results.json reports/ibm-results.sarif
   ```

5. **Analyze results**: Review the SARIF files in `reports/` and summarize:
   - Total findings by tool and severity
   - WCAG conformance level breakdown (A, AA, AAA)
   - Top accessibility violations with affected user groups
   - Recommended remediation priorities
