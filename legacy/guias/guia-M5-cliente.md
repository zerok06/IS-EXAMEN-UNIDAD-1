# Guía M5 · Estación Windows 10 (Estudiante 5)

**Rol:** usuario final + **último eslabón** (se cae por reúso de clave/EternalBlue). Interno, sin exposición directa.

> Versión automatizada: [`ansible/play-m5-client.yml`](../ansible/play-m5-client.yml) (VNC auth None + pausar updates se hacen a mano).

## Estado real de la implementación (2026-10-24)

| Componente | Estado real |
|---|---|
| SO / red | Windows 10, hostname `DESKTOP-DT5F05N`; IP `10.10.10.15/24`, gateway `.1`, DNS `10.10.10.14`; adaptador VMware en **bridge** |
| Cuenta | `cliente` con clave `Admin13.-` (necesaria para administración remota) |
| SMBv1 | **Enabled** (C1) |
| RDP | Activo, **NLA desactivado** (C3), firewall desde la LAN |
| TightVNC | **2.8.90** instalado como servicio `tvnserver`, escucha `:5900`, **autenticación None** (C4) |
| Firewall | SMB y VNC **solo desde M1** (`10.10.10.11`); RDP desde la LAN |
| Prueba desde M1 | `445`, `3389`, `5900` **OPEN** |
| Prueba desde el host | `445` y `5900` bloqueados (separación lógica correcta) |
| Pendiente | Pausar Windows Update (si no se hizo), snapshot `estado-inicial-vulnerable` |

> **Corrección aplicada:** se eliminó la regla “SMB resto DROP”, porque en Windows una regla Block tiene prioridad sobre Allow y bloqueaba también a M1. La denegación al resto se logra con la política por defecto (sin Allow).

## 0. Imagen base

| Qué | Versión exacta | Dónde (verificado 2026-10-24) |
|---|---|---|
| Windows 10 | 21H2 **sin parches** (sin MS17-010; verificar con `winver`) | https://www.microsoft.com/en-us/software-download/windows10ISO |
| TightVNC Server | 2.x (C4: auth **None** en :5900) | https://www.tightvnc.com/download.php (elegir 64-bit) |

VMware: VM Windows 10, 2 vCPU / 4 GB / 40 GB, bridge al lado **INTERNO**, VMware Tools. **Pausar Windows Update** tras instalar (un parche cierra C1).

## 1. VM y red

- Windows 10 21H2 **sin parches** (sin MS17-010). 2 vCPU · 4 GB · 40 GB.
- VMware en **bridge al lado INTERNO**. IP estática:

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 10.10.10.15 `
  -PrefixLength 24 -DefaultGateway 10.10.10.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 10.10.10.14
Rename-Computer -NewName "PC-EST01" -Restart
```

## 2. Puesto de trabajo + superficie vulnerable

1. Navegador + acceso diario a `http://wp.uni.lab` y `http://moodle.uni.lab` (tu tráfico legítimo también sirve de ruido de fondo).
2. **SMBv1 activado** (C1): `Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol`.
3. Admin local con la **misma clave débil que M4** (C2, reúso intencional para el paso 5).
4. Firefox/Office desactualizados + RDP con NLA desactivado (C3, factor humano).
5. **VNC sin contraseña (C4):** instalar TightVNC Server, puerto 5900, autenticación **None** (sin clave). Es administración remota mal configurada: cualquiera en la LAN ve y controla el escritorio.
6. Subir un documento a Moodle y una imagen a WP: verifica que aparecen en M3 (coherencia del escenario).
7. Firewall (separación lógica: solo M1 entra; ver guia-R0 §3):

```powershell
New-NetFirewallRule -DisplayName "SMB solo M1" -Direction Inbound -Protocol TCP `
  -LocalPort 445 -RemoteAddress 10.10.10.11 -Action Allow
New-NetFirewallRule -DisplayName "RDP solo M1" -Direction Inbound -Protocol TCP `
  -LocalPort 3389 -RemoteAddress 10.10.10.11 -Action Allow
New-NetFirewallRule -DisplayName "VNC solo M1" -Direction Inbound -Protocol TCP `
  -LocalPort 5900 -RemoteAddress 10.10.10.11 -Action Allow
# Sin regla Block: la política por defecto deniega el resto (Block anularía el Allow a M1).
```

## 3. Tus vulnerabilidades

| ID | Qué fijar | Validación esperada (vía pivote) |
|---|---|---|
| C1 | SMBv1 sin MS17-010 | `ms17_010_eternalblue` → shell |
| C2 | Misma clave que M4/`credenciales.txt` | `nxc smb 10.10.10.15 -u Administrador -p <débil>` → acceso |
| C3 | Software viejo + RDP expuesto | Inventario de versiones + login RDP débil |
| C4 | VNC :5900 sin clave | `vncviewer 10.10.10.15` entra sin pedir nada (vía pivote) |

## 4. Snapshots y entrega

- `estado-inicial-vulnerable`, `estado-parcheado` (parcheado al día, SMBv1 OFF, clave única larga, RDP con NLA, VNC con clave o desinstalado).
- Evidencia por C1–C4 + retest + capturas de tu uso legítimo (demuestra el rol "factor humano").
