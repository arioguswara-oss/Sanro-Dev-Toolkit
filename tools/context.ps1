param(
    [string]$ProjectRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)][string]$Query,
    [ValidateRange(1,1000)][int]$MaxMatches = 80
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$state = Get-SanroProjectConfig $ProjectRoot
$root = $state.Root
if (-not (Test-SanroCommand 'rg')) { throw 'ripgrep (rg) is required.' }

Push-Location $root
try {
    Write-Host 'SANRO CONTEXT FINDER'
    Write-Host "Query: $Query"
    $excludes = @('--glob','!.git/**','--glob','!**/node_modules/**','--glob','!**/dist/**','--glob','!**/build/**','--glob','!**/coverage/**','--glob','!*.zip','--glob','!.env*')
    Write-Host '[1] FILE NAMES'
    $files = @(rg --files --hidden @excludes)
    if ($LASTEXITCODE -gt 1) { throw 'File discovery failed.' }
    $names = @($files | Where-Object { $_.IndexOf($Query,[StringComparison]::OrdinalIgnoreCase) -ge 0 } | Select-Object -First 30)
    if ($names.Count) { $names } else { Write-Host '(no filename matches)' }

    Write-Host '[2] CONTENT MATCHES'
    $matches = @(rg --hidden --fixed-strings --smart-case --line-number --color never --max-columns 220 @excludes -- $Query .)
    if ($LASTEXITCODE -gt 1) { throw 'Content search failed.' }
    if ($matches.Count) { $matches | Select-Object -First $MaxMatches } else { Write-Host '(no content matches)' }
}
finally { Pop-Location }
