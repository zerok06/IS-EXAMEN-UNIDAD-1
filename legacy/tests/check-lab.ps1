# check-lab.ps1 · conectividad básica desde el host Windows (read-only)
# Uso: powershell -ExecutionPolicy Bypass -File .\tests\check-lab.ps1

$ErrorActionPreference = 'SilentlyContinue'

$targets = @(
  @{ Name = 'R0'; IP = '10.10.10.1';  Ports = @() },
  @{ Name = 'M1'; IP = '10.10.10.11'; Ports = @(22, 80) },
  @{ Name = 'M2'; IP = '10.10.10.12'; Ports = @(3306, 6379, 161) },
  @{ Name = 'M3'; IP = '10.10.10.13'; Ports = @(21, 139, 445, 2049) },
  @{ Name = 'M4'; IP = '10.10.10.14'; Ports = @(445, 3389) },
  @{ Name = 'M5'; IP = '10.10.10.15'; Ports = @(445, 3389, 5900) },
  @{ Name = 'M6'; IP = '10.10.10.20'; Ports = @(22) }
)

Write-Host '== Lab IS-1023 · conectividad desde el host ==' -ForegroundColor Cyan
Write-Host (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss') + ' UTC'
Write-Host ''

$rows = @()
foreach ($t in $targets) {
  $ping = Test-Connection -ComputerName $t.IP -Count 1 -Quiet
  $portResults = @()
  foreach ($p in $t.Ports) {
    $ok = (Test-NetConnection -ComputerName $t.IP -Port $p -WarningAction SilentlyContinue).TcpTestSucceeded
    $portResults += "$p=$ok"
  }
  $rows += [pscustomobject]@{
    VM    = $t.Name
    IP    = $t.IP
    Ping  = if ($ping) { 'OK' } else { 'FAIL' }
    Ports = ($portResults -join ' ')
  }
}

$rows | Format-Table -AutoSize

$fail = ($rows | Where-Object { $_.Ping -eq 'FAIL' }).Count
Write-Host ''
Write-Host "== Resumen: $($rows.Count) VM, $fail sin ping ==" -ForegroundColor Cyan
if ($fail -gt 0) {
  Write-Host 'Revisar: VM apagada, bridge, IP estática o firewall.' -ForegroundColor Yellow
  exit 1
}
exit 0
