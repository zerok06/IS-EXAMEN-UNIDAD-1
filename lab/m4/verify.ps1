<#
.SYNOPSIS
    Verificacion del rol M4 (Windows Server 2016) del laboratorio aislado uni.lab.

.DESCRIPTION
    Comprueba el estado real de M4 sin modificar nada:
      - IP/DNS del cliente, zona uni.lab, registros A/CNAME, AXFR abierto.
      - Puertos 53 (TCP/UDP), 5985 y 445 escuchando.
      - Share Transfer, firma SMB, WinRM, Spooler y cuentas locales.
      - Firewall y archivo de credenciales.

    Codigos de salida:
      0 = todas las comprobaciones criticas pasaron.
      1 = al menos una comprobacion fallo (o no se pudo evaluar).

.NOTES
    - Ejecutar como Administrador (los cmdlets de DNS lo requieren).
    - Solo lectura: no crea, no borra y no reconfigura nada.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

$LabDomain = 'uni.lab'
$M4Ip      = '10.10.10.14'
$M1Ip      = '10.10.10.11'
$M2Ip      = '10.10.10.12'
$M3Ip      = '10.10.10.13'
$M5Ip      = '10.10.10.15'
$ShareName = 'Transfer'
$SharePath = 'C:\Transfer'

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

# ---------------------------------------------------------------- auxiliares
function Get-DnsARecordIp {
    param([string]$Name)
    $record = Get-DnsServerResourceRecord -ZoneName $LabDomain -Name $Name -RRType A -ErrorAction Stop
    return (@($record)[0].RecordData.IPv4Address.IPAddressToString)
}

function Get-DnsCnameTarget {
    param([string]$Name)
    $record = Get-DnsServerResourceRecord -ZoneName $LabDomain -Name $Name -RRType CName -ErrorAction Stop
    return ((@($record)[0].RecordData.HostNameAlias) -replace '\.$', '')
}

function Test-TcpPort {
    param([int]$Port)
    return [bool](Test-NetConnection -ComputerName '127.0.0.1' -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue)
}

# ---------------------------------------------------------------- cabecera
Write-Host ''
Write-Host '==========================================================' -ForegroundColor Cyan
Write-Host ' VERIFY M4 - Windows Server 2016 - 10.10.10.14' -ForegroundColor Cyan
Write-Host ' Solo lectura: comprueba, no modifica' -ForegroundColor Cyan
Write-Host '==========================================================' -ForegroundColor Cyan

$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Ok 'sesion elevada'
} else {
    Fail 'se requiere PowerShell como Administrador para consultar DNS y SMB'
}

Log ('equipo: {0}' -f $env:COMPUTERNAME)

# ---------------------------------------------------------------- red
Invoke-Check ('IP {0}/24 presente' -f $M4Ip) {
    [bool](Get-NetIPAddress -IPAddress $M4Ip -AddressFamily IPv4 -ErrorAction Stop)
}

