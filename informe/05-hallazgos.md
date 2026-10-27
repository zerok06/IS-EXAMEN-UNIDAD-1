# 6. Hallazgos

> **Revalidación 2026-10-26:** 22 demostrables, 2 no reproducibles (D1, B2) y 2 no aplicables (S1, C1). Ver [`../docs/VALIDACION-VULNERABILIDADES.md`](../docs/VALIDACION-VULNERABILIDADES.md) y el flujo por vuln en [`../specs/005-fase-4-validacion-explotacion/vulns/`](../specs/005-fase-4-validacion-explotacion/vulns/).

**Estado a 2026-10-24.** Cada fila enlaza a la ficha completa en `hallazgos/` y a la evidencia en `anexos/b-indice-evidencias.md`.

---

## 6.1 Resumen

| ID | Máquina | CVE / debilidad | CVSS | Estado | Evidencia |
|---|---|---|---|---|---|
| W1 | M1 | CVE-2026-63030 (wp2shell) | 9.8 | 🟡 Fingerprint validado; RCE no ejecutada | `F03-001` |
| W2 | M1 | CVE-2026-109618/109619 (PHP2Shell) | 9.8 / 8.1 (v3.1) | 🟡 Precondiciones NTS/prefork cumplidas; leak de heap no cerrado en time-box; ROOT por M1-SSH | `EV-W2-01`, `EV-W2-ROOT` |
| W3 | M1 | CVE-2021-41773 | 9.8 | 🟢 Explotado: `uid=33(www-data)` vía CGI | `EV-005-M1-03` |
| W4 | M1 | Clave débil `usc.admin` | ~8.8 | 🟢 Validado (login 302 + cookie) | `F03-001` |
| W5 | M1 | `server-status` 200 | ~5.3 | 🟢 Validado | `F02-004` |
| W6 | M1 | `info.php` 200 | ~5.3 | 🟢 Validado | `F02-004` |
| W7 | M1 | `uploads` Index of | ~5.3 | 🟢 Validado | `F02-004` |
| M1-SSH | M1 | Clave reutilizada + sudo | ~8.8 | 🟢 Validado (root) | `F04-000`, `F04-000b` |
| D1 | M2 | CVE-2022-0543 / Redis sin auth | 10.0 | 🟢 Mitigado (`requirepass`; RCE no reproducible) | `F04-018`, `F06-008`, `F07-005` |
| D2 | M2 | Credenciales DB `wp_user`/`moodle_user` | ~8.1 | 🟢 Mitigado (claves rotadas + M1 actualizado) | `F04-018`, `F06-008`, `F07-005` |
| D3 | M2 | 6379 abierto a la LAN | ~7.5 | 🟢 Mitigado (UFW solo M1; filtrado desde M6) | `F04-018`, `F06-008`, `F07-005` |
| D4 | M2 | SNMP `public/private` | ~7.5 | 🟢 Mitigado (comunidades eliminadas; UDP solo M1) | `F04-019`, `F06-008`, `F07-005` |
| B1 | M3 | CVE-2017-7494 (SambaCry) | 9.8 | 🔴 No explotable (4.5.10 = fix) | `F04-005` |
| B2 | M3 | CVE-2011-2523 (vsftpd) | 9.8 | 🔴 Backdoor no presente (`:6200` cerrado) | manual |
| B3 | M3 | FTP anónimo + `credenciales.txt` | ~8.6 | 🟢 Validado | `F04-002` |
| B4 | M3 | NFS `no_root_squash` | ~8.1 | 🟢 Validado (archivo root) | `F04-006` |
| S1 | M4 | CVE-2017-0144 (EternalBlue) | 8.8 | 🔴 No explotable por IPC$/SMB1 | `F04-014` |
| S2 | M4 | CVE-2021-34527 (PrintNightmare) | 8.8 | 🟡 Check vulnerable; exploit sin sesión | `F04-016` |
| S3 | M4 | Administrator clave débil | ~8.8 | 🟢 Validado (`password_2026`, admin) | `F04-015` |
| S4 | M4 | AXFR abierto | ~5.3 | 🟢 Validado (zona completa) | `F04-012` |
| S5 | M4 | SMB signing off + LLMNR | ~7.5 | 🟢 Validado (signing disabled) | `F04-013` |
| C1 | M5 | CVE-2017-0144 en Win10 19045 | 8.8 | 🔴 No aplica (22H2) | `F02-001` |
| C2 | M5 | Clave reutilizada | ~8.8 | 🟢 Validado (SMB por túnel) | salida 13:08 UTC |
| C3 | M5 | RDP sin NLA + software viejo | Variable | 🟡 Puerto abierto; sesión no probada | `F02-001` |
| C4 | M5 | VNC sin clave | ~9.8 | 🟢 Validado (escritorio + `whoami`) | `F04-008`, `F04-011` |

