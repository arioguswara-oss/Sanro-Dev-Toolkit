param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('init','bootstrap','status','handoff','context','check','test','lint','build','verify','release-check','ci','snapshot','help')]
    [string]$Command,

    [string]$ProjectRoot = (Get-Location).Path,
    [ValidateSet('generic','node','wordpress','sanro-node','sanro-wordpress')]
    [string]$Template = 'generic',
    [string]$ProjectName = '',
    [string]$Query = '',
    [string]$Filter = '',
    [int]$RecentCommitCount = 0,
    [switch]$InstallMissing,
    [switch]$SkipDependencies,
    [switch]$Force,
    [switch]$Json,
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$toolsRoot = Join-Path $PSScriptRoot 'tools'
. (Join-Path $toolsRoot 'common.ps1')

function Invoke-Child([string]$ScriptName, [hashtable]$Arguments) {
    $script = Join-Path $toolsRoot $ScriptName
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
        throw "Toolkit script not found: $ScriptName"
    }
    & $script @Arguments
    exit $LASTEXITCODE
}

function Invoke-CiMode([string]$Mode) {
    Invoke-Child 'ci.ps1' @{
        ProjectRoot = $ProjectRoot
        Mode = $Mode
        Json = $Json
    }
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
        switch (Get-SanroPlatform) {
            'windows' {
                Invoke-Child 'bootstrap-windows.ps1' @{
                    ProjectRoot = $ProjectRoot
                    InstallMissing = $InstallMissing
                    SkipDependencies = $SkipDependencies
                }
            }
            'linux' {
                Invoke-Child 'bootstrap-ubuntu.ps1' @{
                    ProjectRoot = $ProjectRoot
                    InstallMissing = $InstallMissing
                    SkipDependencies = $SkipDependencies
                }
            }
            default {
                throw "bootstrap is currently supported on Windows and Ubuntu Linux only. Platform: $(Get-SanroPlatform)"
            }
        }
    }
    'status' {
        Invoke-Child 'status.ps1' @{ ProjectRoot = $ProjectRoot }
    }
    'handoff' {
        Invoke-Child 'handoff.ps1' @{
            ProjectRoot = $ProjectRoot
            RecentCommitCount = $RecentCommitCount
        }
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
    'lint' { Invoke-CiMode 'lint' }
    'build' { Invoke-CiMode 'build' }
    'verify' { Invoke-CiMode 'verify' }
    'release-check' { Invoke-CiMode 'release-check' }
    'ci' { Invoke-CiMode 'ci' }
    'snapshot' {
        $args = @{}
        if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) { $args.OutputDirectory = $OutputDirectory }
        Invoke-Child 'export-recovery.ps1' $args
    }
    'help' {
        Write-Host @'
SANRO Dev Toolkit

Commands:
  init          Create sanro-dev.project.json from a template
  bootstrap     Check/install supported tools and restore dependencies
  status        Show repository, branch, working tree, platform, and tool state
  handoff       Show concise cross-agent recovery/handoff context
  context       Fast literal context search; requires -Query
  check         Diff hygiene + changed-file syntax checks
  test          Run focused tests with -Filter, or configured full tests
  lint          Run manifest-driven lint stage
  build         Run manifest-driven build stage
  verify        Run manifest-driven verification/security stage
  release-check Run CI pipeline plus release/artifact/production-safety gates
  ci            Run the local/VPS authoritative deterministic CI pipeline
  snapshot      Export a source-only offline recovery ZIP

CI commands accept -Json for machine-readable output. Detailed reports are also written under the configured .sanro-ci directory.

Platforms:
  Windows PowerShell / PowerShell 7
  Ubuntu Linux via PowerShell 7 (pwsh); use ./sanro-dev.sh as the launcher

Templates:
  generic, node, wordpress, sanro-node, sanro-wordpress

SANRO templates also create a default AGENTS.md when one does not already exist.
Existing AGENTS.md is preserved.

Windows examples:
  .\sanro-dev.ps1 init -ProjectRoot C:\work\app -Template sanro-node -ProjectName "SANRO App"
  .\sanro-dev.ps1 ci -ProjectRoot C:\work\app
  .\sanro-dev.ps1 release-check -ProjectRoot C:\work\app -Json

Ubuntu examples:
  ./sanro-dev.sh init -ProjectRoot /opt/sanro/projects/app -Template sanro-node -ProjectName "SANRO App"
  ./sanro-dev.sh ci -ProjectRoot /opt/sanro/projects/app
  ./sanro-dev.sh release-check -ProjectRoot /opt/sanro/projects/app -Json
'@
        exit 0
    }
}
