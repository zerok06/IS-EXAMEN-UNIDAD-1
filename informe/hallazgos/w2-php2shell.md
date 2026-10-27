# Hallazgo W2 · PHP2Shell · CVE-2026-109618 / CVE-2026-109619

**Máquina:** M1 `10.10.10.11` · `m1-app`
**Servicio:** PHP 8.4.26 `mod_php` sobre Apache 2.4.49
**Fecha de ejecución:** 2026-10-27 (UTC)
**Estado:** precondiciones NTS/prefork **cumplidas**; PoC en calibración de heap. ROOT obtenido por la cadena M1-SSH (no por W2).

---

## 1. Ficha

| Campo | Valor |
|---|---|
| CVE | CVE-2026-109618 (9.8 v3.1 / 9.2 v4.0) · CVE-2026-109619 (8.1 v3.1 / 9.2 v4.0) |
| CWE | CWE-416 / CWE-755 / CWE-824 |
| Versión afectada | PHP 8.4.0–8.4.26 (también 8.2/8.3/8.5) |
| Versión que corrige | PHP 8.4.27 |
| Artefacto | `artifacts/vulnerable/php-8.4.26.tar.gz` (SHA256 verificado) |
| PoC | `artifacts/pocs/php2shell-poc-main.zip` |
| NVD | https://nvd.nist.gov/vuln/detail/CVE-2026-109618 |
| Impacto | RCE pre-auth como `www-data`; disclosure de memoria del worker |

---

## 2. Fase 0/1 · Versión y línea base

| Comprobación | Resultado |
|---|---|
| `php -v` / phpinfo | PHP **8.4.26** |
| Build original | **ZTS** (`Thread Safety enabled`) y Apache MPM **event** |
| `display_errors` | Off |
| `memory_limit` | 512M |
| `max_input_vars` | 5000 |
| `session.upload_progress.enabled` | On |

**Conclusión:** la versión es vulnerable, pero **las condiciones del PoC no se cumplían** (ZTS + event + `display_errors=Off` + `memory_limit=512M`). Por eso se recompiló en staging.

---

## 3. Fase 2 · Rebuild NTS + prefork (staging, sin tocar el Apache de 80)

Se compiló en `/home/ubuntu/w2` para no alterar el servicio vivo:

| Componente | Resultado |
|---|---|
| Apache | **2.4.49 prefork** en `/home/ubuntu/w2/httpd-prefork` (`Server MPM: prefork`, `threaded: no`) |
| PHP | **8.4.26 NTS** (`PHP 8.4.26 (cli) ... (NTS)`, `Thread Safety disabled`) |
| Módulo | `/home/ubuntu/w2/httpd-prefork/modules/libphp.so` |
| `php.ini` | `memory_limit=8M`, `display_errors=On`, `max_input_vars=5000`, `session.upload_progress.enabled=On`, `cleanup=Off` |
| Target de sesión | `/var/www/wp/session.php` (`session_start(); echo "ok";`) |
| Puerto de prueba | **8080** (el Apache event de 80 sigue intacto) |

**Offsets derivados del binario real:**

```text
zif_system     0x52e6f0
zval_ptr_dtor  0x72ffd0
```

**Evidencia:** `EV-W2-01` (log + captura) — `Thread Safety disabled`, `memory_limit 8M`, `display_errors On`, offsets y `session.php HTTP 200`.

**Comandos reproducibles (resumen):**

```bash
# Apache prefork
./configure --prefix=/home/ubuntu/w2/httpd-prefork \
  --with-apr=/usr/bin/apr-1-config --with-apr-util=/usr/bin/apu-1-config \
  --with-mpm=prefork --enable-so --enable-cgi --enable-rewrite \
  --enable-ssl --with-ssl --enable-mods-shared=most
make -j1 && make install

# PHP NTS contra el Apache prefork
./configure --with-apxs2=/home/ubuntu/w2/httpd-prefork/bin/apxs --disable-zts \
  --with-mysqli --with-pdo-mysql --with-curl --with-openssl --with-zip \
  --enable-mbstring --enable-intl --enable-gd --with-external-gd \
  --with-jpeg --with-freetype --enable-exif --enable-opcache --with-zlib \
  --with-sodium --prefix=/home/ubuntu/w2/php826-nts \
  --with-config-file-path=/home/ubuntu/w2/php826-nts/lib
make -j2 && make install

# Offsets
nm /home/ubuntu/w2/httpd-prefork/modules/libphp.so | grep -E ' (zif_system|zval_ptr_dtor)$'
```

