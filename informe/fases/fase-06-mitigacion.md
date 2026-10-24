# Fase 6 · Mitigación

**Objetivo:** aplicar la corrección a cada hallazgo y registrar el cambio.
**Estado:** ⬜ pendiente de ejecución (M4/M5 apagadas; M1–M3 listas).
**Regla:** snapshot `estado-inicial-vulnerable` antes de tocar; `estado-parcheado` al terminar; retest obligatorio.

---

## 6.1 M1 · Aplicación

```bash
# W1: WordPress 7.0.2+
wp core update --version=7.0.2
wp core version

# W2: PHP 8.4.27+ (recompilar) o mitigación temporal
# session.upload_progress.enabled=0 en /usr/local/lib/php.ini

# W3: Apache 2.4.50+ o denegar CGI
# En httpd.conf: <Directory "/usr/local/apache2/cgi-bin"> Require all denied

# W5/W6/W7
sudo sed -i 's/Require all granted/Require ip 127.0.0.1/' /usr/local/apache2/conf/extra/lab-vhosts.conf
sudo rm -f /var/www/wp/info.php
# quitar +Indexes de uploads en lab-vhosts.conf

# W4 + M1-SSH: claves únicas, 2FA, sudo restringido
passwd ubuntu
```

**Verificación:** `wp core version` 7.0.2; `php -v` 8.4.27; `httpd -v` 2.4.50; W5/W6/W7 403/404; login viejo falla.

---

## 6.2 M2 · Base de datos

```bash
# D1: Redis con contraseña y bind local
sudo sed -i 's/^bind .*/bind 127.0.0.1/' /etc/redis/redis.conf
sudo sed -i 's/^# requirepass .*/requirepass ClaveLarga123!/' /etc/redis/redis.conf
sudo systemctl restart redis

# D2: claves únicas
mysql --skip-ssl -u root -e "ALTER USER 'wp_user'@'10.10.10.11' IDENTIFIED BY 'NuevaClaveWP!';"

# D3: firewall solo M1
sudo ufw allow from 10.10.10.11 to any port 3306 proto tcp
sudo ufw deny 6379/tcp

# D4: SNMPv3/ACL
# rocommunity con ACL o migrar a SNMPv3
```

**Verificación:** `redis-cli PING` → `NOAUTH`; `nmap` → 3306/6379/161 filtered.

---

## 6.3 M3 · Respaldos

```bash
# B2/B3: quitar vsftpd 2.3.4 y anónimo
sudo systemctl stop vsftpd-lab
sudo apt remove vsftpd
# o configurar anonymous_enable=NO

# B4: root_squash
sudo sed -i 's/no_root_squash/root_squash/' /etc/exports
sudo exportfs -ra

# B1: Samba soportado + SMB1 OFF
# actualizar a rama soportada; server min protocol = SMB2

# B3: backups cifrados y sin credenciales
# gpg --encrypt ...; mover credenciales.txt fuera del share
```

**Verificación:** `:6200` cerrado; `530`; `showmount` sin `no_root_squash`; `smbclient -L` sin `backups` anónimo.

---

## 6.4 M4 · Windows Server

```powershell
# S1
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
# Instalar MS17-010 (o actualizar)

# S2
Set-Service Spooler -StartupType Disabled

# S3
net user Administrator "ClaveLarga123!"
# LAPS

# S4
# DNS -> zona uni.lab -> Transferencias -> solo NS autorizados

# S5
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
# GPO: deshabilitar LLMNR/NBT-NS
```

**Verificación:** `smb-vuln-ms17-010` limpio; `smb-security-mode` signing required; `dig axfr` REFUSED; `nxc` falla.

---

## 6.5 M5 · Estación cliente

```powershell
# C1
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

# C2
net user cliente "ClaveLarga123!"
# LAPS

# C3
# RDP con NLA: UserAuthentication=1; actualizar software

# C4
# TightVNC: password fuerte + solo localhost + firewall, o desinstalar
```

**Verificación:** VNC pide clave; 445 filtered; RDP con NLA; credencial vieja falla.

---

## 6.6 Cierre

- [ ] Snapshot `estado-parcheado` en M1–M5.
- [ ] Registro de cambios en `06-remediacion.md`.
- [ ] Retest en `07-retest.md`.
- [ ] Evidencia antes/después por hallazgo.