**Leyenda:** 🟢 validado · 🟡 parcial · 🔴 no explotable/no aplica · ⚪ pendiente.

---

## 6.2 Hallazgos con evidencia completa

### W4 · Clave débil de WordPress

- **Descripción:** `usc.admin` / `Admin13.-` permite login administrativo.
- **Validación:** `302 Found` + `Set-Cookie: wordpress_logged_in` + `Location: /wp-admin/`.
- **Impacto:** control del CMS; posibilidad de subir plugin y ejecutar código.
- **Salto:** admin web + reutilización de clave → SSH/root en M1.
- **Remediación:** clave fuerte, 2FA, límite de intentos, no reutilizar en SSH.
- **Retest:** login con la clave vieja debe fallar.

### B3 · FTP anónimo con credenciales

- **Descripción:** `anonymous` lista `/backups` y descarga `credenciales.txt`.
- **Validación:** `curl ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt` → `admin M4/M5: Admin13.-`.
- **Impacto:** credenciales de M4/M5 y dumps de BD.
- **Salto:** M3 → M4/M5.
- **Remediación:** deshabilitar anónimo, cifrar backups, sacar secretos, permisos.
- **Retest:** `530 Login incorrect`.

### B4 · NFS `no_root_squash`

- **Descripción:** `/srv/storage/backups` exportado con `no_root_squash`.
- **Validación:** desde M1, montar y `touch` → `root root`.
- **Impacto:** escritura como root remoto; manipulación de backups.
- **Remediación:** `root_squash`, export restringido, firewall.
- **Retest:** escritura denegada o propietario `nobody`.

### D2 · Credenciales de base de datos

- **Descripción:** `wp-config.php`/`config.php` contienen `wp_pass123`.
- **Validación:** túnel SSH + `SHOW DATABASES` → `wordpress`; 12 tablas; Moodle 487.
- **Impacto:** lectura de datos de la app y de Moodle.
- **Remediación:** claves únicas, least privilege, rotación, no reutilizar.
- **Retest:** login denegado.

### M1-SSH · Clave reutilizada + sudo

- **Descripción:** `ubuntu` / `Admin13.-` y grupo `sudo`.
- **Validación:** `uid=1000(ubuntu)`; `sudo id` → `uid=0(root)`.
- **Impacto:** root en M1, pivote total.
- **Remediación:** clave única, `PermitRootLogin no`, sudo restringido, 2FA.
- **Retest:** SSH con la clave vieja falla; `sudo` no escala.

---

## 6.3 Limitaciones documentadas

| ID | Limitación | Qué se reporta |
|---|---|---|
| W1 | No se ejecutó PoC completo | Fingerprint + CVE; no se afirma RCE |
| W2 | PHP ZTS original; rebuild NTS/prefork en 8080 | Precondiciones cumplidas; el leak de heap del PoC no cerró en el time-box |
| W3 | CGI corregido (`ExecCGI` + `Scriptsock`) | RCE confirmado; traversal a `/etc/passwd` sigue 500 |
| D1 | `enable_strict_lua` bloquea `package` | Acceso sin auth; RCE no |
| B1 | Samba 4.5.10 es fix | No explotable |
| B2 | Tarball limpio; `:6200` cerrado | No explotable |
| C1 | Win10 21H2 no afectado | No aplica |
| M4/M5 | VM apagadas a las 16:44 UTC | Pendiente de encender |

---

## 6.4 Fichas completas

- [`hallazgos/m1-w1-w7.md`](./hallazgos/m1-w1-w7.md)
- [`hallazgos/w2-php2shell.md`](./hallazgos/w2-php2shell.md)
- [`hallazgos/m2-d1-d4.md`](./hallazgos/m2-d1-d4.md)
- [`hallazgos/m3-b1-b4.md`](./hallazgos/m3-b1-b4.md)
- [`hallazgos/m4-s1-s5.md`](./hallazgos/m4-s1-s5.md)
- [`hallazgos/m5-c1-c4.md`](./hallazgos/m5-c1-c4.md)
