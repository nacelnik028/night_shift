param([switch]$Rendered)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$enginePath = Join-Path $projectPath '../../Godot_v4.7.2-stable_win64_console.exe'
# Isolate editor preferences and test user:// data from the player's real saves.
$env:APPDATA = Join-Path $projectPath 'artifacts/qa_userdata'
$env:LOCALAPPDATA = $env:APPDATA
New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
function Invoke-Check([string]$Name, [string[]]$EngineArgs) {
    $logPath = Join-Path $projectPath ('artifacts/3.0_' + $Name + '.log')
    $ErrorActionPreference = 'Continue'
    & $enginePath @EngineArgs 2>&1 | Out-File -LiteralPath $logPath -Encoding utf8
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $log = Get-Content -LiteralPath $logPath -Raw
    if ($exitCode -ne 0 -or $log -match '(SCRIPT ERROR|ERROR:|FAIL:|WARNING:)') {
        Write-Output $log
        throw "Validation failed: $Name (exit $exitCode). See $logPath"
    }
    Write-Output "PASS $Name - $logPath"
    Get-Content -LiteralPath $logPath | Select-String 'TESTS PASSED:|^PERFORMANCE|^RENDERED.*COMPLETE'
}
Invoke-Check 'import' @('--headless', '--path', $projectPath, '--editor', '--import', '--quit')
Invoke-Check 'gameplay' @('--headless', '--path', $projectPath, '--script', 'res://tests/gameplay_test.gd', '--', '--night-shift-test')
if (Test-Path (Join-Path $PSScriptRoot 'overhaul_test.gd')) {
    Invoke-Check 'overhaul' @('--headless', '--path', $projectPath, '--script', 'res://tests/overhaul_test.gd', '--', '--night-shift-test')
}
Invoke-Check 'polish' @('--headless', '--path', $projectPath, '--script', 'res://tests/polish_test.gd', '--', '--night-shift-test')
Invoke-Check 'remaster' @('--headless', '--path', $projectPath, '--script', 'res://tests/remaster_test.gd', '--', '--night-shift-test')
if ($Rendered) {
    Invoke-Check 'visual' @('--path', $projectPath, '--script', 'res://tests/visual_test.gd', '--', '--night-shift-test')
    Invoke-Check 'performance' @('--path', $projectPath, '--disable-vsync', '--script', 'res://tests/performance_test.gd', '--', '--night-shift-test')
    Invoke-Check 'display' @('--path', $projectPath, '--script', 'res://tests/display_test.gd', '--', '--night-shift-test', '--collision-debug')
}
