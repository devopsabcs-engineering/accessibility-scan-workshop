---
layout: default
title: Home
---

# Accessibility Scan Workshop

Complete hands-on labs to learn WCAG 2.2 accessibility scanning using
axe-core, IBM Equal Access, and custom Playwright checks.

## Lab Dependency Diagram

```mermaid
graph LR
    L00[Lab 00: Setup] --> L01[Lab 01: Demo Apps]
    L01 --> L02[Lab 02: axe-core]
    L01 --> L03[Lab 03: IBM Equal Access]
    L01 --> L04[Lab 04: Custom Checks]
    L02 --> L05[Lab 05: SARIF]
    L03 --> L05
    L04 --> L05
    L05 --> L06[Lab 06: GitHub Actions]
    L06 --> L07[Lab 07: Remediation]
```

## Lab Checklist

- [ ] [Lab 00: Prerequisites and Environment Setup](labs/lab-00-setup.md)
- [ ] [Lab 01: Explore the Demo Apps and WCAG Violations](labs/lab-01.md)
- [ ] [Lab 02: axe-core — Automated Accessibility Testing](labs/lab-02.md)
- [ ] [Lab 03: IBM Equal Access — Comprehensive Policy Scanning](labs/lab-03.md)
- [ ] [Lab 04: Custom Playwright Checks — Manual Inspection](labs/lab-04.md)
- [ ] [Lab 05: SARIF Output and GitHub Security Tab](labs/lab-05.md)
- [ ] [Lab 06: GitHub Actions Pipelines and Scan Gates](labs/lab-06.md)
- [ ] [Lab 07: Remediation Workflows with Copilot Agents](labs/lab-07.md)

## Delivery Tiers

| Tier | Labs | Duration | Azure Required |
| --- | --- | --- | --- |
| Half-Day | 00, 01, 02, 03, 05 | ~3 hours | No |
| Full-Day | 00–07 (all) | ~6.5 hours | Yes |

## Prerequisites

- GitHub account with Copilot access
- Node.js 20+
- Docker Desktop
- Azure subscription (full-day tier only)
- PowerShell 7+

## Getting Started

1. Fork and clone `devopsabcs-engineering/accessibility-scan-demo-app`
2. Run `npm install && npx playwright install --with-deps chromium`
3. Start the scanner: `./start-local.ps1`
4. Open [Lab 00](labs/lab-00-setup.md) and begin
