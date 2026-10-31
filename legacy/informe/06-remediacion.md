# 7. Remediación aplicada

**Estado:** 🟢 aplicada y verificada en **M1–M4** el **2026-10-27**. **M5** sigue pendiente (puertos filtrados, sin acceso). Las versiones **sí cambiaron**: WordPress 7.0.2, PHP 8.4.27, Apache 2.4.51, Redis 6.2.7.

> Regla aplicada: se limpió el estado comprometido (artefactos de Chain A, LFI, marcadores y sesiones) y se parcheó desde la línea base vulnerable. Evidencia de retest: `EV-007-RETEST`.

---

## 7.1 M1 · Aplicación

| ID | Medida aplicada | Verificación | Estado |
|---|---|---|---|
| W1 | WordPress **7.0.2** + bloqueo `/wp-json/batch/v1` | `wp core version` 7.0.2; `POST` = 403 | 🟢 |
| W2 | PHP **8.4.27** + `session.upload_progress.enabled=Off` + LFI eliminado | `php -v` 8.4.27; `opcache/ini`; `/lfi.php` 404 | 🟢 |
| W3 | Apache **2.4.51** + CGI denegado | `httpd -v` 2.4.51; traversal/RCE = 403 | 🟢 |
| W4 | Clave de `usc.admin` rotada a `Uni2026!Admin` | login viejo 200; nuevo 302 + cookie | 🟢 |
| W5 | `server-status` solo localhost | externo 403 | 🟢 |
| W6 | `info.php` eliminado | 404 | 🟢 |
| W7 | `Options -Indexes` en uploads | externo 403 | 🟢 |
| M1-SSH | Clave `ubuntu` rotada a `M1_Ubuntu_2026!` | SSH viejo falla; nuevo entra | 🟢 |

---

## 7.2 M2 · Base de datos

| ID | Medida aplicada | Verificación | Estado |
|---|---|---|---|
| D1 | Redis **6.2.7** + `requirepass` + `protected-mode` + UFW | `PING` = NOAUTH; con clave = PONG | 🟢 |
| D2 | Claves DB rotadas (`Wp_Uni_2026!`, `Moodle_Uni_2026!`) y configs M1 actualizadas | vieja = ERR; nueva = OK; WP responde | 🟢 |
| D3 | UFW: 3306 solo M1; 6379/161 cerrados a la LAN | `nmap` = filtered | 🟢 |
| D4 | SNMP `public/private` deshabilitados; comunidad fuerte solo en `127.0.0.1` | `snmpd` en 127.0.0.1:161; 161 filtrado | 🟢 |

---

## 7.3 M3 · Respaldos

| ID | Medida aplicada | Verificación | Estado |
|---|---|---|---|
| B1 | Samba **4.5.10** (fix) + `server min protocol = SMB2` | `smbd --version` 4.5.10 | 🟢 |
| B2 | vsftpd 2.3.4 limpio, sin backdoor | `:6200` cerrado; no aplica | ⚪ |
| B3 | `anonymous_enable=NO`, `local_enable=YES`; `credenciales.txt` eliminado | FTP anónimo = **530** | 🟢 |
| B4 | NFS `root_squash` en los tres exports | `exportfs -v` = `root_squash` | 🟢 |
| B5 | Clave SSH `rony123` rotada a `M3_Backup_2026!` | SSH viejo falla; nuevo entra | 🟢 |

---

## 7.4 M4 · Windows Server

| ID | Medida aplicada | Verificación | Estado |
|---|---|---|---|
| S1 | SMB1 **off** | `SMBv1:False` | 🟢 |
| S2 | Spooler **Stopped/Disabled**; usuario `soporte` eliminado | `(Get-Service Spooler).Status` = Stopped; sin `soporte` | 🟢 |
| S3 | Clave de `Administrador` rotada a `M4_Admin_2026!` | vieja = LOGON_FAILURE; nueva = OK | 🟢 |
| S4 | AXFR restringido | `dig axfr` = Transfer failed | 🟢 |
| S5 | SMB signing **on** | `signing:True` | 🟢 |

> M4 solo es accesible desde M1 (firewall por diseño); el retest se hizo por túnel SSH M6 → M1 → M4.

---

## 7.5 M5 · Estación cliente

| ID | Medida | Estado |
|---|---|---|
| C1 | No aplica (Win10 19045) | ⚪ |
| C2 | Clave única/LAPS | ⬜ pendiente: M5 con 445/3389/5900 filtrados |
| C3 | RDP con NLA | ⬜ pendiente |
| C4 | VNC con clave/localhost o desinstalar | ⬜ pendiente |

---

## 7.6 Registro de cambios

| Fecha UTC | Máquina | Cambio | Versión/config final | Evidencia |
|---|---|---|---|---|
| 2026-10-27 | M1 | WP 7.0.2 + bloqueo batch | 7.0.2 | `EV-007-RETEST` |
| 2026-10-27 | M1 | PHP 8.4.27 + `upload_progress=Off` | 8.4.27 | `EV-007-RETEST` |
| 2026-10-27 | M1 | Apache 2.4.51 + CGI denegado | 2.4.51 | `EV-007-RETEST` |
| 2026-10-27 | M1 | Claves W4/SSH + W5–W7 | config | `EV-007-RETEST` |
| 2026-10-27 | M2 | Redis 6.2.7 + auth + UFW + SNMP | 6.2.7 | `EV-007-RETEST` |
| 2026-10-27 | M2 | Claves DB rotadas | config | `EV-007-RETEST` |
| 2026-10-27 | M3 | FTP anónimo off, NFS root_squash, SSH | config | `EV-007-RETEST` |
| 2026-10-27 | M4 | SMB1 off, signing on, Spooler off, claves, AXFR | config | `EV-007-RETEST` |
| — | M5 | Pendiente de acceso | — | — |

> La tabla de versiones antes/después está en [`../docs/version-gate-2026-10-27-patched.md`](../docs/version-gate-2026-10-27-patched.md).
