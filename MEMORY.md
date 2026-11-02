# MEMORY.md · Lab PHP2Shell

> Fuente de verdad operativa. Si algo no está aquí, no se asume.
> Última actualización: **2026-11-01**.

## 1. Estado

| Indicador | Valor |
|---|---|
| Estructura | Reenfocada a un solo vector: PHP2Shell → cadena M1→M5 |
| Material anterior | Archivado en `legacy/` (tag `pre-php2shell-2026-10-31`) |
| Instaladores | `lab/m1`…`lab/m6` escritos, `bash -n` OK, **sin probar en VM todavía** |
| Laboratorio | Apagado (10.10.10.11 no responde al 2026-10-31) |
| `entry-a` (CVE-2026-109618) | **No resuelto**: el PoC público falla en stage 1 |
| `entry-b` (Chain A: sesión + LFI) | **Resuelto el 2026-11-02**: `www-data` confirmado (`uid=33`) tras cambiar el campo de progreso de `-F` a `--form-string` (el `;` del payload hacía abortar curl con `rc=26`) |

## 2. Decisiones

1. **Un solo vector de entrada:** PHP2Shell en M1. El resto es pivoteo.
2. **nginx delante de Apache:** nginx termina TLS en 443 y proxya a Apache 2.4.49
   prefork en 127.0.0.1:8080 con mod_php. nginx no ejecuta PHP. Motivo: el PoC de
   PHP2Shell solo se calibró para mod_php + prefork.
3. **Un solo Apache:** se retira el Apache de la distro; no se mezclan instalaciones.
4. **`entry-b` es el camino operativo:** `session.upload_progress` + sink LFI del
   plugin `legacy-download`. Se declara como tal; no se vende como el UAF.
5. **`entry-a` va con time-box** y se documenta la limitación. Sin `id`, no cuenta.
6. **Cada salto es una vulnerabilidad.** M1→M2 Redis sin auth como root;
   M2→M3 NFS `no_root_squash` + cron root; M4 PrintNightmare (opcional, con la
   cuenta `soporte` como precondición); M5 VNC sin autenticación, independiente
   de M4.
7. **M4 es Windows:** el salto M3→M4 (opcional) es PrintNightmare (spooler);
   MS17-010 solo vale si M4 fuera Server 2012 R2.
8. **M5 se alcanza por VNC sin auth** (CWE-306), no por reutilización de claves
   y sin depender de M4.
9. **Las cuentas de `§4` son de administración**, salvo `soporte`, que es la
   precondición declarada del salto opcional 4.
10. **El pivote es real para M2 y M3:** `01b-pivot.sh` monta ligolo-ng en M1 con
    rutas `/32`. M4 y M5 comparten L2 con M6 y van directo por `eth1`; forzar su
    tráfico por el túnel rompe las conexiones inversas.
11. **Instalación automatizada:** cada VM baja `lab.tar.gz` de M6:8000 y ejecuta su rol.
12. **Artefactos solo de `artifacts/`;** nada de Internet.
13. **Todo lo viejo queda congelado** en `legacy/`; no se consulta para la demo.
14. **M4 es opcional:** M5 no depende de M4; la cadena operativa es
    M1 → M2 → M3 → M5.

## 3. Verdad sobre PHP2Shell

- CVE-2026-109618 / 109619 son **reales** (CNA PHP, 2026-10-21, CVSS v4.0 9.2, KEV
  2026-10-26, corregidos en 8.4.27).
