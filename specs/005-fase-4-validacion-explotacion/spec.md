# Spec 005 · Fase 4 · Validación, explotación y cadena

## Metadata

| Campo | Valor |
|---|---|
| ID | `005` |
| Fase guía | 4 |
| Nombre | Validación de vulnerabilidades, explotación y alcance total |
| Estado | `lista` |
| Dueño | Auditor M6 + dueños de VM |
| Dependencias | `004` |
| Specs relacionadas | `006`, `007` |
| Fuente | Guía §8 Fase 4 y §15; `docs/PLAN-MAESTRO.md` §4 |

## 1. Propósito

Demostrar que las vulnerabilidades son **explotables**, obtener acceso real, encadenar de M1 a M5 y medir el impacto, con evidencia fechada. Esta fase es la bisagra: lo que aquí se demuestre es lo que se parchea en Fase 5 y se retestea en Fase 6.

## 2. Alcance

**Incluye:** W1/W2/W3/W4/SSH en M1, pivote, D1–D4 en M2, B1–B5 en M3, S1–S5 en M4, C1–C4 en M5, impacto y evidencia.

**No incluye:** remediación, cambios de versión, parches.

## 3. Actores y precondiciones

- Actores: M6, dueños de VM, coordinador.
- Precondiciones: `estado-inicial-vulnerable`, Fase 3 cerrada, PoCs descargados antes de aislar.

## 3.1 Specs por vulnerabilidad

El flujo concreto de cada vulnerabilidad está en [`vulns/`](./vulns/). Cada archivo tiene ficha, snapshot, comandos, evidencia, impacto, fallback, remediación y retest.

| ID | Spec |
|---|---|
| W1 | [`vulns/W1-wp2shell.md`](./vulns/W1-wp2shell.md) |
| W2 | [`vulns/W2-php2shell.md`](./vulns/W2-php2shell.md) |
| W3 | [`vulns/W3-apache-41773.md`](./vulns/W3-apache-41773.md) |
| W4 | [`vulns/W4-wp-admin.md`](./vulns/W4-wp-admin.md) |
| W5–W7 | [`vulns/W5-W7-config.md`](./vulns/W5-W7-config.md) |
| M1-SSH | [`vulns/M1-SSH.md`](./vulns/M1-SSH.md) |
| D1 | [`vulns/D1-redis.md`](./vulns/D1-redis.md) |
| D2–D4 | [`vulns/D2-D4-config.md`](./vulns/D2-D4-config.md) |
| B1 | [`vulns/B1-samba.md`](./vulns/B1-samba.md) |
| B2 | [`vulns/B2-vsftpd.md`](./vulns/B2-vsftpd.md) |
| B3–B5 | [`vulns/B3-B5-config.md`](./vulns/B3-B5-config.md) |
| S1 | [`vulns/S1-eternalblue.md`](./vulns/S1-eternalblue.md) |
| S2 | [`vulns/S2-printnightmare.md`](./vulns/S2-printnightmare.md) |
| S3–S5 | [`vulns/S3-S5-config.md`](./vulns/S3-S5-config.md) |
| C1 | [`vulns/C1-eternalblue.md`](./vulns/C1-eternalblue.md) |
| C2–C3 | [`vulns/C2-C3-config.md`](./vulns/C2-C3-config.md) |
| C4 | [`vulns/C4-vnc.md`](./vulns/C4-vnc.md) |

La revalidación de versiones está en [`docs/VALIDACION-VULNERABILIDADES.md`](../../docs/VALIDACION-VULNERABILIDADES.md).

## 3.2 Version gate de explotación

