# MEMORY.md · Memoria operativa del laboratorio

> Estado consolidado a **2026-10-26**. Es la fuente de verdad para agentes y para el informe. Si algo no está aquí, no se asume.

## 1. Estado actual

| Indicador | Valor |
|---|---|
| Laboratorio | **M1–M4 parcheados**; M5 arriba con 445/3389/5900 filtrados; M6 arriba; FTP operativo |
| Hallazgos | 24 (9 CVE + 15 configuraciones) |
| Presencia | 4/5 máquinas accesibles (M5 sin servicios) |
| Pre-0 | 19/19 artefactos con SHA256 OK; descargados en M1/M2/M3/M6; M5 pendiente |
| Estado final | **M1–M4 remediados y retestados**; M5 pendiente por filtrado; W2 Chain A neutralizado (PHP 8.4.27 + `upload_progress=Off` + LFI eliminado) |
| RCE demostrado (antes) | W3 RCE `www-data`; W2 **Chain A** `www-data` + ROOT por B3/sudo |
| Versiones parcheadas | **WP 7.0.2 · PHP 8.4.27 · Apache 2.4.51 · Redis 6.2.7 · Samba 4.5.10** |
| Privesc real M4 | 0 (SYSTEM con credenciales admin, no desde acceso limitado) |
| Snapshots | `estado-inicial-vulnerable` y `estado-comprometido` existen; **`estado-parcheado` pendiente de tomar en M1–M4** |
| Retest | **Fase 6 ejecutada en M1–M4**; M5 pendiente; `06`/`07` coherentes |

## 2. Decisiones vigentes

1. **W1 wp2shell es la demo principal** (9.8, KEV, PoC público). W4 es el respaldo inmediato.
2. **W2 PHP2Shell es prioridad de investigación con time-box de 3–4 h**; no es el único camino.
3. **W3 Apache 2.4.49 se hace explotable** corrigiendo CGI (`mod_cgi` + `ScriptAlias` + `+ExecCGI`).
4. **M4 se corrige con un usuario limitado** (`soporte`) y PrintNightmare local; `nxc -x whoami` con admin no cuenta como privesc.
5. **M3 usa Samba 4.5.9** para que SambaCry sea real; 4.5.10 es el fix. B2 se documenta o se descarta.
6. **M5 se cierra con C2 + C4 + C3**; C1 no aplica a Windows 10 19045.
7. **La remediación cambia versiones** en WP, PHP, Apache y Redis; el resto por configuración.
8. **El informe se renumera 0–7** según la guía y los comandos se mueven a un anexo interno.
9. **No se parchea el estado comprometido**: se restaura `estado-inicial-vulnerable` y se parchea desde ahí.
10. **La demo usa snapshots**: restaurar vulnerable → explotar → restaurar parcheado → mostrar fallo.
11. **Proceso oficial:** 7 fases técnicas (0–6) + Fase 7 de informe final; **version gate obligatorio** en cada fase; plantillas en `templates/`.
12. **Artefactos:** 19 archivos en `artifacts/` (vulnerables, corregidos y PoCs) con SHA256 en `checksums.sha256`; transferencia FTP desde M6.
13. **Revalidación:** 22 hallazgos demostrables; D1 y B2 no reproducibles; S1 y C1 no aplicables. D1/B2/S1/C1 no cuentan como profundidad.

## 3. Credenciales de laboratorio

> Solo laboratorio aislado, datos ficticios. Rotar al cerrar la práctica.

| Servicio | Usuario | Clave |
|---|---|---|
| WordPress admin | `usc.admin` | `Uni2026!Admin` |
| Moodle admin | `moodleadmin` | `Admin13.-` |
| Moodle docentes | `jpaye`, `mlopez`, `cramirez` | `Profesor123.` |
| Moodle alumnos | ver `guias/validacion-versiones.md` | `Estudiante123.` |
| SSH M1 | `ubuntu` | `M1_Ubuntu_2026!` |
| SSH M2 | `adminm2` | `adminm2` |
| SSH M3 | `rony123` | `M3_Backup_2026!` |
| MariaDB app | `wp_user` / `moodle_user` | `Wp_Uni_2026!` / `Moodle_Uni_2026!` |
| M4 admin (actual) | `Administrador` | `M4_Admin_2026!` |
| M4 usuario limitado | `soporte` | eliminado en Fase 5 |
| M5 cliente | `cliente` | `Admin13.-` (M5 pendiente) |
| Redis | — | `UniRedis2026!` |
| SNMP | — | `UniSnmp2026!` (solo 127.0.0.1) |

