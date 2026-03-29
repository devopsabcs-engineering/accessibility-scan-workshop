---
permalink: /labs/lab-05
title: "Lab 05: SARIF Output and GitHub Security Tab"
description: "Generate SARIF output from accessibility scans and upload findings to the GitHub Security tab."
---

# Lab 05: SARIF Output and GitHub Security Tab

| | |
|---|---|
| **Duration** | 30 minutes |
| **Level** | Intermediate |
| **Prerequisites** | [Lab 02](lab-02.md), [Lab 03](lab-03.md), or [Lab 04](lab-04.md) (at least one) |

## Learning Objectives

By the end of this lab, you will be able to:

- Generate accessibility scan results in SARIF v2.1.0 format
- Explain the SARIF schema including runs, results, rules, and locations
- Upload SARIF files to the GitHub Security tab using the CodeQL upload action
- Navigate the GitHub Security tab to view accessibility alerts
- Triage findings by filtering, dismissing, and categorizing alerts

## Exercises

### Exercise 5.1: Generate SARIF Output

You will generate accessibility scan results in the SARIF format used by GitHub Code Scanning.

1. Create a results directory if it does not exist:

   ```bash
   mkdir -p results
   ```

2. Run the scanner with SARIF output:

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --format sarif --output results/a11y-001.sarif
   ```

3. Verify the SARIF file was created:

   ```bash
   ls -la results/a11y-001.sarif
   ```

   ![SARIF output file](../images/lab-05/lab-05-sarif-output.png)

### Exercise 5.2: Examine SARIF Structure

You will walk through the SARIF v2.1.0 schema to understand how accessibility findings are represented.

1. Open `results/a11y-001.sarif` in your editor. The top-level structure is:

   ```json
   {
     "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json",
     "version": "2.1.0",
     "runs": [...]
   }
   ```

2. Each **run** represents one scan execution and contains:

   | Section | Description |
   |---------|-------------|
   | `tool` | The scanner tool identity and version |
   | `tool.driver.rules` | Array of rule definitions with IDs, descriptions, and help URLs |
   | `results` | Array of individual findings |
   | `results[].ruleId` | Which rule was violated |
   | `results[].level` | Severity: `error`, `warning`, or `note` |
   | `results[].message` | Human-readable description of the finding |
   | `results[].locations` | Where the violation occurs (URI and region) |

   ![SARIF structure diagram](../images/lab-05/lab-05-sarif-structure.png)

3. Review how severity levels map from axe-core impact to SARIF:

   | axe-core Impact | SARIF Level |
   |-----------------|-------------|
   | critical | error |
   | serious | error |
   | moderate | warning |
   | minor | note |

4. Examine a single result entry:

   ```json
   {
     "ruleId": "image-alt",
     "level": "error",
     "message": {
       "text": "Images must have alternate text"
     },
     "locations": [
       {
         "physicalLocation": {
           "artifactLocation": {
             "uri": "http://localhost:8001"
           }
         }
       }
     ]
   }
   ```

### Exercise 5.3: Upload SARIF to GitHub

You will upload the SARIF file to your fork's Security tab using the GitHub CodeQL action.

1. Create a workflow file at `.github/workflows/upload-sarif.yml` in your fork:

   ```yaml
   name: Upload SARIF

   on:
     workflow_dispatch:
       inputs:
         sarif_file:
           description: 'Path to SARIF file'
           required: true
           default: 'results/a11y-001.sarif'

   permissions:
     security-events: write

   jobs:
     upload:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4

         - name: Upload SARIF
           uses: github/codeql-action/upload-sarif@v4
           with:
             sarif_file: ${{ github.event.inputs.sarif_file }}
             category: accessibility-scan
   ```

2. Commit and push the workflow to your fork:

   ```bash
   git add .github/workflows/upload-sarif.yml
   git commit -m "feat: add SARIF upload workflow"
   git push
   ```

3. Ensure the SARIF file is also committed:

   ```bash
   git add results/a11y-001.sarif
   git commit -m "feat: add sample SARIF scan results"
   git push
   ```

4. Trigger the workflow:

   ```bash
   gh workflow run upload-sarif.yml
   ```

5. Wait for the workflow to complete:

   ```bash
   gh run watch
   ```

> [!NOTE]
> The `github/codeql-action/upload-sarif@v4` action requires the `security-events: write` permission. GitHub Advanced Security must be enabled on your repository (it is enabled by default on public repositories).

### Exercise 5.4: Browse Findings in Security Tab

You will navigate the GitHub Security tab to view the uploaded accessibility alerts.

1. Open your fork on GitHub in a browser.

2. Navigate to the **Security** tab, then click **Code scanning**.

3. You should see accessibility alerts grouped by rule. Each alert shows:
   - Rule ID and description
   - Severity (error, warning, note)
   - The affected URL

   ![Security tab alerts](../images/lab-05/lab-05-security-tab.png)

4. Click on an individual alert to view its full details, including the rule help text and WCAG criterion.

   ![Alert detail view](../images/lab-05/lab-05-alert-detail.png)

### Exercise 5.5: Triage Findings

You will practice filtering and managing alerts in the Security tab.

1. Use the **severity** filter to show only `error`-level alerts (critical and serious violations):

   ![Filter by severity](../images/lab-05/lab-05-filter-severity.png)

2. Click on a low-severity alert and click **Dismiss alert**. Select a reason:
   - **False positive** — if the finding is incorrect
   - **Won't fix** — if the finding is intentional
   - **Used in tests** — if the code is a test artifact

   ![Triage view](../images/lab-05/lab-05-triage-view.png)

3. Note that dismissed alerts remain visible with a strikethrough. You can reopen them later if needed.

> [!TIP]
> In a real project, triage alerts as part of your team's sprint review. Critical and serious violations should be addressed immediately, while moderate and minor issues can be tracked for future sprints.

## Verification Checkpoint

Before proceeding, verify:

- [ ] Generated a SARIF file from the scanner CLI
- [ ] Can describe the 4 main SARIF sections (schema, runs, tool/rules, results)
- [ ] Uploaded a SARIF file to GitHub via the upload-sarif workflow
- [ ] Viewed accessibility alerts in the GitHub Security tab
- [ ] Triaged at least 1 alert (dismissed or reviewed)

## Next Steps

Proceed to [Lab 06: GitHub Actions Pipelines and Scan Gates](lab-06.md).
