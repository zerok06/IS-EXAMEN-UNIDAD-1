# Plan 006 · Remediación

## 1. Enfoque

Se restaura `estado-inicial-vulnerable`, se aplica la medida por máquina y se registra el cambio. Las versiones se actualizan donde existe parche; el resto se cierra por configuración. Las versiones corregidas están en `~/artifacts/fixed/` (spec `000`). Al final se toma `estado-parcheado`.

## 2. M1 · Aplicación

```bash
# W1: WordPress 7.0.2
wp core update --version=7.0.2 --force
wp core version

# W2: PHP 8.4.27 (recompilar) o mitigación temporal
# ./configure ... && make && sudo make install
# php.ini: session.upload_progress.enabled = Off (temporal)
php -v

# W3: Apache 2.4.51+
# compilar/instalar; o denegar CGI
# <Directory "/usr/local/apache2/cgi-bin"> Require all denied </Directory>
httpd -v

# W4 + SSH
wp user update usc.admin --user_pass='ClaveFuerte_2026!'
passwd ubuntu
# PermitRootLogin no; sudoers restringido

# W5/W6/W7
# server-status: Require ip 127.0.0.1
sudo rm -f /var/www/wp/info.php
# uploads: Options -Indexes
```

## 3. M2 · Base de datos

```bash
# Redis 6.2.7+ y requirepass
sudo sed -i 's/^bind .*/bind 127.0.0.1/' /etc/redis/redis.conf
sudo sed -i 's/^# requirepass .*/requirepass ClaveLarga123!/' /etc/redis/redis.conf
sudo systemctl restart redis
redis-cli PING   # NOAUTH

# MariaDB
mysql --skip-ssl -u root -e "ALTER USER 'wp_user'@'10.10.10.11' IDENTIFIED BY 'NuevaWP_2026!';"
# actualizar wp-config.php y Moodle

# UFW
sudo ufw allow from 10.10.10.11 to any port 3306 proto tcp
sudo ufw deny 6379/tcp
sudo ufw deny 161/udp

# SNMPv3/ACL
# eliminar rocommunity public / rwcommunity private
```

## 4. M3 · Respaldos

```bash
# B1: Samba 4.5.10+; SMB1 off
smbd --version
# smb.conf: server min protocol = SMB2

# B2/B3: vsftpd limpio/3.x; anonymous_enable=NO
sudo systemctl stop vsftpd-lab
# o reemplazar por 3.x

# B3: backups cifrados; sacar credenciales.txt
gpg --encrypt --recipient lab@uni.lab /srv/storage/backups/*.sql.gz
sudo rm /srv/storage/backups/credenciales.txt

# B4: root_squash
sudo sed -i 's/no_root_squash/root_squash/' /etc/exports
sudo exportfs -ra

# B5: SSH
passwd rony123
```

## 5. M4 · Windows

```powershell
# S1
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
# instalar MS17-010

# S2
Set-Service Spooler -StartupType Disabled
Stop-Service Spooler

# S3
net user Administrador "M4_Admin_2026!"
net user soporte "SoporteFuerte_2026!"
# o eliminar soporte

# S4
# DNS → zona uni.lab → Transferencias → solo NS autorizados

# S5
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
# GPO: LLMNR/NBT-NS OFF
```

## 6. M5 · Cliente

```powershell
# C1: parches + SMB1 off
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

# C2
net user cliente "ClienteM5_2026!"

# C3
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1

# C4
# TightVNC: password fuerte + localhost + firewall, o desinstalar
```

## 7. Registro de cambios

| Fecha UTC | VM | Hallazgo | Antes | Después | Responsable | Evidencia |
|---|---|---|---|---|---|---|
| — | M1 | W1 | WP 7.0.1 | WP 7.0.2 | — | — |
| — | M1 | W2 | PHP 8.4.26 | PHP 8.4.27 | — | — |
| — | M1 | W3 | Apache 2.4.49 | Apache 2.4.51+ | — | — |
| — | M2 | D1 | Redis 6.2.6 sin auth | Redis 6.2.7+ con auth | — | — |
| — | M3 | B1 | Samba 4.5.9 | Samba 4.5.10+ | — | — |
| — | M4 | S2 | Spooler activo | Spooler off/parcheado | — | — |

## 8. Snapshots

| Snapshot | Cuándo | Para qué |
|---|---|---|
| `estado-parcheado` | Tras aplicar todo | Demo del después |
| `previo-a-parche-<ID>` | Antes de un cambio riesgoso | Rollback |

## 9. Definición de terminado

- [ ] Cada hallazgo con medida.
- [ ] Versiones/configuración final registradas.
- [ ] `estado-parcheado` tomado.
- [ ] Registro de cambios completo.
- [ ] `MEMORY.md` actualizado.

## 10. Estimación

| Máquina | Horas |
|---|---|
| M1 | 3.0 |
| M2 | 1.0 |
| M3 | 1.0 |
| M4 | 1.5 |
| M5 | 0.5 |
| **Total** | **7.0** |
