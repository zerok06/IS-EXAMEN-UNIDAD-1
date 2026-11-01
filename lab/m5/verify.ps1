<#
.SYNOPSIS
    Verificacion del rol M5 (Windows 10 19045) del laboratorio aislado uni.lab.

.DESCRIPTION
    Comprueba el estado real de M5 sin modificar nada:
      - IP/DNS del cliente.
      - Usuario cliente existente y miembro de Administradores.
      - RDP habilitado sin NLA y 3389 escuchando.
      - Firma SMB desactivada y share del cliente publicado.
      - Bandera flag-M5.txt con el marcador esperado.
      - LLMNR activo (informativo), firewall y VNC opcional.

    Codigos de salida:
      0 = todas las comprobaciones criticas pasaron.
      1 = al menos una comprobacion fallo (o no se pudo evaluar).

.NOTES
    - Ejecutar como Administrador.
    - Solo lectura: no crea, no borra y no reconfigura nada.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

$M5Ip          = '10.10.10.15'
$M5Dns         = '10.10.10.14'
$ClientUser    = 'cliente'
$FlagPath      = 'C:\Compartido\flag-M5.txt'
$FlagPattern   = 'FLAG-M5-'
$LlmnrKey      = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'
$TsKey         = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'

$script:ExitOnFail = $false
$script:OkCount    = 0
$script:WarnCount  = 0
$script:FailCount  = 0

# ---------------------------------------------------------------- logging
function Log {
    param([string]$Message)
    Write-Host ('[INFO] {0}' -f $Message) -ForegroundColor Gray
}

function Ok {
    param([string]$Message)
    $script:OkCount++
    Write-Host ('[ OK ] {0}' -f $Message) -ForegroundColor Green
}

function Warn {
    param([string]$Message)
    $script:WarnCount++
    Write-Host ('[WARN] {0}' -f $Message) -ForegroundColor Yellow
}

function Fail {
    param([string]$Message)
    $script:FailCount++
    Write-Host ('[FAIL] {0}' -f $Message) -ForegroundColor Red
    if ($script:ExitOnFail) { exit 1 }
}

# Ejecuta una comprobacion; cualquier excepcion cuenta como FAIL.
function Invoke-Check {
    param(
        [string]$Description,
        [scriptblock]$Block
    )
    try {
        $result = & $Block
        if ($result) { Ok $Description } else { Fail $Description }
    } catch {
        Fail ('{0} [excepcion: {1}]' -f $Description, $_.Exception.Message)
    }
}

function Test-TcpPort {
    param([int]$Port)
    return [bool](Test-NetConnection -ComputerName '127.0.0.1' -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue)
}

# ---------------------------------------------------------------- cabecera
Write-Host ''
Write-Host '==========================================================' -ForegroundColor Cyan
Write-Host ' VERIFY M5 - Windows 10 cliente - 10.10.10.15' -ForegroundColor Cyan
Write-Host ' Solo lectura: comprueba, no modifica' -ForegroundColor Cyan
Write-Host '==========================================================' -ForegroundColor Cyan

$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Ok 'sesion elevada'
} else {
    Warn 'sin elevacion: algunas comprobaciones pueden fallar'
}

Log ('equipo: {0}' -f $env:COMPUTERNAME)

# ---------------------------------------------------------------- red
Invoke-Check ('IP {0}/24 presente' -f $M5Ip) {
    [bool](Get-NetIPAddress -IPAddress $M5Ip -AddressFamily IPv4 -ErrorAction Stop)
}

