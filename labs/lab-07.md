---
permalink: /labs/lab-07
title: "Lab 07: Remediation Workflows with Copilot Agents"
description: "Use GitHub Copilot agents to detect, prioritize, and fix accessibility violations automatically."
---

# Lab 07: Remediation Workflows with Copilot Agents

| | |
|---|---|
| **Duration** | 45 minutes |
| **Level** | Advanced |
| **Prerequisites** | [Lab 06](lab-06.md), GitHub Copilot access |

> [!TIP]
> This lab covers **GitHub-based** remediation workflows. For the Azure DevOps
> pipeline variant, see [Lab 07-ado: ADO YAML Pipelines](lab-07-ado.md).

## Learning Objectives

By the end of this lab, you will be able to:

- Review the A11yDetector agent and understand its scan-score-prioritize workflow
- Invoke the detector agent on a demo app and interpret its output
- Review the A11yResolver agent and understand its pattern-based fix approach
- Apply remediation fixes proposed by the resolver agent
- Create a remediation pull request with before/after evidence
- Re-scan to verify the accessibility score improves after fixes

## Exercises

### Exercise 7.1: Review A11yDetector Agent

The scanner includes two Copilot agents that work together: a **detector** that identifies and prioritizes violations, and a **resolver** that proposes and applies fixes.

1. Open `.github/agents/a11y-detector.agent.md` in your editor.

2. Review the agent definition. The detector's workflow:

   | Step | Action |
   |------|--------|
   | 1 | Scans the target URL using the scanner engine |
   | 2 | Calculates an accessibility score (0–100) |
   | 3 | Identifies the top 10 violations by severity and frequency |
   | 4 | Maps each violation to its WCAG 2.2 success criterion |
   | 5 | Produces a prioritized remediation report |
   | 6 | Hands off to the A11yResolver agent for fixes |

3. Note the **handoff pattern** — the detector invokes the resolver via Copilot's agent system, passing the violation report as context. This separation allows each agent to specialize:
   - **Detector**: Expert in WCAG rules, scanning, and prioritization
   - **Resolver**: Expert in HTML/CSS/ARIA fix patterns

### Exercise 7.2: Run Detection Scan

You will invoke the detector agent on demo app 001 to produce a prioritized violation report.

1. Open **GitHub Copilot Chat** in VS Code (or your preferred Copilot interface).

2. Invoke the detector agent:

   ```text
   @a11y-detector Scan http://localhost:8001 and produce a prioritized violation report
   ```

3. The detector runs the scan and returns a report that includes:
   - **Overall score** — The accessibility score for the page
   - **Top 10 violations** — Ranked by impact × frequency
   - **WCAG mapping** — Each violation linked to its success criterion
   - **Remediation priority** — Which violations to fix first for maximum score improvement

   ![Detector output report](../images/lab-07/lab-07-detector-output.png)

4. Review the prioritization. Violations are ranked by impact:
   - **Critical** violations (missing lang, keyboard traps) are highest priority
   - **Serious** violations (missing alt text, poor contrast) follow
   - **Moderate** and **minor** violations are lower priority

> [!TIP]
> Fixing the top 3–5 critical/serious violations typically produces the largest score improvement. Focus on high-impact items first.

### Exercise 7.3: Review A11yResolver Agent

You will examine the resolver agent that proposes code fixes for detected violations.

1. Open `.github/agents/a11y-resolver.agent.md` in your editor.

2. Review the resolver's fix pattern table:

   | Violation | Fix Pattern |
   |-----------|-------------|
   | Missing `lang` attribute | Add `lang="en"` to the `<html>` element |
   | Missing alt text | Add descriptive `alt` attributes to images |
   | Poor color contrast | Update CSS colours to meet 4.5:1 ratio for normal text |
   | Missing form labels | Add `<label>` elements associated via `for`/`id` |
   | Heading hierarchy | Restructure headings to follow logical order (h1 → h2 → h3) |
   | Keyboard trap | Remove or fix JavaScript that intercepts keyboard events |
   | Missing skip nav | Add a skip navigation link as the first focusable element |
   | Ambiguous links | Replace "click here" with descriptive link text |
   | Missing table headers | Add `<th>` elements with `scope` attributes |
   | Deprecated elements | Replace `<marquee>` and `<font>` with CSS |

3. The resolver references `.github/instructions/a11y-remediation.instructions.md` for detailed fix recipes. Each recipe includes before/after code examples and the WCAG criterion it addresses.

### Exercise 7.4: Apply Remediation Fixes

You will use the resolver agent to propose and apply fixes to demo app 001.

1. Invoke the resolver agent in Copilot Chat:

   ```text
   @a11y-resolver Fix the top 5 violations in a11y-demo-app-001/static/index.html
   ```

2. The resolver proposes targeted code changes. Review each proposed fix:

   - **Add `lang="en"`** to the `<html>` tag
   - **Add `<title>`** element with a descriptive page title
   - **Add `alt` attributes** to all `<img>` elements
   - **Replace `<div class="btn">`** with `<button>` elements
   - **Remove the keyboard trap** JavaScript

   ![Resolver proposed fixes](../images/lab-07/lab-07-resolver-fixes.png)

