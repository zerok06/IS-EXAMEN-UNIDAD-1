# 5. Inventario de vulnerabilidades

**Fecha de verificación NVD/CVE.org:** 2026-10-24
**Métrica:** se declara CVSS v3.1 salvo que se indique v4.0.
**Máquinas objetivo:** M1–M5. M6 es el auditor; R0 es transporte.

> Las debilidades de configuración no tienen CVE: se clasifican con **CWE**, se les asigna un **CVSS ambiental estimado** y se documentan con el mismo rigor.

---

## 5.1 Resumen por máquina

| Máquina | CVE reales | Configuración | Total |
|---|---|---|---|
| M1 Aplicación | W1, W2, W3 | W4, W5, W6, W7 | 7 |
| M2 Base de datos | D1 | D2, D3, D4 | 4 |
| M3 Respaldos | B1, B2 | B3, B4 | 4 |
| M4 Windows Server | S1, S2 | S3, S4, S5 | 5 |
| M5 Estación cliente | C1 | C2, C3, C4 | 4 |
| **Total** | **9** | **15** | **24** |

---

## 5.2 M1 · Aplicación (`10.10.10.11`)

| ID | CVE / CWE | Servicio y versión | CVSS | Severidad | Qué permite | Estado |
|---|---|---|---|---|---|---|
| W1 | **CVE-2026-63030** / CWE-436 | WordPress 7.0.1 | **9.8** `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` | Crítica · **KEV** | RCE pre-auth vía `/wp-json/batch/v1` + SQLi encadenada (CVE-2026-60137) | Por validar |
| W2 | **CVE-2026-109618** / CWE-416 | PHP 8.4.26 mod_php | **9.8** v3.1 / **9.2** v4.0 | Crítica | RCE pre-auth por corrupción OOM (`longjmp`) | Por validar |
| W2b | **CVE-2026-109619** / CWE-416 | PHP 8.4.26 mod_php | **8.1** v3.1 / **9.2** v4.0 | Alta / Crítica | RCE pre-auth por estado global obsoleto | Por validar |
| W3 | **CVE-2021-41773** / CWE-22 | Apache httpd 2.4.49 | **9.8** `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` | Crítica | Path traversal; lectura fuera del docroot y RCE si CGI está activo | Por validar |
| W4 | CONFIG / CWE-521 | `wp-admin` · `usc.admin` | ~8.8 ambiental | Alta | Clave débil → admin → subida de plugin → RCE | Por validar |
| W5 | CONFIG / CWE-200 | Apache `mod_status` | ~5.3 ambiental | Media | `server-status` expone workers y peticiones | Por validar |
| W6 | CONFIG / CWE-200 | `info.php` | ~5.3 ambiental | Media | `phpinfo()` público: versión, extensiones, rutas | Por validar |
| W7 | CONFIG / CWE-548 | `Options +Indexes` en uploads | ~5.3 ambiental | Media | Listado de archivos subidos | Por validar |

**Corrección documental:** la guía interna citaba W1 como 7.5 y W3 como 7.5; **NVD confirma 9.8 para ambos**. W2 debe declarar la métrica: 9.8 en v3.1 y 9.2 en v4.0; W2b es 8.1 en v3.1 y 9.2 en v4.0. No se deben mezclar.

---

## 5.3 M2 · Base de datos (`10.10.10.12`)

| ID | CVE / CWE | Servicio y versión | CVSS | Severidad | Qué permite | Estado |
|---|---|---|---|---|---|---|
| D1 | **CVE-2022-0543** / CWE-94 | Redis 6.2.6 | **10.0** `AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H` | Crítica | Escape del sandbox Lua → RCE como `redis` | Por validar (ver nota) |
| D2 | CONFIG / CWE-521 | MariaDB `wp_user` / `moodle_user` | ~8.1 ambiental | Alta | Credenciales débiles → volcado de `wordpress` y `moodle_db` | Por validar |
| D3 | CONFIG / CWE-284 | 3306 / 6379 / 161 | ~7.5 ambiental | Alta | Superficie expuesta a la LAN | Por validar |
| D4 | CONFIG / CWE-306 | net-snmp `public` / `private` | ~7.5 ambiental | Alta | Lectura y escritura SNMP sin autenticación | Por validar |

