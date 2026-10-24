# Validación de versiones e interconexión — 2026-10-24

**Alcance:** M1, M2, M3 (M4 en red sin configurar; M5 Windows instalado, sin IP).
**Método:** consulta directa por SSH/HTTP desde el host del laboratorio y CLI de cada servicio.

## 1. Versiones vs. requisito del escenario

| Pieza | Versión instalada | Requisito / motivo | Estado |
|---|---|---|---|
| Apache httpd | **2.4.49** (`/usr/local/apache2`) | W3: CVE-2021-41773 | ✅ |
| PHP | **8.4.26** ZTS, mod_php | W2: PHP2Shell (8.4.26 < 8.4.27) | ✅ (ZTS: ver nota) |
| Extensiones PHP | gd, sodium, exif, intl, zip, mysqli | Moodle 5.0 + WordPress | ✅ |
| WordPress | **7.0.1** | W1: wp2shell (7.0.0–7.0.1) | ✅ |
| Moodle | **5.0.11** | Compatible MariaDB 10.11 + PHP 8.4 | ✅ |
| MariaDB | **10.11.19** | Moodle 5.0 exige ≥10.11 | ✅ |
| Redis | **6.2.6** | D1: CVE-2022-0543 (10.0) | ✅ |
| vsftpd | **2.3.4** | B2: CVE-2011-2523 | ✅ |
| Samba | — | B1: SambaCry (4.5.10) | ❌ pendiente (porte waf py3) |
| OpenSSH | distro 22.04 | Administración | ✅ |

**Notas de alineación:**
- Se mantuvo **PHP 8.4.26** (no se bajó a 8.3) para no perder PHP2Shell.
- Moodle **5.3 se descartó** (exige MariaDB 11.4) y **4.5 se descartó** (bloquea PHP 8.4).
- PHP es **ZTS**; los PoC públicos de PHP2Shell se calibraron sobre NTS. Si W2 no reproduce, recompilar NTS es la causa probable.

## 2. Servicios e interconexión

| Enlace / servicio | Prueba | Resultado |
|---|---|---|
| M1 → M2 MariaDB | `mysqli` desde M1 | `DB_OK 10.11.19` ✅ |
| M1 → M3 NFS | `mount \| grep nfs4` | `wp-uploads` y `moodledata` montados ✅ |
| M1 storage | subida WP + miniaturas | archivos en `/srv/storage/wp-uploads/2026/10` ✅ |
| M1 → M3 Moodle data | `moodledata` en M3 | `cache/ filedir/ lang/ ...` (5.1 MB) ✅ |
| DNS interno | `wp.uni.lab` / `moodle.uni.lab` | resuelven a `10.10.10.11` ✅ |
| M1 web | `curl -I` | WP 7.0.1 + `X-Powered-By: PHP/8.4.26` ✅ |
| WordPress | 6 páginas + 2 entradas | todas `200` ✅ |
| Moodle | `/login/index.php` | `200`, título “USC” ✅ |
| M2 Redis | `redis-cli info` | `6.2.6`, sin auth (D1) ✅ |
| M2 SNMP | `ss -uln :161` | escucha en `10.10.10.12` (D4) ✅ |
| M3 FTP | `:21` | vsftpd 2.3.4 anónimo ✅ |
| M4 | ping `.14` | responde; sin roles configurados ⚠️ |
| M5 | bridge en VMware + IP/DNS + VNC | `10.10.10.15`, SMBv1, RDP sin NLA, VNC auth None ✅ |

## 3. Bases de datos

| Esquema | Tablas | Usuario | Origen permitido |
|---|---|---|---|
| `wordpress` | 12 | `wp_user` | `10.10.10.11` |
| `moodle_db` | 487 | `moodle_user` | `10.10.10.11` |

## 4. Contenido cargado

- **WP:** Universidad Sideral Carrión — Inicio, Carreras, Admisión, Contacto, Sobre la USC, Noticias + 2 entradas; menú y footer institucional; CSS azul/dorado.
- **Moodle:** 3 categorías, 5 cursos (ISC-1023, BD-204, MAT-101, ENF-101, ADM-101), 3 docentes, 6 alumnos, 35 matrículas, 2 foros y 2 tareas.

## 5. Credenciales de laboratorio

| Servicio | Usuario | Clave |
|---|---|---|
| WordPress admin | `usc.admin` | `Admin13.-` |
| Moodle admin | `moodleadmin` | `Admin13.-` |
| Moodle alumno | `atorres` | `Estudiante123.` |
| SSH M1 | `ubuntu` | `Admin13.-` |
| SSH M2 | `adminm2` | `adminm2` |
| SSH M3 | `rony123` | `rony123` |

> Cambiar al cerrar la práctica. Son claves de laboratorio, no de producción.

## 6. Desviaciones y pendientes

1. **Samba 4.5.10 (M3)**: `waf` en Python 2; el porte a Python 3 quedó incompleto. Afecta solo B1 (SambaCry); NFS funciona.
2. **M4**: sin DNS/SMBv1/Spooler ni privesc; pendiente ejecutar `play-m4-windows.yml`.
3. **M5**: Windows 10 en bridge, IP `10.10.10.15`, SMBv1, RDP sin NLA y **TightVNC 2.8.90 con auth None** (C4) verificados. Ver `m5-setup.ps1`.
4. **PHP ZTS**: si se requiere el PoC W2, recompilar sin ZTS.
5. **MPM event**: mod_php funciona, pero prefork es lo recomendado; revisar antes de la demo.

## 7. Evidencia

Guardar capturas de: `httpd -v`, `php -v`, `wp core version`, `moodle release`, `mariadb --version`, `redis-server --version`, `vsftpd` en `:21`, `mount | grep nfs4`, y las respuestas HTTP de WP/Moodle. Fecha y hora visibles en cada captura.
