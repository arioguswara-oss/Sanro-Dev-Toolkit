param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('init','bootstrap','status','context','check','test','snapshot','help')]
    [string]$Command,

    [string]$ProjectRoot = (Get-Location).Path,
    [ValidateSet('generic','node','wordpress')]
    [string]$Template = 'generic',
    [string]$ProjectName = '',
    [string]$Query = '',
    [string]$Filter = '',
    [switch]$InstallMissing,
    [switch]$SkipDependencies,
    [switch]$Force,
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$toolsRoot = Join-Path $PSScriptRoot 'tools'

function Invoke-Child([string]$ScriptName, [hashtable]$Arguments) {
    $script = Join-Path $toolsRoot $ScriptName
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
        throw "Toolkit script not found: $ScriptName"
    }
    & $script @Arguments
    exit $LASTEXITCODE
}

switch ($Command) {
    'init' {
        Invoke-Child 'init-project.ps1' @{
            ProjectRoot = $ProjectRoot
            Template = $Template
            ProjectName = $ProjectName
            Force = $Force
        }
    }
    'bootstrap' {
        Invoke-Child 'bootstrap-windows.ps1' @{
            ProjectRoot = $ProjectRoot
            InstallMissing = $InstallMissing
            SkipDependencies = $SkipDependencies
        }
    }
    'status' {
        Invoke-Child 'status.ps1' @{ ProjectRoot = $ProjectRoot }
    }
    'context' {
        if ([string]::IsNullOrWhiteSpace($Query)) { throw 'context requires -Query.' }
        Invoke-Child 'context.ps1' @{ ProjectRoot = $ProjectRoot; Query = $Query }
    }
    'check' {
        Invoke-Child 'check.ps1' @{ ProjectRoot = $ProjectRoot }
    }
    'test' {
        Invoke-Child 'test.ps1' @{ ProjectRoot = $ProjectRoot; Filter = $Filter }
    }
    'snapshot' {
        $args = @{}
        if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) { $args.OutputDirectory = $OutputDirectory }
        Invoke-Child 'export-recovery.ps1' $args
    }
    'help' {
        Write-Host @'
SANRO Dev Toolkit

Commands:
  init       Create sanro-dev.project.json from a template
  bootstrap  Check/install supported tools and restore dependencies
  status     Show repository, branch, working tree, and tool state
  context    Fast literal context search; requires -Query
  check      Diff hygiene + changed-file syntax checks
  test       Run focused tests with -Filter, or configured full tests
  snapshot   Export a source-only offline recovery ZIP

Examples:
  .\sanro-dev.ps1 init -ProjectRoot C:\work\app -Template node -ProjectName "SANRO App"
  .\sanro-dev.ps1 bootstrap -ProjectRoot C:\work\app -InstallMissing
  .\sanro-dev.ps1 context -ProjectRoot C:\work\app -Query subscription
  .\sanro-dev.ps1 test -ProjectRoot C:\work\app -Filter subscription
'@
        exit 0
    }
}
