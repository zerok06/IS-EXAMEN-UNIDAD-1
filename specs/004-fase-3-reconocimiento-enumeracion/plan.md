# Plan 004 · Reconocimiento, escaneo y enumeración

## 1. Enfoque

Primero descubrimiento, luego puertos, después versiones, al final enumeración y correlación. Todo read-only. Se guarda una captura y un log por comando.

## 2. Descubrimiento

```bash
ip -brief a
ip route
ping -c 2 10.10.10.11
nmap -sn 10.10.10.0/24
```

## 3. Puertos y versiones

```bash
nmap -sV -Pn -p 22,80,443,3306,6379,21,139,445,2049,53,3389,5900 10.10.10.11-15
nmap -sV -Pn -p 80 --version-light --host-timeout 30s 10.10.10.11
curl -sI http://10.10.10.11
```

## 4. Enumeración

```bash
# Web
wpscan --url http://10.10.10.11 --enumerate u,vp,vt --max-threads 4
whatweb http://10.10.10.11
nikto -h http://10.10.10.11

# WordPress config
curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/server-status
curl -s http://wp.uni.lab/info.php | grep -i 'PHP Version'
curl -s http://wp.uni.lab/wp-content/uploads/ | grep -i 'Index of'

# M2
redis-cli -h 10.10.10.12 INFO server | grep redis_version
nmap -sT -p 3306,6379,161 10.10.10.12

# M3
smbclient -L //10.10.10.13 -N
showmount -e 10.10.10.13
nmap -sT --script ftp-anon,smb-protocols 10.10.10.13

# M4
dig axfr uni.lab @10.10.10.14
nmap -sT --script smb-security-mode,smb-vuln-ms17-010 -p 445 10.10.10.14

# M5
nmap -sT --script vnc-info -p 5900 10.10.10.15
nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.15
```

## 5. Correlación

| Servicio | Versión | ID | CVE/CWE | CVSS | Fuente |
|---|---|---|---|---|---|
| WordPress | 7.0.1 | W1 | CVE-2026-63030 | 9.8 | NVD |
| PHP | 8.4.26 | W2 | CVE-2026-109618/19 | 9.8/8.1 | NVD |
| Apache | 2.4.49 | W3 | CVE-2021-41773 | 9.8 | NVD |
| Redis | 6.2.6 | D1 | CVE-2022-0543 | 10.0 | NVD |
| Samba | 4.5.9 | B1 | CVE-2017-7494 | 9.8 | NVD |
| vsftpd | 2.3.4 | B2 | CVE-2011-2523 | 9.8 | NVD |
| SMB | WS2016 | S1 | CVE-2017-0144 | 8.8 | NVD |
| Spooler | WS2016 | S2 | CVE-2021-34527 | 8.8 | NVD |
| VNC | 2.8.90 | C4 | CWE-306 | ~9.8 | CWE |

## 6. Evidencia

| ID | Qué demuestra |
|---|---|
| `EV-004-01` | Hosts activos |
| `EV-004-02` | Puertos M1–M5 |
| `EV-004-03` | Versiones Apache/PHP/WP |
| `EV-004-04` | Correlación CVE |
| `EV-004-05` | Enumeración SMB/DNS/NFS/FTP |
| `EV-004-06` | Desviación de firewall |

## 7. Snapshots

No se toman snapshots en Fase 3: es read-only. Se conserva `estado-inicial-vulnerable`.

## 8. Definición de terminado

- [ ] Inventario completo.
- [ ] Versiones confirmadas.
- [ ] Correlación CVE/CWE.
- [ ] Evidencias con hash.
- [ ] `MEMORY.md` actualizado.

## 9. Estimación

| Actividad | Horas |
|---|---|
| Descubrimiento y puertos | 1.0 |
| Versiones y enumeración | 1.5 |
| Correlación y evidencia | 1.0 |
| **Total** | **3.5** |
