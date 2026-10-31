<#
.SYNOPSIS
    Instalador del rol M5 (Windows 10 19045) del laboratorio aislado uni.lab.

.DESCRIPTION
    Deja M5 como estacion cliente del laboratorio:
      - IP estatica 10.10.10.15/24, gateway 10.10.10.1, DNS 10.10.10.14.
      - Nombre de equipo pc-est01.
      - Usuario local cliente / Admin13.- miembro de Administradores (debilidad intencional).
      - RDP habilitado SIN NLA y firewall 3389 abierto para la LAN del laboratorio.
      - Firma SMB desactivada, LLMNR y NBT-NS activos.
      - Share del escritorio (o C:\Compartido) con Everyone lectura/escritura.
      - Bandera C:\Users\cliente\Desktop\flag-M5.txt.
      - VNC opcional: solo si existe C:\lab\artifacts\tightvnc.msi (sin password).

    SOLO para el laboratorio aislado 10.10.10.0/24, sin Internet y con autorizacion
    del docente. Las configuraciones debiles son intencionales (escenario de clase);
    no usar este script en una red real.

.NOTES
    - Ejecutar en la CONSOLA de la VM como Administrador (cambia IP y nombre).
    - Idempotente: cada paso comprueba el estado antes de crear o modificar.
    - No descarga nada de Internet, no instala malware y no borra logs.
    - Al terminar puede requerir reinicio (nombre de equipo); luego correr verify.ps1.
#>

