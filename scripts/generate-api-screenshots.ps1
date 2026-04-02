<#
.SYNOPSIS
    Generate Phase 3 screenshots from GitHub API data instead of browser screenshots.
    Uses gh CLI + freeze to produce distinct screenshots for GitHub web UI captures.
#>
param(
    [string]$Org = 'devopsabcs-engineering',
    [string]$Repo = 'accessibility-scan-demo-app',
    [string]$OutputDir = 'images'
)

$FreezeCommon = @(
    '--window'
    '--theme', 'dracula'
    '--font.size', '14'
    '--padding', '20,40'
    '--border.radius', '8'
    '--shadow.blur', '4'
    '--shadow.x', '0'
    '--shadow.y', '2'
)

function New-FreezeScreenshot {
    param([string]$Content, [string]$OutputFile, [string]$Description)
    Write-Host "  Generating: $Description" -ForegroundColor Gray
    $tempFile = [System.IO.Path]::GetTempFileName()
    $Content | Out-File -FilePath $tempFile -Encoding utf8
    $freezeArgs = @('--output', $OutputFile, '--language', 'text') + $FreezeCommon + @($tempFile)
    & freeze @freezeArgs 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
        Write-Host "    OK: $OutputFile" -ForegroundColor Green
    } else {
        Write-Host "    FAIL: $OutputFile" -ForegroundColor Red
    }
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

$BaseUrl = "$Org/$Repo"

# ── Lab 05: Security Tab Screenshots ──
Write-Host "`n[Lab 05] Security tab screenshots from API" -ForegroundColor Yellow

# 1. Security tab overview
$alerts = gh api "repos/$BaseUrl/code-scanning/alerts?per_page=15" 2>&1 | ConvertFrom-Json
$overview = "GitHub Security Tab - Code Scanning Alerts`n"
$overview += "Repository: $BaseUrl`n"
$overview += "=" * 60 + "`n`n"
$overview += "  #     State    Rule ID                        Severity`n"
$overview += "  ----  -------  -----------------------------  --------`n"
foreach ($a in $alerts | Select-Object -First 12) {
    $severity = if ($a.rule.security_severity_level) { $a.rule.security_severity_level } else { "medium" }
    $ruleId = $a.rule.id
    if ($ruleId.Length -gt 29) { $ruleId = $ruleId.Substring(0, 26) + "..." }
    $overview += "  {0,-5} {1,-8} {2,-30} {3}`n" -f $a.number, $a.state, $ruleId, $severity
}
$overview += "`n  Total alerts: $($alerts.Count)+"
New-FreezeScreenshot -Content $overview -OutputFile "$OutputDir/lab-05/lab-05-security-tab.png" -Description "Security tab overview (API)"

# 2. Alert detail
if ($alerts.Count -gt 0) {
    $alert = $alerts[0]
    $detail = "GitHub Code Scanning - Alert Detail`n"
    $detail += "=" * 60 + "`n`n"
    $detail += "  Alert #$($alert.number)`n"
    $detail += "  State:    $($alert.state)`n"
    $detail += "  Rule:     $($alert.rule.id)`n"
    $detail += "  Severity: $($alert.rule.security_severity_level)`n"
    $detail += "  Tool:     $($alert.tool.name) v$($alert.tool.version)`n`n"
    $desc = $alert.rule.description
    if ($desc.Length -gt 100) { $desc = $desc.Substring(0, 97) + "..." }
    $detail += "  Description:`n    $desc`n`n"
    $msg = $alert.most_recent_instance.message.text
    if ($msg.Length -gt 200) { $msg = $msg.Substring(0, 197) + "..." }
    $detail += "  Message:`n    $msg`n`n"
    $detail += "  Location: $($alert.most_recent_instance.location.path)`n"
    $detail += "  Created:  $($alert.created_at)"
    New-FreezeScreenshot -Content $detail -OutputFile "$OutputDir/lab-05/lab-05-alert-detail.png" -Description "Alert detail view (API)"
}