Invoke-Check 'servidor DNS del cliente = 127.0.0.1' {
    $servers = @((Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses)
    $servers -contains '127.0.0.1'
}

$gateway = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Where-Object { $_.NextHop -eq '10.10.10.1' } |
    Select-Object -First 1
if ($gateway) {
    Ok 'gateway por defecto 10.10.10.1'
} else {
    Warn 'no hay ruta por defecto por 10.10.10.1 (no bloquea la subred /24)'
}

# ---------------------------------------------------------------- DNS
$zone = $null
try { $zone = Get-DnsServerZone -Name $LabDomain -ErrorAction Stop } catch { $zone = $null }

Invoke-Check ('zona {0} existe' -f $LabDomain) { $null -ne $zone }
Invoke-Check ('zona {0} es primaria' -f $LabDomain) { $zone -and $zone.ZoneType -eq 'Primary' }

Invoke-Check 'transferencia de zona abierta a cualquier servidor (AXFR)' {
    $primary = Get-DnsServerPrimaryZone -Name $LabDomain -ErrorAction Stop
    ([string]$primary.SecureSecondaries) -eq 'TransferAnyServer'
}

Invoke-Check 'sin reenviadores DNS (red sin Internet)' {
    $forwarder = Get-DnsServerForwarder -ErrorAction Stop
    @($forwarder.IPAddress | Where-Object { $_ }).Count -eq 0
}

$expectedA = @(
    @{ Name = 'app';      Ip = $M1Ip },
    @{ Name = 'db';       Ip = $M2Ip },
    @{ Name = 'bkp';      Ip = $M3Ip },
    @{ Name = 'srvold';   Ip = $M4Ip },
    @{ Name = 'pc-est01'; Ip = $M5Ip }
)
foreach ($record in $expectedA) {
    $recordName = $record.Name
    $recordIp   = $record.Ip
    Invoke-Check ('A {0}.{1} = {2}' -f $recordName, $LabDomain, $recordIp) {
        (Get-DnsARecordIp -Name $recordName) -eq $recordIp
    }
}

$expectedCname = @(
    @{ Name = 'wp';     Target = 'app.uni.lab' },
    @{ Name = 'moodle'; Target = 'app.uni.lab' }
)
foreach ($record in $expectedCname) {
    $recordName   = $record.Name
    $recordTarget = $record.Target
    Invoke-Check ('CNAME {0}.{1} -> {2}' -f $recordName, $LabDomain, $recordTarget) {
        (Get-DnsCnameTarget -Name $recordName) -ieq $recordTarget
    }
}

Invoke-Check 'Resolve-DnsName wp.uni.lab devuelve el CNAME app.uni.lab' {
    $answer = Resolve-DnsName -Name ('wp.' + $LabDomain) -Type CNAME -Server 127.0.0.1 -DnsOnly -ErrorAction Stop
    [bool](@($answer) | Where-Object { $_.Type -eq 'CNAME' -and ($_.NameHost -replace '\.$', '') -ieq ('app.' + $LabDomain) })
}

Invoke-Check 'Resolve-DnsName wp.uni.lab termina en 10.10.10.11' {
    $answer = Resolve-DnsName -Name ('wp.' + $LabDomain) -Type A -Server 127.0.0.1 -DnsOnly -ErrorAction Stop
    [bool](@($answer) | Where-Object { $_.Type -eq 'A' -and $_.IPAddress -eq $M1Ip })
}

Invoke-Check 'DNS escucha TCP/53' { Test-TcpPort -Port 53 }
Invoke-Check 'DNS escucha UDP/53' {
    [bool](Get-NetUDPEndpoint -LocalPort 53 -ErrorAction Stop)
}

# ---------------------------------------------------------------- puertos y servicios
Invoke-Check 'WinRM escucha TCP/5985' { Test-TcpPort -Port 5985 }
Invoke-Check 'SMB escucha TCP/445' { Test-TcpPort -Port 445 }

$spooler = Get-CimInstance -ClassName Win32_Service -Filter "Name='Spooler'" -ErrorAction SilentlyContinue
Invoke-Check 'Spooler en ejecucion' { $spooler -and $spooler.State -eq 'Running' }
Invoke-Check 'Spooler con inicio Automatic' { $spooler -and $spooler.StartMode -eq 'Auto' }

$winrm = Get-Service -Name WinRM -ErrorAction SilentlyContinue
Invoke-Check 'servicio WinRM en ejecucion' { $winrm -and $winrm.Status -eq 'Running' }

# ---------------------------------------------------------------- SMB
Invoke-Check ('share {0} existe' -f $ShareName) {
    [bool](Get-SmbShare -Name $ShareName -ErrorAction Stop)
}
Invoke-Check ('share {0} apunta a {1}' -f $ShareName, $SharePath) {
    (Get-SmbShare -Name $ShareName -ErrorAction Stop).Path.TrimEnd('\') -ieq $SharePath.TrimEnd('\')
}
Invoke-Check 'firma SMB no es obligatoria' {
    -not (Get-SmbServerConfiguration -ErrorAction Stop).RequireSecuritySignature
}

Invoke-Check 'SMB1 habilitado (MS17-010)' {
    (Get-SmbServerConfiguration -ErrorAction Stop).EnableSMB1Protocol
}

$readmePath = Join-Path $SharePath 'README.txt'
Invoke-Check ('{0} presente y sin secretos' -f $readmePath) {
    (Get-Content -LiteralPath $readmePath -Raw -ErrorAction Stop) -match 'sin secretos'
}

# ---------------------------------------------------------------- cuentas
$admin = Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.SID.Value -match '-500$' } | Select-Object -First 1
Invoke-Check 'cuenta Administrador integrada existe' { $null -ne $admin }
Invoke-Check 'cuenta Administrador habilitada' { $admin -and $admin.Enabled }

$soporte = Get-LocalUser -Name 'soporte' -ErrorAction SilentlyContinue
Invoke-Check 'usuario soporte existe' { $null -ne $soporte }
Invoke-Check 'usuario soporte habilitado' { $soporte -and $soporte.Enabled }

$adminGroup = Get-LocalGroup -SID 'S-1-5-32-544' -ErrorAction SilentlyContinue
$adminMembers = @()
if ($adminGroup) {
    $adminMembers = @(Get-LocalGroupMember -Group $adminGroup -ErrorAction SilentlyContinue)
}
Invoke-Check 'soporte NO pertenece a Administradores' {
    -not ($soporte -and ($adminMembers | Where-Object { $_.SID.Value -eq $soporte.SID.Value }))
}

# ---------------------------------------------------------------- firewall
$firewallRules = @(
    'LAB-M4-DNS-TCP',
    'LAB-M4-DNS-UDP',
    'LAB-M4-SMB',
    'LAB-M4-WINRM',
    'LAB-M4-RDP'
)
foreach ($ruleName in $firewallRules) {
    $name = $ruleName
    Invoke-Check ('regla de firewall {0} existe' -f $name) {
        [bool](Get-NetFirewallRule -DisplayName $name -ErrorAction Stop)
    }
}

# ---------------------------------------------------------------- resumen
Write-Host ''
Write-Host '---------------- resumen M4 ----------------' -ForegroundColor Cyan
Write-Host ('OK: {0}   FAIL: {1}   WARN: {2}' -f $script:OkCount, $script:FailCount, $script:WarnCount) -ForegroundColor Cyan

if ($script:FailCount -gt 0) {
    Write-Host 'M4 NO cumple el estado esperado.' -ForegroundColor Red
    exit 1
}

Write-Host 'M4 cumple el estado esperado del laboratorio.' -ForegroundColor Green
exit 0
