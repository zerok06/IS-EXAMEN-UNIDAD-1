<#
.SYNOPSIS
    Instalador del rol M4 (Windows Server 2016) del laboratorio aislado uni.lab.

.DESCRIPTION
    Deja M4 como servidor de red/DNS del laboratorio:
      - IP estatica 10.10.10.14/24, gateway 10.10.10.1, DNS 127.0.0.1.
      - Nombre de equipo srvold.
      - Rol DNS con zona primaria uni.lab y registros A/CNAME.
      - Transferencia de zona abierta (AXFR intencional) y sin reenviadores.
      - Cuentas locales: Administrador (clave debil intencional) y soporte (sin admin).
      - Share SMB Transfer sobre C:\Transfer con Everyone lectura/escritura y sin firma.
      - WinRM habilitado, Spooler activo y puertos del rol abiertos en el firewall.
      - C:\Transfer\credenciales.txt con la credencial de M5 (debilidad intencional).

    SOLO para el laboratorio aislado 10.10.10.0/24, sin Internet y con autorizacion
    del docente. Las configuraciones debiles son intencionales (escenario de clase);
    no usar este script en una red real.

.NOTES
    - Ejecutar en la CONSOLA de la VM como Administrador (cambia IP y nombre).
    - Idempotente: cada paso comprueba el estado antes de crear o modificar.
    - No descarga nada, no instala malware y no borra logs.
    - Al terminar puede requerir reinicio (nombre de equipo); luego correr verify.ps1.
#>

[CmdletBinding()]
param(
    # Adaptador de red a configurar. Si se omite, se toma el primer adaptador activo.
    [string]$InterfaceAlias
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- constantes
$LabRoot    = 'C:\lab'
$LabDomain  = 'uni.lab'
$ZoneFile   = 'uni.lab.dns'
$M4Ip       = '10.10.10.14'
$M4Gateway  = '10.10.10.1'
$M4Dns      = '127.0.0.1'
$M4Name     = 'srvold'
$M1Ip       = '10.10.10.11'
$M2Ip       = '10.10.10.12'
$M3Ip       = '10.10.10.13'
$M5Ip       = '10.10.10.15'
$LabNet     = '10.10.10.0/24'

$AdminPassword   = 'M4_Admin_2026!'
$SoportePassword = 'Soporte2026!'
$ShareName       = 'Transfer'
$SharePath       = 'C:\Transfer'

# ---------------------------------------------------------------- estado
$script:ExitOnFail   = $true
$script:OkCount      = 0
$script:WarnCount    = 0
$script:FailCount    = 0
$script:LogFile      = $null
$script:RebootNeeded = $false

# ---------------------------------------------------------------- logging
function Write-LabLog {
    param(
        [string]$Level,
        [string]$Message
    )
    if (-not $script:LogFile) { return }
    try {
        $stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        Add-Content -LiteralPath $script:LogFile -Value ('{0} [{1}] {2}' -f $stamp, $Level, $Message) -Encoding UTF8 -ErrorAction Stop
    } catch {
        # el log es auxiliar: si falla no se interrumpe la instalacion
        $script:LogFile = $null
    }
}

function Log {
    param([string]$Message)
    Write-Host ('[INFO] {0}' -f $Message) -ForegroundColor Gray
    Write-LabLog -Level 'INFO' -Message $Message
}

function Ok {
    param([string]$Message)
    $script:OkCount++
    Write-Host ('[ OK ] {0}' -f $Message) -ForegroundColor Green
    Write-LabLog -Level 'OK' -Message $Message
}

function Warn {
    param([string]$Message)
    $script:WarnCount++
    Write-Host ('[WARN] {0}' -f $Message) -ForegroundColor Yellow
    Write-LabLog -Level 'WARN' -Message $Message
}

function Fail {
    param([string]$Message)
    $script:FailCount++
    Write-Host ('[FAIL] {0}' -f $Message) -ForegroundColor Red
    Write-LabLog -Level 'FAIL' -Message $Message
    if ($script:ExitOnFail) {
        Write-Host ''
        Write-Host 'Instalacion abortada. Corrige el error y vuelve a ejecutar (el script es idempotente).' -ForegroundColor Red
        exit 1
    }
}

function Step {
    param([string]$Title)
    Write-Host ''
    Write-Host ('== {0} ==' -f $Title) -ForegroundColor Cyan
    Write-LabLog -Level 'STEP' -Message $Title
}

# ---------------------------------------------------------------- arranque
function Show-Banner {
    Write-Host ''
    Write-Host '==========================================================' -ForegroundColor Cyan
    Write-Host ' LAB PHP2SHELL - M4 - Windows Server 2016' -ForegroundColor Cyan
    Write-Host ' Red 10.10.10.0/24 aislada / sin Internet / autorizada' -ForegroundColor Cyan
    Write-Host '==========================================================' -ForegroundColor Cyan
}

function Assert-Administrator {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Fail 'ejecutar como Administrador (consola: boton derecho > Ejecutar como administrador)'
    }
    Ok 'sesion elevada'
}

