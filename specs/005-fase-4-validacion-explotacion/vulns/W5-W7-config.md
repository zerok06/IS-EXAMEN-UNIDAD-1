# W5–W7 · Configuraciones expuestas en M1

## 1. Ficha

| ID | Servicio | Configuración | CWE | CVSS |
|---|---|---|---|---|
| W5 | Apache `mod_status` | `server-status` 200 | CWE-200 | ~5.3 |
| W6 | `info.php` | `phpinfo()` público | CWE-200 | ~5.3 |
| W7 | `uploads` | `Options +Indexes` | CWE-548 | ~5.3 |

## 2. Flujo

```bash
# W5
curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/server-status

# W6
curl -s http://wp.uni.lab/info.php | grep -i 'PHP Version'

# W7
curl -s http://wp.uni.lab/wp-content/uploads/ | grep -i 'Index of'
```

## 3. Resultado esperado

```text
W5: 200
W6: PHP Version 8.4.26
W7: <title>Index of /wp-content/uploads</title>
```

## 4. Evidencia

- `EV-W5-01`, `EV-W6-01`, `EV-W7-01`.
- `LOG-W5-W7`.

## 5. Impacto

- W5: workers, requests y endpoints visibles.
- W6: versión, extensiones, rutas y configuración.
- W7: enumeración/descarga de archivos subidos.

## 6. Remediación

```apache
# W5
<Location "/server-status">
    Require ip 127.0.0.1
</Location>

# W6
sudo rm -f /var/www/wp/info.php

# W7
<Directory "/var/www/wp/wp-content/uploads">
    Options -Indexes
</Directory>
```

## 7. Retest

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/server-status   # 403
curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/info.php        # 404
curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/wp-content/uploads/  # 403
```

## 8. EARS

- **REQ-W5-01 (Evento).** CUANDO se valide W5, el laboratorio DEBE capturar `server-status` 200.
- **REQ-W6-01 (Evento).** CUANDO se valide W6, el laboratorio DEBE capturar la versión PHP en `info.php`.
- **REQ-W7-01 (Evento).** CUANDO se valide W7, el laboratorio DEBE capturar el `Index of`.
- **REQ-W5-W7-02 (Ubicuo).** La remediación DEBE dejar 403/404 en las tres rutas.

## 9. Checklist

- [ ] Snapshot `previo-a-W5`.
- [ ] W5/W6/W7 capturados.
- [ ] Remediación.
- [ ] Retest 403/404.
