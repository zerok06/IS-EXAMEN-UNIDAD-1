# Plan 002 · Montaje del entorno

## 1. Enfoque

Se monta de abajo hacia arriba: M4 DNS, M2 DB, M3 storage, M1 app, M5 cliente, M6 auditor. Cada dependencia se verifica antes de pasar a la siguiente. No se implantan vulnerabilidades todavía. Los instaladores se descargan de `~/artifacts` (spec `000`).

## 2. Orden de montaje

| # | VM | Servicio | Verificación |
|---|---|---|---|
| 1 | M4 | DNS standalone `uni.lab` | `dig wp.uni.lab @10.10.10.14` |
| 2 | M2 | MariaDB + Redis + SNMP | `mariadb --version`; `redis-cli PING` |
| 3 | M3 | NFS + Samba + vsftpd + backups | `exportfs -v`; `smbclient -L` |
| 4 | M1 | Apache + PHP + WP + Moodle + NFS | `curl`; `findmnt`; `DB_OK` |
| 5 | M5 | Cliente + navegador + SMB/RDP/VNC | `curl`; `Test-NetConnection` |
| 6 | M6 | Kali + herramientas | `nmap`, `wpscan`, `nxc`, `msf` |
| 7 | R0 | Router aislado | captura de configuración |

## 3. Verificación por máquina

### M4 · DNS / SMB / Spooler

```powershell
Get-DnsServerZone
Resolve-DnsName wp.uni.lab
Get-Service Spooler
Get-SmbShare
```

### M2 · DB / Redis / SNMP

```bash
mariadb --version
redis-server --version
redis-cli -h 10.10.10.12 PING
ss -uln | grep 161
```

### M3 · NFS / Samba / FTP

```bash
exportfs -v
smbd --version
smbclient -L //10.10.10.13 -N
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt
```

### M1 · Web / DB / NFS

```bash
curl -sI http://10.10.10.11
curl -sI http://moodle.uni.lab
wp core version
findmnt -t nfs
mysql --skip-ssl -h 10.10.10.12 -u wp_user -p'wp_pass123' -e 'SELECT 1;'
```

### M5 · Cliente

```powershell
curl.exe -sI http://10.10.10.11
Test-NetConnection 10.10.10.11 -Port 80
Test-NetConnection 10.10.10.11 -Port 445
```

### M6 · Kali

```bash
nmap --version
wpscan --version
nxc --version
msfconsole -v
proxychains4 -q echo OK
```

## 4. Snapshots

| Snapshot | Cuándo | Para qué |
|---|---|---|
| `01-rol-listo` | Tras verificar servicios | Reinstalar rápido |
| `estado-inicial-vulnerable` | Tras Fase 2 | Demo |

## 5. Evidencia

- `EV-002-01` … `EV-002-07` por dependencia.
- `LOG-002-*` con salidas completas.
- Captura de `findmnt`, `DB_OK`, `ls backups`, `dig`, `curl`.

## 6. Riesgos y rollback

| Riesgo | Acción |
|---|---|
| M4 inestable | Reiniciar; restaurar `00-base`; documentar |
| NFS no monta | Revisar `/etc/exports`, UFW y `nfs-common` |
| Backups no llegan | Revisar llave, cron y permisos |
| DNS no resuelve | Revisar zona, puerto 53 y firewall |
| Servicio no arranca al boot | `systemctl enable`; documentar |

## 7. Definición de terminado

- [ ] Dependencias verificadas.
- [ ] Versiones registradas.
- [ ] `01-rol-listo` tomado.
- [ ] Evidencias en `informe/evidencias/`.
- [ ] `MEMORY.md` actualizado.

## 8. Estimación

| Actividad | Horas |
|---|---|
| M4 + M2 + M3 | 2.0 |
| M1 + M5 + M6 | 2.0 |
| Verificación y evidencia | 1.0 |
| **Total** | **5.0** |
