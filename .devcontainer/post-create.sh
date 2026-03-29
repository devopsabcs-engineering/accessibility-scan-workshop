#!/usr/bin/env bash
set -euo pipefail

# Clone the scanner repo alongside the workshop if not already present
SCANNER_DIR="/workspaces/accessibility-scan-demo-app"
if [ ! -d "$SCANNER_DIR" ]; then
  gh repo fork devopsabcs-engineering/accessibility-scan-demo-app --clone --clone-dir "$SCANNER_DIR" 2>/dev/null \
    || gh repo clone devopsabcs-engineering/accessibility-scan-demo-app "$SCANNER_DIR"
fi

# Install scanner dependencies and Playwright browser
cd "$SCANNER_DIR"
npm ci
npx playwright install --with-deps chromium

echo ""
echo "=========================================="
echo " Workshop environment ready!"
echo " Scanner repo: $SCANNER_DIR"
echo " Run ./start-local.ps1 to start the scanner"
echo "=========================================="
