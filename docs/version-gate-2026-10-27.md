# Version gate · corte 2026-10-27 00:49 UTC

> Fuente de verdad de versiones: [`version-matrix.md`](./version-matrix.md). Evidencia de este corte: [`EV-000-10`](../informe/evidencias/logs/EV-000-10.log) + [`LOG-000-06`](../informe/evidencias/logs/LOG-000-06.txt), [`LOG-000-07`](../informe/evidencias/logs/LOG-000-07.txt), [`LOG-000-08`](../informe/evidencias/logs/LOG-000-08.txt).
>
> Regla: si la instalada es igual o mayor que el fix, el CVE no cuenta. Si la instalada es vulnerable pero la configuración no permite el PoC, se marca “versión sí / condiciones no”.

## 1. Tabla maestra

| ID | Producto | Instalada | Rango vulnerable | Corrige | ¿Vulnerable hoy? | Evidencia | Fase |
|---|---|---|---|---|---|---|---|
| W1 | WordPress | **7.0.1** | 6.9.0–6.9.4 · 7.0.0–7.0.1 | 6.9.5 / 7.0.2 | **Sí** (versión + ruta batch 400 + BD OK) | `EV-000-11` | 2/4 |
| W2 | PHP | **8.4.26** (ZTS, MPM event en 80) | 8.4.x < 8.4.27 | 8.4.27 | **Versión sí**; en 8080 ya hay **NTS + prefork** con `display_errors=On`, `memory_limit=8M`; el PoC no cerró el leak de heap | `EV-W2-01` | 2/4 |
| W3 | Apache | **2.4.49** | 2.4.49 (CVE-2021-41773) | 2.4.50 / 2.4.51+ | **Sí**: RCE `uid=33(www-data)` con CGI operativo | `EV-005-M1-03`, `EV-000-11` | 2/4 |
| D1 | Redis | **6.2.6** (fuente) | paquete Debian/Ubuntu 6.2 ≤ 6.2.6 | 6.2.7 | **No aplica** al build de fuente | `EV-000-10` | — |
| B1 | Samba | **4.5.10** | 4.5.0–4.5.9 | **4.5.10** | **NO**: es el fix; instalar 4.5.9 | `EV-000-10` | 2 |
| B2 | vsftpd | **2.3.4** limpio | solo tarball troyanizado 2011 | 2.3.4 limpio / 3.x | **No reproducible** (6200 cerrado) | `EV-000-10` | — |
| S2 | Spooler WS2016 | **14393**, Spooler Running | builds bajo umbral | KB / Spooler off | **Candidato**; falta `soporte` | `nxc winrm` | 2/4 |
| C4 | TightVNC | **M5 filtrado** | auth None | password + localhost | **Desconocido**: 5900 filtrado | `EV-000-10` | 2/4 |
| S3 | Admin M4 | `password_2026` | config | clave fuerte/LAPS | **Sí** (`Pwn3d!`) | `nxc smb` | 4 |
| S4 | DNS AXFR | abierto | config | solo NS autorizados | **Sí** (`XFR size: 10`) | `dig axfr` | 4 |
| S5 | SMB signing | off + SMBv1 True | config | signing on + LLMNR off | **Sí** | `nxc smb` | 4 |

## 2. Detalle

### W1 · 7.0.1
- `wp core version` = 7.0.1; fix 7.0.2.
- `GET /wp-json/` = 200; `GET /wp-json/batch/v1` = 404 (esperado); `POST` vacío = **400** (ruta activa).
- BD operativa (sitio 200), 5 posts, `object-cache=Default`, admin `usc.admin`.
- **Decisión:** no reinstalar; ejecutar PoC cuando exista `previo-a-W1`.

### W2 · 8.4.26
- ZTS + MPM event + `php_module` (mod_php).
- `display_errors=Off`, `memory_limit=512M`, `session.upload_progress=On`.
- **Decisión:** el PoC espera NTS + prefork + `display_errors=On` + `memory_limit=8M`; rebuild con time-box. Si falla, documentar y sostener con W1/W3.

### W3 · 2.4.49
- Versión exacta vulnerable; `mod_cgid` cargado.
- Se corrigió el CGI: `Options ... ExecCGI`, `Require all granted`, `Scriptsock cgid/cgisock` y directorio `logs/cgid` de `www-data`.
- **RCE confirmado:** `POST /cgi-bin/.%2e/.../bin/sh` → `uid=33(www-data)` (`EV-005-M1-03`).
- El traversal a `/etc/passwd` sigue dando 500 (no es ejecutable); el impacto se demuestra con RCE, no con lectura de archivo.

### B1 · 4.5.10
- **No cumple el gate**: 4.5.10 es la versión que corrige CVE-2017-7494.
- **Decisión:** instalar `vulnerable/samba-4.5.9.tar.gz` (ya descargado y verificado en M3) con snapshot `previo-a-B1`; si no compila, retirar B1 y sostener M3 con B3/B4/B5.

### D1 y B2
- D1: Redis compilado de fuente; CVE-2022-0543 es de empaquetado Debian/Ubuntu. Documentar limitación.
- B2: tarball limpio, puerto 6200 cerrado. Documentar como no reproducible.

### M4
- `SRVOLD`, WS2016 14393, SMB signing False, SMBv1 True.
- `Administrador`/`password_2026` funciona (`Pwn3d!`).
- **`soporte` existe y es limitado:** está en `Usuarios`, `Usuarios de escritorio remoto` y `Usuarios de administración remota`, **no** en `Administradores`. `Soporte123!` autentica por SMB y WinRM.
- Spooler Running/Automatic; AXFR responde; 445/3389/5985 accesibles **solo desde M1** (firewall por diseño).
- **Decisión:** S3/S4/S5 listos; S2 puede partir de `soporte` (pendiente check MSF/PrintNightmare). El SYSTEM con admin no cuenta como privesc.

### M5
- Host arriba a nivel ARP (`00:0C:29:85:82:CD`), pero 445/3389/5900/5985 **filtrados** desde M6 y desde M1; ICMP sin respuesta.
- **Decisión:** diagnosticar firewall/perfil de red antes de C2/C3/C4; no se puede declarar 5/5 ni C4 todavía.

## 3. Estado del gate por fase

| Fase | Estado | Falta |
|---|---|---|
| Pre-0 Artefactos/FTP | 🟢 M1/M2/M3/M6; 🔶 M5 | Descarga de M5 cuando esté accesible |
| 0 Línea base | 🟢 M1–M4; 🔶 M5 | Snapshot/estado de M5 |
| 1 Instaladas | 🟢 M1–M4; 🔶 M5 | M5 |
| 2 Vulnerables | 🔶 | Samba 4.5.9 en M3; rebuild W2. W3 (CGI) y `soporte` M4 ya listos |
| 3 Fingerprint | ⏸ | Se ejecuta tras cerrar Fase 2 |
| 4 Explotabilidad | ⏸ | Snapshots `previo-a-*` |
| 5 Corregida | ⏸ | Tras Fase 4 |
| 6 Retest | ⏸ | Tras Fase 5 |

## 4. Reglas aplicadas

1. No se declara vulnerable sin comparar instalada vs fix.
2. B1 no cuenta como profundidad hasta que `smbd --version` diga 4.5.9.
3. W2/W3 no cuentan como RCE hasta ejecutar el PoC con las condiciones corregidas.
4. C4 y 5/5 quedan pendientes hasta que M5 responda.
5. Cada fila tiene evidencia fechada y hash en `informe/evidencias/hashes.txt`.
