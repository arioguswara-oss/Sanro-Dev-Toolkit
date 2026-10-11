$ErrorActionPreference = 'Stop'

function Get-SanroCiConfig($ProjectConfig) {
    if ($null -eq $ProjectConfig.ci) {
        throw 'ci is not configured in sanro-dev.project.json.'
    }
    return $ProjectConfig.ci
}

function Get-SanroCiGitState([string]$ProjectRoot) {
    Push-Location $ProjectRoot
    try {
        $branch = (& git branch --show-current 2>$null | Select-Object -First 1)
        $commit = (& git rev-parse HEAD 2>$null | Select-Object -First 1)
        $porcelain = @(& git status --porcelain 2>$null)
        return [ordered]@{
            branch = if ($branch) { ([string]$branch).Trim() } else { '' }
            commit = if ($commit) { ([string]$commit).Trim() } else { '' }
            dirty = ($porcelain.Count -gt 0)
            changedFileCount = $porcelain.Count
        }
    }
    finally { Pop-Location }
}

function Test-SanroCiEnvironmentName([string]$Name) {
    return $Name -match '^[A-Za-z_][A-Za-z0-9_]*$'
}

function Get-SanroCiEnvironmentMetadata($CommandConfig) {
    $literalKeys = @()
    if ($null -ne $CommandConfig.environment) {
        $literalKeys = @($CommandConfig.environment.PSObject.Properties | ForEach-Object { [string]$_.Name })
    }
    $required = @($CommandConfig.requiredEnvironment | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return [ordered]@{
        environmentKeys = @($literalKeys)
        requiredEnvironment = @($required)
    }
}

function Get-SanroCiEnvironmentPlan($CommandConfig) {
    $literal = [ordered]@{}
    $required = @()
    $missing = @()
    $sensitiveValues = @()

    if ($null -ne $CommandConfig.environment) {
        foreach ($property in $CommandConfig.environment.PSObject.Properties) {
            $name = [string]$property.Name
            if (-not (Test-SanroCiEnvironmentName $name)) {
                throw "Invalid environment variable name in CI manifest: $name"
            }
            $value = $property.Value
            if ($value -is [System.Array] -or $value -is [System.Management.Automation.PSCustomObject]) {
                throw "CI environment value must be scalar: $name"
            }
            $text = if ($null -eq $value) { '' } else { [string]$value }
            $literal[$name] = $text
            if ($text.Length -ge 4) { $sensitiveValues += $text }
        }
    }

    foreach ($raw in @($CommandConfig.requiredEnvironment)) {
        $name = [string]$raw
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        if (-not (Test-SanroCiEnvironmentName $name)) {
            throw "Invalid required environment variable name in CI manifest: $name"
        }
        $required += $name
        $value = [Environment]::GetEnvironmentVariable($name, 'Process')
        if ([string]::IsNullOrWhiteSpace($value)) {
            $missing += $name
        }
        elseif ($value.Length -ge 4) {
            $sensitiveValues += $value
        }
    }

    return [ordered]@{
        literal = $literal
        required = @($required)
        missing = @($missing)
        sensitiveValues = @($sensitiveValues | Select-Object -Unique)
    }
}

function Protect-SanroCiText([string]$Text, $SensitiveValues = @()) {
    $safe = [string]$Text
    foreach ($value in @($SensitiveValues)) {
        $secret = [string]$value
        if ($secret.Length -ge 4) {
            $safe = $safe.Replace($secret, '[REDACTED_ENV]')
        }
    }
    $safe = $safe -replace '(?i)((?:password|passwd|pwd|token|secret|credential|api[_-]?key)\s*[:=]\s*)([^\s,;]+)', '$1[REDACTED]'
    return $safe
}

function ConvertTo-SanroCiCommandSummary($CommandConfig) {
    $args = @($CommandConfig.args | ForEach-Object { [string]$_ })
    $environment = Get-SanroCiEnvironmentMetadata $CommandConfig
    return [ordered]@{
        name = [string]$CommandConfig.name
        workingDirectory = if ([string]::IsNullOrWhiteSpace([string]$CommandConfig.workingDirectory)) { '.' } else { [string]$CommandConfig.workingDirectory }
        command = [string]$CommandConfig.command
        args = $args
        environmentKeys = @($environment.environmentKeys)
        requiredEnvironment = @($environment.requiredEnvironment)
    }
}

function Invoke-SanroCiConfiguredCommand {
    param(
        [string]$ProjectRoot,
        $CommandConfig,
        [switch]$Quiet
    )

    $summary = ConvertTo-SanroCiCommandSummary $CommandConfig
    try {
        $environmentPlan = Get-SanroCiEnvironmentPlan $CommandConfig
    }
    catch {
        return [ordered]@{
            status = 'BLOCKED'
            exitCode = 2
            durationMs = 0
            command = $summary
            logTail = @((Protect-SanroCiText ([string]$_)))
        }
    }

    if ($environmentPlan.missing.Count -gt 0) {
        return [ordered]@{
            status = 'BLOCKED'
            exitCode = 2
            durationMs = 0
            command = $summary
            logTail = @("Missing required CI environment variables: $($environmentPlan.missing -join ', ')")
        }
    }

    $working = [string]$CommandConfig.workingDirectory
    if ([string]::IsNullOrWhiteSpace($working)) { $working = '.' }
    $workDir = Join-Path $ProjectRoot $working
    if (-not (Test-Path -LiteralPath $workDir -PathType Container)) {
        return [ordered]@{
            status = 'BLOCKED'
            exitCode = 2
            durationMs = 0
            command = $summary
            logTail = @("Configured working directory not found: $working")
        }
    }

    $configuredCommand = [string]$CommandConfig.command
    if ([string]::IsNullOrWhiteSpace($configuredCommand)) {
        return [ordered]@{
            status = 'BLOCKED'
            exitCode = 2
            durationMs = 0
            command = $summary
            logTail = @('Configured command name is empty.')
        }
    }

    $command = Get-SanroToolCommand $configuredCommand
    if ($null -eq (Get-Command $command -ErrorAction SilentlyContinue)) {
        return [ordered]@{
            status = 'BLOCKED'
            exitCode = 2
            durationMs = 0
            command = $summary
            logTail = @("Configured command unavailable on $(Get-SanroPlatform): $configuredCommand (resolved: $command)")
        }
    }

    $commandArgs = @($CommandConfig.args | ForEach-Object { [string]$_ })
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $output = @()
    $exitCode = 1
    $originalEnvironment = @{}
    $hadOriginalEnvironment = @{}

    foreach ($key in $environmentPlan.literal.Keys) {
        $existing = [Environment]::GetEnvironmentVariable($key, 'Process')
        $hadOriginalEnvironment[$key] = ($null -ne $existing)
        $originalEnvironment[$key] = $existing
        [Environment]::SetEnvironmentVariable($key, [string]$environmentPlan.literal[$key], 'Process')
    }

    Push-Location $workDir
    try {
        $output = @(& $command @commandArgs 2>&1 | ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = if ($?) { 0 } else { 1 } }
    }
    catch {
        $output += [string]$_
        $exitCode = 1
    }
    finally {
        Pop-Location
        foreach ($key in $environmentPlan.literal.Keys) {
            if ($hadOriginalEnvironment[$key]) {
                [Environment]::SetEnvironmentVariable($key, [string]$originalEnvironment[$key], 'Process')
            }
            else {
                [Environment]::SetEnvironmentVariable($key, $null, 'Process')
            }
        }
        $stopwatch.Stop()
    }

    $safeOutput = @($output | ForEach-Object { Protect-SanroCiText ([string]$_) $environmentPlan.sensitiveValues })
    if (-not $Quiet) {
        foreach ($line in $safeOutput) { Write-Host $line }
    }

    $tailCount = [Math]::Min(40, $safeOutput.Count)
    $tail = if ($tailCount -gt 0) { @($safeOutput | Select-Object -Last $tailCount) } else { @() }
    return [ordered]@{
        status = if ([int]$exitCode -eq 0) { 'PASS' } else { 'FAIL' }
        exitCode = [int]$exitCode
        durationMs = [int64]$stopwatch.ElapsedMilliseconds
        command = $summary
        logTail = $tail
    }
}

function Get-SanroPowerShellCommand {
    $pwsh = Get-Command 'pwsh' -ErrorAction SilentlyContinue
    if ($null -ne $pwsh) { return $pwsh.Source }

    $windowsPowerShell = Get-Command 'powershell' -ErrorAction SilentlyContinue
    if ($null -ne $windowsPowerShell) { return $windowsPowerShell.Source }

    throw 'No PowerShell executable is available for isolated Toolkit child execution.'
}

function Invoke-SanroCiFastCheck {
    param(
        [string]$ProjectRoot,
        [string]$ToolsRoot,
        [switch]$Quiet
    )

    $script = Join-Path $ToolsRoot 'check.ps1'
    $shell = Get-SanroPowerShellCommand
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $output = @()
    $exitCode = 1
    try {
        $output = @(& $shell -NoLogo -NoProfile -File $script -ProjectRoot $ProjectRoot 2>&1 | ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = if ($?) { 0 } else { 1 } }
    }
    catch {
        $output += [string]$_
        $exitCode = 1
    }
    finally { $stopwatch.Stop() }

    if (-not $Quiet) {
        foreach ($line in $output) { Write-Host $line }
    }

    $tailCount = [Math]::Min(40, $output.Count)
    $tail = if ($tailCount -gt 0) { @($output | Select-Object -Last $tailCount) } else { @() }
    return [ordered]@{
        status = if ([int]$exitCode -eq 0) { 'PASS' } else { 'FAIL' }
        exitCode = [int]$exitCode
        durationMs = [int64]$stopwatch.ElapsedMilliseconds
        command = [ordered]@{
            name = 'SANRO fast check'
            workingDirectory = '.'
            command = 'builtin:fast-check'
            args = @()
            environmentKeys = @()
            requiredEnvironment = @()
        }
        logTail = $tail
    }
}

function Get-SanroCiStageDefinition($CiConfig, [string]$StageName) {
    if ($null -eq $CiConfig.stages) { return $null }
    $property = $CiConfig.stages.PSObject.Properties[$StageName]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Get-SanroCiArtifactState([string]$ProjectRoot, $CiConfig) {
    $artifacts = @()
    foreach ($item in @($CiConfig.artifactOutputs)) {
        if ($null -eq $item) { continue }
        $path = if ($item -is [string]) { [string]$item } else { [string]$item.path }
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        $required = if ($item -is [string]) { $true } elseif ($null -eq $item.required) { $true } else { [bool]$item.required }
        $fullPath = Join-Path $ProjectRoot $path
        $artifacts += [ordered]@{
            path = $path
            required = $required
            exists = (Test-Path -LiteralPath $fullPath)
        }
    }
    return @($artifacts)
}

function Write-SanroCiReport {
    param(
        [string]$ProjectRoot,
        $CiConfig,
        $Report
    )

    $relative = [string]$CiConfig.reportDirectory
    if ([string]::IsNullOrWhiteSpace($relative)) { $relative = '.sanro-ci' }
    $reportRoot = Join-Path $ProjectRoot $relative
    $runRoot = Join-Path $reportRoot 'runs'
    New-Item -ItemType Directory -Force -Path $runRoot | Out-Null

    $runPath = Join-Path $runRoot ("{0}.json" -f $Report.runId)
    $latestPath = Join-Path $reportRoot 'latest.json'
    $json = $Report | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $runPath -Value $json -Encoding UTF8
    Set-Content -LiteralPath $latestPath -Value $json -Encoding UTF8

    return [ordered]@{
        run = $runPath
        latest = $latestPath
    }
}
