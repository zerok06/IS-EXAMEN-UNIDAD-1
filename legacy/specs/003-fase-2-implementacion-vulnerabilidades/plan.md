# Plan 003 · Implementación de vulnerabilidades

## 1. Enfoque

Se implantan primero las versiones y configuraciones, luego se verifica su presencia con comandos read-only, y al final se toma `estado-inicial-vulnerable`. No se explota nada. Los tarballs están en `~/artifacts/vulnerable/` (spec `000`).

## 2. M1 · Aplicación

### Versiones

```bash
# WordPress 7.0.1
wp core version
# PHP 8.4.26 (mod_php)
php -v
# Apache 2.4.49
/usr/local/apache2/bin/httpd -v
```

### W2 · PHP2Shell

```bash
# Verificar SAPI y MPM
/usr/local/apache2/bin/httpd -V | grep MPM
/usr/local/bin/php -i | grep -E 'Thread Safety|Server API|memory_limit|display_errors|session.upload_progress.enabled'
```

Condiciones:

- MPM **prefork**.
- PHP **NTS** si es posible; si el build es ZTS, recompilar sin `--enable-zts`.
- `memory_limit = 8M`, `display_errors = On`, `session.upload_progress.enabled = On`.
- `max_input_vars = 1000`, `session.use_strict_mode = 0`.

### W3 · Apache 2.4.49

```apache
LoadModule cgi_module modules/mod_cgi.so
ScriptAlias /cgi-bin/ "/usr/local/apache2/cgi-bin/"
<Directory "/usr/local/apache2/cgi-bin">
    AllowOverride None
    Options +ExecCGI
    Require all granted
</Directory>
```

```bash
# Debe responder 200/403, no 503
curl -s -o /dev/null -w '%{http_code}\n' http://10.10.10.11/cgi-bin/
```

### W4–W7

```bash
# W4: login débil
curl -s -c /tmp/wp.cookies http://wp.uni.lab/wp-login.php -o /dev/null
curl -s -b /tmp/wp.cookies -D - -o /dev/null \
  -d 'log=usc.admin&pwd=Admin13.-&wp-submit=Log+In&testcookie=1' \
  http://wp.uni.lab/wp-login.php | grep -E 'HTTP/|Location:'

# W5/W6/W7
curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/server-status
curl -s http://wp.uni.lab/info.php | grep -i 'PHP Version'
curl -s http://wp.uni.lab/wp-content/uploads/ | grep -i 'Index of'
```

## 3. M2 · Base de datos

```bash
redis-server --version
redis-cli -h 10.10.10.12 PING
mariadb --version
mysql --skip-ssl -h 10.10.10.12 -u wp_user -p'wp_pass123' -e 'SELECT 1;'
nmap -sT -p 3306,6379,161 10.10.10.12
snmpwalk -v2c -c public 10.10.10.12 system
```

**D1:** si se quiere CVE-2022-0543, instalar `redis-server` del repo distro y verificar `dpkg -l redis-server`. Si se mantiene el build de fuente, documentar que D1 no es reproducible y sostener M2 con D2/D3/D4.

**D2:** crear `wp_user`/`moodle_user` con `wp_pass123` solo desde `.11`.

**D3:** UFW con 6379/161 abiertos a la LAN y 3306 solo desde M1.

**D4:** `rocommunity public` + `rwcommunity private`.

## 4. M3 · Respaldos

```bash
# B1: Samba 4.5.9 (NO 4.5.10)
smbd --version
smbclient -L //10.10.10.13 -N

# B3: FTP anónimo
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt

# B4: NFS no_root_squash
showmount -e 10.10.10.13
exportfs -v

# B5: SSH débil (si B1/B2 no son reales)
sshpass -p 'rony123' ssh rony123@10.10.10.13 'id'
```

Si no se puede compilar 4.5.9, usar B3 + B4 + B5 y documentar B1 como “no explotable”.

## 5. M4 · Windows

```powershell
# S3: admin débil + usuario limitado
net user Administrador password_2026
net user soporte Soporte123! /add
net localgroup "Remote Management Users" soporte /add
Enable-PSRemoting -Force

# S2: Spooler
Set-Service Spooler -StartupType Automatic
Start-Service Spooler

# S4: AXFR abierto
# DNS → zona uni.lab → Transferencias → cualquier servidor

# S5: signing off
Set-SmbServerConfiguration -RequireSecuritySignature $false -Force

# S1: solo si se va a demostrar
Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
```

Verificación:

```bash
nxc smb 10.10.10.14 -u Administrador -p 'password_2026' --shares
nxc winrm 10.10.10.14 -u soporte -p 'Soporte123!' -x whoami
dig axfr uni.lab @10.10.10.14
nmap -sT --script smb-security-mode -p 445 10.10.10.14
nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.14
```

## 6. M5 · Cliente

```powershell
# C2: clave reutilizada
net user cliente Admin13.-

# C3: RDP sin NLA
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 0

# C4: VNC sin clave
# TightVNC → Authentication None → servicio tvnserver
```

Verificación:

```bash
nxc smb 10.10.10.15 -u cliente -p 'Admin13.-' --shares
nmap -sT --script vnc-info -p 5900 10.10.10.15
xfreerdp /v:10.10.10.15 /u:cliente /p:'Admin13.-' /cert:ignore
```

**C1:** verificar `winver`; si es 19045, no contar EternalBlue.

## 7. Evidencia

| Máquina | Evidencia | Qué demuestra |
|---|---|---|
| M1 | `EV-003-M1-*` | WP 7.0.1 / PHP 8.4.26 / Apache 2.4.49 / W4–W7 |
| M2 | `EV-003-M2-*` | Redis sin auth / DB débil / SNMP |
| M3 | `EV-003-M3-*` | Samba 4.5.9 / FTP anónimo / NFS |
| M4 | `EV-003-M4-*` | Admin débil / `soporte` / AXFR / signing |
| M5 | `EV-003-M5-*` | Clave reutilizada / RDP / VNC |

## 8. Snapshots

| Snapshot | Cuándo | Para qué |
|---|---|---|
| `estado-inicial-vulnerable` | Tras verificar todo | Demo y Fase 4 |
| `previo-a-<ID>` | Antes de cada PoC | Fase 4 |

## 9. Definición de terminado

- [ ] ≥3 vulnerabilidades por máquina.
- [ ] Versiones y configuraciones registradas.
- [ ] Evidencias de presencia.
- [ ] `estado-inicial-vulnerable` tomado.
- [ ] `MEMORY.md` actualizado.

## 10. Estimación

| Máquina | Horas |
|---|---|
| M1 | 3.0 |
| M2 | 1.5 |
| M3 | 2.5 |
| M4 | 2.0 |
| M5 | 1.0 |
| **Total** | **10.0** |