Invoke-Check ('servidor DNS del cliente = {0}' -f $M5Dns) {
    $servers = @((Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses)
    $servers -contains $M5Dns
}

$gateway = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Where-Object { $_.NextHop -eq '10.10.10.1' } |
    Select-Object -First 1
if ($gateway) {
    Ok 'gateway por defecto 10.10.10.1'
} else {
    Warn 'no hay ruta por defecto por 10.10.10.1 (no bloquea la subred /24)'
}

# ---------------------------------------------------------------- cuenta cliente
$client = Get-LocalUser -Name $ClientUser -ErrorAction SilentlyContinue
Invoke-Check ('usuario local {0} existe' -f $ClientUser) { $null -ne $client }
Invoke-Check ('usuario {0} habilitado' -f $ClientUser) { $client -and $client.Enabled }

$adminGroup   = Get-LocalGroup -SID 'S-1-5-32-544' -ErrorAction SilentlyContinue
$adminMembers = @()
if ($adminGroup) {
    $adminMembers = @(Get-LocalGroupMember -Group $adminGroup -ErrorAction SilentlyContinue)
}
Invoke-Check ('usuario {0} es miembro de Administradores (debilidad intencional)' -f $ClientUser) {
    $client -and [bool]($adminMembers | Where-Object { $_.SID.Value -eq $client.SID.Value })
}

# ---------------------------------------------------------------- RDP
$deny = (Get-ItemProperty -Path $TsKey -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections
Invoke-Check 'RDP habilitado (fDenyTSConnections=0)' { $deny -eq 0 }

$rdpKey = Join-Path $TsKey 'WinStations\RDP-Tcp'
$nla = (Get-ItemProperty -Path $rdpKey -Name UserAuthentication -ErrorAction SilentlyContinue).UserAuthentication
Invoke-Check 'RDP sin NLA (UserAuthentication=0)' { $nla -eq 0 }

$termService = Get-Service -Name TermService -ErrorAction SilentlyContinue
Invoke-Check 'servicio TermService en ejecucion' { $termService -and $termService.Status -eq 'Running' }
Invoke-Check 'RDP escucha TCP/3389' { Test-TcpPort -Port 3389 }

# ---------------------------------------------------------------- SMB
Invoke-Check 'firma SMB no es obligatoria' {
    -not (Get-SmbServerConfiguration -ErrorAction Stop).RequireSecuritySignature
}

$shares = @(Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq 'Compartido' })
if ($shares.Count -gt 0) {
    foreach ($share in $shares) {
        Ok ('share {0} publicado en {1}' -f $share.Name, $share.Path)
    }
} else {
    Fail 'no hay share Compartido'
}

Invoke-Check 'SMB escucha TCP/445' { Test-TcpPort -Port 445 }

# ---------------------------------------------------------------- bandera
Invoke-Check ('bandera {0} existe' -f $FlagPath) {
    Test-Path -LiteralPath $FlagPath -ErrorAction Stop
}
Invoke-Check ('bandera contiene {0}' -f $FlagPattern) {
    (Get-Content -LiteralPath $FlagPath -Raw -ErrorAction Stop) -match [regex]::Escape($FlagPattern)
}

# ---------------------------------------------------------------- resolucion legacy
$multicast = (Get-ItemProperty -Path $LlmnrKey -Name EnableMulticast -ErrorAction SilentlyContinue).EnableMulticast
Invoke-Check 'LLMNR habilitado (EnableMulticast=1)' { $multicast -eq 1 }

$netbtKeys = @()
try {
    $netbtKeys = @(Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' -ErrorAction Stop)
} catch {
    $netbtKeys = @()
}
if ($netbtKeys.Count -eq 0) {
    Warn 'no hay interfaces NetBT para inspeccionar (NBT-NS queda por defecto)'
} else {
    foreach ($key in $netbtKeys) {
        $options = (Get-ItemProperty -Path $key.PSPath -Name NetbiosOptions -ErrorAction SilentlyContinue).NetbiosOptions
        if ($null -eq $options -or $options -eq 0) {
            Ok ('NBT-NS activo en {0}' -f $key.PSChildName)
        } else {
            Warn ('NBT-NS podria estar deshabilitado en {0} (NetbiosOptions={1})' -f $key.PSChildName, $options)
        }
    }
}

# ---------------------------------------------------------------- firewall
$firewallRules = @(
    'LAB-M5-SMB-445',
    'LAB-M5-NETBIOS-139',
    'LAB-M5-RDP-3389'
)
foreach ($ruleName in $firewallRules) {
    $name = $ruleName
    Invoke-Check ('regla de firewall {0} existe' -f $name) {
        [bool](Get-NetFirewallRule -DisplayName $name -ErrorAction Stop)
    }
}

# ---------------------------------------------------------------- VNC opcional
$vncService = Get-Service -Name tvnserver -ErrorAction SilentlyContinue
if ($vncService) {
    Invoke-Check 'servicio tvnserver en ejecucion' { $vncService.Status -eq 'Running' }
    if (Test-TcpPort -Port 5900) {
        Ok 'VNC escucha TCP/5900'
    } else {
        Warn 'VNC instalado pero 5900 no responde'
    }
    $vncRule = Get-NetFirewallRule -DisplayName 'LAB-M5-VNC-5900' -ErrorAction SilentlyContinue
    if ($vncRule) { Ok 'regla de firewall LAB-M5-VNC-5900 existe' } else { Warn 'falta la regla de firewall de VNC' }
} else {
    Log 'VNC no instalado (componente opcional)'
}

# ---------------------------------------------------------------- resumen
Write-Host ''
Write-Host '---------------- resumen M5 ----------------' -ForegroundColor Cyan
Write-Host ('OK: {0}   FAIL: {1}   WARN: {2}' -f $script:OkCount, $script:FailCount, $script:WarnCount) -ForegroundColor Cyan

if ($script:FailCount -gt 0) {
    Write-Host 'M5 NO cumple el estado esperado.' -ForegroundColor Red
    exit 1
}

Write-Host 'M5 cumple el estado esperado del laboratorio.' -ForegroundColor Green
exit 0
