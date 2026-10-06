param(
    [string]$ProjectRoot = (Get-Location).Path,
    [int]$RecentCommitCount = 0
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$state = Get-SanroProjectConfig $ProjectRoot
$root = $state.Root
$config = $state.Config
$handoff = $config.handoff

function Get-HandoffValue([string]$Name, $DefaultValue) {
    if ($null -ne $handoff -and $null -ne $handoff.PSObject.Properties[$Name]) {
        $value = $handoff.$Name
        if ($null -ne $value -and -not ([string]$value -eq '')) { return $value }
    }
    return $DefaultValue
}

function Show-HandoffPath([string]$Label, [string]$RelativePath) {
    if ([string]::IsNullOrWhiteSpace($RelativePath)) { return }
    $full = Join-Path $root $RelativePath
    if (Test-Path -LiteralPath $full -PathType Leaf) {
        Write-Host ("[OK] {0}: {1}" -f $Label, $RelativePath)
    }
    else {
        Write-Host ("[MISSING] {0}: {1}" -f $Label, $RelativePath)
    }
}

function Test-SensitivePath([string]$RelativePath) {
    if ([string]::IsNullOrWhiteSpace($RelativePath)) { return $false }
    return $RelativePath -match '(?i)(^|[\\/])\.env($|\.)|(^|[\\/])id_(rsa|ed25519)($|\.)|\.(pem|key|p12|pfx)$|(^|[\\/]).*(secret|credential|token).*(\.|$)'
}

$agentsFile = [string](Get-HandoffValue 'agentsFile' 'AGENTS.md')
$workboard = [string](Get-HandoffValue 'workboard' '')
$checkpoint = [string](Get-HandoffValue 'checkpoint' '')
$remoteIsSource = [bool](Get-HandoffValue 'remoteIsSourceOfTruth' $true)
$configuredCount = [int](Get-HandoffValue 'recentCommitCount' 8)
if ($RecentCommitCount -le 0) { $RecentCommitCount = $configuredCount }
if ($RecentCommitCount -lt 1) { $RecentCommitCount = 1 }
if ($RecentCommitCount -gt 20) { $RecentCommitCount = 20 }
$rules = @()
if ($null -ne $handoff -and $null -ne $handoff.PSObject.Properties['rules']) {
    $rules = @($handoff.rules | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
}

Write-Host 'SANRO DEV TOOLKIT - CROSS-AGENT HANDOFF'
Write-Host ("Project : {0}" -f $config.project)
Write-Host ("Root    : {0}" -f $root)
Write-Host ("Remote source of truth: {0}" -f $(if ($remoteIsSource) { 'YES' } else { 'NO' }))
Write-Host ''

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host '[FAIL] git is unavailable.'
    exit 1
}

Push-Location $root
try {
    & git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host '[FAIL] ProjectRoot is not a Git work tree.'
        exit 1
    }

    $branch = @(& git branch --show-current 2>$null | Select-Object -First 1)
    $branchName = if ($branch.Count -and $branch[0]) { [string]$branch[0] } else { 'DETACHED' }

    $head = @(& git rev-parse --short=12 HEAD 2>$null | Select-Object -First 1)
    $hasHead = $LASTEXITCODE -eq 0 -and $head.Count -and $head[0]
    $headText = if ($hasHead) { [string]$head[0] } else { 'NO_COMMIT_YET' }

    $upstream = @(& git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null | Select-Object -First 1)
    $hasUpstream = $LASTEXITCODE -eq 0 -and $upstream.Count -and $upstream[0]

    $statusLines = @(& git -c core.quotepath=false status --short 2>$null)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read git status.' }

    Write-Host ("Branch  : {0}" -f $branchName)
    Write-Host ("HEAD    : {0}" -f $headText)
    Write-Host ("Upstream: {0}" -f $(if ($hasUpstream) { [string]$upstream[0] } else { 'NOT_CONFIGURED' }))
    Write-Host ("Working tree changes: {0}" -f $statusLines.Count)
    Write-Host ''

    Write-Host 'Shared memory / entry files:'
    Show-HandoffPath 'Agents' $agentsFile
    Show-HandoffPath 'Workboard' $workboard
    Show-HandoffPath 'Checkpoint' $checkpoint
    foreach ($rule in $rules) { Show-HandoffPath 'Rule' ([string]$rule) }
    Write-Host ''

    Write-Host 'Changed paths:'
    if ($hasHead) {
        try {
            $changed = @(Get-SanroChangedFiles $root)
            if (-not $changed.Count) {
                Write-Host '  (clean)'
            }
            else {
                $shown = 0
                $hidden = 0
                foreach ($path in $changed) {
                    if (Test-SensitivePath ([string]$path)) { $hidden++; continue }
                    if ($shown -lt 15) {
                        Write-Host ("  {0}" -f $path)
                        $shown++
                    }
                }
                if ($hidden -gt 0) { Write-Host ("  [REDACTED] {0} sensitive-looking path(s)" -f $hidden) }
                $remaining = $changed.Count - $shown - $hidden
                if ($remaining -gt 0) { Write-Host ("  ... +{0} more path(s)" -f $remaining) }
            }
        }
        catch {
            Write-Host '  [WARN] changed path summary unavailable.'
        }
    }
    else {
        Write-Host '  (unavailable until first commit)'
    }
    Write-Host ''

    Write-Host ("Recent commits (max {0}):" -f $RecentCommitCount)
    if ($hasHead) {
        $recent = @(& git log -n $RecentCommitCount --pretty=format:'%h %s' 2>$null)
        if ($LASTEXITCODE -eq 0 -and $recent.Count) {
            foreach ($line in $recent) { Write-Host ("  {0}" -f $line) }
        }
        else { Write-Host '  (unavailable)' }
    }
    else { Write-Host '  (no commits yet)' }
}
finally {
    Pop-Location
}

Write-Host ''
Write-Host 'NEXT: sync remote -> read only relevant shared-memory sections -> take a non-conflicting lane -> use context -> scoped work.'
Write-Host 'This command is read-only and does not prove hosting/production state.'
exit 0
