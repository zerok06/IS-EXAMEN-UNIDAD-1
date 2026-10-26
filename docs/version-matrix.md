# Matriz de versiones · vulnerable vs. corregida

> Fuente primaria: **NVD** y **CVE.org**. Fecha de consulta: **2026-10-26**. Cada fila declara la métrica CVSS. No se mezclan v3.1 y v4.0.
>
> **Version gate:** antes de avanzar de fase, completar [`../templates/version-gate.md`](../templates/version-gate.md). Si la versión instalada es igual o mayor que la que corrige, el CVE no se cuenta.

## 1. CVE del escenario

| ID | Producto instalado | Rango vulnerable | Versión que corrige | CVSS | ¿Explotable hoy? | NVD |
|---|---|---|---|---|---|---|
| **W1** | WordPress **7.0.1** | 6.9.0–6.9.4 · 7.0.0–7.0.1 | **6.9.5 / 7.0.2** | **9.8** v3.1 | **Sí** con PoC público; falta ejecutarlo | [CVE-2026-63030](https://nvd.nist.gov/vuln/detail/CVE-2026-63030) |
| **W2** | PHP **8.4.26** | 8.4.0–8.4.26 · 8.3.0–8.3.35 · 8.2.0–8.2.34 · 8.5.0–8.5.11 | **8.4.27 / 8.3.36 / 8.2.35 / 8.5.12** | 9.8 v3.1 / 9.2 v4.0 (109618); 8.1 v3.1 / 9.2 v4.0 (109619) | **Con condiciones**: prefork, NTS, offsets | [CVE-2026-109618](https://nvd.nist.gov/vuln/detail/CVE-2026-109618) · [CVE-2026-109619](https://nvd.nist.gov/vuln/detail/CVE-2026-109619) |
| **W3** | Apache httpd **2.4.49** | exactamente 2.4.49 (CVE-2021-41773); 2.4.50 (CVE-2021-42013) | **2.4.50** (41773) · **2.4.51+** (42013) | **9.8** v3.1 | **Sí**, si se corrige CGI; hoy 503 | [CVE-2021-41773](https://nvd.nist.gov/vuln/detail/CVE-2021-41773) · [CVE-2021-42013](https://nvd.nist.gov/vuln/detail/CVE-2021-42013) |
| **D1** | Redis **6.2.6** (compilado de fuente) | paquete Debian/Ubuntu 5.0–5.0.14 · 6.0–6.0.16 · 6.2–6.2.6 | **5.0.15 / 6.0.17 / 6.2.7** | **10.0** v3.1 | **No con build de fuente**; sí con paquete distro | [CVE-2022-0543](https://nvd.nist.gov/vuln/detail/CVE-2022-0543) |
| **B1** | Samba **4.5.10** | 3.5.0–4.6.3 · 4.5.0–4.5.9 · 4.4.0–4.4.13 | **4.6.4 / 4.5.10 / 4.4.14** | **9.8** v3.1 | **No: 4.5.10 es el fix**. Bajar a 4.5.9 | [CVE-2017-7494](https://nvd.nist.gov/vuln/detail/CVE-2017-7494) |
| **B2** | vsftpd **2.3.4** limpio | solo el tarball troyanizado del 2011-06-30 al 2011-07-03 | **2.3.4 limpio / 3.x** | **9.8** v3.1 | **No: backdoor ausente**. Usar binario troyanizado o retirar | [CVE-2011-2523](https://nvd.nist.gov/vuln/detail/CVE-2011-2523) |
| **S1** | WS2016 build **14393** | WS2016 sin MS17-010; Win10 1507/1511/1607 | **MS17-010** | **8.8** v3.1 | **Condicional**: SMB1 activo y build sin parche | [CVE-2017-0144](https://nvd.nist.gov/vuln/detail/CVE-2017-0144) |
| **S2** | WS2016 Spooler | builds bajo umbral con Spooler activo | **KB de PrintNightmare / Spooler off** | **8.8** v3.1 | **Check sí**; falta LPE real desde acceso limitado | [CVE-2021-34527](https://nvd.nist.gov/vuln/detail/CVE-2021-34527) |
| **C1** | Win10 **19045** | solo Win10 1507/1511/1607 | **MS17-010** | **8.8** v3.1 | **No aplica**: 19045 no es vulnerable | [CVE-2017-0144](https://nvd.nist.gov/vuln/detail/CVE-2017-0144) |
| **C4** | TightVNC **2.8.90** | configuración: auth None | password + localhost + firewall / desinstalar | ~9.8 ambiental | **Sí**, ya validado | Sin CVE (CWE-306) |

## 2. Configuraciones (sin CVE)

| ID | Debilidad | CWE | Explotación | Corrección | Retest |
|---|---|---|---|---|---|
| W4 | `usc.admin` / `Admin13.-` | CWE-521 | Login admin → plugin → RCE | Clave fuerte + 2FA + límite | Login viejo falla |
| M1-SSH | Clave reutilizada + sudo | CWE-521 + CWE-269 | `ssh` + `sudo id` → root | Clave única, `PermitRootLogin no`, sudo restringido | SSH viejo falla |
| W5 | `server-status` expuesto | CWE-200 | `curl /server-status` | `Require ip 127.0.0.1` o desactivar | 403 |
| W6 | `info.php` público | CWE-200 | `curl /info.php` | Borrar el archivo | 404 |
| W7 | `+Indexes` en uploads | CWE-548 | Listar/descargar | `Options -Indexes` | 403 |
| D2 | Claves DB débiles | CWE-521 | Dump de `wordpress` y `moodle_db` | Claves únicas + least privilege | Login viejo denegado |
| D3 | 3306/6379/161 expuestos | CWE-284 | `nmap` desde pivote | UFW solo M1 | `filtered` |
| D4 | SNMP `public`/`private` | CWE-306 | `snmpwalk` / `snmpset` | SNMPv3/ACL | `public` falla |
| B3 | FTP anónimo + backups en claro | CWE-306 + CWE-311 | Descargar `credenciales.txt` | Anónimo off + cifrado | `530` |
| B4 | NFS `no_root_squash` | CWE-732 | Montar y `touch` como root | `root_squash` | Denegado |
| S3 | Admin con clave débil | CWE-521 + CWE-269 | `nxc smb` → `Pwn3d!` | Clave larga/LAPS | `nxc` denegado |
| S4 | AXFR abierto | CWE-200 | `dig axfr` | Solo NS autorizados | `REFUSED` |
| S5 | SMB signing off + LLMNR | CWE-319 | Responder / relay | Signing on + LLMNR/NBT-NS off | Signing required |
| C2 | Clave reutilizada M4/M5 | CWE-521 | `nxc smb` | Clave única/LAPS | `nxc` denegado |
| C3 | RDP sin NLA | CWE-287 | `xfreerdp` | NLA on | NLA requerido |

## 3. Comandos de verificación

```bash
# W1
curl -s http://10.10.10.11/wp-json/ | grep -o 'batch[^"]*'
wp core version

# W2
curl -sI http://10.10.10.11 | grep -i x-powered-by
php -v

# W3
curl -s -o /dev/null -w '%{http_code}\n' --path-as-is \
  'http://10.10.10.11/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd'

# D1
redis-cli -h 10.10.10.12 PING
redis-cli -h 10.10.10.12 INFO server | grep redis_version

# B1
smbd --version
smbclient -L //10.10.10.13 -N

# B2
nc -zv 10.10.10.13 6200
# banner: 220 (vsFTPd 2.3.4)

# S1 / C1
nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.14
nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.15

# S2
# PowerShell en M4: Get-Service Spooler
# MSF: use exploit/windows/dcerpc/cve_2021_1675_printnightmare; check

# C4
nmap -sT --script vnc-info -p 5900 10.10.10.15
vncviewer 10.10.10.15
```

## 4. Cómo citar en el informe

Cada fila debe tener:

1. **CVE/CWE** y URL de NVD/CVE.org con fecha de consulta.
2. **Producto y versión instalada**.
3. **Rango afectado** y **versión que corrige**.
4. **CVSS y métrica** (v3.1 o v4.0).
5. **Evidencia de presencia** (fingerprint, banner, `--version`).
6. **Evidencia de explotación** o de no explotabilidad.
7. **Remediación aplicada** (versión/config final).
8. **Retest** con el mismo comando y captura antes/después.

## 5. Correcciones documentales

- W1 y W3 son **9.8**, no 7.5. La arquitectura v4.1 conserva 7.5; unificar con esta matriz.
- W2 debe declarar la métrica; no mezclar 9.8 v3.1 con 9.2 v4.0.
- B1: **Samba 4.5.10 es la versión corregida**; no es vulnerabilidad.
- B2: el tarball limpio **no tiene backdoor**; el CVE aplica al tarball troyanizado.
- C1: **Windows 10 19045 no es vulnerable** a EternalBlue.
- S1: verificar `Get-WindowsOptionalFeature SMB1Protocol` y `winver` antes de afirmar.
- D1: **CVE-2022-0543 es específico del empaquetado Debian/Ubuntu**; el build de fuente no es vulnerable.
