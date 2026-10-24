param([Parameter(Mandatory=$true)][string]$TvAddress)
# Read-only on the TV. Creates a fresh local report folder on every invocation.
$ErrorActionPreference = 'Stop'
if ($TvAddress -notmatch '^(?<address>(?:[0-9]{1,3}\.){3}[0-9]{1,3}):5555$') {
    throw 'Indica la IPv4 de la TV seguida de :5555.'
}
$parsedAddress = $null
if (-not [System.Net.IPAddress]::TryParse($Matches['address'], [ref]$parsedAddress) -or
        $parsedAddress.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
    throw 'La IPv4 no es válida.'
}
$kitRoot = Split-Path $PSScriptRoot -Parent
$adbPath = Join-Path $kitRoot 'tools\platform-tools\adb.exe'
$repoPath = Join-Path $kitRoot 'dumbtv'
if (-not (Test-Path -LiteralPath $adbPath)) { throw 'Falta tools/platform-tools/adb.exe.' }
if (-not (Test-Path -LiteralPath (Join-Path $repoPath 'scripts\preflight.sh'))) {
    throw 'Clona dumbtv en esta carpeta y lee README.md y AGENTS.md antes de continuar.'
}
$gitCommand = Get-Command git -ErrorAction Stop
$gitRoot = Split-Path (Split-Path $gitCommand.Source -Parent) -Parent
$bashPath = Join-Path $gitRoot 'bin\bash.exe'
if (-not (Test-Path -LiteralPath $bashPath)) {
    $bashPath = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
}
if (-not (Test-Path -LiteralPath $bashPath)) { throw 'No se encontró Git Bash.' }
& $adbPath connect $TvAddress
& $adbPath devices -l
$connectionState = & $adbPath -s $TvAddress get-state
if ($LASTEXITCODE -ne 0 -or ($connectionState -join '').Trim() -ne 'device') {
    throw 'Acepta la autorización ADB con el control de la TV y vuelve a ejecutar una vez.'
}
$reportName = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$reportPath = Join-Path (Join-Path $kitRoot 'reports') $reportName
New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
$previousAdb = $env:ADB
$previousSerial = $env:ADB_SERIAL
$previousLegacySerial = $env:SERIAL
$previousReport = $env:REPORT
try {
    $env:ADB = $adbPath.Replace('\','/')
    $env:ADB_SERIAL = $TvAddress
    $env:SERIAL = $TvAddress
    $env:REPORT = $reportPath.Replace('\','/')
    Push-Location $repoPath
    try {
        & $bashPath scripts/preflight.sh 2>&1 | Tee-Object -FilePath (Join-Path $reportPath 'preflight.txt')
        if ($LASTEXITCODE -ne 0) { throw 'preflight no terminó correctamente. No modificar la TV.' }
    } finally { Pop-Location }
    $reads = @(
        @('packages.txt','pm list packages'),
        @('packages-disabled.txt','pm list packages -d'),
        @('packages-third-party.txt','pm list packages -3'),
        @('packages-dump.txt','dumpsys package'),
        @('deviceidle.txt','dumpsys deviceidle whitelist'),
        @('data-saver.txt','cmd netpolicy get restrict-background'),
        @('home.txt','cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME'),
        @('tv-input.txt','dumpsys tv_input')
    )
    foreach ($read in $reads) {
        $result = & $adbPath -s $TvAddress shell $read[1]
        if ($LASTEXITCODE -ne 0) { throw "No se pudo leer $($read[0]). No modificar la TV." }
        $result | Set-Content -Encoding utf8 (Join-Path $reportPath $read[0])
    }
} finally {
    $env:ADB = $previousAdb
    $env:ADB_SERIAL = $previousSerial
    $env:SERIAL = $previousLegacySerial
    $env:REPORT = $previousReport
}
Write-Output "Informes locales: $reportPath"
Write-Output 'No se modificó la TV. Mostrar diagnóstico y pedir autorización antes de instalar o desactivar.'
