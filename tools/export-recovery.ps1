param(
    [string]$OutputDirectory = (Join-Path $env:USERPROFILE 'SANRO-Recovery')
)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stage = Join-Path ([IO.Path]::GetTempPath()) ('sanro-dev-toolkit-' + [guid]::NewGuid().ToString('N'))
$archive = Join-Path $OutputDirectory ("SANRO-Dev-Toolkit-Recovery-{0}.zip" -f $stamp)
$excludeNames = @('.git','node_modules','dist','build','coverage','SANRO-Recovery')
$excludePatterns = @('*.zip','.env','.env.*','*.pem','*.key','id_rsa*','id_ed25519*','credentials*.json','secrets*.json')

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $stage | Out-Null
try {
    Get-ChildItem -LiteralPath $repoRoot -Force | ForEach-Object {
        if ($excludeNames -contains $_.Name) { return }
        foreach ($pattern in $excludePatterns) { if ($_.Name -like $pattern) { return } }
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $stage $_.Name) -Recurse -Force
    }

    $head = 'UNKNOWN'; $branch = 'UNKNOWN'
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Push-Location $repoRoot
        try {
            $value = @(git rev-parse HEAD 2>$null | Select-Object -First 1); if ($LASTEXITCODE -eq 0 -and $value.Count) { $head = $value[0] }
            $value = @(git branch --show-current 2>$null | Select-Object -First 1); if ($LASTEXITCODE -eq 0 -and $value.Count) { $branch = $value[0] }
        }
        finally { Pop-Location }
    }
    @(
        'SANRO Dev Toolkit Recovery Snapshot',
        "Created: $(Get-Date -Format o)",
        "Repository HEAD: $head",
        "Branch: $branch",
        '',
        'Secrets and credentials are intentionally excluded.'
    ) | Set-Content -LiteralPath (Join-Path $stage 'RECOVERY_MANIFEST.txt') -Encoding utf8

    if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive -CompressionLevel Optimal
    Write-Host "[OK] Recovery ZIP: $archive"
}
finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
