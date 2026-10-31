# MEMORY.md · Lab PHP2Shell

> Fuente de verdad operativa. Si algo no está aquí, no se asume.
> Última actualización: **2026-10-31**.

## 1. Estado

| Indicador | Valor |
|---|---|
| Estructura | Reenfocada a un solo vector: PHP2Shell → cadena M1→M5 |
| Material anterior | Archivado en `legacy/` (tag `pre-php2shell-2026-10-31`) |
| Instaladores | `lab/m1`…`lab/m6` escritos, `bash -n` OK, **sin probar en VM todavía** |
| Laboratorio | Apagado (10.10.10.11 no responde al 2026-10-31) |
| `entry-a` (CVE-2026-109618) | **No resuelto**: el PoC público falla en stage 1 |
| `entry-b` (Chain A: sesión + LFI) | **Operativo en diseño**; pendiente de probar en VM |

## 2. Decisiones

1. **Un solo vector de entrada:** PHP2Shell en M1. El resto es pivoteo.
2. **nginx delante de Apache:** nginx termina TLS en 443 y proxya a Apache 2.4.49
   prefork en 127.0.0.1:8080 con mod_php. nginx no ejecuta PHP. Motivo: el PoC de
   PHP2Shell solo se calibró para mod_php + prefork.
3. **Un solo Apache:** se retira el Apache de la distro; no se mezclan instalaciones.
4. **`entry-b` es el camino operativo:** `session.upload_progress` + sink LFI del
   plugin `legacy-download`. Se declara como tal; no se vende como el UAF.
5. **`entry-a` va con time-box** y se documenta la limitación. Sin `id`, no cuenta.
6. **Cada salto es una vulnerabilidad, no una contraseña.** M1→M2 Redis sin auth
   como root; M2→M3 NFS `no_root_squash` + cron root; M3→M4 MS17-010; M4→M5 VNC
   sin autenticación.
7. **M4 es Windows:** el salto M3→M4 es EternalBlue (SMBv1), no PHP.
8. **M5 se alcanza por VNC sin auth** (CWE-306), no por reutilización de claves.
9. **Las cuentas de `§4` son solo de administración** y no forman parte de la cadena.
10. **La LAN es plana:** los saltos se ejecutan desde M6; el pivote es lógico.
11. **Instalación automatizada:** cada VM baja `lab.tar.gz` de M6:8000 y ejecuta su rol.
12. **Artefactos solo de `artifacts/`;** nada de Internet.
13. **Todo lo viejo queda congelado** en `legacy/`; no se consulta para la demo.

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
| M4 limitado | `soporte` | `Soporte2026!` |
| M5 | `cliente` | `Admin13.-` |
| MariaDB | `wp_user` / `moodle_user` | `ClaveDebil123` |
| Redis | — | sin auth |

## 5. Pendientes

1. **Probar los instaladores en VM real** (M1 es el crítico: build de Apache/PHP ~20 min).
2. **Probar `entry-b`** contra M1 y guardar `WS_SID`; verificar el `id` por el sink.
3. **Probar la cadena nueva:** Redis→root, NFS+cron→root, MS17-010→SYSTEM, VNC sin auth.
4. **MS17-010 depende del build:** si el ISO de WS2016 ya trae el parche, usar
   PrintNightmare con `soporte` (documentado como fallback).
5. **`entry-a`:** decidir si se intenta un exploit propio o se cierra como limitación.
6. **Snapshots:** `00-base` y `01-<rol>-listo` por VM antes de explotar.
7. **Informe:** reescribir con la estructura de 5 saltos y evidencias nuevas.
8. **Rotar credenciales** al cerrar la práctica.

## 6. Bitácora

| Fecha UTC | Cambio |
|---|---|
| 2026-10-31 | Reestructuración: `docs/ guias/ informe/ specs/ templates/ tests/ presentacion/ plantilla-IS1023/ .agents/` → `legacy/`; tag `pre-php2shell-2026-10-31` |
| 2026-10-31 | Nuevo `lab/`: README, lib común, instaladores M1–M6, PKI, bootstrap, cadena y smoke |
| 2026-10-31 | M1: nginx TLS → Apache 2.4.49 prefork → PHP 8.4.26 NTS mod_php; harness `/lab/session.php`; sink `legacy-download`; `session.save_path=/tmp` |
| 2026-10-31 | Cadena rediseñada a vulnerabilidades: Redis sin auth como root (M2), NFS `no_root_squash` + cron root (M3), MS17-010 (M4), VNC sin auth (M5). Se eliminan los saltos por credenciales |
