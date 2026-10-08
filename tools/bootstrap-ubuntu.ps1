param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$InstallMissing,
    [switch]$SkipDependencies
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

if ((Get-SanroPlatform) -ne 'linux') {
    throw 'Ubuntu bootstrap can only run on Linux.'
}

$distribution = Get-SanroLinuxDistribution
if ($distribution -ne 'ubuntu') {
    throw "Ubuntu bootstrap requires Ubuntu Linux. Detected distribution: '$distribution'."
}

$state = Get-SanroProjectConfig $ProjectRoot
$root = $state.Root
$config = $state.Config
$failed = $false
$script:AptUpdated = $false

function Test-SanroRootUser {
    if (-not (Get-Command id -ErrorAction SilentlyContinue)) { return $false }
    $uid = (& id -u).Trim()
    return $uid -eq '0'
}

function Invoke-SanroAptGet([string[]]$Arguments) {
    if (-not (Get-Command apt-get -ErrorAction SilentlyContinue)) {
        throw 'apt-get unavailable; this bootstrap currently supports Ubuntu with apt-get.'
    }

    if (Test-SanroRootUser) {
        & apt-get @Arguments
    }
    else {
        if (-not (Get-Command sudo -ErrorAction SilentlyContinue)) {
            throw 'sudo unavailable. Run as root or install required packages manually.'
        }
        & sudo apt-get @Arguments
    }

    if ($LASTEXITCODE -ne 0) {
        throw "apt-get failed: $($Arguments -join ' ')"
    }
}

function Install-SanroAptPackages([string[]]$Packages) {
    if (-not $script:AptUpdated) {
        Write-Host '[APT] update'
        Invoke-SanroAptGet -Arguments @('update')
        $script:AptUpdated = $true
    }
    Write-Host ("[APT] install {0}" -f ($Packages -join ' '))
    Invoke-SanroAptGet -Arguments (@('install', '-y') + $Packages)
}

function Try-InstallTool([string]$Name) {
    switch ($Name.ToLowerInvariant()) {
        'git' { Install-SanroAptPackages @('git') }
        'node' { Install-SanroAptPackages @('nodejs', 'npm') }
        'npm' { Install-SanroAptPackages @('nodejs', 'npm') }
        'rg' { Install-SanroAptPackages @('ripgrep') }
        'fd' { Install-SanroAptPackages @('fd-find') }
        'ast-grep' {
            if (-not (Test-SanroCommand 'npm')) { Install-SanroAptPackages @('nodejs', 'npm') }
            $npm = Get-SanroToolCommand 'npm'
            & $npm install --global '@ast-grep/cli'
            if ($LASTEXITCODE -ne 0) { throw 'npm global install failed for ast-grep.' }
        }
        default { throw "No automatic Ubuntu installer registered for '$Name'." }
    }
}

function Get-SanroToolVersion([string]$Name) {
    $command = Get-SanroToolCommand $Name
    if ([string]::IsNullOrWhiteSpace($command)) { return '' }
    $value = @(& $command --version 2>$null | Select-Object -First 1)
    if (-not $value.Count) { return '' }
    return ([string]$value[0]).Trim()
}

Write-Host 'SANRO DEV TOOLKIT - UBUNTU BOOTSTRAP'
Write-Host ("Project : {0}" -f $config.project)
Write-Host ("Root    : {0}" -f $root)
Write-Host ("Platform: ubuntu/linux")
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
        Write-Host ("[OK] {0}: {1}" -f $name, (Get-SanroToolVersion $name))
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
        Write-Host '[ACTION] Install a supported Node.js LTS version, then rerun bootstrap.'
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
else {
    Write-Host '[SKIP] dependency restore requested'
}

Write-Host 'RECOVERY BOOTSTRAP COMPLETE'
Write-Host 'Secrets are intentionally NOT restored by this script.'
exit 0
