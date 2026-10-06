param(
    [string]$ProjectRoot = (Get-Location).Path,
    [ValidateSet('generic','node','wordpress')][string]$Template = 'generic',
    [string]$ProjectName = '',
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$templatePath = Join-Path (Join-Path $PSScriptRoot '..\templates') ("{0}.json" -f $Template)
$templatePath = (Resolve-Path -LiteralPath $templatePath).Path
$target = Join-Path $root 'sanro-dev.project.json'
if ((Test-Path -LiteralPath $target) -and -not $Force) {
    throw 'sanro-dev.project.json already exists. Use -Force to replace it.'
}
$data = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Json
if (-not [string]::IsNullOrWhiteSpace($ProjectName)) { $data.project = $ProjectName }
$data | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $target -Encoding utf8
Write-Host "[OK] Created $target from template '$Template'."
Write-Host 'Review the generated commands before using bootstrap/test.'