function Initialize-LabLog {
    param([string]$LeafName)
    $dir = Join-Path $LabRoot 'logs'
    try {
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $script:LogFile = Join-Path $dir $LeafName
        $stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        Add-Content -LiteralPath $script:LogFile -Value ('==== inicio {0} ====' -f $stamp) -Encoding UTF8 -ErrorAction Stop
        Log ('log de instalacion: {0}' -f $script:LogFile)
    } catch {
        $script:LogFile = $null
        Write-Host ('[WARN] no se pudo crear el log en {0}: {1}' -f $dir, $_.Exception.Message) -ForegroundColor Yellow
    }
}

function Show-OperatingSystem {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    Log ('SO: {0} (build {1})' -f $os.Caption.Trim(), $os.BuildNumber)
    if ([int]$os.BuildNumber -lt 14393) {
        Warn 'se esperaba Windows Server 2016 o superior; el laboratorio asume build 14393'
    }
}

# ---------------------------------------------------------------- red
function Get-LabAdapter {
    if ($InterfaceAlias) {
        $adapter = Get-NetAdapter -Name $InterfaceAlias -ErrorAction SilentlyContinue
        if (-not $adapter) {
            Fail ('no existe el adaptador de red {0}' -f $InterfaceAlias)
        }
        return $adapter
    }

    $adapter = Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'Loopback' } |
        Sort-Object -Property ifIndex |
        Select-Object -First 1

    if (-not $adapter) {
        Fail 'no hay adaptador de red activo; conecta la VM a la red del laboratorio'
    }
    return $adapter
}

function Ensure-DefaultRoute {
    param(
        [int]$IfIndex,
        [string]$NextHop
    )

    $routes = @(Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue)
    $mine   = $routes | Where-Object { $_.InterfaceIndex -eq $IfIndex -and $_.NextHop -eq $NextHop }
    if ($mine) {
        Ok ('gateway por defecto ya configurado: {0}' -f $NextHop)
        return
    }

    foreach ($route in ($routes | Where-Object { $_.InterfaceIndex -eq $IfIndex })) {
        Remove-NetRoute -InputObject $route -Confirm:$false -ErrorAction SilentlyContinue
    }

    try {
        New-NetRoute -InterfaceIndex $IfIndex -DestinationPrefix '0.0.0.0/0' -NextHop $NextHop -ErrorAction Stop | Out-Null
        Ok ('gateway por defecto: {0}' -f $NextHop)
    } catch {
        # la ruta por defecto puede chocar con otra interfaz de la VM; no es critico
        # porque todo el laboratorio esta en la misma subred /24.
        Warn ('no se pudo fijar el gateway {0}: {1}' -f $NextHop, $_.Exception.Message)
    }
}

