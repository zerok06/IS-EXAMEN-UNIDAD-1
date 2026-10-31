# 2. Resumen ejecutivo

**Escenario:** red de laboratorio `10.10.10.0/24` con seis VM: aplicación (M1), base de datos (M2), respaldos (M3), Windows Server heredado (M4), estación cliente (M5) y Kali (M6). El objetivo fue encadenar debilidades para alcanzar las cinco máquinas objetivo y luego remediarlas.

**Qué se demostró (2026-10-24):**

- **M1:** WordPress 7.0.1, Apache 2.4.49 y PHP 8.4.26 confirmados. Login administrativo con **`usc.admin` / `Admin13.-`** (W4) y reutilización de la misma clave en SSH, con escalada a **root** por `sudo` (M1-SSH). `wp-config.php` entregó `wp_user` / `wp_pass123`.
- **M2:** Redis 6.2.6 exigía nada (`PONG` sin auth) y MariaDB aceptaba `wp_pass123` (12 + 487 tablas). **Mitigado**: `requirepass`, claves rotadas (M1 actualizado), UFW solo M1, comunidades SNMP eliminadas. Retest: `NOAUTH`/timeout, vieja denegada, todo filtrado desde M6.
- **M3:** FTP anónimo con `credenciales.txt` → **`Admin13.-`**; NFS con `no_root_squash` permitió crear un archivo **root** desde M1.
- **M5:** comprometida vía **VNC sin autenticación** (`Authentication: None`): escritorio remoto, consola con `whoami` → `desktop-dt5f05n\cliente` y marcador `PWNED-M5` en el escritorio. También se validó la clave reutilizada `cliente` / `Admin13.-` por SMB a través de un túnel SSH desde M1.
- **M4:** se validaron **S3 (acceso admin con `Administrador` / `password_2026`, `Pwn3d!`; shares `ADMIN$`, `C$`, `legacy`)**, **S4 (AXFR)** y **S5 (SMB signing desactivado)**. **S2 (PrintNightmare)** dio `The target is vulnerable` en el `check`, pero el `run` no creó sesión; el Spooler quedó deshabilitado. Se demostró **`nt authority\system`** con una tarea programada vía WinRM (`F04-017`), evidencia de nivel SYSTEM, aunque no se atribuye a PrintNightmare. **S1 (EternalBlue)** no es accesible por IPC$/SMB1 (`SMB1 only: false`).
- **W1/W2/W3/B1/B2/D1:** se documentan con sus limitaciones reales (PoC no ejecutado, CGI 503, Samba 4.5.10 ya parcheado, backdoor ausente, Redis con `enable_strict_lua`). No se inventan éxitos.

**Criticidad:** el escenario incluye **CVE-2022-0543 (10.0)**, **CVE-2026-63030 (9.8, KEV)**, **CVE-2021-41773 (9.8)**, **CVE-2017-7494 (9.8)** y **CVE-2011-2523 (9.8)**, además de configuraciones críticas (VNC sin clave, FTP anónimo, NFS `no_root_squash`, claves reutilizadas).

**Estado final:** acceso real a M1, M2 y M3; M4/M5 pendientes de encendido; mitigación y retest pendientes. El informe distingue claramente **validado**, **parcial**, **no explotable** y **pendiente**.

**Conclusión preliminar:** el mayor riesgo no fue un CVE aislado, sino la **reutilización de credenciales** y la **exposición de servicios de gestión** (SSH, FTP, NFS, VNC). La cadena M1 → M2 → M3 → M4/M5 se sostiene sobre esos eslabones.