| ID | Versión | PoC | Spec |
|---|---|---|---|
| W1 | 7.0.1 | wp2shell | [`vulns/W1-wp2shell.md`](./vulns/W1-wp2shell.md) |
| W2 | 8.4.26 NTS/prefork | php2shell | [`vulns/W2-php2shell.md`](./vulns/W2-php2shell.md) |
| W3 | 2.4.49 + CGI | traversal/RCE | [`vulns/W3-apache-41773.md`](./vulns/W3-apache-41773.md) |
| D1 | 6.2.6 fuente | no reproducible | [`vulns/D1-redis.md`](./vulns/D1-redis.md) |
| B1 | 4.5.9 | SambaCry | [`vulns/B1-samba.md`](./vulns/B1-samba.md) |
| B2 | 2.3.4 limpio | no reproducible | [`vulns/B2-vsftpd.md`](./vulns/B2-vsftpd.md) |
| S2 | WS2016 + `soporte` | PrintNightmare LPE | [`vulns/S2-printnightmare.md`](./vulns/S2-printnightmare.md) |
| C4 | 2.8.90 auth None | VNC | [`vulns/C4-vnc.md`](./vulns/C4-vnc.md) |

## 4. Requisitos EARS

### Reglas de evidencia

- **REQ-005-01 (Evento).** CUANDO se ejecute un PoC, el laboratorio DEBE tener un snapshot `previo-a-<ID>`.
  - Verificación: `Snapshot Manager`.
- **REQ-005-02 (Ubicuo).** Cada éxito DEBE demostrarse con `id`, `whoami`, archivo de prueba o captura verificable.
  - Verificación: salida real en el log.
- **REQ-005-03 (No deseado).** SI un PoC falla, ENTONCES el laboratorio DEBE documentar la limitación, el fallback y el resultado real.
  - Verificación: ficha del hallazgo + log.
- **REQ-005-04 (Ubicuo).** Cada evidencia DEBE tener captura fechada, log y SHA256.
  - Verificación: `EV-005-*`, `LOG-005-*`, `hashes.txt`.

### M1 · Aplicación

- **REQ-005-05 (Evento).** CUANDO se valide M1, el laboratorio DEBE intentar **W1 wp2shell** como vector principal.
  - Verificación: `python3 poc.py http://10.10.10.11 --check`; admin creado; plugin; `id`.
- **REQ-005-06 (Evento).** CUANDO W1 no esté disponible, el laboratorio DEBE usar **W4** (login débil + plugin) como respaldo.
  - Verificación: 302 + cookie; plugin; `id`.
- **REQ-005-07 (Evento).** CUANDO W3 tenga CGI operativo, el laboratorio DEBE demostrar traversal y RCE.
  - Verificación: `/etc/passwd`; `POST /bin/sh`; `uid=`.
- **REQ-005-08 (Estado).** MIENTRAS W2 esté en time-box, el laboratorio DEBE intentar el PoC con prefork/NTS/offsets y, si falla, documentar la limitación.
  - Verificación: `p1.txt` o log de fallo.
- **REQ-005-09 (Ubicuo).** M1 DEBE quedar con acceso root o `www-data` y con credenciales de `wp-config.php` para el pivote.
  - Verificación: `sudo id`; `wp-config.php`.

### Pivote

- **REQ-005-10 (Evento).** CUANDO M1 esté comprometido, el laboratorio DEBE levantar un pivote (SSH `-L`, ligolo o proxychains) y verificar M2–M5.
  - Verificación: `nmap` vía pivote; captura.

### M2 · Base de datos

- **REQ-005-11 (Evento).** CUANDO se valide M2, el laboratorio DEBE demostrar Redis sin auth, dump de MariaDB y SNMP.
  - Verificación: `PING`; `SHOW DATABASES`; `snmpwalk`.
- **REQ-005-12 (Opcional).** DONDE D1 use el paquete distro, el laboratorio DEBE intentar el PoC Lua y capturar `id`.
  - Verificación: `redis-cli EVAL`; `id`.

### M3 · Respaldos

- **REQ-005-13 (Evento).** CUANDO se valide M3, el laboratorio DEBE demostrar FTP anónimo, NFS `no_root_squash` y, si aplica, Samba 4.5.9.
  - Verificación: `credenciales.txt`; `touch` root; shell Samba.
- **REQ-005-14 (Opcional).** DONDE B2 use el binario troyanizado, el laboratorio DEBE demostrar `nc 6200`.
  - Verificación: shell root.

