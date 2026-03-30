<#
.SYNOPSIS
    Capture all workshop screenshots for Accessibility Scan Workshop labs 00-07.

.DESCRIPTION
    Automates screenshot capture for 8 workshop labs using Charm freeze (terminal
    output) and Playwright (browser pages). Produces 47 PNG files organized into
    images/lab-XX/ directories. Requires the demo apps to be running and all
    prerequisite tools to be installed.

.NOTES
    Prerequisites:
    - freeze (Charm CLI) installed — https://github.com/charmbracelet/freeze
    - Node.js and npx installed (for Playwright)
    - GitHub CLI (gh) authenticated
    - Azure CLI (az) authenticated (Phase 2/3 only)
    - Scanner repo cloned at sibling directory

.EXAMPLE
    .\scripts\capture-screenshots.ps1
    Captures all 47 screenshots across 8 labs.

.EXAMPLE
    .\scripts\capture-screenshots.ps1 -LabFilter '02'
    Captures only Lab 02 screenshots.

.EXAMPLE
    .\scripts\capture-screenshots.ps1 -Phase 1
    Captures only Phase 1 (offline) screenshots.

.EXAMPLE
    .\scripts\capture-screenshots.ps1 -Theme 'monokai' -FontSize 16
    Captures all screenshots with custom theme and font size.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputDir = 'images',

    [Parameter()]
    [string]$LabFilter = '',

    [Parameter()]
    [string]$Theme = 'dracula',

    [Parameter()]
    [int]$FontSize = 14,

    [Parameter()]
    [string]$Org = 'devopsabcs-engineering',

    [Parameter()]
    [string]$GitHubAuthState = 'github-auth.json',

    [Parameter()]
    [string]$AzureAuthState = 'azure-auth.json',

    [Parameter()]
    [ValidateSet('', '1', '2', '3')]
    [string]$Phase = '',

    [Parameter()]
    [ValidateSet('local', 'azure')]
    [string]$Environment = 'azure',

    [Parameter()]
    [string]$ScannerUrl = '',

    [Parameter()]
    [hashtable]$AppUrls = @{}
)

# ── URL Resolution ───────────────────────────────────────────────────────────
if (-not $ScannerUrl) {
    $ScannerUrl = if ($Environment -eq 'azure') {
        'https://a11y-scan-demo-7yt3mwgxp3wiy-app.azurewebsites.net'
    } else {
        'http://localhost:3000'
    }
}

$DefaultAppUrls = if ($Environment -eq 'azure') {
    @{
        '001' = 'https://a11y-demo-app-001-bnf6htmx2apog-app.azurewebsites.net'
        '002' = 'https://a11y-demo-app-002-tqo46d2qcc74q-app.azurewebsites.net'
        '003' = 'https://a11y-demo-app-003-o3nuquxlwptes-app.azurewebsites.net'
        '004' = 'https://a11y-demo-app-004-kpuhb2igkkuxg-app.azurewebsites.net'
        '005' = 'https://a11y-demo-app-005-4l6i3v3ihhr4y-app.azurewebsites.net'
    }
} else {
    @{
        '001' = 'http://localhost:8001'
        '002' = 'http://localhost:8002'
        '003' = 'http://localhost:8003'
        '004' = 'http://localhost:8004'
        '005' = 'http://localhost:8005'
    }
}