# 3. Filter by severity
$highAlerts = $alerts | Where-Object { $_.rule.security_severity_level -eq 'high' -or $_.rule.severity -eq 'error' }
$filterView = "GitHub Code Scanning - Filter: severity:high`n"
$filterView += "=" * 60 + "`n`n"
$filterView += "  Query: severity:high`n`n"
$filterView += "  #     Rule ID                        Severity  State`n"
$filterView += "  ----  -----------------------------  --------  -------`n"
foreach ($a in $highAlerts | Select-Object -First 8) {
    $ruleId = $a.rule.id
    if ($ruleId.Length -gt 29) { $ruleId = $ruleId.Substring(0, 26) + "..." }
    $filterView += "  {0,-5} {1,-30} {2,-9} {3}`n" -f $a.number, $ruleId, "high", $a.state
}
if ($highAlerts.Count -eq 0) {
    $filterView += "  (Showing error-level alerts instead)`n"
    foreach ($a in ($alerts | Select-Object -First 5)) {
        $ruleId = $a.rule.id
        if ($ruleId.Length -gt 29) { $ruleId = $ruleId.Substring(0, 26) + "..." }
        $filterView += "  {0,-5} {1,-30} {2,-9} {3}`n" -f $a.number, $ruleId, ($a.rule.security_severity_level ?? "medium"), $a.state
    }
}
$filterView += "`n  Showing $($highAlerts.Count) high-severity alerts"
New-FreezeScreenshot -Content $filterView -OutputFile "$OutputDir/lab-05/lab-05-filter-severity.png" -Description "Severity filter view (API)"

# 4. Triage view (open alerts sorted by date)
$triageView = "GitHub Code Scanning - Triage View`n"
$triageView += "=" * 60 + "`n`n"
$triageView += "  Query: is:open sort:created-desc`n`n"
$triageView += "  #     Created              Rule ID                  State`n"
$triageView += "  ----  -------------------  -----------------------  -------`n"
foreach ($a in ($alerts | Where-Object { $_.state -eq 'open' } | Select-Object -First 8)) {
    $date = $a.created_at.Substring(0, 19).Replace('T', ' ')
    $ruleId = $a.rule.id
    if ($ruleId.Length -gt 23) { $ruleId = $ruleId.Substring(0, 20) + "..." }
    $triageView += "  {0,-5} {1,-20} {2,-24} {3}`n" -f $a.number, $date, $ruleId, $a.state
}
$triageView += "`n  Triage: Review each alert, dismiss false positives,`n"
$triageView += "  prioritize critical/serious violations for remediation."
New-FreezeScreenshot -Content $triageView -OutputFile "$OutputDir/lab-05/lab-05-triage-view.png" -Description "Triage view (API)"

# ── Lab 06: GitHub Actions Screenshots ──
Write-Host "`n[Lab 06] GitHub Actions screenshots from API" -ForegroundColor Yellow

# Actions runs overview
$runs = gh api "repos/$BaseUrl/actions/runs?per_page=10" 2>&1 | ConvertFrom-Json
$actionsView = "GitHub Actions - Workflow Runs`n"
$actionsView += "Repository: $BaseUrl`n"
$actionsView += "=" * 60 + "`n`n"
$actionsView += "  Status  Workflow                   Branch   Duration`n"
$actionsView += "  ------  -------------------------  -------  --------`n"
foreach ($r in $runs.workflow_runs | Select-Object -First 8) {
    $status = switch ($r.conclusion) { 'success' { '[pass]' } 'failure' { '[FAIL]' } $null { '[run.]' } default { "[$($r.conclusion)]" } }
    $name = $r.name
    if ($name.Length -gt 25) { $name = $name.Substring(0, 22) + "..." }
    $branch = $r.head_branch
    if ($branch.Length -gt 7) { $branch = $branch.Substring(0, 7) }
    $actionsView += "  {0,-6} {1,-26} {2,-8} --`n" -f $status, $name, $branch
}
New-FreezeScreenshot -Content $actionsView -OutputFile "$OutputDir/lab-06/lab-06-actions-runs.png" -Description "Actions runs overview (API)"

