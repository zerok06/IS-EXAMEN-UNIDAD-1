# Spec 003 · Fase 2 · Implementación de vulnerabilidades

## Metadata

| Campo | Valor |
|---|---|
| ID | `003` |
| Fase guía | 2 |
| Nombre | Implementación de vulnerabilidades CVE y configuraciones |
| Estado | `lista` |
| Dueño | Cada dueño de VM |
| Dependencias | `000`, `002` |
| Specs relacionadas | `004`, `005` |
| Fuente | Guía §8 Fase 2 y §10; `docs/PLAN-MAESTRO.md` §4 |

## 1. Propósito

Dejar **≥3 vulnerabilidades presentes y verificables por máquina**, con versión/configuración, CVE/CWE, CVSS y evidencia, sin explotarlas todavía.

## 2. Alcance

**Incluye:** versiones fijadas, configuraciones inseguras, cuentas débiles, servicios expuestos, evidencia de presencia.

**No incluye:** explotación, escaneo ofensivo, remediación.

## 3. Actores y precondiciones

- Actores: dueños M1–M5, coordinador, auditor M6.
- Precondiciones: Fase 1 cerrada; `01-rol-listo`; versiones registradas.

## 3.1 Version gate

| ID | Instalada | Corrige | Artefacto |
|---|---|---|---|
| W1 | WordPress 7.0.1 | 6.9.5 / 7.0.2 | `vulnerable/wordpress-7.0.1.zip` |
| W2 | PHP 8.4.26 | 8.4.27 | `vulnerable/php-8.4.26.tar.gz` |
| W3 | Apache 2.4.49 | 2.4.50 / 2.4.51+ | `vulnerable/httpd-2.4.49.tar.gz` |
| D1 | Redis 6.2.6 fuente | 6.2.7 | `vulnerable/redis-6.2.6.tar.gz` (no reproduce CVE) |
| B1 | Samba 4.5.9 | 4.5.10 | `vulnerable/samba-4.5.9.tar.gz` |
| B2 | vsftpd 2.3.4 limpio | 2.3.4 limpio / 3.x | `vulnerable/vsftpd-2.3.4.tar.gz` (no backdoor) |
| C4 | TightVNC 2.8.90 | password | `vulnerable/tightvnc-2.8.90...msi` |

Regla: si la instalada es igual o mayor que el fix, no se cuenta como vulnerabilidad.

## 4. Requisitos EARS

### Generales

- **REQ-003-01 (Ubicuo).** Cada máquina objetivo DEBE tener al menos **3 vulnerabilidades presentes y verificables**.
  - Verificación: tabla por máquina con IDs y evidencia.
- **REQ-003-02 (Ubicuo).** Cada vulnerabilidad DEBE declarar CVE/CWE, servicio, versión, CVSS, métrica y fuente NVD/CVE.org.
  - Verificación: `docs/version-matrix.md` y ficha del hallazgo.
- **REQ-003-03 (No deseado).** SI la versión instalada es la que corrige el CVE, ENTONCES el laboratorio DEBE bajarla, reemplazarla o retirar el hallazgo.
  - Verificación: ficha con versión afectada vs corregida.
- **REQ-003-04 (Evento).** CUANDO se termine de implantar, el laboratorio DEBE tomar `estado-inicial-vulnerable`.
  - Verificación: `Snapshot Manager`.

### M1 · Aplicación

- **REQ-003-05 (Ubicuo).** M1 DEBE ejecutar WordPress **7.0.1**, PHP **8.4.26** y Apache **2.4.49**.
  - Verificación: `wp core version`; `php -v`; `httpd -v`.
- **REQ-003-06 (Estado).** MIENTRAS se use PHP 8.4.26 para W2, el laboratorio DEBE usar **mod_php con prefork**, `session.upload_progress.enabled=On`, `display_errors=On` y `memory_limit=8M` (o el valor que el PoC requiera).
  - Verificación: `httpd -V | grep MPM`; `php -i`.
- **REQ-003-07 (Estado).** MIENTRAS se use Apache 2.4.49 para W3, el laboratorio DEBE tener **CGI operativo** (`mod_cgi`/`mod_cgid`, `ScriptAlias`, `+ExecCGI`).
  - Verificación: `curl /cgi-bin/` responde 200/403, no 503.
- **REQ-003-08 (Ubicuo).** M1 DEBE tener W4 (`usc.admin`/`Admin13.-`), W5 (`server-status` 200), W6 (`info.php` 200) y W7 (`uploads` Index of).
  - Verificación: login 302 + cookie; `curl` a las tres rutas.

### M2 · Base de datos

- **REQ-003-09 (Ubicuo).** M2 DEBE tener Redis **6.2.6 sin `requirepass`** y MariaDB con `wp_user`/`moodle_user` débiles.
  - Verificación: `redis-cli PING`; `mysql` con `wp_pass123`.