foreach ($key in $DefaultAppUrls.Keys) {
    if (-not $AppUrls.ContainsKey($key)) {
        $AppUrls[$key] = $DefaultAppUrls[$key]
    }
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$FreezeCommon = @(
    '--window'
    '--theme', $Theme
    '--font.size', $FontSize
    '--padding', '20,40'
    '--border.radius', '8'
    '--shadow.blur', '4'
    '--shadow.x', '0'
    '--shadow.y', '2'
)

$script:CaptureCount = 0
$script:FailureCount = 0
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# ── Helper Functions ─────────────────────────────────────────────────────────

function New-LabDirectory {
    <#
    .SYNOPSIS
        Creates images/lab-XX/ directory if it does not exist.
    #>
    param([string]$Lab)
    $dir = Join-Path $OutputDir "lab-$Lab"
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return $dir
}

function Test-ShouldCapture {
    <#
    .SYNOPSIS
        Returns $true if this lab and phase should be captured based on filters.
    #>
    param(
        [string]$Lab,
        [string]$CapturePhase
    )
    if ($LabFilter -and $Lab -ne $LabFilter) { return $false }
    if ($Phase -and $CapturePhase -ne $Phase) { return $false }
    return $true
}

function Invoke-FreezeScreenshot {
    <#
    .SYNOPSIS
        Execute a command and capture terminal output via freeze --execute.
    #>
    param(
        [string]$Command,
        [string]$OutputFile,
        [string]$Description
    )
    Write-Host "  Capturing: $Description" -ForegroundColor Gray
    try {
        $freezeArgs = @('--execute', $Command, '--output', $OutputFile) + $FreezeCommon
        & freeze @freezeArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
            $script:CaptureCount++
            Write-Host "    OK: $OutputFile" -ForegroundColor Green
        }
        else {
            $script:FailureCount++
            Write-Host "    FAIL: $OutputFile (freeze returned $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    catch {
        $script:FailureCount++
        Write-Host "    FAIL: $OutputFile ($_)" -ForegroundColor Red
    }
}

function Invoke-CapturedFreezeScreenshot {
    <#
    .SYNOPSIS
        Pre-capture command output to a temp file, then render with freeze.
    #>
    param(
        [string]$Command,
        [string]$OutputFile,
        [string]$Description
    )
    Write-Host "  Capturing: $Description" -ForegroundColor Gray
    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        $savedDir = (Get-Location).Path
        $absOutput = if ([System.IO.Path]::IsPathRooted($OutputFile)) { $OutputFile } else { Join-Path $savedDir $OutputFile }
        $output = Invoke-Expression $Command 2>&1
        Set-Location $savedDir
        $output | Out-File -FilePath $tempFile -Encoding utf8
        $freezeArgs = @('--output', $absOutput, '--language', 'text') + $FreezeCommon + @($tempFile)
        & freeze @freezeArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $absOutput)) {
            $script:CaptureCount++
            Write-Host "    OK: $OutputFile" -ForegroundColor Green
        }
        else {
            $script:FailureCount++
            Write-Host "    FAIL: $OutputFile (freeze returned $LASTEXITCODE)" -ForegroundColor Red
        }
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
    catch {
        Set-Location $savedDir -ErrorAction SilentlyContinue
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        $script:FailureCount++
        Write-Host "    FAIL: $OutputFile ($_)" -ForegroundColor Red
    }
}

function Invoke-FreezeFile {
    <#
    .SYNOPSIS
        Capture source file content with line numbers via freeze.
    #>
    param(
        [string]$FilePath,
        [string]$OutputFile,
        [string]$Description,
        [string]$Language = ''
    )
    Write-Host "  Capturing: $Description" -ForegroundColor Gray
    if (-not (Test-Path $FilePath)) {
        $script:FailureCount++
        Write-Host "    FAIL: Source file not found: $FilePath" -ForegroundColor Red
        return
    }
    try {
        $langArgs = @()
        if ($Language) {
            $langArgs = @('--language', $Language)
        }
        $freezeArgs = @('--output', $OutputFile, '--show-line-numbers') + $langArgs + $FreezeCommon + @($FilePath)
        & freeze @freezeArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
            $script:CaptureCount++
            Write-Host "    OK: $OutputFile" -ForegroundColor Green
        }
        else {
            $script:FailureCount++
            Write-Host "    FAIL: $OutputFile (freeze returned $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    catch {
        $script:FailureCount++
        Write-Host "    FAIL: $OutputFile ($_)" -ForegroundColor Red
    }
}

function Invoke-PlaywrightScreenshot {
    <#
    .SYNOPSIS
        Capture browser page via npx playwright screenshot.
    #>
    param(
        [string]$Url,
        [string]$OutputFile,
        [string]$Description,
        [switch]$FullPage
    )
    Write-Host "  Capturing: $Description" -ForegroundColor Gray
    try {
        $fullPageArg = if ($FullPage) { '--full-page' } else { '' }
        $playwrightArgs = @('playwright', 'screenshot', '--browser', 'chromium')
        if ($FullPage) { $playwrightArgs += '--full-page' }
        $playwrightArgs += @($Url, $OutputFile)
        & npx @playwrightArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
            $script:CaptureCount++
            Write-Host "    OK: $OutputFile" -ForegroundColor Green
        }
        else {
            $script:FailureCount++
            Write-Host "    FAIL: $OutputFile (playwright returned $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    catch {
        $script:FailureCount++
        Write-Host "    FAIL: $OutputFile ($_)" -ForegroundColor Red
    }
}

