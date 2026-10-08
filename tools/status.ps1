param([string]$ProjectRoot = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$state = Get-SanroProjectConfig $ProjectRoot
$root = $state.Root
$config = $state.Config
$failed = $false

Push-Location $root
try {
    Write-Host 'SANRO DEV STATUS'
    Write-Host ("Project : {0}" -f $config.project)
    Write-Host ("Platform: {0}" -f (Get-SanroPlatform))
    if ((Get-SanroPlatform) -eq 'linux') {
        Write-Host ("Linux   : {0}" -f (Get-SanroLinuxDistribution))
    }
    Write-Host '[Repository]'
    git rev-parse --show-toplevel
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read repository root.' }
    Write-Host '[HEAD]'
    git rev-parse --verify HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read HEAD.' }
    Write-Host '[Branch / Working Tree]'
    git status -sb
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read Git status.' }

    Write-Host '[Tools]'
    $required = @($config.requiredTools)
    foreach ($name in @($required + @($config.optionalTools) | Where-Object { $_ } | Sort-Object -Unique)) {
        $requiredTool = $required -contains $name
        if (Test-SanroCommand $name) {
            Write-Host ("[OK] {0}: {1}" -f $name, (Get-SanroToolVersion $name))
        }
        elseif ($requiredTool) { Write-Host ("[FAIL] {0}: unavailable" -f $name); $failed = $true }
        else { Write-Host ("[OPTIONAL] {0}: unavailable" -f $name) }
    }
}
catch { Write-Host "[FAIL] $_"; $failed = $true }
finally { Pop-Location }
if ($failed) { exit 1 }
exit 0
