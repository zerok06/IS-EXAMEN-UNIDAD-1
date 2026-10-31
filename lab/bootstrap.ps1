<#
.SYNOPSIS
  Bootstrap de una VM Windows del laboratorio (M4 / M5).

.DESCRIPTION
  Equivalente Windows de lab/bootstrap.sh. Descarga el paquete de despliegue
  desde M6 (http://10.10.10.20:8000/lab.zip), lo expande en C:\lab y ejecuta
  el instalador del rol pedido (m4 o m5).

  Idempotente: el paquete se valida en un directorio de stage antes de tocar
  C:\lab; si el rol no viene en el paquete se aborta sin destruir la
  instalacion previa. Si el reemplazo falla, se restaura el C:\lab anterior.

  No descarga nada de Internet: todo sale del servidor de M6 en la LAN aislada.

.PARAMETER Role
  Rol de la VM: m4 (Windows Server 2016, DNS + SMB + WinRM) o m5 (Windows 10).

.PARAMETER Mirror
  Servidor de despliegue. Por defecto http://10.10.10.20:8000.

.PARAMETER Dest
  Directorio destino. Por defecto C:\lab.

.EXAMPLE
  iwr http://10.10.10.20:8000/bootstrap.ps1 -UseBasicParsing -OutFile $env:TEMP\bootstrap.ps1
  powershell -NoProfile -ExecutionPolicy Bypass -File $env:TEMP\bootstrap.ps1 -Role m4

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\lab-bootstrap.ps1 -Role m5

.NOTES
  Laboratorio aislado IS-1023. Solo 10.10.10.0/24. Sin Internet.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('m4', 'm5')]
    [string]$Role,

    [string]$Mirror = 'http://10.10.10.20:8000',

    [string]$Dest = 'C:\lab'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ------------------------------------------------------------------ logging
$script:LogFile = Join-Path $env:TEMP 'lab-bootstrap.log'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $line = '{0} [{1}] {2}' -f $stamp, $Level, $Message
    Write-Host $line
    try { Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8 } catch { }
}

function Write-Step { param([string]$Message) Write-Host ''; Write-Log ('== ' + $Message + ' ==') }
function Write-Ok   { param([string]$Message) Write-Host ('[ OK ] ' + $Message) }
function Write-Warn { param([string]$Message) Write-Host ('[WARN] ' + $Message) }

function Stop-Bootstrap {
    param([string]$Message)
    Write-Log $Message 'FAIL'
    throw $Message
}

# ------------------------------------------------------------------ pre-vuelo
Write-Step "pre-vuelo"
Write-Log ("rol={0} mirror={1} dest={2}" -f $Role, $Mirror, $Dest)

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Stop-Bootstrap 'ejecutar en una consola elevada (Administrador)'
}
Write-Ok 'sesion elevada'

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Stop-Bootstrap ('PowerShell 5.1+ requerido; actual: ' + $PSVersionTable.PSVersion)
}

