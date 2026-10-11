$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..' 'tools' 'common.ps1')
. (Join-Path $PSScriptRoot '..' 'tools' 'ci-common.ps1')

$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("sanro-ci-env-{0}" -f ([guid]::NewGuid().ToString('N')))
New-Item -ItemType Directory -Force -Path $temp | Out-Null

$requiredName = 'SANRO_CI_REQUIRED_TEST_VALUE'
$literalName = 'SANRO_CI_LITERAL_TEST_VALUE'
$requiredValue = 'required-secret-test-value'
$literalValue = 'literal-secret-test-value'
$originalRequired = [Environment]::GetEnvironmentVariable($requiredName, 'Process')
$originalLiteral = [Environment]::GetEnvironmentVariable($literalName, 'Process')

try {
    [Environment]::SetEnvironmentVariable($requiredName, $requiredValue, 'Process')
    [Environment]::SetEnvironmentVariable($literalName, 'original-value', 'Process')

    $script = Join-Path $temp 'probe.ps1'
    @"
if (`$env:$literalName -ne '$literalValue') { exit 31 }
if (`$env:$requiredName -ne '$requiredValue') { exit 32 }
Write-Output "literal=`$env:$literalName required=`$env:$requiredName"
exit 0
"@ | Set-Content -LiteralPath $script -Encoding UTF8

    $config = [pscustomobject]@{
        name = 'environment injection probe'
        workingDirectory = '.'
        command = 'pwsh'
        args = @('-NoLogo', '-NoProfile', '-File', $script)
        environment = [pscustomobject]@{
            SANRO_CI_LITERAL_TEST_VALUE = $literalValue
        }
        requiredEnvironment = @($requiredName)
    }

    $result = Invoke-SanroCiConfiguredCommand -ProjectRoot $temp -CommandConfig $config -Quiet
    if ($result.status -ne 'PASS' -or $result.exitCode -ne 0) {
        throw "Expected PASS environment probe, got $($result.status)/$($result.exitCode)"
    }
    if ($result.command.environmentKeys -notcontains $literalName) {
        throw 'Environment key metadata missing.'
    }
    if ($result.command.requiredEnvironment -notcontains $requiredName) {
        throw 'Required environment metadata missing.'
    }
    $joined = @($result.logTail) -join "`n"
    if ($joined.Contains($literalValue) -or $joined.Contains($requiredValue)) {
        throw 'Environment value leaked into CI log tail.'
    }
    if (-not $joined.Contains('[REDACTED_ENV]')) {
        throw 'Expected environment redaction marker was not present.'
    }

    $restoredLiteral = [Environment]::GetEnvironmentVariable($literalName, 'Process')
    if ($restoredLiteral -ne 'original-value') {
        throw 'Literal environment value was not restored after command execution.'
    }

    [Environment]::SetEnvironmentVariable($requiredName, $null, 'Process')
    $blocked = Invoke-SanroCiConfiguredCommand -ProjectRoot $temp -CommandConfig $config -Quiet
    if ($blocked.status -ne 'BLOCKED' -or $blocked.exitCode -ne 2) {
        throw "Expected BLOCKED for missing required environment, got $($blocked.status)/$($blocked.exitCode)"
    }
    if ((@($blocked.logTail) -join "`n") -notmatch $requiredName) {
        throw 'Missing required environment name was not reported.'
    }

    Write-Host 'SANRO_CI_ENVIRONMENT_TEST=PASS'
}
finally {
    [Environment]::SetEnvironmentVariable($requiredName, $originalRequired, 'Process')
    [Environment]::SetEnvironmentVariable($literalName, $originalLiteral, 'Process')
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
