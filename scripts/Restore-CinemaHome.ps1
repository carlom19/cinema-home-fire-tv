param(
    [Parameter(Mandatory=$true)][string]$TvAddress,
    [Parameter(Mandatory=$true)][string]$SnapshotDirectory,
    [string]$AdbPath = '',
    [switch]$RemoveCinema
)
# Restore the previous HOME hook using snapshots from this specific TV only.
$ErrorActionPreference = 'Stop'
if ($TvAddress -notmatch '^\d{1,3}(\.\d{1,3}){3}:5555$') { throw 'Use IPv4:5555.' }
if (-not $AdbPath) { $AdbPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'tools\platform-tools\adb.exe' }
function Read-Snapshot([string]$Name) {
    $path = Join-Path $SnapshotDirectory $Name
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing snapshot: $Name" }
    return [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $path).Path).Trim()
}
function Tv([string[]]$CommandArgs) {
    $result = & $AdbPath -s $TvAddress shell @CommandArgs
    if ($LASTEXITCODE -ne 0) { throw "ADB failed: $CommandArgs" }
    return ($result -join "`n").Trim()
}
$identity = Read-Snapshot 'cinema-device.json' | ConvertFrom-Json
$services = Read-Snapshot 'cinema-enable-services-before.txt'
$enabled = Read-Snapshot 'cinema-accessibility-before.txt'
$alarms = Read-Snapshot 'cinema-alarm-before.txt'
$whitelist = Read-Snapshot 'cinema-whitelist-before.txt'
$currentSerial = Tv @('getprop','ro.serialno')
if (-not $identity.serial -or $currentSerial -ne $identity.serial -or
        (Tv @('getprop','ro.product.model')) -ne $identity.model) {
    throw 'These snapshots do not identify this TV. No changes made.'
}
function Restore-Setting([string]$Namespace,[string]$Key,[string]$Value) {
    if (-not $Value -or $Value -eq 'null') {
        Tv @('settings','delete',$Namespace,$Key)
    } else {
        $quoted = "'" + $Value.Replace("'", "'\''") + "'"
        Tv @("settings put $Namespace $Key $quoted")
    }
}
Restore-Setting 'secure' 'enabled_accessibility_services' $services
Restore-Setting 'secure' 'accessibility_enabled' $enabled
Restore-Setting 'global' 'alarm_manager_constants' $alarms
if ($whitelist -notmatch 'tv\.dumbtv\.cinema') {
    Tv @('dumpsys','deviceidle','whitelist','-tv.dumbtv.cinema')
}
Tv @('am','force-stop','tv.dumbtv.cinema')
if ($RemoveCinema) {
    & $AdbPath -s $TvAddress uninstall tv.dumbtv.cinema
    if ($LASTEXITCODE -ne 0) { throw 'Uninstall failed.' }
}
Tv @('input','keyevent','KEYCODE_HOME')
Write-Output 'Previous HOME settings restored. Check HOME with the remote.'