- **REQ-003-10 (Opcional).** DONDE se quiera demostrar CVE-2022-0543, M2 DEBE usar el **paquete Debian/Ubuntu** de Redis, no el build de fuente.
  - Verificación: `dpkg -l redis-server`; `redis-server --version`.
- **REQ-003-11 (Ubicuo).** M2 DEBE tener 6379/161 abiertos a la LAN y SNMP `public`/`private`.
  - Verificación: `nmap`; `snmpwalk`.

### M3 · Respaldos

- **REQ-003-12 (Ubicuo).** M3 DEBE usar **Samba 4.5.9** (vulnerable), no 4.5.10 (fix), para B1.
  - Verificación: `smbd --version`.
- **REQ-003-13 (Ubicuo).** M3 DEBE tener FTP anónimo con `credenciales.txt` y NFS `no_root_squash`.
  - Verificación: `curl ftp://anonymous...`; `showmount -e`.
- **REQ-003-14 (Opcional).** DONDE B1/B2 no sean reales, M3 DEBE agregar una tercera vulnerabilidad (SSH débil `rony123`/`rony123`).
  - Verificación: `sshpass -p rony123 ssh rony123@10.10.10.13 id`.

### M4 · Windows

- **REQ-003-15 (Ubicuo).** M4 DEBE tener S3 (admin débil), S4 (AXFR abierto), S5 (signing off + LLMNR/NBT-NS) y S2 (Spooler).
  - Verificación: `nxc smb`; `dig axfr`; `smb-security-mode`; `Get-Service Spooler`.
- **REQ-003-16 (Ubicuo).** M4 DEBE tener un usuario limitado `soporte` con clave débil y acceso WinRM, para el privesc de Fase 4.
  - Verificación: `nxc winrm ... -u soporte -p 'Soporte123!' -x whoami` → `srvold\soporte`.
- **REQ-003-17 (Opcional).** DONDE S1 se quiera demostrar, M4 DEBE tener SMBv1 activo y build sin MS17-010.
  - Verificación: `Get-WindowsOptionalFeature SMB1Protocol`; `nmap --script smb-vuln-ms17-010`.

### M5 · Cliente

- **REQ-003-18 (Ubicuo).** M5 DEBE tener C2 (clave reutilizada), C3 (RDP sin NLA) y C4 (VNC sin clave).
  - Verificación: `nxc smb`; `xfreerdp`; `vncviewer`.
- **REQ-003-19 (No deseado).** SI M5 es Windows 10 19045, ENTONCES C1 (EternalBlue) NO DEBE contarse como vulnerabilidad.
  - Verificación: `winver`; ficha NVD.
- **REQ-003-20 (Opcional).** DONDE C1 no aplique y falte una tercera, M5 DEBE agregar SMB signing off/LLMNR o una cuenta débil adicional.
  - Verificación: `nmap --script smb-security-mode`; `nxc smb`.

## 5. Criterios de aceptación

- [ ] Artefactos vulnerables instalados desde `artifacts/vulnerable/`.
- [ ] M1–M5 con ≥3 vulnerabilidades presentes.
- [ ] Cada una con CVE/CWE, versión, CVSS y NVD.
- [ ] W2 con prefork/upload_progress; W3 con CGI.
- [ ] B1 con Samba 4.5.9 o B5 SSH.
- [ ] M4 con `soporte` y S2.
- [ ] C1 no contado si 19045.
- [ ] `estado-inicial-vulnerable` tomado.
- [ ] Evidencia de presencia por hallazgo.
- [ ] Version gate: instalada dentro del rango vulnerable y menor que el fix.

## 6. Trazabilidad

| REQ | Test/evidencia | Tarea |
|---|---|---|
| REQ-003-01/02 | Inventario + `docs/version-matrix.md` | T-003-01 |
| REQ-003-05–08 | `EV-003-M1-*` | T-003-02–05 |
| REQ-003-09–11 | `EV-003-M2-*` | T-003-06–08 |
| REQ-003-12–14 | `EV-003-M3-*` | T-003-09–11 |
| REQ-003-15–17 | `EV-003-M4-*` | T-003-12–14 |
| REQ-003-18–20 | `EV-003-M5-*` | T-003-15–17 |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| W2 no funciona con ZTS/event | Recompilar NTS y cambiar a prefork |
| W3 sigue en 503 | Revisar `mod_cgi`, `ScriptAlias` y `+ExecCGI` |
| Redis de fuente no vulnerable a D1 | Usar paquete distro o documentar |
| Samba 4.5.9 no compila | Usar SSH débil como B5 |
| M4 inestable | Snapshot y reinicio; documentar |
| C1 no aplica | Retirar y sostener M5 con C2/C3/C4 |

## 8. Fuera de alcance

- Explotar.
- Escanear con herramientas ofensivas.
- Remediar.
