param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$Filter = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$state = Get-SanroProjectConfig $ProjectRoot
$root = $state.Root
$config = $state.Config

if (-not [string]::IsNullOrWhiteSpace($Filter) -and $config.focusedTest) {
    $focused = $config.focusedTest.PSObject.Copy()
    $args = @($focused.args | ForEach-Object { ([string]$_).Replace('{filter}', $Filter) })
    $focused | Add-Member -NotePropertyName args -NotePropertyValue $args -Force
    Write-Host ("SANRO TEST RUNNER - FOCUSED: {0}" -f $Filter)
    $code = Invoke-SanroConfiguredCommand $root $focused
    exit $code
}

if ($null -eq $config.fullTest) {
    throw 'fullTest is not configured for this project.'
}
Write-Host 'SANRO TEST RUNNER - FULL'
$code = Invoke-SanroConfiguredCommand $root $config.fullTest
exit $code
