param([string]$ProjectRoot = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$state = Get-SanroProjectConfig $ProjectRoot
$root = $state.Root
$failed = $false

Push-Location $root
try {
    Write-Host 'SANRO FAST CHECK'
    git diff --check HEAD
    if ($LASTEXITCODE -ne 0) { $failed = $true } else { Write-Host '[OK] git diff --check HEAD' }

    $files = Get-SanroChangedFiles $root
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
        $extension = [IO.Path]::GetExtension($file).ToLowerInvariant()
        try {
            switch ($extension) {
                '.js' { node --check $file; if ($LASTEXITCODE -ne 0) { throw 'JavaScript syntax check failed.' } }
                '.json' { Get-Content -LiteralPath $file -Raw | ConvertFrom-Json | Out-Null }
                '.ps1' {
                    $tokens = $null; $errors = $null
                    [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $root $file), [ref]$tokens, [ref]$errors) | Out-Null
                    if ($errors.Count) { throw ($errors.Message -join '; ') }
                }
                '.php' {
                    if (Get-Command php -ErrorAction SilentlyContinue) {
                        php -l $file | Out-Host
                        if ($LASTEXITCODE -ne 0) { throw 'PHP syntax check failed.' }
                    }
                }
                default { continue }
            }
            Write-Host "[OK] $file"
        }
        catch { Write-Host ("[FAIL] {0}: {1}" -f $file, $_); $failed = $true }
    }
}
finally { Pop-Location }
if ($failed) { Write-Host 'FAST CHECK FAILED'; exit 1 }
Write-Host 'FAST CHECK PASS'
exit 0
