<#
.SYNOPSIS
    Capture all workshop screenshots for Accessibility Scan Workshop labs 00-07
    (GitHub track) and labs 06-ado/07-ado (ADO track).

.DESCRIPTION
    Automates screenshot capture for workshop labs using Charm freeze (terminal
    output) and Playwright (browser pages). Produces PNG files organized into
    images/lab-XX/ directories. Supports GitHub-only, ADO-only, or both platforms.

    Phase 1 — Offline captures (freeze, freeze-file)
    Phase 2 — App-dependent captures (Playwright, no auth)
    Phase 3 — GitHub Web UI captures (authenticated Playwright)
    Phase 4 — ADO Web UI captures (authenticated Playwright)

.NOTES
    Prerequisites:
    - freeze (Charm CLI) installed — https://github.com/charmbracelet/freeze
    - Node.js and npx installed (for Playwright)
    - GitHub CLI (gh) authenticated (Phase 3 only)
    - Azure DevOps auth state file (Phase 4 only)
    - Azure CLI (az) authenticated (Phase 2/3 only)
    - Scanner repo cloned at sibling directory

.PARAMETER Platform
    Which platform track to capture: 'github', 'ado', or 'both' (default).

.PARAMETER AdoAuthState
    Path to Playwright storage state JSON for ADO authentication (Phase 4).

.PARAMETER AdoOrg
    Azure DevOps organization name. Default: MngEnvMCAP675646.

.PARAMETER AdoProject
    Azure DevOps project name (URL-encoded). Default: AODA%20WCAG%20Compliance.

.EXAMPLE
    .\scripts\capture-screenshots.ps1
    Captures all screenshots across all labs and platforms.

.EXAMPLE
    .\scripts\capture-screenshots.ps1 -LabFilter '02'
    Captures only Lab 02 screenshots.

.EXAMPLE
    .\scripts\capture-screenshots.ps1 -Phase 1
    Captures only Phase 1 (offline) screenshots.

.EXAMPLE
    .\scripts\capture-screenshots.ps1 -Platform ado -Phase 4
    Captures only Phase 4 ADO web UI screenshots.

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
    [ValidateSet('', '1', '2', '3', '4')]
    [string]$Phase = '',

    [Parameter()]
    [ValidateSet('local', 'azure')]
    [string]$Environment = 'azure',

    [Parameter()]
    [string]$ScannerUrl = '',

    [Parameter()]
    [hashtable]$AppUrls = @{},

    [Parameter()]
    [ValidateSet('github', 'ado', 'both')]
    [string]$Platform = 'both',

    [Parameter()]
    [string]$AdoAuthState = 'ado-auth.json',

    [Parameter()]
    [string]$AdoOrg = 'MngEnvMCAP675646',

    [Parameter()]
    [string]$AdoProject = 'AODA%20WCAG%20Compliance'
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

# ── ADO URL Resolution ───────────────────────────────────────────────────────
$AdoBaseUrl = "https://dev.azure.com/$AdoOrg/$AdoProject"
$AdoAdvSecUrl = "https://advsec.dev.azure.com/$AdoOrg/$AdoProject"

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
        Returns $true if this lab, phase, and platform should be captured based on filters.
    #>
    param(
        [string]$Lab,
        [string]$CapturePhase,
        [string]$CapturePlatform = ''
    )
    if ($LabFilter -and $Lab -ne $LabFilter) { return $false }
    if ($Phase -and $CapturePhase -ne $Phase) { return $false }
    if ($CapturePlatform -and $Platform -ne 'both' -and $Platform -ne $CapturePlatform) { return $false }
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
Write-Host "Platform: $Platform" -ForegroundColor Gray
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
        # Capture CLI help output by running built CLI directly
        Invoke-CapturedFreezeScreenshot `
            -Command "cd '$ScannerRepoDir'; node dist/cli/bin/a11y-scan.js --help 2>&1 | Select-Object -First 40" `
            -OutputFile (Join-Path $lab02Dir 'lab-02-cli-output.png') `
            -Description 'CLI scan help output'

        # Capture scanner API response structure (first 50 lines of engine)
        Invoke-CapturedFreezeScreenshot `
            -Command "cd '$ScannerRepoDir'; Get-Content src\lib\scanner\engine.ts | Select-Object -First 50" `
            -OutputFile (Join-Path $lab02Dir 'lab-02-api-response.png') `
            -Description 'Scanner API response structure (first 50 lines)'
    }
}

