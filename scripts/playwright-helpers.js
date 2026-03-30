const { chromium } = require('playwright');

async function simpleScreenshot(url, outputFile, options = {}) {
    const browser = await chromium.launch();
    const context = await browser.newContext({
        viewport: { width: 1280, height: 720 }
    });
    const page = await context.newPage();
    await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
    await page.screenshot({ path: outputFile, fullPage: !!options.fullPage });
    await browser.close();
}

async function scanCapture(scannerUrl, targetUrl, outputFile, options = {}) {
    const browser = await chromium.launch();
    const context = await browser.newContext({
        viewport: { width: 1280, height: 900 }
    });
    const page = await context.newPage();
    await page.goto(scannerUrl, { waitUntil: 'networkidle', timeout: 60000 });

    // Find URL input and enter target URL
    const urlInput = page.locator(
        'input[type="url"], input[type="text"], input[placeholder*="url" i], input[name*="url" i]'
    ).first();
    await urlInput.fill(targetUrl);

    // Click scan button
    const scanButton = page.locator(
        'button:has-text("Scan"), button:has-text("scan"), button[type="submit"]'
    ).first();
    await scanButton.click();

    const timeout = options.timeout || 120000;

    // Wait for results
    await page.waitForSelector(
        '[data-testid="results"], .results, .scan-results, table, .MuiTable-root',
        { timeout }
    );

    if (options.action === 'results') {
        await page.waitForTimeout(2000);
        await page.screenshot({ path: outputFile, fullPage: true });
    } else if (options.action === 'detail') {
        const firstViolation = page.locator(
            '.violation, tr[data-severity], [role="row"], tbody tr'
        ).first();
        await firstViolation.click();
        await page.waitForTimeout(1000);
        await page.screenshot({ path: outputFile });
    } else if (options.action === 'comparison') {
        await page.waitForTimeout(2000);
        await page.screenshot({ path: outputFile, fullPage: true });
    } else if (options.action === 'progress') {
        // Capture immediately after clicking scan (before results load)
        await page.waitForTimeout(2000);
        await page.screenshot({ path: outputFile });
    } else {
        await page.screenshot({ path: outputFile, fullPage: !!options.fullPage });
    }

    await browser.close();
}

async function authScreenshot(url, outputFile, storageStatePath, options = {}) {
    const browser = await chromium.launch();
    const context = await browser.newContext({
        storageState: storageStatePath,
        viewport: { width: 1280, height: 720 }
    });
    const page = await context.newPage();
    await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
    await page.screenshot({ path: outputFile, fullPage: !!options.fullPage });
    await browser.close();
}

// CLI entrypoint
(async () => {
    const args = process.argv.slice(2);
    const action = args[0];

    function getFlag(name) {
        const idx = args.indexOf(name);
        if (idx === -1) return undefined;
        return args[idx + 1];
    }

    function hasFlag(name) {
        return args.includes(name);
    }

    try {
        if (action === 'screenshot') {
            const url = args[1];
            const output = args[2];
            await simpleScreenshot(url, output, { fullPage: hasFlag('--full-page') });
        } else if (action === 'scan') {
            const scannerUrl = args[1];
            const targetUrl = args[2];
            const output = args[3];
            await scanCapture(scannerUrl, targetUrl, output, {
                action: getFlag('--action') || 'results',
                timeout: parseInt(getFlag('--timeout') || '120000', 10),
                fullPage: hasFlag('--full-page')
            });
        } else if (action === 'auth-screenshot') {
            const url = args[1];
            const output = args[2];
            const storageState = args[3];
            await authScreenshot(url, output, storageState, {
                fullPage: hasFlag('--full-page')
            });
        } else {
            console.error('Usage: node playwright-helpers.js <screenshot|scan|auth-screenshot> [args...]');
            process.exit(1);
        }
    } catch (err) {
        console.error(`Error: ${err.message}`);
        process.exit(1);
    }
})();
