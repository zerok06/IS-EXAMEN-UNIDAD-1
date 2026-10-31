# 8. Verificación de la remediación (retest Fase 6)

**Estado:** 🟢 Fase 6 completada en **M1–M4** el **2026-10-27**; **M5 pendiente** por puertos filtrados. Se usaron los **mismos comandos** de la explotación y se comparó antes/después. Evidencia única: `EV-007-RETEST`.

---

## 8.1 Método

1. Se limpió el estado comprometido (LFI, sesiones de Chain A, marcadores, plugin/admin) y se partió de la línea base vulnerable.
2. Se aplicaron versiones corregidas y configuraciones seguras en M1–M4.
3. Se repitieron los comandos de Fase 4/5 desde M6 (mismos paths y puertos).
4. Se capturó log + pantalla + SHA256 (`EV-007-RETEST`).

---

## 8.2 Tabla antes/después

| ID | Antes | Después real | Estado |
|---|---|---|---|
| W1 | WP 7.0.1; `POST /batch/v1` = 400 | WP **7.0.2**; `POST` = **403** | 🟢 |
| W2 | PHP 8.4.26; Chain A RCE `www-data` | PHP **8.4.27**; `upload_progress=Off`; `/lfi.php` = **404** | 🟢 |
| W3 | Apache 2.4.49; RCE `uid=www-data` | Apache **2.4.51**; traversal/RCE = **403** | 🟢 |
| W4 | `Admin13.-` → login 302 | `Admin13.-` = **200**; `Uni2026!Admin` = **302** | 🟢 |
| W5 | `server-status` 200 | externo **403** | 🟢 |
| W6 | `info.php` 200 | **404** | 🟢 |
| W7 | `Index of` uploads | externo **403** | 🟢 |
| M1-SSH | `ubuntu/Admin13.-` + sudo = root | `Admin13.-` falla; `M1_Ubuntu_2026!` funciona | 🟢 |
| D1 | Redis 6.2.6, `PING` = PONG sin auth | Redis **6.2.7**; `PING` = **NOAUTH**; con clave = PONG | 🟢 |
| D2 | `wp_pass123` conectaba | vieja = **ERR**; `Wp_Uni_2026!` = **OK** | 🟢 |
| D3 | 3306/6379 abiertos; 161/UDP | 3306/6379 **filtered**; 161 solo localhost | 🟢 |
| D4 | SNMP `public`/`private` | `public` deshabilitado; comunidad fuerte solo `127.0.0.1` | 🟢 |
| B1 | Samba 4.5.10 (fix) | 4.5.10 + SMB2 mínimo | 🟢 |
| B2 | vsftpd 2.3.4 limpio | sin backdoor; `:6200` cerrado | ⚪ |
| B3 | FTP anónimo 230 | anónimo = **530**; `credenciales.txt` eliminado | 🟢 |
| B4 | NFS `no_root_squash` | `root_squash` en los tres exports | 🟢 |
| B5 | SSH `rony123/rony123` | vieja falla; `M3_Backup_2026!` funciona | 🟢 |
| S1 | SMBv1 True | **SMBv1 False** | 🟢 |
| S2 | Spooler Running; `soporte` | Spooler **Stopped**; `soporte` eliminado | 🟢 |
| S3 | `password_2026` funcionaba | vieja = **LOGON_FAILURE**; `M4_Admin_2026!` = OK | 🟢 |
| S4 | AXFR completo | **Transfer failed** | 🟢 |
| S5 | signing off | **signing:True** | 🟢 |
| C1 | Win10 19045 | no aplica | ⚪ |
| C2–C4 | M5 filtrado | **pendiente de acceso** | ⬜ |

---

## 8.3 Versiones antes/después

| Componente | Antes | Después | Fix |
|---|---|---|---|
| WordPress | 7.0.1 | **7.0.2** | 7.0.2 |
| PHP | 8.4.26 ZTS | **8.4.27 ZTS** + `upload_progress=Off` | 8.4.27 |
| Apache | 2.4.49 | **2.4.51** | 2.4.50/2.4.51 |
| Redis | 6.2.6 | **6.2.7** + auth | 6.2.7 |
| Samba | 4.5.10 | **4.5.10** (fix) | 4.5.10 |
| vsftpd | 2.3.4 limpio | 2.3.4 + anónimo off | 3.0.5 / limpio |
| WS2016 | 14393 | SMB1 off, signing on, Spooler off | config |
| Win10 | 19045 | pendiente | — |

---

## 8.4 Residuales

| ID | Residual | Mitigación / decisión |
|---|---|---|
| W2 | Chain A sigue siendo posible **si existe un LFI**; Chain D zero-dep no está disponible (pago) | LFI eliminado; `upload_progress=Off`; PHP 8.4.27 |
| M5 | 445/3389/5900 filtrados; no se pudo remediar C2/C3/C4 | Documentar como pendiente; requiere consola/VMware |
| B2 | vsftpd 2.3.4 limpio | No aplica; `:6200` cerrado |
| D1 | Redis 6.2.7 en 0.0.0.0:6379 | UFW filtra 6379 + `requirepass`; bind residual tolerable |
| S1 | SMB1 off | S1 no aplica en este build |

---

## 8.5 Evidencia

| ID | Qué demuestra |
|---|---|
| `EV-007-RETEST` | Versiones, W1/W3/W5/W6/W7, W4, SSH M1; Redis/DB/UFW; FTP/NFS/Samba/SSH M3; SMB/Spooler/admin/AXFR M4; M5 filtrado |
| `EV-W2-08` / `EV-W2-09` | Antes: RCE `www-data` y ROOT con marcadores (para el antes/después) |
| `EV-ROOT-CHAIN` | Cadena B3 → M1 → sudo → root (antes) |

---

## 8.6 Conclusión

- **M1–M4 cerrados**: W1/W2/W3/W4/W5/W6/W7/M1-SSH, D1–D4, B1–B5 y S1–S5 con evidencia.
- **M5 pendiente**: sin acceso a servicios; no se declara remediado.
- **W2**: la versión fija (8.4.27) y `upload_progress=Off` están aplicados; Chain A queda neutralizado al eliminar el LFI. Chain D zero-dep no fue ejecutado (no público).
- El estado final para demo es **`estado-parcheado`**; debe tomarse snapshot tras este retest en M1–M4 (M5 cuando se acceda).
