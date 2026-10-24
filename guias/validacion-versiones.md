# Validación de versiones e interconexión — 2026-10-24

**Alcance:** M1, M2, M3, M5 verificados por SSH/HTTP el 2026-10-24 (solo verificación, sin explotación).
**Método:** consulta directa por SSH/HTTP desde el host del laboratorio y CLI de cada servicio.

## 1. Versiones vs. vulnerabilidad (correlación)

| ID | Pieza instalada | Requisito / motivo | Verificación 2026-10-24 | Estado |
|---|---|---|---|---|
| W3 | Apache **2.4.49** (`/usr/local/apache2`, `mod_cgid` + `cgi-bin/` + `Require all granted`) | CVE-2021-41773 | `httpd -v` 2.4.49; `httpd -M` muestra `cgid_module`; `/cgi-bin/` → 403 (ScriptAlias activo) | ✅ |
| W2 | PHP **8.4.26** ZTS mod_php (`gd sodium exif intl zip mysqli`) | PHP2Shell (8.4.26 < 8.4.27) | `php -v` 8.4.26; `upload_progress.enabled=On` | ✅ (ZTS: ver nota) |
| W1 | WordPress **7.0.1** (tema `usc-oficial` 1.0.0) | wp2shell (ruta `/wp-json/batch/v1`) | 129 rutas; `/batch/v1` existe (GET→404 normal, POST vacío→400); 6 páginas + 5 entradas | ✅ |
| W4 | `wp-admin` clave débil | `usc.admin` / `Admin13.-` | login manual posible (no se fuerza por política de solo-verificación) | ✅ |
| W5 | `server-status` expuesto | Location + `Require all granted` + exclusión en `.htaccess` de WP | `curl …/server-status` → **200** | ✅ (implantado hoy) |
| W6 | `info.php` público | disclosure de versión | `curl …/info.php` → **200** | ✅ |
| W7 | `+Indexes` en `wp-content/uploads` | listado de ficheros | `curl …/uploads/` → **200** `Index of` | ✅ (implantado hoy) |
| Moodle | **5.0.11** + tema `boost_usc` + idioma `es` | Compatible MariaDB 10.11 + PHP 8.4 | hero institucional, logo propio, `/login/index.php` 200 | ✅ |
| D1 | Redis **6.2.6** en `10.10.10.12:6379` | CVE-2022-0543 (sin auth) | `PING`→`+PONG`, `INFO` sin clave (solo lectura) | ✅ |
| D2 | MariaDB **10.11.19** + claves de app débiles | `wp_user`/`moodle_user` desde `.11` | `DB_OK 10.11.19`; 12 y 487 tablas | ✅ |
| B2 | vsftpd **2.3.4** en `:21` | CVE-2011-2523 (banner) | `220 (vsFTPd 2.3.4)` | ✅ |
| B3 | FTP anónimo + `credenciales.txt` | `anonymous_enable=YES`, `anon_root=/srv/storage` | login `anonymous` 230; listado muestra `/backups/credenciales.txt` (sin leer contenido) | ✅ (reparado hoy: usuario `ftp`, `/usr/share/empty`, pasivo 40000-40100) |
| B1 | Samba **4.5.10** + recurso `[backups]` invitado/escribible | SambaCry CVE-2017-7494 | `smbd --version` 4.5.10; `smbclient -L` muestra `backups`+`IPC$`; `:445` OPEN desde M1 | ✅ |
| C1 | M5 SMBv1 | `10.10.10.15:445` solo M1 | `Enabled`; 445 OPEN desde M1 | ✅ |
| C3 | M5 RDP sin NLA | `UserAuthentication=0` | 3389 OPEN desde M1 | ✅ |
| C4 | TightVNC **2.8.90** auth None | servicio `tvnserver`, `:5900` | handshake `RFB 003.008`, tipos `[1,16]` → AUTH_NONE | ✅ |
| — | OpenSSH distro 22.04 | administración | — | ✅ |

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
| M2 → M3 respaldos | `m2-backup-m3.sh` + `rsync` a `backup@M3` + cron 03:00 | `wordpress`+`moodle_db`+`redis` en `/srv/storage/backups/` ✅ |
| DNS interno | `wp.uni.lab` / `moodle.uni.lab` | resuelven a `10.10.10.11` ✅ |
| M1 web | `curl -I` | WP 7.0.1 + `X-Powered-By: PHP/8.4.26` ✅ |
| WordPress | 6 páginas + 2 entradas | todas `200` ✅ |
| Moodle | `/login/index.php` | `200`, título “USC” ✅ |
| M2 Redis | `PING`+`INFO` sin auth desde M1 | `redis_version:6.2.6`, sin clave (D1) ✅ |
| M2 SNMP | `ss -uln :161` | escucha en `10.10.10.12` (D4) ✅ |
| M3 FTP | `:21` + login anónimo + pasivo | vsftpd 2.3.4, `230 Login successful`, listado `/backups/credenciales.txt` ✅ |
| M3 NFS | `exportfs -v` | `wp-uploads`+`moodledata` solo `.11`; `backups` `.0/24` `no_root_squash` ✅ |
| M3 UFW | `ufw status` | `22` Anywhere; `2049` solo `.11`; `21,139,445` Anywhere; pasivo `40000:40100` ✅ |
| M3 Samba | `smbd-lab`+`nmbd-lab` **4.5.10** activos, `:139`/`:445` escuchando, recurso `backups` | ✅ (B1 listo, sin explotar) |
| M4 | `.14` (`:22`/`:445` desde M1) | closed — VM sin roles configurados ⚠️ |
| M6 | Kali | pendiente inventariar herramientas (nmap, Metasploit, wpscan, ligolo) ⚠️ |
| M5 | bridge en VMware + IP/DNS + VNC | `10.10.10.15`, SMBv1, RDP sin NLA, VNC auth None ✅ |