---

## 4. Fase 3 · Ejecución del PoC

**Comando base:**

```bash
python3 poc_109618.py -u http://10.10.10.11:8080/session.php \
  -c 'id>/tmp/p1' \
  --zif-offset 0x52e6f0 --dtor-offset 0x72ffd0 \
  --profile lab --offsets-file '' --no-auto-offsets
```

**Resultado observado (perfiles `lab` y `bookworm`):**

```text
[*] target http://10.10.10.11:8080/session.php (cmd='id>/tmp/p1')
[*] offsets: zif=0x52e6f0 dtor=0x72ffd0 htdata=0x6e0d8
[*] rotating worker over HTTP
[*] stage 1: heap leak (attempt 1/3)
[-] heap leak missed
...
HEAP_LEAK_FAILED
```

**Diagnóstico:** el OOM sí ocurre (respuesta `Allowed memory size of 8388608 bytes exhausted`), pero la cookie `Set-Cookie: PHPSESSID=...` no contiene el leak de heap; el `stage1_n` del PoC (892/841) está calibrado para otro build (Debian 12 / Apache 2.4.68). Se está barriendo `stage1_n` para el build Ubuntu 22.04 + Apache 2.4.49.

**Honestidad:** a esta hora **no se ha obtenido `id` por W2**. No se declara RCE de W2. Si la calibración no cierra en el time-box, se documenta como limitación y se sostiene la cadena con W3/W1.

---

## 5. Fase 4 · Impacto y ROOT

| Paso | Resultado | Evidencia |
|---|---|---|
| W2 RCE `www-data` | ❌ No demostrado aún | `EV-W2-01`, log del PoC |
| W3 RCE `www-data` (Apache 2.4.49 + CGI) | ✅ `uid=33(www-data)` | `EV-005-M1-03` |
| W1 ruta batch + login admin | ✅ `POST 400`, login 302 | `EV-000-11` |
| SSH M1 `ubuntu/Admin13.-` + sudo | ✅ `uid=0(root)` y lectura de `/etc/shadow` | `EV-W2-ROOT` |

**Cadena real para ROOT hoy:** acceso a M1 (W3 RCE como `www-data` o SSH con credencial débil) → `ubuntu` está en `sudo` → `sudo id` = `root`. Es una cadena válida y documentada; **no** es W2.

---

## 6. Fase 5/6 · Remediación y retest (propuesta)

| Medida | Verificación |
|---|---|
| PHP **8.4.27** (o `session.upload_progress.enabled=Off`) | `php -v` / phpinfo |
| Recompilar sin ZTS y con prefork solo para el estado vulnerable | `Thread Safety disabled`, `Server MPM: prefork` |
| Retest: mismo PoC | Debe fallar; sin OOM ni leak |
| Cerrar el Apache prefork de 8080 y volver al de 80 | `ss -lnt | grep 8080` vacío |

---

## 7. Evidencias

| ID | Qué demuestra |
|---|---|
| `EV-W2-01` | Apache prefork, PHP NTS, php.ini, offsets, target 200 |
| `EV-W2-ROOT` | `uid=0(root)` y `/etc/shadow` en M1 |
| `EV-005-M1-03` | W3 RCE `uid=33(www-data)` |
| `EV-000-11` | W1/W3/W4/W5/W6/W7 y versiones |
| Log del PoC | `HEAP_LEAK_FAILED` (limitación real) |

---

## 8. Conclusión

- **W2 no se declara explotado**: se cumplieron las precondiciones y se ejecutó el PoC con offsets reales, pero el leak de heap no cerró en el time-box.
- **ROOT sí se obtuvo** por la cadena M1 (SSH débil + sudo), con evidencia `EV-W2-ROOT`.
- La limitación y el fallback quedan documentados; no se inventa `id` de W2.