# Matrix jobs view - specific scan workflow
$scanRuns = $runs.workflow_runs | Where-Object { $_.name -match 'scan|a11y' } | Select-Object -First 1
if ($scanRuns) {
    $jobs = gh api "repos/$BaseUrl/actions/runs/$($scanRuns.id)/jobs" 2>&1 | ConvertFrom-Json
    $matrixView = "GitHub Actions - Matrix Jobs`n"
    $matrixView += "Workflow: $($scanRuns.name) (#$($scanRuns.run_number))`n"
    $matrixView += "=" * 60 + "`n`n"
    $matrixView += "  Status  Job Name                   Duration`n"
    $matrixView += "  ------  -------------------------  --------`n"
    foreach ($j in $jobs.jobs) {
        $status = switch ($j.conclusion) { 'success' { '[pass]' } 'failure' { '[FAIL]' } $null { '[run.]' } default { "[$($j.conclusion)]" } }
        $name = $j.name
        if ($name.Length -gt 25) { $name = $name.Substring(0, 22) + "..." }
        $matrixView += "  {0,-6} {1,-26} --`n" -f $status, $name
    }
    New-FreezeScreenshot -Content $matrixView -OutputFile "$OutputDir/lab-06/lab-06-matrix-jobs.png" -Description "Matrix jobs view (API)"
} else {
    # Fallback: use first run's jobs
    $jobs = gh api "repos/$BaseUrl/actions/runs/$($runs.workflow_runs[0].id)/jobs" 2>&1 | ConvertFrom-Json
    $matrixView = "GitHub Actions - Workflow Jobs`n"
    $matrixView += "Workflow: $($runs.workflow_runs[0].name) (#$($runs.workflow_runs[0].run_number))`n"
    $matrixView += "=" * 60 + "`n`n"
    foreach ($j in $jobs.jobs | Select-Object -First 6) {
        $status = switch ($j.conclusion) { 'success' { '[pass]' } 'failure' { '[FAIL]' } $null { '[run.]' } default { "[$($j.conclusion)]" } }
        $matrixView += "  $status  $($j.name)`n"
    }
    New-FreezeScreenshot -Content $matrixView -OutputFile "$OutputDir/lab-06/lab-06-matrix-jobs.png" -Description "Workflow jobs view (API)"
}

# Deploy status - deployment workflows
$deployRuns = $runs.workflow_runs | Where-Object { $_.name -match 'deploy|Deploy' } | Select-Object -First 1
if (-not $deployRuns) { $deployRuns = $runs.workflow_runs | Select-Object -First 1 -Skip 1 }
$deployView = "GitHub Actions - Deployment Status`n"
$deployView += "=" * 60 + "`n`n"
if ($deployRuns) {
    $deployView += "  Workflow: $($deployRuns.name)`n"
    $deployView += "  Run:     #$($deployRuns.run_number)`n"
    $deployView += "  Status:  $($deployRuns.conclusion ?? 'in_progress')`n"
    $deployView += "  Branch:  $($deployRuns.head_branch)`n"
    $deployView += "  Commit:  $($deployRuns.head_sha.Substring(0, 7))`n"
    $deployView += "  Created: $($deployRuns.created_at.Substring(0, 19).Replace('T', ' '))`n"
} else {
    $deployView += "  No deployment workflows found`n"
}
New-FreezeScreenshot -Content $deployView -OutputFile "$OutputDir/lab-06/lab-06-deploy-status.png" -Description "Deploy status view (API)"

# ── Lab 07: Remediation PR ──
Write-Host "`n[Lab 07] Remediation PR screenshot from API" -ForegroundColor Yellow

$prs = gh api "repos/$BaseUrl/pulls?state=all&per_page=5" 2>&1 | ConvertFrom-Json
$prView = "GitHub Pull Requests - Remediation`n"
$prView += "Repository: $BaseUrl`n"
$prView += "=" * 60 + "`n`n"
$prView += "  #     State   Title`n"
$prView += "  ----  ------  ------------------------------------------`n"
foreach ($pr in $prs | Select-Object -First 5) {
    $state = if ($pr.state -eq 'open') { 'OPEN' } else { 'MERGED' }
    $title = $pr.title
    if ($title.Length -gt 42) { $title = $title.Substring(0, 39) + "..." }
    $prView += "  {0,-5} {1,-7} {2}`n" -f $pr.number, $state, $title
}
$prView += "`n  Remediation PRs contain before/after scan evidence."
New-FreezeScreenshot -Content $prView -OutputFile "$OutputDir/lab-07/lab-07-remediation-pr.png" -Description "Remediation PR list (API)"

Write-Host "`nDone!" -ForegroundColor Green