$trimmed = $Dest.TrimEnd('\')
if ($trimmed.Length -le 3) {
    Stop-Bootstrap ('destino inseguro: ' + $Dest)
}

# ------------------------------------------------------------------ descarga
Write-Step 'descarga del paquete'
$zip = Join-Path $env:TEMP 'lab.zip'
$url = ($Mirror.TrimEnd('/')) + '/lab.zip'
Write-Log ('GET ' + $url)

$downloaded = $false
for ($i = 1; $i -le 3; $i++) {
    try {
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -TimeoutSec 300
        $downloaded = $true
        break
    }
    catch {
        Write-Warn ('intento {0}/3 fallido: {1}' -f $i, $_.Exception.Message)
        if ($i -lt 3) { Start-Sleep -Seconds 2 }
    }
}
if (-not $downloaded) {
    Stop-Bootstrap ('no se pudo descargar ' + $url + ' (M6 arriba y sirviendo en :8000?)')
}
if (-not (Test-Path -LiteralPath $zip) -or (Get-Item -LiteralPath $zip).Length -eq 0) {
    Stop-Bootstrap 'lab.zip llego vacio'
}
Write-Ok ('paquete descargado: {0:N1} MB' -f ((Get-Item -LiteralPath $zip).Length / 1MB))

# Integridad: si el espejo publica lab.zip.sha256, se verifica antes de expandir.
Write-Step 'integridad del paquete'
$shaFile = Join-Path $env:TEMP 'lab.zip.sha256'
Remove-Item -LiteralPath $shaFile -Force -ErrorAction SilentlyContinue
$shaDownloaded = $false
try {
    Invoke-WebRequest -Uri ($url + '.sha256') -OutFile $shaFile -UseBasicParsing -TimeoutSec 30
    $shaDownloaded = $true
}
catch {
    Write-Warn 'el espejo no publica lab.zip.sha256; se continua sin verificar'
}
if ($shaDownloaded) {
    $want = ((Get-Content -LiteralPath $shaFile -TotalCount 1) -split '\s+')[0]
    $got = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLower()
    if (-not $want) {
        Stop-Bootstrap 'el archivo lab.zip.sha256 esta vacio'
    }
    if ($want.ToLower() -ne $got) {
        Stop-Bootstrap ('SHA256 de lab.zip no coincide (esperado ' + $want + ', obtenido ' + $got + ')')
    }
    Write-Ok ('SHA256 OK: ' + $got)
    Remove-Item -LiteralPath $shaFile -Force -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------------ extraccion
Write-Step ('extraccion en ' + $Dest)
$stage = $Dest + '.stage'
$old = $Dest + '.old'
$movedOld = $false

try {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
    New-Item -ItemType Directory -Path $stage -Force | Out-Null

    try {
        Expand-Archive -LiteralPath $zip -DestinationPath $stage -Force
    }
    catch {
        Stop-Bootstrap ('no se pudo expandir lab.zip: ' + $_.Exception.Message)
    }

    # El paquete puede traer el laboratorio en la raiz (m4\install.ps1) o el
    # repo completo (lab\m4\install.ps1). Se aceptan ambos.
    $rel = $null
    foreach ($cand in @("$Role\install.ps1", "lab\$Role\install.ps1")) {
        if (Test-Path -LiteralPath (Join-Path $stage $cand)) { $rel = $cand; break }
    }
    if (-not $rel) {
        $roles = @(Get-ChildItem -LiteralPath $stage -Recurse -Filter 'install.ps1' -ErrorAction SilentlyContinue |
                   ForEach-Object { Split-Path -Leaf (Split-Path -Parent $_.FullName) }) -join ' '
        if (-not $roles) { $roles = '<ninguno>' }
        Stop-Bootstrap ("el paquete no trae el rol '$Role' (falta $Role\install.ps1). Roles incluidos: $roles")
    }
    Write-Ok ("rol '$Role' presente en el paquete ($rel)")

    # Reemplazo: el stage ya esta completo y validado.
    if (Test-Path -LiteralPath $Dest) {
        if (Test-Path -LiteralPath $old) { Remove-Item -LiteralPath $old -Recurse -Force }
        Write-Log ('reemplazando ' + $Dest + ' (respaldo temporal en ' + $old + ')')
        Move-Item -LiteralPath $Dest -Destination $old
        $movedOld = $true
    }
    Move-Item -LiteralPath $stage -Destination $Dest
    Write-Ok ('instalado en ' + $Dest)
}
catch {
    # Restaurar la instalacion anterior si el reemplazo quedo a medias.
    if ($movedOld -and -not (Test-Path -LiteralPath $Dest) -and (Test-Path -LiteralPath $old)) {
        Move-Item -LiteralPath $old -Destination $Dest
        Write-Warn 'instalacion anterior restaurada'
    }
    throw
}
finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
}

# ------------------------------------------------------------------ instalador
Write-Step ('instalador del rol ' + $Role)
$installer = Join-Path $Dest ($rel)
Write-Log ('ejecutando ' + $installer)

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer
$code = $LASTEXITCODE
if ($code -ne 0) {
    Stop-Bootstrap ('install.ps1 devolvio ' + $code)
}

# El instalador corrio bien: se descarta el respaldo anterior.
if (Test-Path -LiteralPath $old) {
    Remove-Item -LiteralPath $old -Recurse -Force
}

# ------------------------------------------------------------------ resumen
Write-Step 'resumen'
Write-Ok ('rol {0} instalado desde {1}' -f $Role, $Mirror)
Write-Host ('repo:  ' + $Dest)
Write-Host ('log:   ' + $script:LogFile)

$verify = Join-Path (Split-Path -Parent $installer) 'verify.ps1'
if (Test-Path -LiteralPath $verify) {
    Write-Host ''
    Write-Host ('Siguiente paso: powershell -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $verify)
}
