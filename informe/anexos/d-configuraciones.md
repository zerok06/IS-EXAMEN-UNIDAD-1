# Anexo D · Configuraciones clave

**Objetivo:** dejar el “antes” exacto que explica cada vulnerabilidad. El “después” se agrega al aplicar la fase 6.

---

## D.1 M1 · Apache

`/usr/local/apache2/conf/extra/lab-vhosts.conf` (real):

```apache
ServerName wp.uni.lab

<VirtualHost *:80>
    ServerName wp.uni.lab
    ServerAlias www.wp.uni.lab
    DocumentRoot "/var/www/wp"
    <Directory "/var/www/wp">
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

# W5 INTENCIONAL (laboratorio): server-status expuesto
<Location /server-status>
    SetHandler server-status
    Require all granted
</Location>

# W7 INTENCIONAL (laboratorio): listado en uploads
<Directory "/var/www/wp/wp-content/uploads">
    Options +Indexes
    Require all granted
</Directory>
```

`/usr/local/apache2/conf/httpd.conf`:

```apache
LoadModule cgid_module modules/mod_cgid.so
ScriptAlias /cgi-bin/ "/usr/local/apache2/cgi-bin/"
<Directory "/usr/local/apache2/cgi-bin">
    AllowOverride None
    Options Indexes FollowSymLinks
    Require all granted
</Directory>
```

**Lectura:** W5 y W7 son intencionales. W3 tiene `ScriptAlias` y `Require all granted`, pero `mod_cgid` no tiene daemon/socket operativo → 503 (no explotable).

---

## D.2 M1 · PHP

`/usr/local/lib/php.ini` (real):

```ini
memory_limit = 512M
session.upload_progress.enabled = On
session.upload_progress.cleanup = On
```

**Lectura:** `upload_progress` está activo (precondición de W2). PHP es **8.4.26 ZTS**; el PoC de PHP2Shell se calibró en NTS.

---

## D.3 M1 · `wp-config.php`

```php
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wp_user' );
define( 'DB_PASSWORD', 'wp_pass123' );
define( 'DB_HOST', '10.10.10.12' );
define( 'WP_HOME', 'http://wp.uni.lab' );
define( 'WP_SITEURL', 'http://wp.uni.lab' );
```

**Lectura:** `DISALLOW_FILE_EDIT` **no** está definido; el admin puede editar archivos. La clave `wp_pass123` es la que se usa en D2. `wp-config.php` fue leído desde M1 con `sudo`.

---

## D.4 M2 · Redis

```conf
bind 0.0.0.0
protected-mode yes
# requirepass no configurado
```

**Verificado por CLI:**

```text
CONFIG GET bind          → 0.0.0.0
CONFIG GET protected-mode → yes
CONFIG GET requirepass    → (vacío)
```

**Lectura:** `protected-mode yes` no ayuda porque `bind 0.0.0.0` y no hay `requirepass`; el acceso sin auth funciona. `enable_strict_lua` bloquea `package` → CVE-2022-0543 no reproducible.

---

## D.5 M2 · MariaDB

```sql
CREATE USER 'wp_user'@'10.10.10.11' IDENTIFIED BY 'wp_pass123';
CREATE USER 'moodle_user'@'10.10.10.11' IDENTIFIED BY 'wp_pass123';
GRANT ALL ON wordpress.* TO 'wp_user'@'10.10.10.11';
GRANT ALL ON moodle_db.* TO 'moodle_user'@'10.10.10.11';
```

**Verificado:** `wordpress` 12 tablas; `moodle_db` 487 tablas; acceso por túnel SSH desde M1.

---

## D.6 M3 · NFS

`/etc/exports` (real):

```text
/srv/storage/backups  10.10.10.0/24(rw,sync,no_subtree_check,no_root_squash)
```

**Lectura:** B4 validado: un root remoto escribe como root en `/srv/storage/backups`.

---

## D.7 M3 · Samba

`/usr/local/samba/etc/smb.conf` (real, extracto):

```ini
[backups]
    path = /srv/storage/backups
    read only = no
    guest ok = yes
```

**Lectura:** recurso escribible e invitado. Samba **4.5.10** es la versión que corrige CVE-2017-7494; B1 no explotable.

---

## D.8 M3 · vsftpd

```conf
anonymous_enable=YES
# 2.3.4 compilado de tarball limpio
```

**Lectura:** B3 validado (anónimo); B2 no (sin backdoor `:6200`).

---

## D.9 M4 / M5

Pendiente de encender las VM. Se documentarán:

- M4: `Get-SmbServerConfiguration`, `Get-Service Spooler`, reglas de firewall, zona DNS.
- M5: `Get-SmbServerConfiguration`, TightVNC `auth None`, RDP `UserAuthentication=0`, firewall.

---

## D.10 Cambios de la fase 6

| Fecha | Máquina | Config antes | Config después | Evidencia |
|---|---|---|---|---|
| — | — | — | — | — |
