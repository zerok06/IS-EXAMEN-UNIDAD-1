# Guía M4 · Windows Server heredado (Estudiante 4)

**Rol:** DNS + SMB legacy. **100% interno: Kali NO te ve directo** (R0 bloquea WAN→.14). Solo se llega por pivote desde M1. Aquí va el **privesc obligatorio**.

> Versión automatizada: [`ansible/play-m4-windows.yml`](../ansible/play-m4-windows.yml) (requiere WinRM según `ansible/README-AUTO.md` §1).

## 0. Imagen base (descargar ANTES de aislar)

| Qué | Versión exacta | Dónde (verificado 2026-10-24) |
|---|---|---|
| Windows Server 2016 | Evaluación 180 días (sin parches post-2017) | https://www.microsoft.com/en-us/evalcenter/download-windows-server-2016 |
| TightVNC | Solo si se usa variante VNC en M4 (el VNC principal va en M5) | https://www.tightvnc.com/download.php |

VMware: VM Windows Server 2016, 2 vCPU / 4 GB / 60 GB, red en **bridge al lado INTERNO**, VMware Tools. **No instalar Windows Update** (el parche MS17-010 arruinaría S1; documentar build con `winver`).

## 1. VM y red

- Windows Server 2016 **sin parches** (sin MS17-010, con SMBv1 y Spooler). 2 vCPU · 4 GB · 60 GB.
- VMware en **bridge al lado INTERNO**. IP estática:

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 10.10.10.14 `
  -PrefixLength 24 -DefaultGateway 10.10.10.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 127.0.0.1
Rename-Computer -NewName "SRVOLD" -Restart
```

## 2. Servicios

DNS standalone (sin AD):

```powershell
Install-WindowsFeature DNS -IncludeManagementTools
Add-DnsServerPrimaryZone -Name "uni.lab" -ZoneFile "uni.lab.dns"
Add-DnsServerResourceRecordA -ZoneName "uni.lab" -Name "app"     -IPv4Address 10.10.10.11
Add-DnsServerResourceRecordCName -ZoneName "uni.lab" -Name "wp"     -HostNameAlias app.uni.lab.
Add-DnsServerResourceRecordCName -ZoneName "uni.lab" -Name "moodle" -HostNameAlias app.uni.lab.
Add-DnsServerResourceRecordA -ZoneName "uni.lab" -Name "db"      -IPv4Address 10.10.10.12
Add-DnsServerResourceRecordA -ZoneName "uni.lab" -Name "bkp"     -IPv4Address 10.10.10.13
Add-DnsServerResourceRecordA -ZoneName "uni.lab" -Name "srvold"  -IPv4Address 10.10.10.14
Add-DnsServerResourceRecordA -ZoneName "uni.lab" -Name "pc-est01" -IPv4Address 10.10.10.15
```

SMB legacy + superficie vulnerable:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol   # S1: EternalBlue
Set-Service Spooler -StartupType Automatic; Start-Service Spooler # S2: PrintNightmare
New-Item C:\LegacyShare -ItemType Directory
New-SmbShare -Name legacy -Path C:\LegacyShare -FullAccess Administradores
net user Administrator <CLAVE_DEBIL_COMUN>   # S3: misma clave que M5 y credenciales.txt (intencional)
```

Errores de configuración intencionales (S4–S5):

```powershell
# S4: AXFR abierto (variante vulnerable; en línea base: solo NS autorizados)
# DNS Manager -> zona uni.lab -> Propiedades -> Transferencias de zona ->
#   "Permitir transferencia de zona a cualquier servidor" (variante intencional)

# S5: firma SMB NO requerida + resolución de nombres legacy activa
Set-SmbServerConfiguration -RequireSecuritySignature $false -Force
# LLMNR/NBT-NS: dejar activos (defecto) para la demo con Responder
```

Firewall (tú impones la separación lógica: solo M1 entra a SMB/RDP; DNS abierto a la LAN):

```powershell
New-NetFirewallRule -DisplayName "SMB solo M1" -Direction Inbound -Protocol TCP `
  -LocalPort 445 -RemoteAddress 10.10.10.11 -Action Allow
New-NetFirewallRule -DisplayName "RDP solo M1" -Direction Inbound -Protocol TCP `
  -LocalPort 3389 -RemoteAddress 10.10.10.11 -Action Allow
New-NetFirewallRule -DisplayName "DNS LAN" -Direction Inbound -Protocol UDP `
  -LocalPort 53 -RemoteAddress 10.10.10.0/24 -Action Allow
New-NetFirewallRule -DisplayName "SMB resto DROP" -Direction Inbound -Protocol TCP `
  -LocalPort 445 -Action Block
```

## 3. Tus vulnerabilidades

| ID | Qué fijar | Validación esperada (vía pivote) |
|---|---|---|
| S1 | SMBv1 sin MS17-010 | `ms17_010_eternalblue` → shell SYSTEM |
| S2 | Spooler sin parche | PoC PrintNightmare → SYSTEM |
| S3 | Privesc + clave débil | `nxc smb ... -u Administrator -p <débil>` → `legacy`; escalada a admin/SYSTEM documentada |
| S4 | AXFR abierto | `dig axfr uni.lab @10.10.10.14` vuelca la zona |
| S5 | Signing OFF + LLMNR/NBT-NS | `smb-security-mode` + Responder captura hash |

## 4. Prueba de "cerrado para M6, abierto para M1" (evidencia clave)

Pedir a M6 desde su `.20` (misma LAN, pero con tu firewall):

```bash
nmap -Pn -p 445,3389 10.10.10.14   # filtered: tu FW solo deja a M1
```

Y desde el pivote (M1): `smbclient -L //10.10.10.14` SÍ responde. Esa pareja demuestra el modelo.

## 5. Snapshots y entrega

- `estado-inicial-vulnerable`, `estado-parcheado` (MS17-010 + SMBv1 OFF + Spooler OFF/parcheado + clave larga + RDP con NLA/solo M6 + AXFR restringido + signing required + LLMNR/NBT-NS OFF).
- Evidencia por S1–S5 + retest + prueba de invisibilidad externa.
