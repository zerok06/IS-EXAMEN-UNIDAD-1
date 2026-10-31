# m5-setup.ps1 — Configuración de M5 (Windows 10) para el laboratorio
# Ejecutar en PowerShell COMO ADMINISTRADOR dentro de la VM M5.
# Deja: IP 10.10.10.15, DNS 10.14, clave de laboratorio, SMBv1, RDP sin NLA y reglas de firewall.
# La IP del host del laboratorio se asume 10.10.10.1 (MitraStar) y DNS 10.10.10.14 (M4).

$ErrorActionPreference = 'Stop'

# 1. Clave de la cuenta actual (necesaria para administración remota por VMware/Ansible)
$cuenta = $env:USERNAME
$clave  = 'Admin13.-'
Write-Host "[1/6] Asignando clave de laboratorio a $cuenta ..."
net user $cuenta $clave | Out-Null

# 2. Red estática
Write-Host "[2/6] Configurando IP estática ..."
$if = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
if (-not $if) { throw 'No hay adaptador de red activo' }
New-NetIPAddress -InterfaceAlias $if.Name -IPAddress 10.10.10.15 -PrefixLength 24 -DefaultGateway 10.10.10.1 -ErrorAction SilentlyContinue | Out-Null
Set-DnsClientServerAddress -InterfaceAlias $if.Name -ServerAddresses 10.10.10.14
Write-Host ("Interfaz: " + $if.Name)

# 3. SMBv1 (vuln C1 intencional)
Write-Host "[3/6] Habilitando SMBv1 (C1) ..."
Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null

# 4. RDP sin NLA (C3 intencional)
Write-Host "[4/6] Habilitando RDP sin NLA (C3) ..."
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 0
New-NetFirewallRule -DisplayName 'RDP laboratorio' -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress 10.10.10.0/24 -Action Allow -ErrorAction SilentlyContinue | Out-Null

# 5. Firewall: solo M1 para SMB y VNC (separación lógica)
Write-Host "[5/6] Reglas de firewall (solo M1) ..."
New-NetFirewallRule -DisplayName 'SMB solo M1' -Direction Inbound -Protocol TCP -LocalPort 445 -RemoteAddress 10.10.10.11 -Action Allow -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName 'VNC solo M1' -Direction Inbound -Protocol TCP -LocalPort 5900 -RemoteAddress 10.10.10.11 -Action Allow -ErrorAction SilentlyContinue | Out-Null
# Sin regla Block: la política por defecto deniega el resto.

# 6. Estado
Write-Host "[6/6] Verificación:"
Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -like '10.10.10.*' | Format-Table InterfaceAlias, IPAddress, PrefixLength
Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object ServerAddresses -ne $null | Format-Table InterfaceAlias, ServerAddresses
Write-Host ''
Write-Host 'Listo. Reinicia si se habilitó SMBv1 por primera vez.'
Write-Host 'Siguiente: instalar TightVNC Server y poner autenticación None (C4).'