function Invoke-InteractiveScanCapture {
    <#
    .SYNOPSIS
        Capture interactive scan results via playwright-helpers.js scan action.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScannerUrl,

        [Parameter(Mandatory)]
        [string]$TargetUrl,

        [Parameter(Mandatory)]
        [string]$OutputFile,

        [Parameter()]
        [string]$Action = 'results',

        [Parameter()]
        [int]$Timeout = 120000,

        [Parameter()]
        [string]$Description = ''
    )

    Write-Host "  Capturing: $Description" -ForegroundColor Gray
    try {
        $nodeArgs = @('scripts/playwright-helpers.js', 'scan', $ScannerUrl, $TargetUrl, $OutputFile, '--action', $Action, '--timeout', $Timeout)
        & node @nodeArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
            $script:CaptureCount++
            Write-Host "    OK: $OutputFile" -ForegroundColor Green
        }
        else {
            $script:FailureCount++
            Write-Host "    FAIL: $OutputFile (interactive capture returned $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    catch {
        $script:FailureCount++
        Write-Host "    FAIL: $OutputFile ($_)" -ForegroundColor Red
    }
}

function Invoke-AuthenticatedPlaywrightScreenshot {
    <#
    .SYNOPSIS
        Capture authenticated browser page via playwright-helpers.js auth-screenshot action.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutputFile,

        [Parameter(Mandatory)]
        [string]$StorageState,

        [Parameter()]
        [switch]$FullPage,

        [Parameter()]
        [string]$Description = ''
    )

    if (-not (Test-Path $StorageState)) {
        Write-Host "    SKIP (no auth state): $Description" -ForegroundColor DarkYellow
        return
    }

    Write-Host "  Capturing: $Description" -ForegroundColor Gray
    try {
        $nodeArgs = @('scripts/playwright-helpers.js', 'auth-screenshot', $Url, $OutputFile, $StorageState)
        if ($FullPage) { $nodeArgs += '--full-page' }
        & node @nodeArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
            $script:CaptureCount++
            Write-Host "    OK: $OutputFile" -ForegroundColor Green
        }
        else {
            $script:FailureCount++
            Write-Host "    FAIL: $OutputFile (auth capture returned $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    catch {
        $script:FailureCount++
        Write-Host "    FAIL: $OutputFile ($_)" -ForegroundColor Red
    }
}

# ── Prerequisite Validation ──────────────────────────────────────────────────

Write-Host "`n=== Accessibility Scan Workshop Screenshot Capture ===" -ForegroundColor Cyan
Write-Host "Output directory: $OutputDir" -ForegroundColor Gray
Write-Host "Lab filter: $(if ($LabFilter) { $LabFilter } else { 'all' })" -ForegroundColor Gray
Write-Host "Phase filter: $(if ($Phase) { "Phase $Phase" } else { 'all' })" -ForegroundColor Gray
Write-Host "Theme: $Theme | Font size: $FontSize" -ForegroundColor Gray

$requiredTools = @('freeze', 'node', 'npx')
foreach ($tool in $requiredTools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: '$tool' not found on PATH. Please install it first." -ForegroundColor Red
        exit 1
    }
}
Write-Host "Prerequisite tools verified." -ForegroundColor Green

# ── Scanner Repo Path ────────────────────────────────────────────────────────

$ScannerRepoDir = Join-Path $PSScriptRoot '..\..\accessibility-scan-demo-app'
if (-not (Test-Path $ScannerRepoDir)) {
    $ScannerRepoDir = Join-Path $PSScriptRoot '..\accessibility-scan-demo-app'
}
if (-not (Test-Path $ScannerRepoDir)) {
    Write-Host "WARNING: Scanner repo not found. Some file screenshots will be skipped." -ForegroundColor Yellow
    $ScannerRepoDir = $null
}
else {
    $ScannerRepoDir = (Resolve-Path $ScannerRepoDir).Path
    Write-Host "Scanner repo: $ScannerRepoDir" -ForegroundColor Gray
}