### M4 · Windows

- **REQ-005-15 (Evento).** CUANDO se valide M4, el laboratorio DEBE demostrar S3, S4 y S5.
  - Verificación: `nxc smb`; `dig axfr`; `smb-security-mode`.
- **REQ-005-16 (Evento).** CUANDO se valide S2, el laboratorio DEBE partir de una sesión **limitada** (`soporte`) y obtener SYSTEM con PrintNightmare local.
  - Verificación: `whoami` previo `srvold\soporte`; posterior `nt authority\system`.
- **REQ-005-17 (No deseado).** SI el único SYSTEM se obtiene con credenciales de admin, ENTONCES el laboratorio NO DEBE declararlo privesc.
  - Verificación: revisión del comando y del usuario inicial.
- **REQ-005-18 (Opcional).** DONDE S1 sea explotable, el laboratorio DEBE demostrar EternalBlue; si no, documentar “no aplica”.
  - Verificación: `smb-vuln-ms17-010`; MSF.

### M5 · Cliente

- **REQ-005-19 (Evento).** CUANDO se valide M5, el laboratorio DEBE demostrar C2, C3 y C4.
  - Verificación: `nxc smb`; `xfreerdp`; `vncviewer`.
- **REQ-005-20 (No deseado).** SI M5 es 19045, ENTONCES C1 NO DEBE declararse explotado.
  - Verificación: `winver`; ficha NVD.

### Impacto y alcance

- **REQ-005-21 (Evento).** CUANDO se comprometa una máquina, el laboratorio DEBE dejar un marcador inocuo y capturarlo.
  - Verificación: `PWNED-*`; captura.
- **REQ-005-22 (Ubicuo).** El laboratorio DEBE completar una tabla de alcance 5/5 con prueba de compromiso por máquina.
  - Verificación: tabla §9 del playbook.
- **REQ-005-23 (No deseado).** SI se usa una técnica destructiva, ENTONCES el laboratorio DEBE detenerse y restaurar el snapshot.
  - Verificación: revisión ética.

## 5. Criterios de aceptación

- [ ] W1 o W4 con `id` real.
- [ ] W3 con traversal/RCE o limitación documentada.
- [ ] W2 intentado con time-box y resultado real.
- [ ] M1 con root/pivote.
- [ ] M2 con dump/Redis/SNMP.
- [ ] M3 con B3/B4 y B1/B5.
- [ ] M4 con S3/S4/S5 y S2 desde `soporte` → SYSTEM.
- [ ] M5 con C2/C3/C4.
- [ ] 5/5 con marcador.
- [ ] Spec por vulnerabilidad aplicada (W1…C4).
- [ ] Evidencias y hashes.
- [ ] Version gate: PoC ejecutado sobre la versión vulnerable documentada.

## 6. Trazabilidad

| REQ | Evidencia | Tarea |
|---|---|---|
| REQ-005-05–09 | `EV-005-M1-*` | T-005-01–05 |
| REQ-005-10 | `EV-005-PIVOTE` | T-005-06 |
| REQ-005-11–12 | `EV-005-M2-*` | T-005-07–08 |
| REQ-005-13–14 | `EV-005-M3-*` | T-005-09–11 |
| REQ-005-15–18 | `EV-005-M4-*` | T-005-12–15 |
| REQ-005-19–20 | `EV-005-M5-*` | T-005-16–18 |
| REQ-005-21–23 | `EV-005-IMPACTO` | T-005-19–20 |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| W2 no reproduce | Time-box; W1/W4/W3 de respaldo |
| PrintNightmare falla | Módulo local + `Invoke-Nightmare`; otro LPE |
| M4 inestable | Snapshot y reinicio; ejecutar desde M1 |
| Samba 4.5.9 no compila | B5 SSH débil |
| El PoC rompe el servicio | Restaurar `previo-a-<ID>` |
| Se confunde admin→SYSTEM con privesc | Revisar usuario inicial |

## 8. Fuera de alcance

- Remediar.
- Cambiar versiones.
- Parchear.
