param(
    [string]$ProjectRoot = (Get-Location).Path,
    [ValidateSet('generic','node','wordpress','sanro-node','sanro-wordpress')][string]$Template = 'generic',
    [string]$ProjectName = '',
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$templateRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\templates')).Path
$templatePath = Join-Path $templateRoot ("{0}.json" -f $Template)
$templatePath = (Resolve-Path -LiteralPath $templatePath).Path
$target = Join-Path $root 'sanro-dev.project.json'
if ((Test-Path -LiteralPath $target) -and -not $Force) {
    throw 'sanro-dev.project.json already exists. Use -Force to replace it.'
}
$data = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Json
if (-not [string]::IsNullOrWhiteSpace($ProjectName)) { $data.project = $ProjectName }
$data | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $target -Encoding utf8
Write-Host "[OK] Created $target from template '$Template'."

if ($Template.StartsWith('sanro-', [StringComparison]::OrdinalIgnoreCase)) {
    $agentsTarget = Join-Path $root 'AGENTS.md'
    if (-not (Test-Path -LiteralPath $agentsTarget -PathType Leaf)) {
        $agentsTemplate = Join-Path $templateRoot 'AGENTS_SANRO.md'
        $agentsText = Get-Content -LiteralPath $agentsTemplate -Raw
        $resolvedName = if ([string]::IsNullOrWhiteSpace($ProjectName)) { [string]$data.project } else { $ProjectName }
        $agentsText = $agentsText.Replace('{{PROJECT_NAME}}', $resolvedName)
        Set-Content -LiteralPath $agentsTarget -Value $agentsText -Encoding utf8
        Write-Host "[OK] Created $agentsTarget from SANRO agent standard."
    }
    else {
        Write-Host '[PRESERVE] Existing AGENTS.md was not overwritten.'
    }
}

Write-Host 'Review the generated commands, paths, and project-specific safety rules before using bootstrap/test.'
