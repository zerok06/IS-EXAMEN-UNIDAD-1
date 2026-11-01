# ============================================================================
#  lab/patch/m5.ps1 — parchea M5: VNC solo loopback + auth, RDP con NLA,
#  SMB anónimo cerrado.
#  Ejecutar como Administrador DESPUÉS de restaurar el snapshot estado-inicial.
# ============================================================================

$ErrorActionPreference = 'Stop'
function Ok($m)   { Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "[FAIL] $m" -ForegroundColor Red; exit 1 }

Write-Host "== M5 · parche ==" -ForegroundColor Cyan

# 1. VNC: solo loopback + autenticación
$vncKey = 'HKLM:\SOFTWARE\TightVNC\Server'
if (Test-Path $vncKey) {
    New-ItemProperty -Path $vncKey -Name 'AllowOnlyLoopbackConnections' -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $vncKey -Name 'UseVncAuthentication' -PropertyType DWord -Value 1 -Force | Out-Null
    Ok 'VNC: solo loopback y autenticación activada'
    Restart-Service tvnserver -Force -ErrorAction SilentlyContinue
} else {
    Warn 'TightVNC no está instalado; nada que parchear'
}
Remove-NetFirewallRule -DisplayName 'LAB-M5-VNC-5900' -ErrorAction SilentlyContinue
Ok 'regla de firewall 5900 eliminada'

# 2. RDP con NLA
$rdp = 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
Set-ItemProperty -Path $rdp -Name 'UserAuthentication' -Value 1 -Type DWord -Force
Ok 'RDP con NLA obligatorio'

# 3. SMB anónimo cerrado
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' `
    -Name EveryoneIncludesAnonymous -Value 0 -Type DWord -Force
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' `
    -Name RestrictNullSessAccess -Value 1 -Type DWord -Force
Restart-Service LanmanServer -Force -ErrorAction SilentlyContinue
Ok 'SMB anónimo deshabilitado'

# 4. verificación
if ((Get-ItemProperty -Path $rdp -Name UserAuthentication).UserAuthentication -ne 1) {
    Fail 'RDP sigue sin NLA'
}
if (Test-Path $vncKey) {
    if ((Get-ItemProperty -Path $vncKey -Name AllowOnlyLoopbackConnections -ErrorAction SilentlyContinue).AllowOnlyLoopbackConnections -ne 1) {
        Fail 'VNC sigue aceptando conexiones remotas'
    }
}
if (Get-NetFirewallRule -DisplayName 'LAB-M5-VNC-5900' -ErrorAction SilentlyContinue) {
    Fail 'la regla 5900 sigue abierta'
}
Ok 'M5 parcheado: VNC loopback+auth, RDP NLA, SMB anónimo off'
