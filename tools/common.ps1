$ErrorActionPreference = 'Stop'

function Get-SanroPlatform {
    if ($env:OS -eq 'Windows_NT' -or $IsWindows) { return 'windows' }
    if ($IsLinux) { return 'linux' }
    if ($IsMacOS) { return 'macos' }
    return 'unknown'
}

function Get-SanroLinuxDistribution {
    if ((Get-SanroPlatform) -ne 'linux') { return '' }
    $path = '/etc/os-release'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return '' }
    $line = Get-Content -LiteralPath $path | Where-Object { $_ -match '^ID=' } | Select-Object -First 1
    if (-not $line) { return '' }
    return (($line -replace '^ID=', '').Trim().Trim('"').Trim("'")).ToLowerInvariant()
}

function Resolve-SanroProjectRoot([string]$ProjectRoot) {
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = (Get-Location).Path }
    $resolved = Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop
    return $resolved.Path
}

function Get-SanroProjectConfig([string]$ProjectRoot) {
    $root = Resolve-SanroProjectRoot $ProjectRoot
    $path = Join-Path $root 'sanro-dev.project.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "sanro-dev.project.json not found in $root"
    }
    $config = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    if ([int]$config.schemaVersion -ne 1) {
        throw "Unsupported sanro-dev.project.json schemaVersion: $($config.schemaVersion)"
    }
    return [pscustomobject]@{ Root = $root; Path = $path; Config = $config }
}

function Get-SanroToolCommand([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { return $Name }

    $platform = Get-SanroPlatform
    $candidate = $Name.Trim()

    if ($platform -eq 'windows') {
        switch ($candidate.ToLowerInvariant()) {
            'npm' { return 'npm.cmd' }
            'npx' { return 'npx.cmd' }
            default { return $candidate }
        }
    }

    if ($candidate.EndsWith('.cmd', [System.StringComparison]::OrdinalIgnoreCase)) {
        $candidate = $candidate.Substring(0, $candidate.Length - 4)
    }

    if ($platform -eq 'linux' -and $candidate -ieq 'fd') {
        if ($null -ne (Get-Command 'fd' -ErrorAction SilentlyContinue)) { return 'fd' }
        if ($null -ne (Get-Command 'fdfind' -ErrorAction SilentlyContinue)) { return 'fdfind' }
    }

    return $candidate
}

function Test-SanroCommand([string]$Name) {
    $command = Get-SanroToolCommand $Name
    return -not [string]::IsNullOrWhiteSpace($command) -and $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

function Get-SanroToolVersion([string]$Name) {
    $command = Get-SanroToolCommand $Name
    if ([string]::IsNullOrWhiteSpace($command)) { return '' }
    $value = & $command --version 2>$null | Select-Object -First 1
    if ($null -eq $value) { return '' }
    return ([string]$value).Trim()
}

function Invoke-SanroConfiguredCommand([string]$ProjectRoot, $CommandConfig) {
    if ($null -eq $CommandConfig) { throw 'Configured command is missing.' }
    $working = [string]$CommandConfig.workingDirectory
    if ([string]::IsNullOrWhiteSpace($working)) { $working = '.' }
    $workDir = Join-Path $ProjectRoot $working
    if (-not (Test-Path -LiteralPath $workDir -PathType Container)) {
        throw "Configured working directory not found: $working"
    }
    $configuredCommand = [string]$CommandConfig.command
    if ([string]::IsNullOrWhiteSpace($configuredCommand)) { throw 'Configured command name is empty.' }
    $command = Get-SanroToolCommand $configuredCommand
    if ($null -eq (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Configured command unavailable on $(Get-SanroPlatform): $configuredCommand (resolved: $command)"
    }
    $commandArgs = @($CommandConfig.args | ForEach-Object { [string]$_ })
    Push-Location $workDir
    try {
        & $command @commandArgs | ForEach-Object { Write-Host $_ }
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }
        return [int]$exitCode
    }
    finally { Pop-Location }
}

function Get-SanroChangedFiles([string]$ProjectRoot) {
    Push-Location $ProjectRoot
    try {
        $changed = @(git -c core.quotepath=false diff --name-only --diff-filter=ACMR HEAD)
        if ($LASTEXITCODE -ne 0) { throw 'Cannot list changed files.' }
        $untracked = @(git -c core.quotepath=false ls-files --others --exclude-standard)
        if ($LASTEXITCODE -ne 0) { throw 'Cannot list untracked files.' }
        return @(($changed + $untracked) | Where-Object { $_ } | Sort-Object -Unique)
    }
    finally { Pop-Location }
}