[CmdletBinding()]
param(
    # Adaptador de red a configurar. Si se omite, se toma el primer adaptador activo.
    [string]$InterfaceAlias
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- constantes
$LabRoot   = 'C:\lab'
$M5Ip      = '10.10.10.15'
$M5Gateway = '10.10.10.1'
$M5Dns     = '10.10.10.14'
$M5Name    = 'pc-est01'
$LabNet    = '10.10.10.0/24'

$ClientUser     = 'cliente'
$ClientPassword = 'Admin13.-'
$ClientDesktop  = 'C:\Users\cliente\Desktop'
$FallbackShare  = 'C:\Compartido'
$FlagPath       = 'C:\Users\cliente\Desktop\flag-M5.txt'
$FlagMarker     = 'FLAG-M5-cliente'
$VncCandidates  = @(
    'C:\lab\artifacts\vulnerable\tightvnc-2.8.90-gpl-setup-64bit.msi',
    'C:\lab\artifacts\tightvnc.msi',
    'C:\lab\artifacts\vulnerable\tightvnc.msi'
)
$VncMsi         = ($VncCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)
if (-not $VncMsi) { $VncMsi = $VncCandidates[0] }

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
    Write-Host ' LAB PHP2SHELL - M5 - Windows 10 cliente' -ForegroundColor Cyan
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
    if ([int]$os.BuildNumber -lt 19045) {
        Warn 'se esperaba Windows 10 22H2 (build 19045); el laboratorio asume esa version'
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
        # no es critico para el laboratorio: toda la red esta en la misma subred /24
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

# ---------------------------------------------------------------- cuentas locales
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

    $group   = Get-LocalGroup -SID $GroupSid -ErrorAction Stop
    $user    = Get-LocalUser -Name $UserName -ErrorAction Stop
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

# ---------------------------------------------------------------- RDP
function Enable-LabRdp {
    $tsKey  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
    $rdpKey = Join-Path $tsKey 'WinStations\RDP-Tcp'

    $deny = (Get-ItemProperty -Path $tsKey -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections
    if ($null -eq $deny -or $deny -ne 0) {
        Set-ItemProperty -Path $tsKey -Name fDenyTSConnections -Value 0 -Type DWord -ErrorAction Stop
        Ok 'RDP habilitado (fDenyTSConnections=0)'
    } else {
        Ok 'fDenyTSConnections ya es 0'
    }

    # NLA desactivado: debilidad intencional del escenario
    $nla = (Get-ItemProperty -Path $rdpKey -Name UserAuthentication -ErrorAction SilentlyContinue).UserAuthentication
    if ($null -eq $nla -or $nla -ne 0) {
        Set-ItemProperty -Path $rdpKey -Name UserAuthentication -Value 0 -Type DWord -ErrorAction Stop
        Ok 'NLA desactivado en RDP-Tcp (debilidad intencional)'
    } else {
        Ok 'NLA ya desactivado en RDP-Tcp'
    }

    $service = Get-Service -Name TermService -ErrorAction SilentlyContinue
    if (-not $service) {
        Fail 'el servicio TermService no esta disponible'
    }
    if ($service.Status -ne 'Running') {
        Start-Service -Name TermService -ErrorAction Stop
        Ok 'TermService iniciado'
    } else {
        Ok 'TermService en ejecucion'
    }

    # El listener puede tardar unos segundos en abrir 3389 tras habilitar RDP.
    Start-Sleep -Seconds 2
    if (-not (Test-NetConnection -ComputerName 127.0.0.1 -Port 3389 -InformationLevel Quiet -WarningAction SilentlyContinue)) {
        try {
            Restart-Service -Name TermService -Force -ErrorAction Stop
            Start-Sleep -Seconds 3
            Ok 'TermService reiniciado para abrir el listener'
        } catch {
            Warn ('no se pudo reiniciar TermService: {0}' -f $_.Exception.Message)
        }
    }

    if (Test-NetConnection -ComputerName 127.0.0.1 -Port 3389 -InformationLevel Quiet -WarningAction SilentlyContinue) {
        Ok '3389 escuchando'
    } else {
        Warn '3389 aun no responde; revisar despues del reinicio'
    }
}

# ---------------------------------------------------------------- SMB y share
function Disable-SmbSigning {
    $config = Get-SmbServerConfiguration -ErrorAction Stop
    if (-not $config.RequireSecuritySignature -and -not $config.EnableSecuritySignature) {
        Ok 'firma SMB ya desactivada'
        return
    }

    Set-SmbServerConfiguration -RequireSecuritySignature $false -EnableSecuritySignature $false -Force -ErrorAction Stop
    Ok 'firma SMB desactivada (debilidad intencional)'

    $config = Get-SmbServerConfiguration -ErrorAction Stop
    if ($config.RequireSecuritySignature) {
        Fail 'no se pudo desactivar la firma SMB obligatoria'
    }
}

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

function Ensure-ClientShare {
    # Se prefiere el escritorio del usuario cliente; si no se puede, C:\Compartido.
    $path = $ClientDesktop
    try {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop | Out-Null
            Ok ('carpeta creada: {0}' -f $path)
        }
    } catch {
        Warn ('no se pudo preparar {0}: {1}' -f $path, $_.Exception.Message)
        $path = $FallbackShare
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Ok ('carpeta creada: {0}' -f $path)
    }

    $name = if ($path -eq $ClientDesktop) { 'Desktop' } else { 'Compartido' }

    try {
        Ensure-LabShare -Name $name -Path $path -Description 'Share del cliente (Everyone lectura/escritura)'
    } catch {
        Warn ('no se pudo compartir {0}: {1}' -f $path, $_.Exception.Message)
        $path = $FallbackShare
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
        Ensure-LabShare -Name 'Compartido' -Path $path -Description 'Share del cliente (Everyone lectura/escritura)'
    }

    return $path
}

function Write-FlagFile {
    param(
        [string]$Path,
        [string]$Marker
    )

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $content = @(
        $Marker,
        '',
        'Nota: marcador del laboratorio aislado uni.lab (M5 / pc-est01).',
        'Obtenido por la cadena M4 -> M5 (SMB/RDP). No es un dato real.',
        'Plantilla del marcador: FLAG-M5-{cliente}'
    )

    $expected = $content -join [Environment]::NewLine
    if (Test-Path -LiteralPath $Path) {
        $actual = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
        if ($actual -and $actual.Trim() -eq $expected.Trim()) {
            Ok ('bandera sin cambios: {0}' -f $Path)
            return
        }
    }

    Set-Content -LiteralPath $Path -Value $content -Encoding ASCII -ErrorAction Stop
    Ok ('bandera escrita: {0}' -f $Path)
}

# ---------------------------------------------------------------- resolucion legacy
function Enable-Llmnr {
    $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'
    try {
        if (-not (Test-Path -Path $key)) {
            New-Item -Path $key -Force -ErrorAction Stop | Out-Null
            Ok 'clave de politica DNSClient creada'
        }

        $current = (Get-ItemProperty -Path $key -Name EnableMulticast -ErrorAction SilentlyContinue).EnableMulticast
        if ($null -eq $current -or $current -ne 1) {
            New-ItemProperty -Path $key -Name EnableMulticast -PropertyType DWord -Value 1 -Force -ErrorAction Stop | Out-Null
            Ok 'LLMNR habilitado (EnableMulticast=1, debilidad intencional)'
        } else {
            Ok 'LLMNR ya habilitado (EnableMulticast=1)'
        }
    } catch {
        Warn ('no se pudo habilitar LLMNR: {0}' -f $_.Exception.Message)
    }
}

function Enable-Netbios {
    $base = 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces'
    if (-not (Test-Path -Path $base)) {
        Warn ('no existe {0}; NBT-NS queda como este por defecto' -f $base)
        return
    }

    $interfaces = @(Get-ChildItem -Path $base -ErrorAction SilentlyContinue)
    if ($interfaces.Count -eq 0) {
        Warn 'no hay interfaces NetBT registradas; NBT-NS queda por defecto'
        return
    }

    foreach ($interfaceKey in $interfaces) {
        try {
            # 0 = tomar la configuracion por defecto (NBT-NS habilitado con IP estatica)
            New-ItemProperty -Path $interfaceKey.PSPath -Name NetbiosOptions -PropertyType DWord -Value 0 -Force -ErrorAction Stop | Out-Null
            Ok ('NBT-NS activo en {0}' -f $interfaceKey.PSChildName)
        } catch {
            Warn ('no se pudo ajustar NetbiosOptions en {0}: {1}' -f $interfaceKey.PSChildName, $_.Exception.Message)
        }
    }
}

# ---------------------------------------------------------------- firewall
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
    Ensure-FirewallRule -DisplayName 'LAB-M5-SMB-445'    -Protocol 'TCP' -Ports @(445)
    Ensure-FirewallRule -DisplayName 'LAB-M5-NETBIOS-139' -Protocol 'TCP' -Ports @(139)
    Ensure-FirewallRule -DisplayName 'LAB-M5-RDP-3389'   -Protocol 'TCP' -Ports @(3389)
}

# ---------------------------------------------------------------- VNC opcional
function Install-OptionalVnc {
    if (-not (Test-Path -LiteralPath $VncMsi)) {
        Warn ('VNC opcional omitido: no existe {0} (se continua sin VNC)' -f $VncMsi)
        return $false
    }

    $service = Get-Service -Name tvnserver -ErrorAction SilentlyContinue
    if ($service) {
        Ok 'TightVNC ya esta instalado'
    } else {
        Log 'instalando TightVNC en modo silencioso (sin password, debilidad intencional)'
        $arguments = @(
            '/i', ('"{0}"' -f $VncMsi),
            '/qn', '/norestart',
            'ADDLOCAL=Server',
            'SET_USEVNCAUTHENTICATION=1',
            'VALUE_OF_USEVNCAUTHENTICATION=0',
            'SET_RUNCONTROLINTERFACE=1',
            'LICENSE_ACCEPTED=1'
        )

        try {
            $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop
            if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                Ok ('TightVNC instalado (exit {0})' -f $process.ExitCode)
            } else {
                Warn ('msiexec devolvio {0}; se continua sin VNC' -f $process.ExitCode)
                return $false
            }
        } catch {
            Warn ('fallo la instalacion de TightVNC: {0}' -f $_.Exception.Message)
            return $false
        }
    }

    # Autenticacion VNC desactivada en el registro, si la clave existe.
    $restartNeeded = $false
    $vncKey = 'HKLM:\SOFTWARE\TightVNC\Server'
    if (Test-Path -Path $vncKey) {
        try {
            $current = (Get-ItemProperty -Path $vncKey -Name 'UseVncAuthentication' -ErrorAction SilentlyContinue).UseVncAuthentication
            if ($null -eq $current -or $current -ne 0) {
                New-ItemProperty -Path $vncKey -Name 'UseVncAuthentication' -PropertyType DWord -Value 0 -Force -ErrorAction Stop | Out-Null
                Ok 'TightVNC: autenticacion VNC desactivada'
                $restartNeeded = $true
            } else {
                Ok 'TightVNC: autenticacion VNC ya estaba desactivada'
            }
        } catch {
            Warn ('no se pudo ajustar UseVncAuthentication: {0}' -f $_.Exception.Message)
        }
    }

    $service = Get-Service -Name tvnserver -ErrorAction SilentlyContinue
    if (-not $service) {
        Warn 'el servicio tvnserver no aparece; VNC no queda operativo'
        return $false
    }

    Set-Service -Name tvnserver -StartupType Automatic -ErrorAction SilentlyContinue
    if ((Get-Service -Name tvnserver).Status -ne 'Running') {
        try {
            Start-Service -Name tvnserver -ErrorAction Stop
        } catch {
            Warn ('no se pudo iniciar tvnserver: {0}' -f $_.Exception.Message)
        }
    } elseif ($restartNeeded) {
        # reiniciar solo si se cambio la autenticacion en el registro
        try {
            Restart-Service -Name tvnserver -Force -ErrorAction Stop
        } catch {
            Warn ('no se pudo reiniciar tvnserver: {0}' -f $_.Exception.Message)
        }
    }

    Start-Sleep -Seconds 2
    if (Test-NetConnection -ComputerName 127.0.0.1 -Port 5900 -InformationLevel Quiet -WarningAction SilentlyContinue) {
        Ok 'VNC escuchando en 5900'
    } else {
        Warn 'VNC no responde en 5900; revisar tras el reinicio'
    }

    Ensure-FirewallRule -DisplayName 'LAB-M5-VNC-5900' -Protocol 'TCP' -Ports @(5900)
    return $true
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
    param([bool]$VncInstalled)

    Write-Host ''
    Write-Host '---------------- resumen M5 ----------------' -ForegroundColor Cyan
    Log ('nombre de equipo actual: {0} (objetivo {1})' -f $env:COMPUTERNAME, $M5Name)

    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -like '10.10.10.*' } |
        ForEach-Object { Log ('IP: {0}/{1} en {2}' -f $_.IPAddress, $_.PrefixLength, $_.InterfaceAlias) }

    Log ('usuario de laboratorio: {0} (miembro de Administradores)' -f $ClientUser)
    Log ('bandera: {0}' -f $FlagPath)

    try {
        $shares = @(Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @('Desktop', 'Compartido') })
        foreach ($item in $shares) { Log ('share {0} -> {1}' -f $item.Name, $item.Path) }
    } catch {
        Log 'no se pudo enumerar shares'
    }

    if ($VncInstalled) {
        Log 'VNC: instalado sin password (C4 del escenario)'
    } else {
        Log 'VNC: no instalado (opcional)'
    }

    if ($script:RebootNeeded) {
        Warn 'REINICIA la VM para aplicar el nombre y despues ejecuta verify.ps1'
    }

    Log ('resultado: {0} OK, {1} WARN, {2} FAIL' -f $script:OkCount, $script:WarnCount, $script:FailCount)
    if ($script:FailCount -gt 0) {
        Write-Host 'M5 termino con errores.' -ForegroundColor Red
        exit 1
    }
    Ok 'M5 configurado. Siguiente paso: .\verify.ps1'
}