**Nota D1:** CVE-2022-0543 es un fallo de **empaquetado Debian/Ubuntu** (Lua enlazado dinámicamente + `package.loadlib`). El Redis del laboratorio está compilado de fuente; si el PoC Lua no devuelve `id`, se documenta la limitación y se sostiene el acceso con D2/D3 (Redis sin auth + volcado de BD). No se afirmará RCE sin evidencia.

---

## 5.4 M3 · Respaldos (`10.10.10.13`)

| ID | CVE / CWE | Servicio y versión | CVSS | Severidad | Qué permite | Estado |
|---|---|---|---|---|---|---|
| B1 | **CVE-2017-7494** / CWE-94 | Samba 4.5.10 | **9.8** `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` | Crítica | Subir librería a un share escribible → RCE root (SambaCry) | **No explotable tal cual** (ver nota) |
| B2 | **CVE-2011-2523** / CWE-78 | vsftpd 2.3.4 | **9.8** | Crítica | Backdoor `:)` → shell root en `:6200` | Por validar (ver nota) |
| B3 | CONFIG / CWE-306 + CWE-311 | FTP anónimo + backups en claro | ~8.6 ambiental | Alta | Descarga de `credenciales.txt` y dumps | Por validar |
| B4 | CONFIG / CWE-732 | NFS `no_root_squash` en `/srv/storage/backups` | ~8.1 ambiental | Alta | Escritura como root remoto | Por validar |

**Corrección B1:** NVD indica que CVE-2017-7494 afecta a versiones **anteriores a 4.6.4, 4.5.10 y 4.4.14**. Es decir, **Samba 4.5.10 es la versión que corrige SambaCry**. El laboratorio tiene 4.5.10, por lo que **B1 no es explotable tal como está**. Para mantener B1 hay que compilar **4.5.9** o **4.4.13**; si no, se retira y M3 se sostiene con B2/B3/B4.

**Nota B2:** el backdoor de vsftpd 2.3.4 solo existe en el tarball distribuido entre el **30-jun-2011 y el 03-jul-2011**. Si el binario se compiló del tarball oficial limpio, el banner dice 2.3.4 pero el puerto `6200` no abre. Se valida con `nc 10.10.10.13 6200`; si no responde, se documenta y se usa B3/B4.

---

## 5.5 M4 · Windows Server heredado (`10.10.10.14`)

| ID | CVE / CWE | Servicio y versión | CVSS | Severidad | Qué permite | Estado |
|---|---|---|---|---|---|---|
| S1 | **CVE-2017-0144** / SMBv1 | WS2016 sin MS17-010 | **8.8** `AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H` | Alta | EternalBlue → RCE como SYSTEM | Por validar |
| S2 | **CVE-2021-34527** / Spooler | WS2016 sin parche | **8.8** | Alta | PrintNightmare → elevación a SYSTEM | Por validar |
| S3 | CONFIG / CWE-521 + CWE-269 | Administrator con clave débil | ~8.8 ambiental | Alta | Acceso administrativo y privesc | Por validar |
| S4 | CONFIG / CWE-200 | DNS AXFR abierto | ~5.3 ambiental | Media | Transferencia completa de la zona `uni.lab` | Por validar |
| S5 | CONFIG / CWE-319 | SMB signing off + LLMNR/NBT-NS | ~7.5 ambiental | Alta | Captura/relay de hash NetNTLM | Por validar |

**Nota:** M4 es un servidor **standalone** (DNS sin AD DS). Por eso **Zerologon (CVE-2020-1472)** y **MS14-068** no aplican: requieren controlador de dominio. El privesc obligatorio se cubre con **PrintNightmare (S2)** y, como alternativa, EternalBlue (S1) + S3.