# ── Phase 1: Offline Captures ───────────────────────────────────────────────
# Local tool versions, file content, scan outputs — no Azure or GitHub web needed

Write-Host "`n── Phase 1: Offline Captures ──" -ForegroundColor Cyan

# Lab 00: Tool version screenshots
if (Test-ShouldCapture -Lab '00' -CapturePhase '1') {
    Write-Host "`n[Lab 00] Tool versions" -ForegroundColor Yellow
    $lab00Dir = New-LabDirectory -Lab '00'

    Invoke-FreezeScreenshot `
        -Command 'node --version' `
        -OutputFile (Join-Path $lab00Dir 'lab-00-node-version.png') `
        -Description 'Node.js version'

    Invoke-FreezeScreenshot `
        -Command 'docker --version' `
        -OutputFile (Join-Path $lab00Dir 'lab-00-docker-version.png') `
        -Description 'Docker version'

    Invoke-FreezeScreenshot `
        -Command 'gh --version' `
        -OutputFile (Join-Path $lab00Dir 'lab-00-gh-version.png') `
        -Description 'GitHub CLI version'

    Invoke-CapturedFreezeScreenshot `
        -Command 'az --version' `
        -OutputFile (Join-Path $lab00Dir 'lab-00-az-version.png') `
        -Description 'Azure CLI version'

    Invoke-FreezeScreenshot `
        -Command 'pwsh --version' `
        -OutputFile (Join-Path $lab00Dir 'lab-00-pwsh-version.png') `
        -Description 'PowerShell version'

    Invoke-FreezeScreenshot `
        -Command 'freeze --version' `
        -OutputFile (Join-Path $lab00Dir 'lab-00-freeze-version.png') `
        -Description 'Charm freeze version'
}

# Lab 01: WCAG mapping reference file
if (Test-ShouldCapture -Lab '01' -CapturePhase '1') {
    Write-Host "`n[Lab 01] WCAG mapping reference" -ForegroundColor Yellow
    $lab01Dir = New-LabDirectory -Lab '01'

    if ($ScannerRepoDir) {
        $wcagRulesFile = Join-Path $ScannerRepoDir '.github\instructions\wcag22-rules.instructions.md'
        if (Test-Path $wcagRulesFile) {
            Invoke-FreezeFile `
                -FilePath $wcagRulesFile `
                -OutputFile (Join-Path $lab01Dir 'lab-01-wcag-mapping.png') `
                -Description 'WCAG 2.2 rules reference' `
                -Language 'markdown'
        }
        else {
            Write-Host "  SKIP: wcag22-rules.instructions.md not found" -ForegroundColor Yellow
        }
    }
}

