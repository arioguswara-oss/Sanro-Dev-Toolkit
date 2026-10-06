param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$InstallMissing,
    [switch]$SkipDependencies
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$state = Get-SanroProjectConfig $ProjectRoot
$root = $state.Root
$config = $state.Config
$failed = $false

function Refresh-ProcessPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = @($machine, $user) -join ';'
}

function Install-WingetPackage([string]$Id) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget unavailable; install this tool manually.'
    }
    Write-Host "[INSTALL] $Id"
    & winget install --id $Id -e --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget install failed: $Id" }
    Refresh-ProcessPath
}

function Try-InstallTool([string]$Name) {
    switch ($Name.ToLowerInvariant()) {
        'git' { Install-WingetPackage 'Git.Git' }
        'node' { Install-WingetPackage 'OpenJS.NodeJS.LTS' }
        'npm' {
            if (-not (Test-SanroCommand 'node')) { Install-WingetPackage 'OpenJS.NodeJS.LTS' }
            Refresh-ProcessPath
        }
        'rg' { Install-WingetPackage 'BurntSushi.ripgrep.MSVC' }
        'fd' { Install-WingetPackage 'sharkdp.fd' }
        'ast-grep' {
            if (-not (Test-SanroCommand 'npm')) { Install-WingetPackage 'OpenJS.NodeJS.LTS' }
            & npm.cmd install --global '@ast-grep/cli'
            if ($LASTEXITCODE -ne 0) { throw 'npm global install failed for ast-grep.' }
            Refresh-ProcessPath
        }
        default { throw "No automatic installer registered for '$Name'." }
    }
}

Write-Host 'SANRO DEV TOOLKIT - WINDOWS BOOTSTRAP'
Write-Host ("Project: {0}" -f $config.project)
Write-Host ("Root   : {0}" -f $root)
Write-Host ''

$required = @($config.requiredTools)
$optional = @($config.optionalTools)
$allTools = @($required + $optional | Where-Object { $_ } | Sort-Object -Unique)

foreach ($name in $allTools) {
    $isRequired = $required -contains $name
    if (-not (Test-SanroCommand $name) -and $InstallMissing) {
        try { Try-InstallTool $name }
        catch { Write-Host ("[WARN] {0}: {1}" -f $name, $_) }
    }

    if (Test-SanroCommand $name) {
        $command = Get-SanroToolCommand $name
        $version = @(& $command --version 2>$null | Select-Object -First 1)
        Write-Host ("[OK] {0}: {1}" -f $name, $version)
    }
    elseif ($isRequired) {
        Write-Host ("[FAIL] required tool unavailable: {0}" -f $name)
        $failed = $true
    }
    else {
        Write-Host ("[OPTIONAL] unavailable: {0}" -f $name)
    }
}

if ($config.minimumNodeMajor -and (Test-SanroCommand 'node')) {
    $rawNode = (& node --version).Trim().TrimStart('v')
    $major = 0
    [int]::TryParse(($rawNode -split '\.')[0], [ref]$major) | Out-Null
    if ($major -lt [int]$config.minimumNodeMajor) {
        Write-Host ("[FAIL] Node {0}; minimum major is {1}." -f $rawNode, $config.minimumNodeMajor)
        $failed = $true
    }
}

if ($failed) {
    Write-Host 'BOOTSTRAP INCOMPLETE'
    exit 1
}

if (-not $SkipDependencies) {
    foreach ($step in @($config.dependencyCommands)) {
        if ($null -eq $step) { continue }
        Write-Host ("[DEPENDENCIES] {0}" -f $step.name)
        $code = Invoke-SanroConfiguredCommand $root $step
        if ($code -ne 0) { throw "Dependency command failed: $($step.name)" }
    }
}
else { Write-Host '[SKIP] dependency restore requested' }

Write-Host 'RECOVERY BOOTSTRAP COMPLETE'
Write-Host 'Secrets are intentionally NOT restored by this script.'
exit 0
