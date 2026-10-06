$ErrorActionPreference = 'Stop'

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
    switch ($Name.ToLowerInvariant()) {
        'npm' { return 'npm.cmd' }
        default { return $Name }
    }
}

function Test-SanroCommand([string]$Name) {
    $command = Get-SanroToolCommand $Name
    return $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

function Invoke-SanroConfiguredCommand([string]$ProjectRoot, $CommandConfig) {
    if ($null -eq $CommandConfig) { throw 'Configured command is missing.' }
    $working = [string]$CommandConfig.workingDirectory
    if ([string]::IsNullOrWhiteSpace($working)) { $working = '.' }
    $workDir = Join-Path $ProjectRoot $working
    if (-not (Test-Path -LiteralPath $workDir -PathType Container)) {
        throw "Configured working directory not found: $working"
    }
    $command = [string]$CommandConfig.command
    if ([string]::IsNullOrWhiteSpace($command)) { throw 'Configured command name is empty.' }
    $args = @($CommandConfig.args)
    Push-Location $workDir
    try {
        & $command @args
        return $LASTEXITCODE
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
