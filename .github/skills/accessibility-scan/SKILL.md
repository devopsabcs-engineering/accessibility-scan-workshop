---
name: accessibility-scan
description: "Use this skill when the user asks about accessibility scanning, running axe-core, IBM Equal Access, or custom Playwright checks against web applications, interpreting SARIF results, or configuring any of the 3 scanner tools. Also use when discussing WCAG 2.2 compliance, accessibility violations, or scan result analysis."
---

## Overview

The Accessibility Scanner combines 3 tools to scan web applications for WCAG 2.2
accessibility violations. Each tool covers a distinct domain and produces or
converts to SARIF v2.1.0 for GitHub Security tab integration.

## axe-core

**Purpose:** Automated WCAG 2.2 rule checking engine that identifies accessibility
violations in rendered web pages.

**What it scans:** Live web pages for structural accessibility issues (missing alt
text, colour contrast, ARIA violations, missing form labels).

**Key rules for accessibility:**

- `color-contrast` — Ensures text has sufficient contrast ratio against its background
- `image-alt` — Ensures every image element has alternative text
- `label` — Ensures every form input has an associated label
- `aria-roles` — Ensures ARIA roles are valid and used correctly
- `link-name` — Ensures every link has discernible text
- `button-name` — Ensures every button has discernible text
- `html-has-lang` — Ensures the HTML element has a valid lang attribute

**Run locally:**

```bash
npm install @axe-core/cli
npx @axe-core/cli http://localhost:3001 --save reports/axe-results.json
```

Or using Playwright integration:

```bash
npx playwright test --project=axe-scan
```

**Run in CI (GitHub Actions):**

```yaml
- name: Run axe-core scan
  run: npx playwright test --project=axe-scan
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: reports/axe-results.sarif
    category: accessibility/axe-core
```

**SARIF output:** JSON (requires conversion). Use `src/converters/axe-to-sarif.js`
to convert axe-core JSON output to SARIF v2.1.0. Upload with category
`accessibility/axe-core`.

## IBM Equal Access

**Purpose:** Policy-based accessibility scanner that checks against IBM accessibility
guidelines aligned with WCAG 2.2 and Section 508.

**What it scans:** Web pages for comprehensive accessibility policy violations
including document structure, ARIA usage, and keyboard accessibility.

**Key checks:**

- Heading hierarchy validation
- Landmark region presence and nesting
- ARIA attribute correctness
- Keyboard focus management
- Form input labelling
- Table structure and headers

**Run locally:**

```bash
npm install accessibility-checker
npx accessibility-checker http://localhost:3001 --output reports/
```

**Run in CI (GitHub Actions):**

```yaml
- name: Run IBM Equal Access
  run: npx accessibility-checker http://localhost:3001 --output reports/
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: reports/ibm-results.sarif
    category: accessibility/ibm-equal-access
```

**SARIF output:** JSON (requires conversion). Use `src/converters/ibm-to-sarif.js`
to convert IBM Equal Access output to SARIF v2.1.0. Upload with category
`accessibility/ibm-equal-access`.

## Custom Playwright Checks

**Purpose:** Automated checks for accessibility issues that require browser
interaction — keyboard navigation, focus management, dynamic content, and
custom WCAG rules not covered by automated scanners.

**What it scans:** Live web pages using Playwright browser automation to verify
keyboard accessibility, focus order, skip links, modal dialogs, and live regions.

**Key checks:**

- Keyboard trap detection
- Focus order validation
- Skip navigation link functionality
- Modal focus management
- Live region announcements
- Timeout and animation controls

**Run locally:**

```bash
npx playwright test --project=custom-checks
```

**SARIF output:** JSON (requires conversion). Use `src/converters/custom-to-sarif.js`
to convert custom check results to SARIF v2.1.0. Upload with category
`accessibility/custom-checks`.

## Interpreting SARIF Results in GitHub Security Tab

SARIF results appear under the **Security** tab > **Code scanning alerts** in
each repository.

**Filtering by tool:**

- Use the "Tool" filter to select `axe-core`, `IBMEqualAccess`, or `CustomPlaywrightChecks`
- Each tool uses a distinct SARIF category prefix (`accessibility/axe-core`, `accessibility/ibm-equal-access`, `accessibility/custom-checks`)

**Severity mapping:**

| SARIF Level | Impact | WCAG Level | Action |
|-------------|--------|------------|--------|
| `error` | Critical/Serious | A, AA | Immediate fix required |
| `warning` | Moderate | AA, AAA | Plan remediation |
| `note` | Minor | AAA | Track for review |

**Rule ID prefixes:**

- `A11Y-CONTRAST-*` — Colour contrast violations
- `A11Y-ALT-*` — Alternative text violations
- `A11Y-LABEL-*` — Form labelling violations
- `A11Y-ARIA-*` — ARIA usage violations
- `A11Y-KBD-*` — Keyboard navigation violations
- `A11Y-STRUCT-*` — Document structure violations
