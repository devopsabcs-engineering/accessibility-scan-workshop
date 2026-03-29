---
permalink: /labs/lab-04
title: "Lab 04: Custom Playwright Checks — Manual Inspection Automation"
description: "Extend scanner coverage with custom Playwright-based accessibility checks beyond automated engines."
---

# Lab 04: Custom Playwright Checks — Manual Inspection Automation

| | |
|---|---|
| **Duration** | 35 minutes |
| **Level** | Intermediate |
| **Prerequisites** | [Lab 01](lab-01.md) |

## Learning Objectives

By the end of this lab, you will be able to:

- Explain why custom checks are needed beyond axe-core and IBM Equal Access
- Review existing custom checks in the scanner source code
- Understand how Playwright tests keyboard navigation and focus management
- Write a new custom check to detect deprecated HTML elements
- Run the updated scanner and verify the new check produces findings

## Exercises

### Exercise 4.1: Review Custom Checks Source

Automated engines like axe-core cannot catch every accessibility issue. The scanner includes custom Playwright-based checks for issues that require DOM interaction or visual inspection.

1. Open the custom checks source file in your editor:

   ```text
   src/lib/scanner/custom-checks.ts
   ```

2. Review the existing checks:

   | Check Function | What It Detects | WCAG Criterion |
   |---------------|-----------------|----------------|
   | `checkAmbiguousLinkText` | Links with vague text like "click here," "read more," or "learn more" | 2.4.4 Link Purpose |
   | `checkAriaCurrentPage` | Navigation elements missing `aria-current="page"` on the active link | 1.3.1 Info and Relationships |
   | `checkEmphasisStrongSemantics` | Presentational use of `<b>` / `<i>` instead of semantic `<strong>` / `<em>` | 1.3.1 Info and Relationships |
   | `checkDiscountPriceAccessibility` | Prices marked with strikethrough (`<del>` / `<s>`) missing screen reader context | 1.1.1 Non-text Content |
   | `checkStickyElementOverlap` | Sticky headers or footers that could overlap content when scrolling | 2.4.11 Focus Not Obscured |

3. Note the check function pattern. Each function:
   - Takes a Playwright `Page` object
   - Returns a `CustomCheckResult` or `null` (null if no violation found)
   - Uses `page.evaluate()` to query the DOM
   - Includes impact level, help text, and affected element selectors

   ![Custom checks source code](../images/lab-04/lab-04-custom-checks-source.png)

### Exercise 4.2: Run Scanner with Custom Checks

You will run a scan that includes custom checks and examine the additional findings.

1. Scan demo app 001 with the scanner (custom checks run automatically):

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --format json --output results/demo-001-custom.json
   ```

2. Open `results/demo-001-custom.json` and search for findings with the `custom-` prefix in their rule IDs. These are the custom check results.

3. You should see findings for:
   - **Ambiguous link text** — Demo app 001 uses "click here" links throughout
   - **Missing aria-current** — The navigation bar does not mark the active page

   ![Custom check results](../images/lab-04/lab-04-custom-check-results.png)

> [!NOTE]
> Custom checks complement automated engines. axe-core checks `link-name` (whether a link has accessible text at all), while the custom check `checkAmbiguousLinkText` goes further to flag links that have text but the text is not descriptive enough.

### Exercise 4.3: Understand Keyboard Navigation Testing

Many accessibility issues only appear during keyboard interaction. You will review how the scanner tests keyboard accessibility.

1. The demo apps include a deliberate keyboard trap. Demo app 001 contains this JavaScript:

   ```javascript
   document.addEventListener('keydown', function(e) {
     if (e.key === 'Tab') { }
   });
   ```

   This intercepts the `Tab` key and does nothing, trapping keyboard users on the page.

2. Additionally, all interactive elements (buttons) are implemented as `<div>` elements with `onclick` handlers instead of `<button>` elements:

   ```html
   <!-- Inaccessible -->
   <div class="btn" onclick="bookFlight()">Book Now</div>

   <!-- Accessible -->
   <button onclick="bookFlight()">Book Now</button>
   ```

3. The scanner's custom checks can detect some keyboard issues by:
   - Evaluating whether interactive elements have proper roles
   - Checking for `tabindex` on non-interactive elements used as controls
   - Detecting event listeners that suppress default keyboard behaviour

   ![Keyboard navigation testing](../images/lab-04/lab-04-keyboard-test.png)

> [!TIP]
> For manual keyboard testing, press `Tab` to move forward, `Shift+Tab` to move backward, `Enter` to activate buttons and links, and `Space` to toggle checkboxes and buttons. Every interactive element should be reachable and operable via keyboard alone.

### Exercise 4.4: Write a New Custom Check

You will create a custom check to detect `<marquee>` elements, which are deprecated and cause WCAG 2.3.1 violations.

1. Open `src/lib/scanner/custom-checks.ts` in your editor.

2. Add a new check function before the `runCustomChecks` function:

   ```typescript
   async function checkDeprecatedMarquee(page: Page): Promise<CustomCheckResult | null> {
     const marquees = await page.evaluate(() => {
       const elements = document.querySelectorAll('marquee');
       if (elements.length === 0) return null;
       return Array.from(elements).map((el) => ({
         selector: 'marquee',
         html: el.outerHTML.substring(0, 200),
       }));
     });

     if (!marquees) return null;

     return {
       id: 'custom-deprecated-marquee',
       impact: 'serious',
       description: 'Page contains deprecated <marquee> elements that cause distracting motion',
       help: 'Remove <marquee> elements and use CSS animations with prefers-reduced-motion support instead',
       helpUrl: 'https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html',
       wcag: ['2.2.2', '2.3.1'],
       nodes: marquees.map((m) => ({
         target: [m.selector],
         html: m.html,
       })),
     };
   }
   ```

   ![New custom check code](../images/lab-04/lab-04-new-check-code.png)

3. Add the new check to the `runCustomChecks` function's check array:

   ```typescript
   const checks = [
     checkAmbiguousLinkText,
     checkAriaCurrentPage,
     checkEmphasisStrongSemantics,
     checkDiscountPriceAccessibility,
     checkStickyElementOverlap,
     checkDeprecatedMarquee,  // Add this line
   ];
   ```

4. Save the file.

### Exercise 4.5: Run Updated Scanner

You will verify that your new custom check detects the `<marquee>` element in demo app 001.

1. Run the scanner against demo app 001:

   ```bash
   npx ts-node src/cli/commands/scan.ts --url http://localhost:8001 --format json --output results/demo-001-marquee.json
   ```

2. Search the output for `custom-deprecated-marquee`:

   ```bash
   grep "custom-deprecated-marquee" results/demo-001-marquee.json
   ```

   On PowerShell:

   ```powershell
   Select-String -Path results/demo-001-marquee.json -Pattern "custom-deprecated-marquee"
   ```

3. The check should detect the `<marquee>` element that demo app 001 uses for its scrolling banner.

   ![New check results](../images/lab-04/lab-04-new-check-results.png)

> [!WARNING]
> Revert your changes to `custom-checks.ts` after this exercise if you do not want to keep the custom check, or commit the change to your fork. The remaining labs use the original scanner code.

## Verification Checkpoint

Before proceeding, verify:

- [ ] Reviewed the existing custom checks in `custom-checks.ts`
- [ ] Ran a scan and identified custom check findings in the output
- [ ] Can explain why custom checks complement automated engines
- [ ] Successfully wrote and tested a new custom check for `<marquee>` elements
- [ ] New check produced findings when scanning demo app 001

## Next Steps

Proceed to [Lab 05: SARIF Output and GitHub Security Tab](lab-05.md).