## 3. Bases de datos

| Esquema | Tablas | Usuario | Origen permitido |
|---|---|---|---|
| `wordpress` | 12 | `wp_user` | `10.10.10.11` |
| `moodle_db` | 487 | `moodle_user` | `10.10.10.11` |

## 4. Contenido cargado

- **WP:** Universidad Sideral Carrión — Inicio, Carreras, Admisión, Contacto, Sobre la USC, Noticias + 2 entradas; menú y footer institucional; CSS azul/dorado.
- **Moodle:** 5 cursos con imagen (ISC-1023, BD-204, MAT-101, ENF-101, ADM-101), 3 docentes, 6 alumnos, 2 foros y 2 tareas; tema `boost_usc` + idioma `es`; accesos de ejemplo en `guia-M1` §7.

## 5. Credenciales de laboratorio

| Servicio | Usuario | Clave |
|---|---|---|
| WordPress admin | `usc.admin` | `Admin13.-` |
| Moodle admin | `moodleadmin` | `Admin13.-` |
| Moodle docentes (`jpaye`, `mlopez`, `cramirez`) | ver `guia-M1` §7 | `Profesor123.` |
| Moodle alumnos (6) | ver `guia-M1` §7 | `Estudiante123.` |
| SSH M1 | `ubuntu` | `Admin13.-` |
| SSH M2 | `adminm2` | `adminm2` |
| SSH M3 | `rony123` | `rony123` |

> Cambiar al cerrar la práctica. Son claves de laboratorio, no de producción.

## 6. Desviaciones y pendientes

1. **Samba 4.5.10 (M3, B1) ✅**: compilado e instalado en `/usr/local/samba` (`smbd --version` + `smbclient -L` muestra `backups`; `:445` OPEN desde M1). Obstáculos resueltos: Python 2.7 `--enable-shared` en `/opt/python2.7`, `--without-acl-support`, headers NIS rotos de glibc (parche `source3/include/includes.h`: `#if 0` a includes YP + stubs `yp_*`/`YPERR_KEY`), `nsstest` desactivado del build (choca con `<nss.h>` moderno). Unidades `smbd-lab`/`nmbd-lab`; recurso `[backups]` invitado/escribible.
2. **M4**: `.14` sin `:22`/`:445` desde M1; pendiente encender y ejecutar `play-m4-windows.yml` (DNS/SMBv1/Spooler).
3. **M6 (Kali)**: pendiente inventariar `nmap`, `metasploit-framework`, `wpscan`, `proxychains`/`ligolo` y fijar su IP.
4. **PHP ZTS**: si se requiere el PoC W2, recompilar sin ZTS.
5. **MPM event**: mod_php funciona, pero prefork es lo recomendado; revisar antes de la demo.
6. **Lo hecho hoy (2026-10-24)**: W5+W7 implantados en M1, `mod_cgid` activado, FTP anónimo reparado en M3 (usuario `ftp`, `secure_chroot_dir`, rango pasivo + UFW), claves de ejemplo reseteadas en Moodle, tema WP `usc-oficial` + tema Moodle `boost_usc` + idioma `es`.

## 7. Evidencia

Guardar capturas de: `httpd -v`, `php -v`, `wp core version`, `moodle release`, `mariadb --version`, `redis-server --version`, `vsftpd` en `:21`, `mount | grep nfs4`, y las respuestas HTTP de WP/Moodle. Fecha y hora visibles en cada captura.
