# Version gate · estado parcheado · 2026-10-27

> Corte posterior a Fase 5/6. Evidencia de retest: [`EV-007-RETEST`](../informe/evidencias/logs/EV-007-RETEST.log). Fuente de versiones: [`version-matrix.md`](./version-matrix.md) y [`version-gate-2026-10-27.md`](./version-gate-2026-10-27.md).

## 1. Tabla maestra

| ID | Producto | Instalada final | Fix | ¿Cumple? | Evidencia |
|---|---|---|---|---|---|
| W1 | WordPress | **7.0.2** | 6.9.5 / 7.0.2 | **Sí** (7.0.2) + `/batch/v1` 403 | `EV-007-RETEST` |
| W2 | PHP | **8.4.27** ZTS + `upload_progress=Off` | 8.4.27 | **Sí** (versión + config) | `EV-007-RETEST` |
| W3 | Apache | **2.4.51** | 2.4.50 / 2.4.51+ | **Sí** (2.4.51) + CGI 403 | `EV-007-RETEST` |
| D1 | Redis | **6.2.7** + `requirepass` | 6.2.7 | **Sí** (versión + auth) | `EV-007-RETEST` |
| B1 | Samba | **4.5.10** | 4.5.10 | **Sí** (fix) + SMB2 mínimo | `EV-007-RETEST` |
| B2 | vsftpd | 2.3.4 limpio | 2.3.4 limpio / 3.x | **No aplica** (sin backdoor) | `EV-007-RETEST` |
| S2 | Spooler | WS2016 14393, **Stopped** | KB / off | **Sí** (config) | `EV-007-RETEST` |
| C4 | TightVNC | M5 filtrado | password/localhost | **Pendiente** (sin acceso) | `EV-007-RETEST` |

## 2. Configuraciones cerradas

| ID | Antes | Después |
|---|---|---|
| W4 | `Admin13.-` | `Uni2026!Admin` (viejo 200, nuevo 302) |
| W5 | `server-status` 200 | 403 externo |
| W6 | `info.php` 200 | 404 |
| W7 | `Index of` | 403 |
| M1-SSH | `ubuntu/Admin13.-` + sudo | `M1_Ubuntu_2026!`; viejo falla |
| D2 | `wp_pass123` | `Wp_Uni_2026!` (viejo ERR, nuevo OK) |
| D3 | 3306/6379/161 abiertos | 3306/6379 filtered; 161 localhost |
| D4 | `public`/`private` | deshabilitados; comunidad fuerte local |
| B3 | FTP anónimo 230 | 530 |
| B4 | `no_root_squash` | `root_squash` |
| B5 | `rony123/rony123` | `M3_Backup_2026!`; viejo falla |
| S1 | SMBv1 True | False |
| S2 | Spooler Running | Stopped |
| S3 | `password_2026` | `M4_Admin_2026!`; viejo falla |
| S4 | AXFR | Transfer failed |
| S5 | signing off | signing True |

## 3. Pendiente

- **M5**: 445/3389/5900 filtrados; C2/C3/C4 no verificados. Requiere consola/VMware.
- **Snapshot `estado-parcheado`**: M1–M4 listos para tomarlo; M5 cuando se acceda.
- **Chain D zero-dep**: no público; W2 se cierra por versión 8.4.27 + `upload_progress=Off` + eliminación del LFI.
