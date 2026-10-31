# Bitácora · Fase 6 · Mitigación (M2)

Fecha UTC: 2026-10-24 · Ejecuta: M6 + SSH a M2 (`adminm2`) y M1 (`ubuntu`)

| ID | Comando | Explicación | Salida real (resumen) | Evidencia |
|---|---|---|---|---|
| CMD-F06-010 | `cp /etc/redis.conf ...bak...; echo 'requirepass ...' >> /etc/redis.conf; systemctl restart redis` | D1: exige contraseña | `PING` sin clave → `NOAUTH`; con clave → `PONG` | `F06-008` |
| CMD-F06-011 | `mariadb -e "ALTER USER 'wp_user'@'10.10.10.11' ...; ALTER USER 'moodle_user'@...; FLUSH PRIVILEGES;"` | D2: rota claves DB | `rc=0` | `F06-008` |
| CMD-F06-012 | `sed -i s/wp_pass123/.../g wp-config.php config.php` en M1 | D2: actualiza app | `DB_PASSWORD` y `dbpass` nuevas | `F06-008` |
| CMD-F06-013 | `ufw delete allow 6379/tcp; ufw allow from 10.10.10.11 to any port 6379` + igual para `161/udp` | D3: solo M1 | `6379` y `161` solo `10.10.10.11` | `F06-008` |
| CMD-F06-014 | `sed -i ... snmpd.conf` (elimina `public`/`private`); `systemctl restart snmpd` | D4: comunidades largas | solo `rocommunity` larga; `active` | `F06-008` |

**Nota:** las claves nuevas son de laboratorio (ver logs). Versiones sin cambiar: Redis 6.2.6, MariaDB 10.11.19.