## 4. Matriz de versiones

| ID | Instalado | Corrige | CVSS | Estado |
|---|---|---|---|---|
| W1 | WordPress **7.0.2** | 6.9.5 / 7.0.2 | 9.8 | 🟢 **Parcheado**; `/batch/v1` 403 |
| W2 | PHP **8.4.27** + `upload_progress=Off` | 8.4.27 | 9.8 v3.1 / 9.2 v4.0 | 🟢 **Parcheado**; Chain A neutralizado (LFI eliminado) |
| W3 | Apache **2.4.51** | 2.4.50 / 2.4.51+ | 9.8 | 🟢 **Parcheado**; CGI/RCE 403 |
| D1 | Redis **6.2.7** + `requirepass` | 6.2.7 | 10.0 | 🟢 **Parcheado/auth**; UFW 6379 |
| B1 | Samba 4.5.10 | 4.5.10 | 9.8 | 4.5.10 es el fix; bajar a 4.5.9 |
| B2 | vsftpd 2.3.4 limpio | 2.3.4 limpio / 3.x | 9.8 | Backdoor ausente |
| S1 | WS2016 14393 | MS17-010 | 8.8 | SMB1 off / no explotable |
| S2 | WS2016 Spooler **Stopped** | KB / Spooler off | 8.8 | 🟢 **Mitigado**; `soporte` eliminado |
| C1 | Win10 19045 | MS17-010 | 8.8 | No aplica |
| C4 | TightVNC 2.8.90 | password + localhost + FW | ~9.8 ambiental | ⬜ M5 filtrado; pendiente |

## 5. Limitaciones conocidas

- **W1/W3**: parcheados (7.0.2 / 2.4.51); RCE y rutas cerradas.
- **W2**: parcheado a 8.4.27 + `upload_progress=Off`; **Chain A** requiere un LFI (se eliminó) y Chain D zero-dep no es público.
- **W3**: Apache 2.4.51; CGI denegado; traversal/RCE 403.
- **D1**: Redis compilado de fuente; CVE-2022-0543 es un problema de empaquetado Debian/Ubuntu.
- **B1**: Samba 4.5.10 es la versión corregida; no es explotable.
- **B2**: el tarball limpio de vsftpd 2.3.4 no contiene el backdoor.
- **S1**: SMBv1 no está activo/no vulnerable; no se demostró.
- **C1**: Windows 10 19045 no está afectado por EternalBlue.
- **M4**: Spooler detenido, `soporte` eliminado, admin rotado; S2 mitigado.
- **M4**: PrintNightmare ya no aplica con Spooler detenido.
- **Informe**: `06`/`07` actualizados con versiones finales y retest; M5 queda pendiente explícito.
- **M5**: arriba a nivel ARP pero 445/3389/5900/5985 filtrados desde M6 y desde M1; no se puede validar C2/C3/C4 ni declarar 5/5.
- **M1**: entre 2026-10-26 23:53 y 2026-10-27 00:42 UTC pasó de “BD rota + rutas bloqueadas” a “BD OK + W1/W5/W6/W7 abiertas”; el cambio no está documentado.

## 6. Snapshots

| VM | Snapshot | Estado | Nota |
|---|---|---|---|
| M1 | `estado-inicial-vulnerable` | Existe (mapear nombre) | Incluye W1–W7 + SSH |
| M2 | `estado-inicial-vulnerable` | Existe (mapear nombre) | Redis sin auth, claves DB |
| M3 | `estado-inicial-vulnerable` | Existe (mapear nombre) | FTP anónimo, NFS |
| M4 | `estado-inicial-vulnerable` | Existe (mapear nombre) | SMBv1, Spooler, DNS |
| M5 | `estado-inicial-vulnerable` | Existe (mapear nombre) | SMBv1, RDP, VNC |
| M1–M4 | `estado-parcheado` | **Pendiente de tomar** | Tomar ahora, tras Fase 6 |
| M5 | `estado-parcheado` | **Pendiente** | Requiere acceso/consola |
| M1–M5 | Clon full | **Pendiente** | Antes de Fase 2 |

