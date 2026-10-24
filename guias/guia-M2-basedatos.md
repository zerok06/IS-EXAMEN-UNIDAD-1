# Guía M2 · Base de datos (Estudiante 2)

**Rol:** MariaDB de la app + Redis de caché. **Solo habla con M1** (y entrega backups a M3).

> Versión automatizada: [`ansible/play-m2-db.yml`](../ansible/play-m2-db.yml).

## Estado real de la implementación (validado 2026-10-24)

| Componente | Estado real |
|---|---|
| MariaDB | **10.11.19** (paquetes core del repo oficial), unidad `mariadb-lab`, escucha `10.10.10.12:3306`, `skip-name-resolve` |
| Datos | `wordpress` (12 tablas) y `moodle_db` (487 tablas); usuarios `wp_user`/`moodle_user` solo desde `10.10.10.11` |
| Migración | Se reemplazó 10.6 por 10.11 conservando el datadir; respaldo en `/var/lib/mysql.bak106` |
| Redis | **6.2.6** compilado en `/usr/local/bin`, unidad `redis`, escucha `0.0.0.0:6379` **sin requirepass** (D1 intencional) |
| SNMP | `snmpd` con `public`/`private`, escucha `10.10.10.12:161` (D4 intencional) |
| Firewall | UFW activo: 22, 3306 solo desde M1, 6379 y 161 abiertos a la LAN (D3 intencional) |
| Pendiente | Nada funcional; las aperturas son vulns de laboratorio |

## 0. Imagen base e instaladores

| Qué | Versión exacta | Origen |
|---|---|---|
| Ubuntu Server | **22.04.5** (misma ISO que M1) | https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso |
| MariaDB | **10.11.19** (repo oficial, `.deb` core) | https://archive.mariadb.org/mariadb-10.11.19/repo/ubuntu/ |
| Redis | **6.2.6** `redis-6.2.6.tar.gz` (D1) | https://download.redis.io/releases/redis-6.2.6.tar.gz |
| net-snmp | repo (`apt install snmpd`, D4) | repo Ubuntu |

```bash
sudo apt update && sudo apt install -y build-essential tcl snmpd
tar xzf redis-6.2.6.tar.gz && cd redis-6.2.6 && make -j$(nproc)
sudo make install && redis-server --version   # debe decir 6.2.6
mariadb --version   # 10.11.19 (paquetes core del repo MariaDB)
```

## 1. VM y red

- Ubuntu Server 22.04 · 2 vCPU · 4 GB · 40 GB. Bridge al lado **INTERNO**.
- Estática: `10.10.10.12/24`, gateway `10.10.10.1`, DNS `10.10.10.14` (ver guía 00).

## 2. Servicios (versiones FIJADAS)

```bash
sudo apt install -y mariadb-server redis-server=5:6.2.6*
redis-server --version   # debe decir 6.2.6 (D1: CVE-2022-0543, 10.0)
```

MariaDB (`/etc/mysql/mariadb.conf.d/50-server.cnf`):

```ini
[mysqld]
bind-address = 10.10.10.12
```

```sql
CREATE DATABASE wp_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE moodle_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wp_user'@'10.10.10.11' IDENTIFIED BY 'ClaveDebil123';      -- D2 intencional
CREATE USER 'moodle_user'@'10.10.10.11' IDENTIFIED BY 'ClaveDebil123';  -- D2 intencional
GRANT ALL ON wp_db.* TO 'wp_user'@'10.10.10.11';
GRANT ALL ON moodle_db.* TO 'moodle_user'@'10.10.10.11';
```

Redis (`/etc/redis/redis.conf`, variante vulnerable):

```text
bind 0.0.0.0        # D3: escucha en la LAN
# requirepass ...   # D1/D2: SIN contraseña (intencional)
```

SNMP (D4, monitoreo mal configurado):

```bash
sudo apt install -y snmpd
# /etc/snmp/snmpd.conf:
#   rocommunity public
#   rwcommunity private
#   agentAddress udp:161
sudo systemctl enable --now snmpd
```

Moodle (M1) usa este Redis como caché de sesión (coherente con el escenario).

## 3. Firewall (puertos abiertos de más = D3)

```bash
sudo ufw allow from 10.10.10.11 to any port 3306 proto tcp
sudo ufw allow 6379/tcp   # intencional: Redis abierto a la LAN
sudo ufw deny 3306
```

## 4. Backups hacia M3 (origen del paso 3 de la cadena)

```bash
sudo useradd -m -s /bin/bash backup
sudo -u backup ssh-keygen -t ed25519 -N "" -f /home/backup/.ssh/id_ed25519
sudo -u backup ssh-copy-id backup@10.10.10.13
# cron root 02:00: mysqldump --all-databases | gzip > /var/backups/db-$(date +\%F).sql.gz
# cron backup 02:15: rsync -az /var/backups/ backup@10.10.10.13:/srv/storage/backups/
```

## 5. Tus vulnerabilidades

| ID | Qué fijar | Validación esperada |
|---|---|---|
| D1 | Redis 6.2.6 sin auth | `redis-cli -h 10.10.10.12` entra sin clave → PoC Lua → shell |
| D2 | Claves débiles + Redis sin auth | Login `wp_user`/`moodle_user`, volcado de BD |
| D3 | 6379 (y 3306 mal filtrado) a la LAN | `nmap -p 3306,6379` open desde pivote |
| D4 | SNMP `public`/`private` | `snmpwalk -v2c -c public` enumera; `snmpset` con `private` escribe |

## 6. Snapshots y entrega

- `estado-inicial-vulnerable`, `estado-parcheado` (Redis ≥6.2.7 + `requirepass` + `bind 127.0.0.1`, claves fuertes, firewall solo M1).
- Evidencia por D1–D3 + retest.
