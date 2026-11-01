# ============================================================================
#  lab/patch/m4.ps1 — parchea M4: SMB1 off, Spooler detenido, SMB anónimo off
#  Ejecutar como Administrador DESPUÉS de restaurar el snapshot estado-inicial.
# ============================================================================

$ErrorActionPreference = 'Stop'
function Ok($m)   { Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "[FAIL] $m" -ForegroundColor Red; exit 1 }

Write-Host "== M4 · parche ==" -ForegroundColor Cyan

# 1. SMB1 fuera
try {
    $f = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
    if ($f.State -ne 'Disabled') {
        Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart | Out-Null
        Ok 'SMB1 deshabilitado (puede requerir reinicio)'
    } else { Ok 'SMB1 ya deshabilitado' }
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
} catch { Fail ('no se pudo deshabilitar SMB1: ' + $_.Exception.Message) }

# 2. Spooler detenido (elimina el vector PrintNightmare)
try {
    Stop-Service Spooler -Force -ErrorAction SilentlyContinue
    Set-Service Spooler -StartupType Disabled
    Ok 'Spooler detenido y deshabilitado'
} catch { Fail ('no se pudo detener el Spooler: ' + $_.Exception.Message) }

# 3. SMB anónimo cerrado
try {
    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' `
        -Name EveryoneIncludesAnonymous -Value 0 -Type DWord -Force
    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' `
        -Name RestrictNullSessAccess -Value 1 -Type DWord -Force
    Restart-Service LanmanServer -Force -ErrorAction SilentlyContinue
    Ok 'SMB anónimo deshabilitado'
} catch { Fail ('no se pudo cerrar SMB anónimo: ' + $_.Exception.Message) }

# 4. verificación
$f = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
if ($f.State -eq 'Enabled') { Fail 'SMB1 sigue habilitado' }
if ((Get-Service Spooler).Status -eq 'Running') { Fail 'Spooler sigue corriendo' }
if ((Get-SmbServerConfiguration).EnableSMB1Protocol) { Fail 'EnableSMB1Protocol sigue en true' }
Ok 'M4 parcheado: SMB1 off, Spooler detenido, SMB anónimo off'
Warn 'si SMB1 quedó DisablePending, reinicia la VM antes del retest'