# Lab 03: Comparison table and deduplication logic
if (Test-ShouldCapture -Lab '03' -CapturePhase '1') {
    Write-Host "`n[Lab 03] IBM Equal Access reference files" -ForegroundColor Yellow
    $lab03Dir = New-LabDirectory -Lab '03'

    if ($ScannerRepoDir) {
        # Capture package.json showing scanner engine dependencies
        Invoke-CapturedFreezeScreenshot `
            -Command "cd '$ScannerRepoDir'; Write-Output '=== Scanner Engine Comparison ==='; Write-Output ''; `$deps = (Get-Content package.json | ConvertFrom-Json).dependencies; Write-Output ('axe-core (Playwright):  ' + `$deps.'@axe-core/playwright'); Write-Output ('IBM Equal Access:       ' + `$deps.'accessibility-checker'); Write-Output ''; Write-Output '=== Engine Differences ==='; Write-Output 'axe-core: WCAG 2.x rules, fast, widely adopted'; Write-Output 'IBM EAC:  IBM-specific policies, broader coverage'" `
            -OutputFile (Join-Path $lab03Dir 'lab-03-comparison-table.png') `
            -Description 'Scanner engine comparison (axe-core vs IBM)'

        # Capture deduplication logic if present
        $dedupeFiles = @(
            (Join-Path $ScannerRepoDir 'src\lib\report\sarif-generator.ts'),
            (Join-Path $ScannerRepoDir 'src\lib\scanner\engine.ts')
        )
        foreach ($df in $dedupeFiles) {
            if (Test-Path $df) {
                Invoke-CapturedFreezeScreenshot `
                    -Command "Get-Content '$df' -TotalCount 60" `
                    -OutputFile (Join-Path $lab03Dir 'lab-03-deduplication.png') `
                    -Description 'Deduplication logic (first 60 lines)'
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
            Invoke-CapturedFreezeScreenshot `
                -Command "Get-Content '$customChecksFile' -TotalCount 50" `
                -OutputFile (Join-Path $lab04Dir 'lab-04-custom-checks-source.png') `
                -Description 'Custom checks source code (first 50 lines)'
        }
        else {
            Write-Host "  SKIP: custom-checks.ts not found" -ForegroundColor Yellow
        }

        # Capture a new check code example (use a11y-remediation instructions as reference)
        $remediationFile = Join-Path $ScannerRepoDir '.github\instructions\a11y-remediation.instructions.md'
        if (Test-Path $remediationFile) {
            Invoke-CapturedFreezeScreenshot `
                -Command "Get-Content '$remediationFile' -TotalCount 50" `
                -OutputFile (Join-Path $lab04Dir 'lab-04-new-check-code.png') `
                -Description 'Remediation patterns reference (first 50 lines)'
        }

        # Capture result normalizer (distinct from custom-checks-source)
        $resultNormalizerFile = Join-Path $ScannerRepoDir 'src\lib\scanner\result-normalizer.ts'
        if (Test-Path $resultNormalizerFile) {
            Invoke-CapturedFreezeScreenshot `
                -Command "Get-Content '$resultNormalizerFile' -TotalCount 50" `
                -OutputFile (Join-Path $lab04Dir 'lab-04-custom-check-results.png') `
                -Description 'Custom check result normalizer (first 50 lines)'
        }

        # Capture axe fixture for new check patterns (distinct from custom-checks)
        $newCheckFile = Join-Path $ScannerRepoDir 'e2e\fixtures\axe-fixture.ts'
        if (-not (Test-Path $newCheckFile)) {
            $newCheckFile = Join-Path $ScannerRepoDir 'e2e\fixtures\threshold.ts'
        }
        if (Test-Path $newCheckFile) {
            Invoke-FreezeFile `
                -FilePath $newCheckFile `
                -OutputFile (Join-Path $lab04Dir 'lab-04-new-check-results.png') `
                -Description 'New check results implementation' `
                -Language 'typescript'
        }
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

# Lab 06-ado: ADO Advanced Security YAML and SARIF files
if (Test-ShouldCapture -Lab '06-ado' -CapturePhase '1' -CapturePlatform 'ado') {
    Write-Host "`n[Lab 06-ado] ADO Advanced Security files" -ForegroundColor Yellow
    $lab06AdoDir = New-LabDirectory -Lab '06-ado'

    if ($ScannerRepoDir) {
        # SARIF file content (first 40 lines to avoid freeze memory limit)
        $sarifFiles = Get-ChildItem -Path (Join-Path $ScannerRepoDir 'results') -Filter '*.json' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($sarifFiles) {
            Invoke-CapturedFreezeScreenshot `
                -Command "Get-Content '$($sarifFiles.FullName)' -TotalCount 40" `
                -OutputFile (Join-Path $lab06AdoDir 'lab-06-ado-sarif-file.png') `
                -Description 'SARIF output file (first 40 lines)'
        }

        # Pipeline YAML
        $advsecPipeline = Join-Path $ScannerRepoDir '.azuredevops\pipelines\a11y-scan-advancedsecurity.yml'
        if (Test-Path $advsecPipeline) {
            Invoke-FreezeFile `
                -FilePath $advsecPipeline `
                -OutputFile (Join-Path $lab06AdoDir 'lab-06-ado-pipeline-yaml.png') `
                -Description 'ADO Advanced Security pipeline YAML' `
                -Language 'yaml'
        }
    }
}

# Lab 07-ado: ADO pipeline YAML files and templates
if (Test-ShouldCapture -Lab '07-ado' -CapturePhase '1' -CapturePlatform 'ado') {
    Write-Host "`n[Lab 07-ado] ADO pipeline files" -ForegroundColor Yellow
    $lab07AdoDir = New-LabDirectory -Lab '07-ado'

    if ($ScannerRepoDir) {
        # Pipeline basics (ci.yml)
        $ciPipeline = Join-Path $ScannerRepoDir '.azuredevops\pipelines\ci.yml'
        if (Test-Path $ciPipeline) {
            Invoke-FreezeFile `
                -FilePath $ciPipeline `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-pipeline-basics.png') `
                -Description 'ADO CI pipeline basics' `
                -Language 'yaml'
        }

        # Scan matrix (a11y-scan.yml)
        $scanPipeline = Join-Path $ScannerRepoDir '.azuredevops\pipelines\a11y-scan.yml'
        if (Test-Path $scanPipeline) {
            Invoke-FreezeFile `
                -FilePath $scanPipeline `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-scan-matrix.png') `
                -Description 'Multi-stage scan pipeline matrix' `
                -Language 'yaml'
        }

        # Schedule syntax (scan-and-store.yml)
        $schedulePipeline = Join-Path $ScannerRepoDir '.azuredevops\pipelines\scan-and-store.yml'
        if (Test-Path $schedulePipeline) {
            Invoke-FreezeFile `
                -FilePath $schedulePipeline `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-schedule-syntax.png') `
                -Description 'Schedule trigger syntax' `
                -Language 'yaml'
        }

        # Templates directory listing
        $templatesDir = Join-Path $ScannerRepoDir '.azuredevops\pipelines\templates'
        if (Test-Path $templatesDir) {
            Invoke-CapturedFreezeScreenshot `
                -Command "Get-ChildItem '$templatesDir' -Name" `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-templates-dir.png') `
                -Description 'Pipeline templates directory listing'
        }

        # Template parameters (deploy-app-stage.yml)
        $templateFile = Join-Path $ScannerRepoDir '.azuredevops\pipelines\templates\deploy-app-stage.yml'
        if (Test-Path $templateFile) {
            Invoke-FreezeFile `
                -FilePath $templateFile `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-template-params.png') `
                -Description 'Pipeline template parameters' `
                -Language 'yaml'
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

    # DevTools audit — capture scanner results overview as audit proxy
    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab01Dir 'lab-01-devtools-audit.png') `
        -Action 'results' `
        -Description 'Accessibility audit results overview'
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
        -TargetUrl $AppUrls['002'] `
        -OutputFile (Join-Path $lab03Dir 'lab-03-ibm-violation-detail.png') `
        -Action 'detail' `
        -Description 'IBM violation detail (app 002)'

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

    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab04Dir 'lab-04-keyboard-test.png') `
        -Action 'detail' `
        -Description 'Keyboard navigation test results'
}

# ── Phase 3: GitHub Web UI Captures ─────────────────────────────────────────
# Screenshots requiring GitHub authentication and uploaded scan results
if ($Platform -in @('github', 'both')) {
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
        -Url "$GitHubBaseUrl/security/code-scanning/1" `
        -OutputFile (Join-Path $lab05Dir 'lab-05-alert-detail.png') `
        -StorageState $GitHubAuthState `
        -Description 'Alert detail view (specific alert)'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/security/code-scanning?query=severity%3Ahigh" `
        -OutputFile (Join-Path $lab05Dir 'lab-05-filter-severity.png') `
        -StorageState $GitHubAuthState `
        -Description 'Filter by severity'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/security/code-scanning?query=is%3Aopen+sort%3Acreated-desc" `
        -OutputFile (Join-Path $lab05Dir 'lab-05-triage-view.png') `
        -StorageState $GitHubAuthState `
        -Description 'Triage view (open alerts sorted by date)'
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
        -Url "$GitHubBaseUrl/actions/workflows/a11y-scan.yml" `
        -OutputFile (Join-Path $lab06Dir 'lab-06-matrix-jobs.png') `
        -StorageState $GitHubAuthState `
        -Description 'Matrix jobs in scan workflow'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/actions/workflows/deploy-all.yml" `
        -OutputFile (Join-Path $lab06Dir 'lab-06-deploy-status.png') `
        -StorageState $GitHubAuthState `
        -Description 'Deployment workflow status'
}

# Lab 07: Remediation PR and score changes
if (Test-ShouldCapture -Lab '07' -CapturePhase '3') {
    Write-Host "`n[Lab 07] Remediation workflow" -ForegroundColor Yellow
    $lab07Dir = New-LabDirectory -Lab '07'

    Invoke-AuthenticatedPlaywrightScreenshot `
        -Url "$GitHubBaseUrl/pulls?q=is%3Apr+is%3Aopen+label%3Aaccessibility" `
        -OutputFile (Join-Path $lab07Dir 'lab-07-remediation-pr.png') `
        -StorageState $GitHubAuthState `
        -Description 'Accessibility remediation pull requests'

    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab07Dir 'lab-07-before-after.png') `
        -Action 'comparison' `
        -Description 'Before/after score comparison'

    Invoke-InteractiveScanCapture `
        -ScannerUrl $ScannerUrl `
        -TargetUrl $AppUrls['001'] `
        -OutputFile (Join-Path $lab07Dir 'lab-07-score-improvement.png') `
        -Action 'results' `
        -Description 'Score improvement visualization'
}

} # end Phase 3 GitHub platform gate

# ── Phase 4: ADO Web UI Captures ────────────────────────────────────────────
# Screenshots requiring Azure DevOps authentication

if ($Platform -in @('ado', 'both')) {
    Write-Host "`n── Phase 4: ADO Web UI Captures ──" -ForegroundColor Cyan

    if (-not (Test-Path $AdoAuthState)) {
        Write-Host "  ADO auth state not found at '$AdoAuthState'. Phase 4 captures will be skipped." -ForegroundColor Yellow
        Write-Host "  To set up auth: npx playwright codegen --save-storage=$AdoAuthState dev.azure.com" -ForegroundColor Yellow
    }
    else {
        # Lab 06-ado: ADO Advanced Security pages
        if (Test-ShouldCapture -Lab '06-ado' -CapturePhase '4' -CapturePlatform 'ado') {
            Write-Host "`n[Lab 06-ado] ADO Advanced Security pages" -ForegroundColor Yellow
            $lab06AdoDir = New-LabDirectory -Lab '06-ado'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoBaseUrl/_settings/repositories" `
                -OutputFile (Join-Path $lab06AdoDir 'lab-06-ado-advsec-settings.png') `
                -StorageState $AdoAuthState `
                -Description 'ADO Advanced Security settings panel'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoBaseUrl/_settings/repositories" `
                -OutputFile (Join-Path $lab06AdoDir 'lab-06-ado-advsec-enable.png') `
                -StorageState $AdoAuthState `
                -Description 'Enable Advanced Security confirmation'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoBaseUrl/_build" `
                -OutputFile (Join-Path $lab06AdoDir 'lab-06-ado-pipeline-run.png') `
                -StorageState $AdoAuthState `
                -Description 'Pipeline execution run view'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoBaseUrl/_build" `
                -OutputFile (Join-Path $lab06AdoDir 'lab-06-ado-pipeline-logs.png') `
                -StorageState $AdoAuthState `
                -Description 'Pipeline logs showing SARIF upload'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoAdvSecUrl/_advsec/overview" `
                -OutputFile (Join-Path $lab06AdoDir 'lab-06-ado-advsec-overview.png') `
                -StorageState $AdoAuthState `
                -Description 'Advanced Security Overview dashboard'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoAdvSecUrl/_advsec/alerts" `
                -OutputFile (Join-Path $lab06AdoDir 'lab-06-ado-advsec-alerts.png') `
                -StorageState $AdoAuthState `
                -Description 'Alerts listed by severity'
        }

        # Lab 07-ado: ADO Pipeline pages
        if (Test-ShouldCapture -Lab '07-ado' -CapturePhase '4' -CapturePlatform 'ado') {
            Write-Host "`n[Lab 07-ado] ADO Pipeline pages" -ForegroundColor Yellow
            $lab07AdoDir = New-LabDirectory -Lab '07-ado'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoBaseUrl/_library?itemType=VariableGroups" `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-variable-groups.png') `
                -StorageState $AdoAuthState `
                -Description 'Variable groups in ADO portal'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoBaseUrl/_environments" `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-environments.png') `
                -StorageState $AdoAuthState `
                -Description 'Environments list in ADO'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoBaseUrl/_environments" `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-approval-gate.png') `
                -StorageState $AdoAuthState `
                -Description 'Approval gate configuration'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoBaseUrl/_build" `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-scan-run.png') `
                -StorageState $AdoAuthState `
                -Description 'Scan pipeline run view'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoBaseUrl/_build" `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-deploy-stages.png') `
                -StorageState $AdoAuthState `
                -Description 'Multi-stage deployment view'

            Invoke-AuthenticatedPlaywrightScreenshot `
                -Url "$AdoBaseUrl/_workitems" `
                -OutputFile (Join-Path $lab07AdoDir 'lab-07-ado-workitem-link.png') `
                -StorageState $AdoAuthState `
                -Description 'AB# work item linked from commit'
        }
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────

$Stopwatch.Stop()
$Elapsed = $Stopwatch.Elapsed

Write-Host "`n=== Screenshot Capture Summary ===" -ForegroundColor Cyan
Write-Host "  Captured:  $($script:CaptureCount)" -ForegroundColor $(if ($script:CaptureCount -gt 0) { 'Green' } else { 'Yellow' })
Write-Host "  Failed:    $($script:FailureCount)" -ForegroundColor $(if ($script:FailureCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Platform:  $Platform" -ForegroundColor Gray
Write-Host "  Elapsed:   $($Elapsed.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Host ""

if ($script:FailureCount -gt 0) {
    Write-Host "Some screenshots failed. Common causes:" -ForegroundColor Yellow
    Write-Host "  - Demo apps not running (start with docker build/run)" -ForegroundColor Yellow
    Write-Host "  - Scanner not running (start with ./start-local.ps1)" -ForegroundColor Yellow
    Write-Host "  - GitHub authentication required (run: gh auth login)" -ForegroundColor Yellow
    Write-Host "  - Playwright browsers not installed (run: npx playwright install chromium)" -ForegroundColor Yellow
}
