# Spec 002 · Fase 1 · Montaje del entorno

## Metadata

| Campo | Valor |
|---|---|
| ID | `002` |
| Fase guía | 1 |
| Nombre | Montaje de las 6 VM, servicios y dependencias |
| Estado | `lista` |
| Dueño | Cada dueño de VM + coordinador |
| Dependencias | `000`, `001` |
| Specs relacionadas | `003`, `004` |
| Fuente | Guía §8 Fase 1; `docs/PLAN-MAESTRO.md` §4 |

## 1. Propósito

Levantar los servicios de cada rol y demostrar que el escenario es **coherente**: M1 usa la base de M2, M1 monta el storage de M3, M2 respalda en M3, M4 resuelve DNS y M5 usa la aplicación.

## 2. Alcance

**Incluye:** servicios por rol, dependencias, versiones, arranque automático, verificación y evidencia.

**No incluye:** vulnerabilidades intencionales (Fase 2), escaneo ofensivo, explotación.

## 3. Actores y precondiciones

- Actores: dueños M1–M5, auditor M6, coordinador.
- Precondiciones: Fase 0 cerrada; snapshots `00-base`; red verificada.

## 3.1 Version gate

| VM | Servicio | Versión esperada |
|---|---|---|
| M1 | Apache / PHP / WordPress | 2.4.49 / 8.4.26 / 7.0.1 |
| M2 | MariaDB / Redis | 10.11.19 / 6.2.6 |
| M3 | Samba / vsftpd | 4.5.9 (vulnerable) / 2.3.4 |
| M4 | Windows Server | 2016 build 14393 |
| M5 | Windows 10 / TightVNC | 19045 / 2.8.90 |

## 4. Requisitos EARS

- **REQ-002-01 (Ubicuo).** M1 DEBE servir WordPress y Moodle por HTTP en `10.10.10.11:80`.
  - Verificación: `curl -sI http://10.10.10.11`; `curl -sI http://moodle.uni.lab`.
- **REQ-002-02 (Ubicuo).** M1 DEBE usar la base de datos de M2 para WordPress y Moodle.
  - Verificación: `wp db check`; `mysql` desde M1; `DB_OK`.
- **REQ-002-03 (Ubicuo).** M1 DEBE montar `wp-uploads` y `moodledata` desde M3 por NFS.
  - Verificación: `findmnt -t nfs`; subir un archivo y verlo en M3.
- **REQ-002-04 (Ubicuo).** M2 DEBE ejecutar MariaDB, Redis y SNMP en `10.10.10.12`.
  - Verificación: `mariadb --version`; `redis-cli PING`; `ss -uln :161`.
- **REQ-002-05 (Evento).** CUANDO el cron de M2 se ejecute, los respaldos DEBEN llegar a `/srv/storage/backups` en M3.
  - Verificación: `ls -lh /srv/storage/backups`; `rsync` exitoso.
- **REQ-002-06 (Ubicuo).** M3 DEBE exportar NFS, Samba y FTP, y contener `credenciales.txt`.
  - Verificación: `exportfs -v`; `smbclient -L`; `ftp` anónimo.
- **REQ-002-07 (Ubicuo).** M4 DEBE resolver la zona `uni.lab` y exponer SMB/Spooler/share `legacy`.
  - Verificación: `dig wp.uni.lab @10.10.10.14`; `nmap -p 445`; `Get-Service Spooler`.
- **REQ-002-08 (Ubicuo).** M5 DEBE acceder a `http://wp.uni.lab` y tener SMB/RDP/VNC activos según el escenario.
  - Verificación: navegador/`curl`; `Test-NetConnection` a 445/3389/5900.
- **REQ-002-09 (Ubicuo).** M6 DEBE tener las herramientas de auditoría instaladas.
  - Verificación: `nmap --version`; `wpscan --version`; `nxc --version`; `msfconsole -v`.
- **REQ-002-10 (Ubicuo).** R0 DEBE estar sin DSL, con DHCP off, WPA2 y UPnP/WPS off.
  - Verificación: captura de la configuración del router.
- **REQ-002-11 (Evento).** CUANDO una VM arranque, sus servicios DEBEN iniciar automáticamente.
  - Verificación: reiniciar y repetir `curl`/`redis-cli`/`smbclient`.
- **REQ-002-12 (No deseado).** SI una dependencia falla, ENTONCES el laboratorio DEBE documentar el fallo y no avanzar a Fase 2.
  - Verificación: tabla de dependencias con estado.

## 5. Criterios de aceptación

- [ ] Artefactos transferidos por FTP y verificados.
- [ ] M1 responde WP y Moodle.
- [ ] M1 usa M2 y monta M3.
- [ ] M2 respalda en M3.
- [ ] M4 resuelve DNS y expone SMB/Spooler.
- [ ] M5 accede a M1.
- [ ] M6 tiene herramientas.
- [ ] R0 aislado.
- [ ] Versiones registradas.
- [ ] Version gate: versiones instaladas coinciden con la matriz.

## 6. Trazabilidad

| REQ | Test/evidencia | Tarea |
|---|---|---|
| REQ-002-01 | `curl` + `EV-F01-*` | T-002-01 |
| REQ-002-02 | `DB_OK` | T-002-02 |
| REQ-002-03 | `findmnt` | T-002-03 |
| REQ-002-04 | `redis-cli`/`mariadb` | T-002-04 |
| REQ-002-05 | `ls backups` | T-002-05 |
| REQ-002-06 | `exportfs`/`smbclient` | T-002-06 |
| REQ-002-07 | `dig`/`nmap` | T-002-07 |
| REQ-002-08 | `curl`/`Test-NetConnection` | T-002-08 |
| REQ-002-09 | `--version` | T-002-09 |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| M4 inestable | Snapshot y reinicio; documentar |
| NFS no monta | Verificar `exports`, UFW y `nfs-common` |
| Backups no llegan | Verificar llave y cron |
| DNS no resuelve | Verificar zona y firewall 53 |
| Versiones cambian | Fijar y registrar; no actualizar aún |

## 8. Fuera de alcance

- Implantar vulnerabilidades.
- Escanear o explotar.
- Parchear.