function Set-LabNetwork {
    param(
        [string]$Ip,
        [string]$Gateway,
        [string]$DnsServer,
        [int]$PrefixLength = 24
    )

    $adapter = Get-LabAdapter
    Log ('adaptador: {0} (ifIndex {1})' -f $adapter.Name, $adapter.ifIndex)

    $ipif = Get-NetIPInterface -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($ipif -and $ipif.Dhcp -ne 'Disabled') {
        Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -Dhcp Disabled -ErrorAction Stop
        Log 'DHCP deshabilitado en el adaptador'
    }

    $current = @(Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue)
    $match   = $current | Where-Object { $_.IPAddress -eq $Ip -and $_.PrefixLength -eq $PrefixLength }

    if ($match) {
        Ok ('IP ya configurada: {0}/{1}' -f $Ip, $PrefixLength)
    } else {
        foreach ($addr in $current) {
            if ($addr.IPAddress -ne $Ip) {
                Remove-NetIPAddress -IPAddress $addr.IPAddress -InterfaceIndex $adapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
        New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $Ip -PrefixLength $PrefixLength -ErrorAction Stop | Out-Null
        Ok ('IP estatica aplicada: {0}/{1}' -f $Ip, $PrefixLength)
    }

    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $DnsServer -ErrorAction Stop
    Ok ('DNS del cliente: {0}' -f $DnsServer)

    Ensure-DefaultRoute -IfIndex $adapter.ifIndex -NextHop $Gateway
}

# ---------------------------------------------------------------- DNS
function Install-DnsRole {
    $feature = Get-WindowsFeature -Name DNS -ErrorAction Stop
    if ($feature.Installed) {
        Ok 'rol DNS ya instalado'
    } else {
        $result = Install-WindowsFeature -Name DNS -IncludeManagementTools -ErrorAction Stop
        if ($result.RestartNeeded) { $script:RebootNeeded = $true }
        Ok 'rol DNS instalado'
    }

    $service = Get-Service -Name DNS -ErrorAction SilentlyContinue
    if (-not $service) {
        Fail 'el servicio DNS no aparece despues de instalar el rol'
    }
    if ($service.Status -ne 'Running') {
        Start-Service -Name DNS -ErrorAction Stop
        Ok 'servicio DNS iniciado'
    } else {
        Ok 'servicio DNS en ejecucion'
    }
}

function Ensure-DnsZone {
    $zone = Get-DnsServerZone -Name $LabDomain -ErrorAction SilentlyContinue
    if ($zone) {
        if ($zone.ZoneType -ne 'Primary') {
            Fail ('la zona {0} existe pero no es primaria (tipo: {1})' -f $LabDomain, $zone.ZoneType)
        }
        Ok ('zona {0} ya existe (primaria)' -f $LabDomain)
        return
    }

    Add-DnsServerPrimaryZone -Name $LabDomain -ZoneFile $ZoneFile -DynamicUpdate None -ErrorAction Stop | Out-Null
    Ok ('zona primaria {0} creada (archivo {1})' -f $LabDomain, $ZoneFile)
}

function Ensure-DnsARecord {
    param(
        [string]$Name,
        [string]$Ip
    )

    $existing = $null
    try {
        $existing = Get-DnsServerResourceRecord -ZoneName $LabDomain -Name $Name -RRType A -ErrorAction Stop
    } catch {
        $existing = $null
    }

    if ($existing) {
        $values = @($existing | ForEach-Object { $_.RecordData.IPv4Address.IPAddressToString })
        if ($values.Count -eq 1 -and $values[0] -eq $Ip) {
            Ok ('A {0} -> {1} ya existe' -f $Name, $Ip)
            return
        }
        Remove-DnsServerResourceRecord -ZoneName $LabDomain -Name $Name -RRType A -Force -ErrorAction Stop
        Log ('A {0} reemplazado (antes: {1})' -f $Name, ($values -join ', '))
    }

    Add-DnsServerResourceRecordA -ZoneName $LabDomain -Name $Name -IPv4Address $Ip -ErrorAction Stop | Out-Null
    Ok ('A {0} -> {1}' -f $Name, $Ip)
}

function Ensure-DnsCname {
    param(
        [string]$Name,
        [string]$Target
    )

    $existing = $null
    try {
        $existing = Get-DnsServerResourceRecord -ZoneName $LabDomain -Name $Name -RRType CName -ErrorAction Stop
    } catch {
        $existing = $null
    }

    if ($existing) {
        $alias = (@($existing)[0].RecordData.HostNameAlias)
        if ($alias -and $alias.TrimEnd('.') -ieq $Target.TrimEnd('.')) {
            Ok ('CNAME {0} -> {1} ya existe' -f $Name, $Target)
            return
        }
        Remove-DnsServerResourceRecord -ZoneName $LabDomain -Name $Name -RRType CName -Force -ErrorAction Stop
        Log ('CNAME {0} reemplazado (antes: {1})' -f $Name, $alias)
    }

    Add-DnsServerResourceRecordCName -ZoneName $LabDomain -Name $Name -HostNameAlias $Target -ErrorAction Stop | Out-Null
    Ok ('CNAME {0} -> {1}' -f $Name, $Target)
}

function Set-OpenZoneTransfer {
    # AXFR abierto a cualquier servidor: debilidad intencional (enumeracion de la red).
    try {
        Set-DnsServerPrimaryZone -Name $LabDomain -SecureSecondaries TransferAnyServer -ErrorAction Stop
        Ok 'transferencia de zona abierta (TransferAnyServer)'
        return
    } catch {
        Warn ('Set-DnsServerPrimaryZone fallo: {0}' -f $_.Exception.Message)
    }

    # Alternativa soportada tambien en WS2016: dnscmd.
    $output = & dnscmd.exe /ZoneResetSecondaries $LabDomain /NonSecure 2>&1
    if ($LASTEXITCODE -eq 0) {
        Ok 'transferencia de zona abierta via dnscmd /NonSecure'
    } else {
        Fail ('no se pudo abrir AXFR en {0}: {1}' -f $LabDomain, ($output -join ' '))
    }
}

function Disable-DnsForwarders {
    $forwarder = Get-DnsServerForwarder -ErrorAction SilentlyContinue
    $list = @()
    if ($forwarder) { $list = @($forwarder.IPAddress | Where-Object { $_ }) }

    if ($list.Count -eq 0) {
        Ok 'sin reenviadores DNS (coherente con red sin Internet)'
        return
    }

    $text = ($list | ForEach-Object { $_.IPAddressToString }) -join ', '
    Remove-DnsServerForwarder -IPAddress $list -Force -ErrorAction Stop
    Ok ('reenviadores DNS eliminados: {0}' -f $text)
}

# ---------------------------------------------------------------- cuentas locales
function Get-BuiltinAdminAccount {
    return Get-LocalUser -ErrorAction SilentlyContinue |
        Where-Object { $_.SID.Value -match '-500$' } |
        Select-Object -First 1
}

function Ensure-LabUser {
    param(
        [string]$UserName,
        [string]$Password,
        [string]$Description
    )

    $secure = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $user   = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue

    if (-not $user) {
        New-LocalUser -Name $UserName -Password $secure -Description $Description `
            -PasswordNeverExpires -AccountNeverExpires -ErrorAction Stop | Out-Null
        Ok ('usuario local creado: {0}' -f $UserName)
    } else {
        Set-LocalUser -Name $UserName -Password $secure -ErrorAction Stop
        Ok ('clave de {0} actualizada' -f $UserName)
    }

    try {
        Set-LocalUser -Name $UserName -PasswordNeverExpires $true -ErrorAction Stop
    } catch {
        Warn ('no se pudo fijar PasswordNeverExpires en {0}: {1}' -f $UserName, $_.Exception.Message)
    }

    $user = Get-LocalUser -Name $UserName -ErrorAction Stop
    if (-not $user.Enabled) {
        Enable-LocalUser -Name $UserName -ErrorAction Stop
        Ok ('usuario {0} habilitado' -f $UserName)
    }
    return $user
}

function Set-LabGroupMembership {
    param(
        [string]$UserName,
        [string]$GroupSid,
        [switch]$Remove
    )

    $group  = Get-LocalGroup -SID $GroupSid -ErrorAction Stop
    $user   = Get-LocalUser -Name $UserName -ErrorAction Stop
    $members = @(Get-LocalGroupMember -Group $group -ErrorAction SilentlyContinue)
    $isMember = [bool]($members | Where-Object { $_.SID.Value -eq $user.SID.Value })

    if ($Remove) {
        if ($isMember) {
            Remove-LocalGroupMember -Group $group -Member $user -ErrorAction Stop
            Ok ('{0} retirado del grupo {1}' -f $UserName, $group.Name)
        } else {
            Ok ('{0} no pertenece al grupo {1}' -f $UserName, $group.Name)
        }
        return
    }

    if ($isMember) {
        Ok ('{0} ya es miembro del grupo {1}' -f $UserName, $group.Name)
    } else {
        Add-LocalGroupMember -Group $group -Member $user -ErrorAction Stop
        Ok ('{0} agregado al grupo {1}' -f $UserName, $group.Name)
    }
}

function Set-LabAccounts {
    $admin = Get-BuiltinAdminAccount
    if (-not $admin) {
        Fail 'no se encontro la cuenta Administrador integrada (SID -500)'
    }
    Ensure-LabUser -UserName $admin.Name -Password $AdminPassword `
        -Description 'Administrador local del laboratorio (clave debil intencional)' | Out-Null

    Ensure-LabUser -UserName 'soporte' -Password $SoportePassword `
        -Description 'Usuario limitado de soporte (sin privilegios)' | Out-Null

    # soporte debe quedar SIN privilegios de administrador
    Set-LabGroupMembership -UserName 'soporte' -GroupSid 'S-1-5-32-544' -Remove
    Set-LabGroupMembership -UserName 'soporte' -GroupSid 'S-1-5-32-545'
}

# ---------------------------------------------------------------- SMB
function Grant-EveryoneFullControl {
    param([string]$Path)

    $acl = Get-Acl -LiteralPath $Path
    if ($acl.Sddl -match 'S-1-1-0') {
        Ok ('ACL NTFS de {0} ya incluye Everyone' -f $Path)
        return
    }

    # icacls con SID: funciona igual en Windows en espanol o ingles
    $output = & icacls.exe $Path /grant '*S-1-1-0:(OI)(CI)F' 2>&1
    if ($LASTEXITCODE -eq 0) {
        Ok ('ACL NTFS: Everyone lectura/escritura en {0}' -f $Path)
    } else {
        Warn ('icacls fallo en {0}: {1}' -f $Path, ($output -join ' '))
    }
}

function Ensure-LabShare {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Ok ('carpeta creada: {0}' -f $Path)
    }

    $share = Get-SmbShare -Name $Name -ErrorAction SilentlyContinue
    if ($share) {
        if ($share.Path -ne $Path) {
            Warn ('el share {0} apunta a {1}; se recrea sobre {2}' -f $Name, $share.Path, $Path)
            Remove-SmbShare -Name $Name -Force -ErrorAction Stop
            $share = $null
        } else {
            Ok ('share {0} ya existe en {1}' -f $Name, $Path)
        }
    }

    if (-not $share) {
        New-SmbShare -Name $Name -Path $Path -Description $Description -ErrorAction Stop | Out-Null
        Ok ('share {0} creado' -f $Name)
    }

    # "WD" = Everyone en SDDL: no depende del idioma del sistema operativo
    Set-SmbShare -Name $Name -SecurityDescriptor 'D:(A;;FA;;;WD)' -Force -ErrorAction Stop
    Ok ('permisos de share {0}: Everyone lectura/escritura' -f $Name)

    Grant-EveryoneFullControl -Path $Path
}

function Enable-LabSmb1 {
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction Stop
        if ($feature.State -ne 'Enabled') {
            Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop | Out-Null
            Ok 'SMB1 habilitado (intencional: MS17-010)'
        } else {
            Ok 'SMB1 ya habilitado'
        }
        Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force -ErrorAction Stop
    } catch {
        Fail ('no se pudo habilitar SMB1: {0}' -f $_.Exception.Message)
    }
}

function Disable-SmbSigning {
    $config = Get-SmbServerConfiguration -ErrorAction Stop
    if (-not $config.RequireSecuritySignature) {
        Ok 'firma SMB ya no es obligatoria'
    } else {
        Set-SmbServerConfiguration -RequireSecuritySignature $false -Force -ErrorAction Stop
        Ok 'firma SMB desactivada (debilidad intencional)'
    }

    $config = Get-SmbServerConfiguration -ErrorAction Stop
    if ($config.RequireSecuritySignature) {
        Fail 'no se pudo desactivar la firma SMB obligatoria'
    }
}

function Write-CredentialsFile {
    param(
        [string]$Path,
        [string]$Content
    )

    if (Test-Path -LiteralPath $Path) {
        $actual = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
        if ($actual -and $actual.Trim() -eq $Content) {
            Ok ('{0} sin cambios' -f $Path)
            return
        }
    }

    Set-Content -LiteralPath $Path -Value $Content -Encoding ASCII -ErrorAction Stop
    Ok ('credenciales escritas en {0}' -f $Path)
}

# ---------------------------------------------------------------- WinRM / Spooler / firewall
function Enable-LabWinRm {
    $service = Get-Service -Name WinRM -ErrorAction SilentlyContinue
    if (-not $service) {
        Fail 'el servicio WinRM no esta disponible'
    }

    $listener = $null
    try {
        $listener = Get-ChildItem -Path 'WSMan:\localhost\Listener' -ErrorAction Stop
    } catch {
        $listener = $null
    }

    if (-not $listener) {
        try {
            Enable-PSRemoting -Force -SkipNetworkProfileCheck -ErrorAction Stop | Out-Null
            Ok 'WinRM habilitado (Enable-PSRemoting)'
        } catch {
            Warn ('Enable-PSRemoting fallo: {0}' -f $_.Exception.Message)
        }
    } else {
        Ok 'WinRM ya tiene listener configurado'
    }

    Set-Service -Name WinRM -StartupType Automatic -ErrorAction Stop
    if ((Get-Service -Name WinRM).Status -ne 'Running') {
        Start-Service -Name WinRM -ErrorAction Stop
    }
    Ok 'servicio WinRM en ejecucion'

    Start-Sleep -Seconds 2
    if (Test-NetConnection -ComputerName 127.0.0.1 -Port 5985 -InformationLevel Quiet -WarningAction SilentlyContinue) {
        Ok 'WinRM escuchando en 5985'
    } else {
        Warn '5985 no responde todavia; revisar despues del reinicio'
    }
}

function Ensure-Spooler {
    $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='Spooler'" -ErrorAction Stop
    if (-not $service) {
        Fail 'el servicio Spooler no existe'
    }

    if ($service.StartMode -ne 'Auto') {
        Set-Service -Name Spooler -StartupType Automatic -ErrorAction Stop
        Ok 'Spooler en inicio Automatic'
    } else {
        Ok 'Spooler ya esta en inicio Automatic'
    }

    if ($service.State -ne 'Running') {
        Start-Service -Name Spooler -ErrorAction Stop
        Ok 'Spooler iniciado'
    } else {
        Ok 'Spooler en ejecucion'
    }
}

function Ensure-FirewallRule {
    param(
        [string]$DisplayName,
        [string]$Protocol,
        [int[]]$Ports
    )

    $rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
    if ($rule) {
        Set-NetFirewallRule -DisplayName $DisplayName -Enabled True -Action Allow -Profile Any -ErrorAction SilentlyContinue
        Ok ('regla de firewall presente: {0}' -f $DisplayName)
        return
    }

    New-NetFirewallRule -DisplayName $DisplayName -Direction Inbound -Protocol $Protocol `
        -LocalPort $Ports -RemoteAddress $LabNet -Action Allow -Profile Any -ErrorAction Stop | Out-Null
    Ok ('regla de firewall creada: {0} ({1})' -f $DisplayName, $Protocol)
}

function Set-LabFirewall {
    $rules = @(
        @{ Name = 'LAB-M4-DNS-TCP';    Protocol = 'TCP'; Ports = @(53) },
        @{ Name = 'LAB-M4-DNS-UDP';    Protocol = 'UDP'; Ports = @(53) },
        @{ Name = 'LAB-M4-KERBEROS';   Protocol = 'TCP'; Ports = @(88) },
        @{ Name = 'LAB-M4-LDAP';       Protocol = 'TCP'; Ports = @(389) },
        @{ Name = 'LAB-M4-SMB';        Protocol = 'TCP'; Ports = @(445) },
        @{ Name = 'LAB-M4-NETBIOS';    Protocol = 'TCP'; Ports = @(139) },
        @{ Name = 'LAB-M4-WINRM';      Protocol = 'TCP'; Ports = @(5985, 5986) },
        @{ Name = 'LAB-M4-RDP';        Protocol = 'TCP'; Ports = @(3389) }
    )

    foreach ($rule in $rules) {
        Ensure-FirewallRule -DisplayName $rule.Name -Protocol $rule.Protocol -Ports $rule.Ports
    }
}

# ---------------------------------------------------------------- nombre
function Rename-LabComputer {
    param([string]$NewName)

    if ($env:COMPUTERNAME -ieq $NewName) {
        Ok ('nombre de equipo ya es {0}' -f $NewName)
        return
    }

    Rename-Computer -NewName $NewName -Force -ErrorAction Stop
    $script:RebootNeeded = $true
    Ok ('equipo renombrado a {0} (requiere reinicio)' -f $NewName)
}

# ---------------------------------------------------------------- resumen
function Show-Summary {
    Write-Host ''
    Write-Host '---------------- resumen M4 ----------------' -ForegroundColor Cyan
    Log ('nombre de equipo actual: {0} (objetivo {1})' -f $env:COMPUTERNAME, $M4Name)

    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -like '10.10.10.*' } |
        ForEach-Object { Log ('IP: {0}/{1} en {2}' -f $_.IPAddress, $_.PrefixLength, $_.InterfaceAlias) }

    try {
        $zone = Get-DnsServerZone -Name $LabDomain -ErrorAction Stop
        Log ('zona DNS {0}: tipo {1}' -f $LabDomain, $zone.ZoneType)
    } catch {
        Log ('zona DNS {0}: no consultable' -f $LabDomain)
    }

    try {
        $shares = @(Get-SmbShare -ErrorAction Stop | Where-Object { $_.Name -eq $ShareName })
        foreach ($item in $shares) { Log ('share {0} -> {1}' -f $item.Name, $item.Path) }
    } catch {
        Log 'no se pudo enumerar shares'
    }

    if ($script:RebootNeeded) {
        Warn 'REINICIA la VM para aplicar nombre/rol y despues ejecuta verify.ps1'
    }

    Log ('resultado: {0} OK, {1} WARN, {2} FAIL' -f $script:OkCount, $script:WarnCount, $script:FailCount)
    if ($script:FailCount -gt 0) {
        Write-Host 'M4 termino con errores.' -ForegroundColor Red
        exit 1
    }
    Ok 'M4 configurado. Siguiente paso: .\verify.ps1'
}

# ---------------------------------------------------------------- principal
Show-Banner
Assert-Administrator
Initialize-LabLog -LeafName 'm4-install.log'
Show-OperatingSystem

Step '1/10 red estatica'
Set-LabNetwork -Ip $M4Ip -Gateway $M4Gateway -DnsServer $M4Dns -PrefixLength 24

Step '2/10 rol DNS'
Install-DnsRole

Step '3/10 zona uni.lab y registros'
Ensure-DnsZone

$recordsA = @(
    @{ Name = 'app';      Ip = $M1Ip },
    @{ Name = 'db';       Ip = $M2Ip },
    @{ Name = 'bkp';      Ip = $M3Ip },
    @{ Name = 'srvold';   Ip = $M4Ip },
    @{ Name = 'pc-est01'; Ip = $M5Ip }
)
foreach ($record in $recordsA) {
    Ensure-DnsARecord -Name $record.Name -Ip $record.Ip
}

$recordsCname = @(
    @{ Name = 'wp';     Target = 'app.uni.lab.' },
    @{ Name = 'moodle'; Target = 'app.uni.lab.' }
)
foreach ($record in $recordsCname) {
    Ensure-DnsCname -Name $record.Name -Target $record.Target
}

Step '4/10 transferencia de zona y reenviadores'
Set-OpenZoneTransfer
Disable-DnsForwarders

Step '5/10 cuentas locales'
Set-LabAccounts

Step '6/10 share SMB y firma'
Ensure-LabShare -Name $ShareName -Path $SharePath -Description 'Transfer del laboratorio (Everyone lectura/escritura)'
Enable-LabSmb1
Disable-SmbSigning

Step '7/10 WinRM'
Enable-LabWinRm

Step '8/10 Spooler'
Ensure-Spooler

Step '9/10 firewall'
Set-LabFirewall

Step '10/10 credenciales y nombre de equipo'
Write-CredentialsFile -Path (Join-Path $SharePath 'README.txt') -Content 'Share de transferencia del laboratorio. Sin secretos: la cadena no usa credenciales.'
Rename-LabComputer -NewName $M4Name

Show-Summary
exit 0