## 7. Próximos pasos

1. **Tomar `estado-parcheado` en M1–M4** (VMware) tras el retest; mapear el nombre real en `c-snapshots`.
2. **M5:** requiere consola/VMware; 445/3389/5900 filtrados. No se declara 5/5 remediado.
3. **Fase 7:** renumerar el informe 0–7, mover comandos al anexo interno, completar deck y ensayar la demo.
4. **Demo:** restaurar `estado-inicial-vulnerable` → Chain A/W3 → B3/sudo → ROOT; restaurar `estado-parcheado` → mostrar bloqueo.
5. **Opcional:** construir target Debian 12/Chain D si se consigue el exploit zero-dependency (no público).

> Version gate final: [`docs/version-gate-2026-10-27-patched.md`](./docs/version-gate-2026-10-27-patched.md).

## 8. Bitácora de cambios

| Fecha UTC | Cambio | Autor | Evidencia |
|---|---|---|---|
| 2026-10-26 | Capa SDD creada: constitución, plan maestro, 8 specs, tests | Agente | `docs/`, `specs/`, `tests/` |
| 2026-10-26 | Proceso 7 fases + informe, version gate y plantillas | Agente | `docs/PROCESO-7-FASES.md`, `templates/` |
| 2026-10-26 | 19 artefactos descargados y verificados; FTP por rol | Agente | `artifacts/`, `checksums.sha256` |
| 2026-10-26 | Revalidación de 24 vulns + specs por vulnerabilidad | Agente | `docs/VALIDACION-VULNERABILIDADES.md`, `specs/005.../vulns/` |
| 2026-10-27 | Pre-0 ejecutada: FTP 2121, 19/19 SHA OK, descargas M1/M2/M3/M6; M5 pendiente | Agente | `LOG-000-04`…`LOG-000-08` |
| 2026-10-27 | Version gate real: W1 listo; W2/W3 con condiciones pendientes; B1=4.5.10 no cumple; M5 filtrado | Agente | `docs/version-gate-2026-10-27.md`, `EV-000-10` |
| 2026-10-27 | Protocolo de snapshots/evidencias y herramientas `capture.sh`/`vm.sh` | Agente | `docs/PROTOCOLO-SNAPSHOTS-EVIDENCIAS.md`, `informe/tools/` |
| 2026-10-27 | Validación de estado: W1/W3/W4/W5/W6/W7 + SSH listos; M2 D2/D3/D4 y M3 B3/B4/B5; M4 S3/S4/S5 + `soporte`; **W2 y B1 pendientes; M5 filtrada** | Agente | `EV-000-11`, `docs/version-gate-2026-10-27.md` |
| 2026-10-27 | W2: rebuild Apache 2.4.49 prefork + PHP 8.4.26 NTS en 8080; offsets 0x52e6f0/0x72ffd0; sesión compartida `session2.php`; PoC `HEAP_LEAK_FAILED` (limitación) | Agente | `EV-W2-01`, `EV-W2-02`, `informe/hallazgos/w2-php2shell.md` |
| 2026-10-27 | W2 en target oficial `php:8.4.26-apache` (Docker, offsets reales 0x465370/0x65eb60, 8M/12MB): `HEAP_LEAK_FAILED`; el PoC no cierra en el entorno | Agente | `EV-W2-05` |
| 2026-10-27 | W2 **Chain A** (`ikow/php2shell-poc`) desde M1: session injection + LFI → `uid=33(www-data)`; marcador y ROOT | Agente | `EV-W2-07`…`EV-W2-09` |
| 2026-10-27 | M1 ROOT: `ubuntu/Admin13.-` + sudo; lectura de `/etc/shadow` | Agente | `EV-W2-ROOT` |
| 2026-10-27 | Fase 5: WP 7.0.2, PHP 8.4.27, Apache 2.4.51, Redis 6.2.7; M3/M4 config; claves rotadas | Agente | `EV-007-RETEST` |
| 2026-10-27 | Fase 6: retest M1–M4 OK; W1 403, W3 403, W2 8.4.27/Off, D1 NOAUTH, B3 530, S1/S3/S4/S5 cerrados; M5 pendiente | Agente | `EV-007-RETEST`, `docs/version-gate-2026-10-27-patched.md` |