# Lab 02: CLI scan output and API response
if (Test-ShouldCapture -Lab '02' -CapturePhase '1') {
    Write-Host "`n[Lab 02] axe-core scan outputs" -ForegroundColor Yellow
    $lab02Dir = New-LabDirectory -Lab '02'

    if ($ScannerRepoDir) {
        # Capture CLI help output showing scan command
        Invoke-CapturedFreezeScreenshot `
            -Command "cd '$ScannerRepoDir'; npx a11y-scan scan --help 2>&1 | Select-Object -First 40" `
            -OutputFile (Join-Path $lab02Dir 'lab-02-cli-output.png') `
            -Description 'CLI scan help output'

        # Capture API endpoint info from scanner source
        $engineFile = Join-Path $ScannerRepoDir 'src\lib\scanner\engine.ts'
        if (Test-Path $engineFile) {
            Invoke-FreezeFile `
                -FilePath $engineFile `
                -OutputFile (Join-Path $lab02Dir 'lab-02-api-response.png') `
                -Description 'Scanner engine source (API reference)' `
                -Language 'typescript'
        }
    }
}

# Lab 03: Comparison table and deduplication logic
if (Test-ShouldCapture -Lab '03' -CapturePhase '1') {
    Write-Host "`n[Lab 03] IBM Equal Access reference files" -ForegroundColor Yellow
    $lab03Dir = New-LabDirectory -Lab '03'

    if ($ScannerRepoDir) {
        # Capture package.json showing accessibility-checker dependency
        Invoke-CapturedFreezeScreenshot `
            -Command "cd '$ScannerRepoDir'; Get-Content package.json | Select-String -Pattern 'accessibility-checker|ibm|axe-core' -Context 1,1" `
            -OutputFile (Join-Path $lab03Dir 'lab-03-comparison-table.png') `
            -Description 'Scanner dependencies (axe vs IBM)'

        # Capture deduplication logic if present
        $dedupeFiles = @(
            (Join-Path $ScannerRepoDir 'src\lib\scanner\engine.ts'),
            (Join-Path $ScannerRepoDir 'src\lib\report\sarif-generator.ts')
        )
        foreach ($df in $dedupeFiles) {
            if (Test-Path $df) {
                Invoke-FreezeFile `
                    -FilePath $df `
                    -OutputFile (Join-Path $lab03Dir 'lab-03-deduplication.png') `
                    -Description 'Deduplication logic' `
                    -Language 'typescript'
                break
            }
        }
    }
}

# Lab 04: Custom checks source and results
if (Test-ShouldCapture -Lab '04' -CapturePhase '1') {
    Write-Host "`n[Lab 04] Custom Playwright checks" -ForegroundColor Yellow
    $lab04Dir = New-LabDirectory -Lab '04'

    if ($ScannerRepoDir) {
        # Capture custom-checks.ts source
        $customChecksFile = Join-Path $ScannerRepoDir 'src\lib\scanner\custom-checks.ts'
        if (Test-Path $customChecksFile) {
            Invoke-FreezeFile `
                -FilePath $customChecksFile `
                -OutputFile (Join-Path $lab04Dir 'lab-04-custom-checks-source.png') `
                -Description 'Custom checks source code' `
                -Language 'typescript'
        }
        else {
            Write-Host "  SKIP: custom-checks.ts not found" -ForegroundColor Yellow
        }

        # Capture a new check code example (use a11y-remediation instructions as reference)
        $remediationFile = Join-Path $ScannerRepoDir '.github\instructions\a11y-remediation.instructions.md'
        if (Test-Path $remediationFile) {
            Invoke-FreezeFile `
                -FilePath $remediationFile `
                -OutputFile (Join-Path $lab04Dir 'lab-04-new-check-code.png') `
                -Description 'Remediation patterns reference' `
                -Language 'markdown'
        }

        # Capture custom check run output placeholder
        Invoke-CapturedFreezeScreenshot `
            -Command "cd '$ScannerRepoDir'; npx a11y-scan scan --help 2>&1 | Select-Object -First 30" `
            -OutputFile (Join-Path $lab04Dir 'lab-04-custom-check-results.png') `
            -Description 'Custom check results (placeholder from CLI help)'

        Invoke-CapturedFreezeScreenshot `
            -Command "cd '$ScannerRepoDir'; npx a11y-scan scan --help 2>&1 | Select-Object -First 30" `
            -OutputFile (Join-Path $lab04Dir 'lab-04-new-check-results.png') `
            -Description 'New check results (placeholder from CLI help)'
    }
}

# Lab 05: SARIF file content
if (Test-ShouldCapture -Lab '05' -CapturePhase '1') {
    Write-Host "`n[Lab 05] SARIF output and structure" -ForegroundColor Yellow
    $lab05Dir = New-LabDirectory -Lab '05'

    if ($ScannerRepoDir) {
        # Capture SARIF generator source
        $sarifGenFile = Join-Path $ScannerRepoDir 'src\lib\report\sarif-generator.ts'
        if (Test-Path $sarifGenFile) {
            Invoke-FreezeFile `
                -FilePath $sarifGenFile `
                -OutputFile (Join-Path $lab05Dir 'lab-05-sarif-output.png') `
                -Description 'SARIF generator source code' `
                -Language 'typescript'
        }

        # Capture SARIF CI formatter source
        $sarifFormatterFile = Join-Path $ScannerRepoDir 'src\lib\ci\formatters\sarif.ts'
        if (Test-Path $sarifFormatterFile) {
            Invoke-FreezeFile `
                -FilePath $sarifFormatterFile `
                -OutputFile (Join-Path $lab05Dir 'lab-05-sarif-structure.png') `
                -Description 'SARIF CI formatter structure' `
                -Language 'typescript'
        }

        # Check for existing SARIF result files
        $sarifResults = Get-ChildItem -Path (Join-Path $ScannerRepoDir 'results') -Filter '*.json' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($sarifResults) {
            Invoke-FreezeFile `
                -FilePath $sarifResults.FullName `
                -OutputFile (Join-Path $lab05Dir 'lab-05-sarif-output.png') `
                -Description 'SARIF result file sample' `
                -Language 'json'
        }
    }
}

# Lab 06: Workflow YAML files and threshold config
if (Test-ShouldCapture -Lab '06' -CapturePhase '1') {
    Write-Host "`n[Lab 06] GitHub Actions workflow files" -ForegroundColor Yellow
    $lab06Dir = New-LabDirectory -Lab '06'

    if ($ScannerRepoDir) {
        # Capture CI workflow YAML
        $ciWorkflow = Join-Path $ScannerRepoDir '.github\workflows\ci.yml'
        if (Test-Path $ciWorkflow) {
            Invoke-FreezeFile `
                -FilePath $ciWorkflow `
                -OutputFile (Join-Path $lab06Dir 'lab-06-ci-workflow.png') `
                -Description 'CI workflow YAML' `
                -Language 'yaml'
        }

        # Capture scan workflow (a11y-scan.yml or scan-all.yml)
        $scanWorkflow = Join-Path $ScannerRepoDir '.github\workflows\a11y-scan.yml'
        if (-not (Test-Path $scanWorkflow)) {
            $scanWorkflow = Join-Path $ScannerRepoDir '.github\workflows\scan-all.yml'
        }
        if (Test-Path $scanWorkflow) {
            Invoke-FreezeFile `
                -FilePath $scanWorkflow `
                -OutputFile (Join-Path $lab06Dir 'lab-06-scan-workflow.png') `
                -Description 'Scan workflow matrix strategy' `
                -Language 'yaml'
        }

        # Capture OIDC setup script output
        $oidcScript = Join-Path $ScannerRepoDir 'scripts\setup-oidc.ps1'
        if (Test-Path $oidcScript) {
            Invoke-FreezeFile `
                -FilePath $oidcScript `
                -OutputFile (Join-Path $lab06Dir 'lab-06-oidc-setup.png') `
                -Description 'OIDC setup script' `
                -Language 'powershell'
        }

        # Capture threshold config from e2e fixtures
        $thresholdFile = Join-Path $ScannerRepoDir 'e2e\fixtures\threshold.ts'
        if (Test-Path $thresholdFile) {
            Invoke-FreezeFile `
                -FilePath $thresholdFile `
                -OutputFile (Join-Path $lab06Dir 'lab-06-threshold-config.png') `
                -Description 'Threshold configuration' `
                -Language 'typescript'
        }
    }
}

# Lab 07: Detector and resolver agent definitions
if (Test-ShouldCapture -Lab '07' -CapturePhase '1') {
    Write-Host "`n[Lab 07] Copilot agent definitions" -ForegroundColor Yellow
    $lab07Dir = New-LabDirectory -Lab '07'

    if ($ScannerRepoDir) {
        # Capture detector agent definition
        $detectorAgent = Join-Path $ScannerRepoDir '.github\agents\a11y-detector.agent.md'
        if (Test-Path $detectorAgent) {
            Invoke-FreezeFile `
                -FilePath $detectorAgent `
                -OutputFile (Join-Path $lab07Dir 'lab-07-detector-output.png') `
                -Description 'A11yDetector agent definition' `
                -Language 'markdown'
        }

        # Capture resolver agent definition
        $resolverAgent = Join-Path $ScannerRepoDir '.github\agents\a11y-resolver.agent.md'
        if (Test-Path $resolverAgent) {
            Invoke-FreezeFile `
                -FilePath $resolverAgent `
                -OutputFile (Join-Path $lab07Dir 'lab-07-resolver-fixes.png') `
                -Description 'A11yResolver agent definition' `
                -Language 'markdown'
        }
    }
}

# ── Phase 2: App-Dependent Captures ─────────────────────────────────────────
# Screenshots requiring demo apps running (locally or deployed to Azure)

Write-Host "`n── Phase 2: App-Dependent Captures ──" -ForegroundColor Cyan

# Lab 00: Scanner home page
if (Test-ShouldCapture -Lab '00' -CapturePhase '2') {
    Write-Host "`n[Lab 00] Scanner home page" -ForegroundColor Yellow
    $lab00Dir = New-LabDirectory -Lab '00'

    Invoke-PlaywrightScreenshot `
        -Url $ScannerUrl `
        -OutputFile (Join-Path $lab00Dir 'lab-00-scanner-home.png') `
        -Description "Scanner home page ($ScannerUrl)"
}

# Lab 01: Demo app pages
if (Test-ShouldCapture -Lab '01' -CapturePhase '2') {
    Write-Host "`n[Lab 01] Demo app pages" -ForegroundColor Yellow
    $lab01Dir = New-LabDirectory -Lab '01'

    $demoApps = @(
        @{ Name = '001'; Title = 'Travel Booking' }
        @{ Name = '002'; Title = 'E-Commerce' }
        @{ Name = '003'; Title = 'Learning Platform' }
        @{ Name = '004'; Title = 'Recipe Site' }
        @{ Name = '005'; Title = 'Fitness Tracker' }
    )

    foreach ($app in $demoApps) {
        Invoke-PlaywrightScreenshot `
            -Url $AppUrls[$app.Name] `
            -OutputFile (Join-Path $lab01Dir "lab-01-demo-app-$($app.Name).png") `
            -Description "Demo app $($app.Name) ($($app.Title))" `
            -FullPage
    }

    # Capture popup violation on app 001
    Invoke-PlaywrightScreenshot `
        -Url $AppUrls['001'] `
        -OutputFile (Join-Path $lab01Dir 'lab-01-violations-popup.png') `
        -Description 'Popup modal violation (app 001)'

    # DevTools audit is a browser screenshot
    Invoke-PlaywrightScreenshot `
        -Url $AppUrls['001'] `
        -OutputFile (Join-Path $lab01Dir 'lab-01-devtools-audit.png') `
        -Description 'DevTools accessibility audit placeholder'
}

# Lab 02: Web UI scan pages
if (Test-ShouldCapture -Lab '02' -CapturePhase '2') {
    Write-Host "`n[Lab 02] Scanner web UI" -ForegroundColor Yellow
    $lab02Dir = New-LabDirectory -Lab '02'

    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab02Dir 'lab-02-web-ui-scan.png') `
        -Action 'progress' `
        -Description 'Web UI scan in progress'

    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab02Dir 'lab-02-scan-results.png') `
        -Action 'results' `
        -Description 'Scan results overview'

    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab02Dir 'lab-02-violation-detail.png') `
        -Action 'detail' `
        -Description 'Violation detail view'

    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab02Dir 'lab-02-multi-app-comparison.png') `
        -Action 'comparison' `
        -Description 'Multi-app scan comparison'
}

