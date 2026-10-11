param(
    [string]$ProjectRoot = (Get-Location).Path,
    [ValidateSet('lint','unit','integration','build','verify','release-check','ci')]
    [string]$Mode = 'ci',
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
. (Join-Path $PSScriptRoot 'ci-common.ps1')

$state = Get-SanroProjectConfig $ProjectRoot
$root = $state.Root
$config = $state.Config
$ci = Get-SanroCiConfig $config
$quiet = [bool]$Json

$pipeline = switch ($Mode) {
    'lint' { @('lint') }
    'unit' { @('unit') }
    'integration' { @('integration') }
    'build' { @('build') }
    'verify' { @('verify') }
    default {
        $configured = @($ci.pipeline | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($configured.Count -eq 0) { @('check') } else { $configured }
    }
}

$started = [DateTimeOffset]::UtcNow
$runId = $started.ToString('yyyyMMddTHHmmssfffZ')
$gitBefore = Get-SanroCiGitState $root
$stageResults = @()
$hasRequiredFailure = $false
$hasRequiredBlocked = $false

if (-not $quiet) {
    Write-Host ("SANRO LOCAL CI - {0}" -f $Mode.ToUpperInvariant())
    Write-Host ("Project: {0}" -f $config.project)
    Write-Host ("Branch: {0}" -f $gitBefore.branch)
    Write-Host ("Commit: {0}" -f $gitBefore.commit)
}

foreach ($stageName in $pipeline) {
    $stage = Get-SanroCiStageDefinition $ci $stageName

    if ($null -eq $stage) {
        $result = [ordered]@{
            name = $stageName
            required = $true
            status = 'BLOCKED'
            exitCode = 2
            durationMs = 0
            steps = @()
            logTail = @("CI stage is listed in pipeline but not configured: $stageName")
        }
        $stageResults += $result
        $hasRequiredBlocked = $true
        if (-not $quiet) { Write-Host ("[BLOCKED] {0}: not configured" -f $stageName) }
        continue
    }

    $enabled = if ($null -eq $stage.enabled) { $true } else { [bool]$stage.enabled }
    $required = if ($null -eq $stage.required) { $true } else { [bool]$stage.required }

    if (-not $enabled) {
        $stageResults += [ordered]@{
            name = $stageName
            required = $required
            status = 'SKIP'
            exitCode = 0
            durationMs = 0
            steps = @()
            logTail = @('Stage disabled by project manifest.')
        }
        if (-not $quiet) { Write-Host ("[SKIP] {0}" -f $stageName) }
        continue
    }

    if (-not $quiet) { Write-Host ("--- {0} ---" -f $stageName) }
    $stageWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $steps = @()

    if ([string]$stage.builtin -eq 'fast-check') {
        $steps += Invoke-SanroCiFastCheck -ProjectRoot $root -ToolsRoot $PSScriptRoot -Quiet:$quiet
    }
    elseif ($null -ne $stage.commands) {
        foreach ($commandConfig in @($stage.commands)) {
            $steps += Invoke-SanroCiConfiguredCommand -ProjectRoot $root -CommandConfig $commandConfig -Quiet:$quiet
            if ($steps[-1].status -ne 'PASS' -and [bool]$ci.failFast) { break }
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$stage.command)) {
        $steps += Invoke-SanroCiConfiguredCommand -ProjectRoot $root -CommandConfig $stage -Quiet:$quiet
    }
    else {
        $steps += [ordered]@{
            status = 'BLOCKED'
            exitCode = 2
            durationMs = 0
            command = $null
            logTail = @("Stage has no builtin, command, or commands: $stageName")
        }
    }

    $stageWatch.Stop()
    $blocked = @($steps | Where-Object { $_.status -eq 'BLOCKED' }).Count -gt 0
    $failed = @($steps | Where-Object { $_.status -eq 'FAIL' }).Count -gt 0
    $stageStatus = if ($blocked) { 'BLOCKED' } elseif ($failed) { 'FAIL' } else { 'PASS' }
    $stageExit = if ($blocked) { 2 } elseif ($failed) { 1 } else { 0 }
    $tail = @($steps | ForEach-Object { @($_.logTail) } | Select-Object -Last 40)

    $stageResults += [ordered]@{
        name = $stageName
        required = $required
        status = $stageStatus
        exitCode = $stageExit
        durationMs = [int64]$stageWatch.ElapsedMilliseconds
        steps = $steps
        logTail = $tail
    }

    if ($required -and $stageStatus -eq 'BLOCKED') { $hasRequiredBlocked = $true }
    if ($required -and $stageStatus -eq 'FAIL') { $hasRequiredFailure = $true }

    if (-not $quiet) { Write-Host ("[{0}] {1}" -f $stageStatus, $stageName) }
    if ([bool]$ci.failFast -and $required -and $stageStatus -ne 'PASS') { break }
}

$releaseChecks = @()
$artifactState = Get-SanroCiArtifactState $root $ci

if ($Mode -eq 'release-check') {
    $gitRelease = Get-SanroCiGitState $root
    $release = $ci.releaseValidation
    $requireClean = if ($null -eq $release -or $null -eq $release.requireCleanWorkingTree) { $true } else { [bool]$release.requireCleanWorkingTree }
    $enforceApproval = if ($null -eq $release -or $null -eq $release.enforceProductionApproval) { $true } else { [bool]$release.enforceProductionApproval }
    $requireArtifacts = if ($null -eq $release -or $null -eq $release.requireArtifacts) { $false } else { [bool]$release.requireArtifacts }

    $cleanPass = (-not $requireClean) -or (-not $gitRelease.dirty)
    $releaseChecks += [ordered]@{
        name = 'clean-working-tree'
        required = $requireClean
        status = if ($cleanPass) { 'PASS' } else { 'FAIL' }
        detail = if ($cleanPass) { 'Working tree policy satisfied.' } else { 'Working tree has uncommitted changes.' }
    }
    if (-not $cleanPass) { $hasRequiredFailure = $true }

    $missingArtifacts = @($artifactState | Where-Object { $_.required -and -not $_.exists })
    $artifactPass = (-not $requireArtifacts) -or ($missingArtifacts.Count -eq 0)
    $releaseChecks += [ordered]@{
        name = 'artifacts'
        required = $requireArtifacts
        status = if ($artifactPass) { 'PASS' } else { 'FAIL' }
        detail = if ($artifactPass) { 'Artifact policy satisfied.' } else { "Missing required artifacts: $($missingArtifacts.path -join ', ')" }
    }
    if (-not $artifactPass) { $hasRequiredFailure = $true }

    $productionApprovalRequired = if ($null -eq $ci.deploymentPolicy -or $null -eq $ci.deploymentPolicy.productionApprovalRequired) { $true } else { [bool]$ci.deploymentPolicy.productionApprovalRequired }
    $autoDeploy = if ($null -eq $ci.deploymentPolicy -or $null -eq $ci.deploymentPolicy.autoDeploy) { $false } else { [bool]$ci.deploymentPolicy.autoDeploy }
    $policyPass = (-not $enforceApproval) -or ($productionApprovalRequired -and -not $autoDeploy)
    $releaseChecks += [ordered]@{
        name = 'production-safety-policy'
        required = $enforceApproval
        status = if ($policyPass) { 'PASS' } else { 'FAIL' }
        detail = if ($policyPass) { 'Production approval remains required and auto-deploy is disabled.' } else { 'Unsafe deployment policy: production approval must be required and autoDeploy must be false.' }
    }
    if (-not $policyPass) { $hasRequiredFailure = $true }
}

$finished = [DateTimeOffset]::UtcNow
$overallStatus = if ($hasRequiredBlocked) { 'BLOCKED' } elseif ($hasRequiredFailure) { 'FAIL' } else { 'PASS' }
$exitCode = if ($overallStatus -eq 'PASS') { 0 } elseif ($overallStatus -eq 'BLOCKED') { 2 } else { 1 }

$report = [ordered]@{
    schemaVersion = 1
    tool = 'SANRO Dev Toolkit'
    mode = $Mode
    runId = $runId
    project = [ordered]@{
        name = [string]$config.project
        type = [string]$config.projectType
        root = $root
    }
    source = $gitBefore
    startedAt = $started.ToString('o')
    finishedAt = $finished.ToString('o')
    durationMs = [int64]($finished - $started).TotalMilliseconds
    status = $overallStatus
    exitCode = $exitCode
    productionMutation = $false
    pipeline = @($pipeline)
    stages = @($stageResults)
    artifacts = @($artifactState)
    releaseChecks = @($releaseChecks)
    policies = [ordered]@{
        dependency = $ci.dependencyPolicy
        deployment = $ci.deploymentPolicy
        rollback = $ci.rollbackPolicy
        healthCheck = $ci.healthCheck
    }
}

$paths = Write-SanroCiReport -ProjectRoot $root -CiConfig $ci -Report $report
$report['reportFiles'] = $paths
# Rewrite once so persisted report also contains its own locations.
$null = Write-SanroCiReport -ProjectRoot $root -CiConfig $ci -Report $report

if ($Json) {
    $report | ConvertTo-Json -Depth 20
}
else {
    Write-Host ("SANRO LOCAL CI {0}" -f $overallStatus)
    Write-Host ("Report: {0}" -f $paths.latest)
    Write-Host ("Production mutation: false")
}

exit $exitCode