3. Accept the proposed fixes. The resolver modifies `a11y-demo-app-001/static/index.html` with the changes.

4. Verify the fixes look correct by reviewing the diff in your editor.

### Exercise 7.5: Create Remediation PR

You will commit the fixes and create a pull request documenting the before/after state.

1. Create a feature branch for the remediation:

   ```bash
   git checkout -b fix/a11y-demo-001-top-violations
   ```

2. Stage and commit the changes:

   ```bash
   git add a11y-demo-app-001/static/index.html
   git commit -m "fix: remediate top 5 WCAG violations in demo app 001"
   ```

3. Push the branch:

   ```bash
   git push -u origin fix/a11y-demo-001-top-violations
   ```

4. Create a pull request:

   ```bash
   gh pr create \
     --title "fix: remediate top 5 WCAG violations in demo app 001" \
     --body "## Changes

   Fixes the top 5 accessibility violations detected by the A11yDetector agent:

   1. Added \`lang=\"en\"\` to \`<html>\` element (WCAG 3.1.1)
   2. Added descriptive \`<title>\` element (WCAG 2.4.2)
   3. Added \`alt\` attributes to all images (WCAG 1.1.1)
   4. Replaced div buttons with semantic \`<button>\` elements (WCAG 4.1.2)
   5. Removed keyboard trap JavaScript (WCAG 2.1.2)

   ## Before / After

   | Metric | Before | After |
   |--------|--------|-------|
   | Score | ~25 | ~55 |
   | Critical violations | 3 | 0 |
   | Serious violations | 8 | 3 |
   "
   ```

   ![Remediation pull request](../images/lab-07/lab-07-remediation-pr.png)

### Exercise 7.6: Verify Score Improvement

You will re-scan demo app 001 after applying fixes to confirm the accessibility score improved.

1. Rebuild the demo app with the fixes:

   ```bash
   docker build -t a11y-demo-app-001 ./a11y-demo-app-001
   docker stop a11y-001
   docker rm a11y-001
   docker run -d --name a11y-001 -p 8001:8080 a11y-demo-app-001
   ```

2. Run the scanner against the updated app:

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --format json --output results/demo-001-after.json
   ```

3. Compare the before and after results:

   ```powershell
   $before = Get-Content results/demo-001.json | ConvertFrom-Json
   $after = Get-Content results/demo-001-after.json | ConvertFrom-Json
   Write-Host "Before: $($before.score)  After: $($after.score)"
   ```

   ![Before/after score comparison](../images/lab-07/lab-07-before-after.png)

4. The score should show meaningful improvement. Fixing the top 5 violations typically raises the score by 20–30 points.

   ![Score improvement chart](../images/lab-07/lab-07-score-improvement.png)

> [!TIP]
> To achieve a score above 90, additional fixes are needed beyond the top 5: improving colour contrast throughout, adding form labels, fixing heading hierarchy, and adding skip navigation. The A11yResolver agent can be invoked iteratively to address remaining violations.

## Verification Checkpoint

Before completing the workshop, verify:

- [ ] Reviewed the A11yDetector agent definition and understand its scan-score-prioritize workflow
- [ ] Ran the detector and received a prioritized violation report
- [ ] Reviewed the A11yResolver agent definition and its fix pattern table
- [ ] Applied at least 3 remediation fixes to demo app 001
- [ ] Created a pull request with before/after documentation
- [ ] Re-scanned and confirmed the accessibility score improved

## Congratulations

You have completed all 8 labs in the Accessibility Scan Workshop. Here is a summary of what you learned:

| Lab | What You Learned |
|-----|------------------|
| **Lab 00** | Set up the development environment with Node.js, Docker, and scanner tools |
| **Lab 01** | Explored the 5 demo apps and mapped their violations to WCAG POUR principles |
| **Lab 02** | Ran axe-core scans via web UI, CLI, and API to detect WCAG violations |
| **Lab 03** | Used IBM Equal Access for broader policy-based scanning and compared with axe-core |
| **Lab 04** | Extended coverage with custom Playwright checks for issues automated engines miss |
| **Lab 05** | Generated SARIF output and uploaded findings to the GitHub Security tab |
| **Lab 06** | Built automated pipelines with matrix strategy, OIDC auth, and threshold gates |
| **Lab 06-ado** | Configured ADO Advanced Security with SARIF integration (ADO track) |
| **Lab 07** | Used Copilot agents to detect, prioritize, and fix accessibility violations |
| **Lab 07-ado** | Built ADO YAML pipelines for automated accessibility scanning (ADO track) |

You now have the skills to implement a complete accessibility scanning platform that:

- **Scans web pages** using multiple engines (axe-core, IBM Equal Access, custom Playwright checks)
- **Produces unified SARIF output** for all scan engines
- **Integrates with GitHub Security tab** or **ADO Advanced Security** for centralized alert management
- **Enforces accessibility gates** in CI/CD pipelines with configurable thresholds
- **Automates remediation** using AI-powered Copilot agents
- **Runs automatically** on schedule and on-demand via GitHub Actions or ADO Pipelines