---

## 5.6 M5 · Estación cliente (`10.10.10.15`)

| ID | CVE / CWE | Servicio y versión | CVSS | Severidad | Qué permite | Estado |
|---|---|---|---|---|---|---|
| C1 | **CVE-2017-0144** / SMBv1 | Windows 10 **21H2** | **8.8** | Alta | EternalBlue → SYSTEM | **No aplica a 21H2** (ver nota) |
| C2 | CONFIG / CWE-521 | Clave reutilizada de M4 | ~8.8 ambiental | Alta | Acceso admin local / SMB / RDP | Por validar |
| C3 | CONFIG / CWE-1104 + CWE-287 | Software viejo + RDP sin NLA | Variable | Alta | Acceso gráfico y superficie obsoleta | Por validar |
| C4 | CONFIG / CWE-306 | TightVNC 2.8.90 · auth None · `:5900` | ~9.8 ambiental | Crítica | Control gráfico total sin credenciales | Por validar |

**Corrección C1:** CVE-2017-0144 afecta a Windows 10 Gold/1511/1607 y Windows Server 2016; **Windows 10 21H2 no es vulnerable** aunque SMBv1 esté activado. Para demostrar EternalBlue en M5 habría que usar una build antigua (1607) o cambiar de vulnerabilidad. La cadena realista a M5 es **C2 (clave reutilizada) + C4 (VNC)**.

---

## 5.7 Clasificación y criterios

| Campo | Criterio |
|---|---|
| **Criticidad** | CVSS v3.1/v4.0 verificado en NVD; para configuración, CVSS ambiental estimado y justificado |
| **Tipo** | `CVE` si existe identificador; `CONFIG` si es debilidad de configuración |
| **CWE** | Clasificación de la debilidad (CWE-22, 78, 94, 200, 284, 306, 416, 436, 521, 548, 732, etc.) |
| **Estado** | `Por validar` → `Validada` / `No explotable` / `Parchada` |
| **Evidencia** | `EV-...` + `LOG-...` + hash |
| **Referencia** | URL NVD + URL CVE.org + fecha de consulta |

---

## 5.8 Fuentes oficiales consultadas

| CVE | NVD | CVE.org |
|---|---|---|
| CVE-2026-63030 | https://nvd.nist.gov/vuln/detail/CVE-2026-63030 | https://cve.org/CVERecord?id=CVE-2026-63030 |
| CVE-2026-109618 | https://nvd.nist.gov/vuln/detail/CVE-2026-109618 | https://cve.org/CVERecord?id=CVE-2026-109618 |
| CVE-2026-109619 | https://nvd.nist.gov/vuln/detail/CVE-2026-109619 | https://cve.org/CVERecord?id=CVE-2026-109619 |
| CVE-2021-41773 | https://nvd.nist.gov/vuln/detail/CVE-2021-41773 | https://cve.org/CVERecord?id=CVE-2021-41773 |
| CVE-2022-0543 | https://nvd.nist.gov/vuln/detail/CVE-2022-0543 | https://cve.org/CVERecord?id=CVE-2022-0543 |
| CVE-2017-7494 | https://nvd.nist.gov/vuln/detail/CVE-2017-7494 | https://cve.org/CVERecord?id=CVE-2017-7494 |
| CVE-2011-2523 | https://nvd.nist.gov/vuln/detail/CVE-2011-2523 | https://cve.org/CVERecord?id=CVE-2011-2523 |
| CVE-2017-0144 | https://nvd.nist.gov/vuln/detail/CVE-2017-0144 | https://cve.org/CVERecord?id=CVE-2017-0144 |
| CVE-2021-34527 | https://nvd.nist.gov/vuln/detail/CVE-2021-34527 | https://cve.org/CVERecord?id=CVE-2021-34527 |

> **KEV:** CVE-2026-63030 está en el catálogo CISA KEV desde 2026-07-21. Se recomienda comprobar también CVE-2017-0144 y CVE-2011-2523 en la fecha de entrega.