# Lab 03: IBM scan results pages
if (Test-ShouldCapture -Lab '03' -CapturePhase '2') {
    Write-Host "`n[Lab 03] IBM Equal Access scan results" -ForegroundColor Yellow
    $lab03Dir = New-LabDirectory -Lab '03'

    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab03Dir 'lab-03-ibm-scan-results.png') `
        -Action 'results' `
        -Description 'IBM Equal Access scan results'

    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab03Dir 'lab-03-ibm-violation-detail.png') `
        -Action 'detail' `
        -Description 'IBM violation detail'

    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab03Dir 'lab-03-combined-report.png') `
        -Action 'results' `
        -Description 'Combined report output'
}

# Lab 04: Keyboard navigation testing
if (Test-ShouldCapture -Lab '04' -CapturePhase '2') {
    Write-Host "`n[Lab 04] Keyboard navigation testing" -ForegroundColor Yellow
    $lab04Dir = New-LabDirectory -Lab '04'

    Invoke-PlaywrightScreenshot `
        -Url $AppUrls['001'] `
        -OutputFile (Join-Path $lab04Dir 'lab-04-keyboard-test.png') `
        -Description 'Keyboard navigation testing on demo app 001'
}

# ── Phase 3: GitHub Web UI Captures ─────────────────────────────────────────
# Screenshots requiring GitHub authentication and uploaded scan results

Write-Host "`n── Phase 3: GitHub Web UI Captures ──" -ForegroundColor Cyan

$GitHubBaseUrl = "https://github.com/$Org/accessibility-scan-demo-app"

if (-not (Test-Path $GitHubAuthState)) {
    Write-Host "  Auth state not found at '$GitHubAuthState'. Phase 3 captures will be skipped." -ForegroundColor Yellow
    Write-Host "  To set up auth: npx playwright codegen --save-storage=$GitHubAuthState github.com" -ForegroundColor Yellow
}

# Lab 05: Security tab screenshots
if (Test-ShouldCapture -Lab '05' -CapturePhase '3') {
    Write-Host "`n[Lab 05] GitHub Security tab" -ForegroundColor Yellow
    $lab05Dir = New-LabDirectory -Lab '05'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/security/code-scanning" `
        -OutputFile (Join-Path $lab05Dir 'lab-05-security-tab.png') `
        -StorageState $GitHubAuthState `
        -Description 'Security tab code scanning alerts' `
        -FullPage

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/security/code-scanning" `
        -OutputFile (Join-Path $lab05Dir 'lab-05-alert-detail.png') `
        -StorageState $GitHubAuthState `
        -Description 'Alert detail view'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/security/code-scanning?query=severity%3Ahigh" `
        -OutputFile (Join-Path $lab05Dir 'lab-05-filter-severity.png') `
        -StorageState $GitHubAuthState `
        -Description 'Filter by severity'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/security/code-scanning" `
        -OutputFile (Join-Path $lab05Dir 'lab-05-triage-view.png') `
        -StorageState $GitHubAuthState `
        -Description 'Triage view'
}

# Lab 06: GitHub Actions pages
if (Test-ShouldCapture -Lab '06' -CapturePhase '3') {
    Write-Host "`n[Lab 06] GitHub Actions pages" -ForegroundColor Yellow
    $lab06Dir = New-LabDirectory -Lab '06'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/actions" `
        -OutputFile (Join-Path $lab06Dir 'lab-06-actions-runs.png') `
        -StorageState $GitHubAuthState `
        -Description 'GitHub Actions runs page' `
        -FullPage

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/actions" `
        -OutputFile (Join-Path $lab06Dir 'lab-06-matrix-jobs.png') `
        -StorageState $GitHubAuthState `
        -Description 'Matrix jobs running'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/actions" `
        -OutputFile (Join-Path $lab06Dir 'lab-06-deploy-status.png') `
        -StorageState $GitHubAuthState `
        -Description 'Deploy status'
}

# Lab 07: Remediation PR and score changes
if (Test-ShouldCapture -Lab '07' -CapturePhase '3') {
    Write-Host "`n[Lab 07] Remediation workflow" -ForegroundColor Yellow
    $lab07Dir = New-LabDirectory -Lab '07'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/pulls" `
        -OutputFile (Join-Path $lab07Dir 'lab-07-remediation-pr.png') `
        -StorageState $GitHubAuthState `
        -Description 'Remediation pull request'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl" `
        -OutputFile (Join-Path $lab07Dir 'lab-07-before-after.png') `
        -StorageState $GitHubAuthState `
        -Description 'Before/after score comparison'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl" `
        -OutputFile (Join-Path $lab07Dir 'lab-07-score-improvement.png') `
        -StorageState $GitHubAuthState `
        -Description 'Score improvement chart'
}

# ── Summary ──────────────────────────────────────────────────────────────────

$Stopwatch.Stop()
$Elapsed = $Stopwatch.Elapsed

Write-Host "`n=== Screenshot Capture Summary ===" -ForegroundColor Cyan
Write-Host "  Captured:  $($script:CaptureCount)" -ForegroundColor $(if ($script:CaptureCount -gt 0) { 'Green' } else { 'Yellow' })
Write-Host "  Failed:    $($script:FailureCount)" -ForegroundColor $(if ($script:FailureCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Elapsed:   $($Elapsed.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Host ""

if ($script:FailureCount -gt 0) {
    Write-Host "Some screenshots failed. Common causes:" -ForegroundColor Yellow
    Write-Host "  - Demo apps not running (start with docker build/run)" -ForegroundColor Yellow
    Write-Host "  - Scanner not running (start with ./start-local.ps1)" -ForegroundColor Yellow
    Write-Host "  - GitHub authentication required (run: gh auth login)" -ForegroundColor Yellow
    Write-Host "  - Playwright browsers not installed (run: npx playwright install chromium)" -ForegroundColor Yellow
}