- El PoC `poc_109618.py` **no es fiable**: falla en stage 1 incluso contra
  `php:8.4.26-apache` (issue #8 del repo) y le falta `docker/offsets.py`.
- `HTDATA` (0x6e0d8/0x690d8) es un offset de heap, **no** se deriva con `nm`.
- `entry-a` exigiría un exploit propio calibrado al build. No hay exploit público
  zero-dependency.
- `entry-b` sí produce `www-data`, pero **requiere el sink LFI**. Es una cadena
  session-injection + LFI, no el UAF.

## 4. Credenciales (laboratorio aislado)

| Servicio | Usuario | Clave |
|---|---|---|
| WP admin | `usc.admin` | `Admin13.-` |
| Moodle admin | `moodleadmin` | `Admin13.-` |
| M1 SSH | `ubuntu` | `Admin13.-` |
| M2 SSH | `adminm2` | `adminm2` |
| M3 SSH | `rony123` | `rony123` |
| M3 backup | `backup` | solo llave de M2 |
| M4 | `Administrador` | `M4_Admin_2026!` |
| M4 limitado | `soporte` | `UniLab2026!` |
| M5 | `cliente` | `Admin13.-` |
| MariaDB | `wp_user` / `moodle_user` | `ClaveDebil123` |
| Redis | — | sin auth |

## 5. Pendientes

1. **Probar los instaladores en VM real** (M1 es el crítico: build de Apache/PHP ~20 min).
2. **Probar `entry-b`** contra M1 y guardar `WS_SID`; verificar el `id` por el sink.
3. **Cadena probada (2026-11-02):** M1 `www-data`, M2 `root`, M3 `root` y M5 VNC PASS; M4 obtuvo sesión `SYSTEM` pero sin `getuid`/marcador por inestabilidad del módulo.
4. **Probar el parchado:** `lab/patch/m1-php.sh` … `m5.ps1` + `retest.sh` (los saltos deben fallar, incluido el opcional M4).
5. **Moodle:** opcional (`INSTALL_MOODLE=0`); 5.0.11 exige MariaDB 10.11 y Ubuntu trae 10.6.
6. **`entry-a`:** decidir si se intenta un exploit propio o se cierra como limitación.
7. **Snapshots:** `00-base` y `01-<rol>-listo` por VM antes de explotar.
8. **Informe:** reescribir con la estructura de 4 saltos + M4 opcional y evidencias nuevas.
9. **Rotar credenciales** al cerrar la práctica.

## 6. Bitácora

| Fecha UTC | Cambio |
|---|---|
| 2026-10-31 | Reestructuración: `docs/ guias/ informe/ specs/ templates/ tests/ presentacion/ plantilla-IS1023/ .agents/` → `legacy/`; tag `pre-php2shell-2026-10-31` |
| 2026-10-31 | Nuevo `lab/`: README, lib común, instaladores M1–M6, PKI, bootstrap, cadena y smoke |
| 2026-10-31 | M1: nginx TLS → Apache 2.4.49 prefork → PHP 8.4.26 NTS mod_php; harness `/lab/session.php`; sink `legacy-download`; `session.save_path=/tmp` |
| 2026-10-31 | Pivote ligolo por M1 (`01b`), matriz de versiones (`VERSIONES.md`), chequeo (`check-versions.sh`) y scripts de parchado/retest (`lab/patch/`) |
| 2026-11-01 | M6 con dos NIC: `lab/m6/net.sh` deja `eth1` en `10.10.10.20/24` sin gateway (Internet sigue por el NAT) y monta DNS partido en `127.0.0.1` (`dnsmasq`, `lab-dns.service`): `uni.lab` → M4, resto → NAT. `/etc/hosts` queda solo como plan B (`LAB_HOSTS=1`) para no tapar a M4 |
| 2026-11-01 | Guía de explotación reescrita como runbook secuencial: gate de arranque, salto 1.5 (pivote) con sección propia, comandos manuales alineados con los scripts, captura de evidencias con SHA256 y límites de M5. Verificado con el artefacto ligolo 0.9.2: el tar trae `proxy` (renombrar a `ligolo-proxy`), el agente **no acepta `-id`** y su id es la MAC; `01b-pivot.sh` todavía pasa `-id` (pendiente de corregir en script) |
| 2026-11-02 | **Saltos 1, 1.5, 2 y 3 PASS**: `www-data` en M1, pivote por `lab`, `root` en M2 y `root` en M3 (`PWNED-M3.txt`). Correcciones: `-F` → `--form-string` y extracción de MAC con `grep -oE` |
| 2026-11-02 | **Salto 4:** sesión `NT AUTHORITY\SYSTEM @ SRVOLD` obtenida; el módulo crashea el spooler y no se capturó `getuid`/marcador. Causa del callback: la ruta `/32` de `.14`; se elimina |
| 2026-11-02 | **Salto 5 PASS**: VNC de M5 sin autenticación (`Security types: None`), escritorio capturado con Xvfb+TigerVNC (`evidence/EV-05-01.png`) y bandera `FLAG-M5-cliente` por SMB con `cliente` (anónimo denegado) |
| 2026-11-02 | **Reclasificación:** M4 (PrintNightmare) pasa a **opcional**; usa `soporte`/`UniLab2026!` como precondición. Cadena operativa M1→M2→M3→M5. Se corrigieron README, guía y guion; se añadió el mapeo de red (§0.3) y se documentó que M4/M5 van directo por L2 |
