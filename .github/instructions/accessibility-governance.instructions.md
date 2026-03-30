---
description: "WCAG 2.2 accessibility governance rules, compliance standards, and scan conventions for web application accessibility testing."
applyTo: "**/*.html,**/*.tsx,**/*.jsx,**/*.vue,**/*.svelte"
---

# Accessibility Governance Rules

## WCAG 2.2 Conformance Levels

Every scanned web application must meet WCAG 2.2 Level AA conformance. Scan results are categorized by conformance level:

| Level | Requirement | Action |
|-------|-------------|--------|
| A | Minimum accessibility | Must fix immediately |
| AA | Standard conformance target | Must fix before release |
| AAA | Enhanced accessibility | Recommended but not required |

## Core Accessibility Principles (POUR)

All accessibility violations map to one of the four POUR principles:

| Principle | Description | Example Violations |
|-----------|-------------|--------------------|
| Perceivable | Content must be presentable to all users | Missing alt text, low contrast, no captions |
| Operable | UI must be navigable by all users | Keyboard traps, no focus indicators, timing issues |
| Understandable | Content and UI must be comprehensible | Missing form labels, unclear error messages, no language attribute |
| Robust | Content must work with assistive technologies | Invalid ARIA, broken semantics, missing roles |

## Required Scan Coverage

Every demo application must be scanned for the following categories:

| # | Category | Scanner | Rule Examples |
|---|----------|---------|---------------|
| 1 | Color Contrast | axe-core | `color-contrast`, `link-in-text-block` |
| 2 | Image Alternatives | axe-core | `image-alt`, `input-image-alt`, `area-alt` |
| 3 | Form Labels | axe-core, IBM Equal Access | `label`, `select-name`, `input-button-name` |
| 4 | Keyboard Navigation | Custom Playwright | Focus order, keyboard traps, skip links |
| 5 | ARIA Compliance | axe-core, IBM Equal Access | `aria-roles`, `aria-valid-attr`, `aria-required-attr` |
| 6 | Document Structure | IBM Equal Access | Heading hierarchy, landmark regions, page title |
| 7 | Dynamic Content | Custom Playwright | Live regions, status messages, modal focus management |

## Severity Mapping

Accessibility violations map to SARIF severity levels based on user impact:

| Impact Level | SARIF Level | Description | Action |
|--------------|-------------|-------------|--------|
| Critical | `error` | Complete barrier preventing access | Immediate fix required |
| Serious | `error` | Significant difficulty for users | Fix within current sprint |
| Moderate | `warning` | Some difficulty for certain users | Plan remediation |
| Minor | `note` | Cosmetic or best practice issue | Track for review |

## SARIF Integration

Accessibility scan findings use the following SARIF conventions:

- **Category prefix:** `accessibility/`
- **Rule ID prefix:** `A11Y-`
- **Tool names:** `axe-core`, `IBMEqualAccess`, `CustomPlaywrightChecks`
- **Security severity:** Mapped to WCAG conformance level and user impact