# ---------------------------------------------------------------- principal
Show-Banner
Assert-Administrator
Initialize-LabLog -LeafName 'm5-install.log'
Show-OperatingSystem

Step '1/9 red estatica'
Set-LabNetwork -Ip $M5Ip -Gateway $M5Gateway -DnsServer $M5Dns -PrefixLength 24

Step '2/9 usuario cliente'
Ensure-LabUser -UserName $ClientUser -Password $ClientPassword `
    -Description 'Usuario del laboratorio (clave debil, miembro de Administradores)' | Out-Null
Set-LabGroupMembership -UserName $ClientUser -GroupSid 'S-1-5-32-544'

Step '3/9 RDP sin NLA'
Enable-LabRdp

Step '4/9 SMB sin firma y share del cliente'
Disable-SmbSigning
$sharePath = Ensure-ClientShare

Step '5/9 bandera'
Write-FlagFile -Path $FlagPath -Marker $FlagMarker

Step '6/9 LLMNR y NBT-NS'
Enable-Llmnr
Enable-Netbios

Step '7/9 firewall'
Set-LabFirewall

Step '8/9 VNC opcional'
$vncInstalled = Install-OptionalVnc

Step '9/9 nombre de equipo'
Rename-LabComputer -NewName $M5Name

Show-Summary -VncInstalled $vncInstalled
exit 0
