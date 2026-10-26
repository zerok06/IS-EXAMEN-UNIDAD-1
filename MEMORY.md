# MEMORY.md · Memoria operativa del laboratorio

> Estado consolidado a **2026-10-26**. Es la fuente de verdad para agentes y para el informe. Si algo no está aquí, no se asume.

## 1. Estado actual

| Indicador | Valor |
|---|---|
| Laboratorio | Apagado; ningún `10.10.10.x` responde desde el host |
| Hallazgos | 24 (9 CVE + 15 configuraciones) |
| Presencia | 5/5 máquinas objetivo (M1–M5) |
| RCE de CVE estrella | 0 (W1/W2/W3 solo fingerprint) |
| Versiones parcheadas | 0 (mitigación por configuración) |
| Privesc real M4 | 0 (SYSTEM con credenciales admin, no desde acceso limitado) |
| Snapshots | `estado-inicial-vulnerable` existen; `estado-parcheado` pendiente |
| Retest | Ejecutado por configuración, pero contradictorio con `06-remediacion.md` |

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
| WordPress admin | `usc.admin` | `Admin13.-` |
| Moodle admin | `moodleadmin` | `Admin13.-` |
| Moodle docentes | `jpaye`, `mlopez`, `cramirez` | `Profesor123.` |
| Moodle alumnos | ver `guias/validacion-versiones.md` | `Estudiante123.` |
| SSH M1 | `ubuntu` | `Admin13.-` |
| SSH M2 | `adminm2` | `adminm2` |
| SSH M3 | `rony123` | `rony123` |
| MariaDB app | `wp_user` / `moodle_user` | `wp_pass123` |
| M4 admin (antes) | `Administrador` | `password_2026` |
| M4 admin (después) | `Administrador` | `M4_Admin_2026!` |
| M4 usuario limitado | `soporte` | `Soporte123!` (crear en Fase 2) |
| M5 cliente | `cliente` | `Admin13.-` |

## 4. Matriz de versiones

| ID | Instalado | Corrige | CVSS | Estado |
|---|---|---|---|---|
| W1 | WordPress 7.0.1 | 6.9.5 / 7.0.2 | 9.8 | PoC público pendiente de ejecutar |
| W2 | PHP 8.4.26 | 8.4.27 | 9.8 v3.1 / 9.2 v4.0 | PoC público; requiere prefork/NTS/offsets |
| W3 | Apache 2.4.49 | 2.4.50 (41773) / 2.4.51+ (42013) | 9.8 | CGI 503; falta corregir |
| D1 | Redis 6.2.6 fuente | 6.2.7 | 10.0 | No reproducible con build de fuente |
| B1 | Samba 4.5.10 | 4.5.10 | 9.8 | 4.5.10 es el fix; bajar a 4.5.9 |
| B2 | vsftpd 2.3.4 limpio | 2.3.4 limpio / 3.x | 9.8 | Backdoor ausente |
| S1 | WS2016 14393 | MS17-010 | 8.8 | SMB1 off / no explotable |
| S2 | WS2016 Spooler | KB / Spooler off | 8.8 | Check vulnerable; LPE pendiente |
| C1 | Win10 19045 | MS17-010 | 8.8 | No aplica |
| C4 | TightVNC 2.8.90 | password + localhost + FW | ~9.8 ambiental | Validado |

## 5. Limitaciones conocidas

- **W1/W2/W3**: no se ejecutó el PoC completo; no se afirma RCE.
- **W2**: PHP ZTS + MPM event; el PoC espera mod_php prefork y, probablemente, NTS.
- **W3**: `mod_cgid` sin daemon → 503; no es fallo de versión, es configuración.
- **D1**: Redis compilado de fuente; CVE-2022-0543 es un problema de empaquetado Debian/Ubuntu.
- **B1**: Samba 4.5.10 es la versión corregida; no es explotable.
- **B2**: el tarball limpio de vsftpd 2.3.4 no contiene el backdoor.
- **S1**: SMBv1 no está activo/no vulnerable; no se demostró.
- **C1**: Windows 10 19045 no está afectado por EternalBlue.
- **M4**: `nt authority\system` se obtuvo con credenciales de admin vía tarea programada; no es privesc.
- **M4**: PrintNightmare dio `check vulnerable`, pero el `run` no creó sesión; probablemente por `SRVHOST` en M6 y firewall de M4.
- **Informe**: `07-retest.md` dice ejecutado; `06-remediacion.md` dice pendiente; las versiones no cambiaron.

## 6. Snapshots

| VM | Snapshot | Estado | Nota |
|---|---|---|---|
| M1 | `estado-inicial-vulnerable` | Existe (mapear nombre) | Incluye W1–W7 + SSH |
| M2 | `estado-inicial-vulnerable` | Existe (mapear nombre) | Redis sin auth, claves DB |
| M3 | `estado-inicial-vulnerable` | Existe (mapear nombre) | FTP anónimo, NFS |
| M4 | `estado-inicial-vulnerable` | Existe (mapear nombre) | SMBv1, Spooler, DNS |
| M5 | `estado-inicial-vulnerable` | Existe (mapear nombre) | SMBv1, RDP, VNC |
| M1–M5 | `estado-parcheado` | **Pendiente** | Tomar tras Fase 6 |
| M1–M5 | Clon full | **Pendiente** | Antes de Fase 2 |

## 7. Próximos pasos

1. Encender R0/M1–M6 y verificar red, DNS y aislamiento.
2. Completar snapshots `00-base`, `01-rol-listo`, `estado-inicial-vulnerable` y clon full.
3. Ejecutar Fase 4 en M1: W1 → W4 → W3 → W2 (time-box).
4. Pivotar y cerrar M2/M3; crear `soporte` y hacer PrintNightmare LPE en M4; cerrar M5.
5. Restaurar `estado-inicial-vulnerable`; aplicar Fase 5 con versiones; hacer Fase 6.
6. Renumerar el informe, mover comandos al anexo interno y preparar diapositivas.

> Antes de avanzar de fase, completar [`templates/version-gate.md`](./templates/version-gate.md).

## 8. Bitácora de cambios

| Fecha UTC | Cambio | Autor | Evidencia |
|---|---|---|---|
| 2026-10-26 | Capa SDD creada: constitución, plan maestro, 8 specs, tests | Agente | `docs/`, `specs/`, `tests/` |
| 2026-10-26 | Proceso 7 fases + informe, version gate y plantillas | Agente | `docs/PROCESO-7-FASES.md`, `templates/` |
| 2026-10-26 | 19 artefactos descargados y verificados; FTP por rol | Agente | `artifacts/`, `checksums.sha256` |
| 2026-10-26 | Revalidación de 24 vulns + specs por vulnerabilidad | Agente | `docs/VALIDACION-VULNERABILIDADES.md`, `specs/005.../vulns/` |
