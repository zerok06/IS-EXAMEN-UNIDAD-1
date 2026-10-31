# Guía M1 · Servidor de aplicación (Estudiante 1)

**Rol:** publicar WordPress + Moodle. **Puerta de entrada** del ataque (única visible desde fuera).

> Versión automatizada: [`ansible/play-m1-app.yml`](../ansible/play-m1-app.yml) (ver [`ansible/README-AUTO.md`](../ansible/README-AUTO.md)). Esta guía es la referencia manual de lo mismo.

## Estado real de la implementación (validado 2026-10-24)

| Componente | Estado real |
|---|---|
| Apache | **2.4.49** compilado en `/usr/local/apache2`; servicio `apache-lab` (enabled/active); corre como `www-data`; `mod_rewrite` + `mod_status` + `mod_cgid` activos; `Include conf/extra/lab-vhosts.conf` (línea 517) |
| PHP | **8.4.26** (ZTS) con `gd`, `sodium`, `exif`, `intl`, `zip`, `mysqli`; configuración en `/usr/local/lib/php.ini`; `session.upload_progress.enabled=On` |
| VirtualHosts | `conf/extra/lab-vhosts.conf`: `wp.uni.lab` → `/var/www/wp`, `moodle.uni.lab` → `/var/www/moodle`; más bloques W5 (Location `/server-status`) y W7 (`+Indexes` en uploads) |
| WordPress | **7.0.1** con wp-cli; sitio **Universidad Sideral Carrión** (tema `usc-oficial` 1.0.0, logo + 4 fotos propias); admin `usc.admin`; 6 páginas + 5 entradas + menú `Principal` con Campus Virtual |
| Moodle | **5.0.11**; tema hijo `boost_usc` (hero + pie institucional, logo propio); idioma `es`; 5 cursos con imagen, 3 docentes, 6 alumnos; accesos en §7 |
| BD | `wordpress` (12 tablas) y `moodle_db` (487 tablas) en M2, usuario de app desde `10.10.10.11` |
| Storage | NFSv4 desde M3 montado en `wp-content/uploads` y `moodledata`; subida real verificada con miniaturas |
| Pendiente | MPM `event` con mod_php (cambiar a prefork), PHP ZTS (los PoC se calibraron en NTS), TLS |

## 0. Imagen base e instaladores (descargar ANTES de aislar)

| Qué | Versión exacta | Dónde (verificado 2026-10-24) |
|---|---|---|
| Ubuntu Server | **22.04.5** `ubuntu-22.04.5-live-server-amd64.iso` | https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso |
| Apache httpd | **2.4.49** `httpd-2.4.49.tar.gz` (W3) | https://archive.apache.org/dist/httpd/httpd-2.4.49.tar.gz |
| PHP | **8.4.26** `php-8.4.26.tar.gz` mod_php (W2) | https://www.php.net/distributions/php-8.4.26.tar.gz |
| WordPress | **7.0.1** `wordpress-7.0.1.zip` (W1) | https://wordpress.org/wordpress-7.0.1.zip |
| Moodle | **v5.0.11** (compatible MariaDB 10.11 y PHP 8.4) | https://github.com/moodle/moodle/archive/refs/tags/v5.0.11.tar.gz |

Verificar la ISO (en tu laptop, antes de instalar):

```powershell
Get-FileHash .\ubuntu-22.04.5-live-server-amd64.iso -Algorithm SHA256
# comparar con https://releases.ubuntu.com/22.04/SHA256SUMS
```

VMware: Workstation Player/Pro 17+, VM Ubuntu 64-bit, 2 vCPU / 4 GB / 40 GB, red en **bridge al lado INTERNO**.

## 1. VM y red

- Ubuntu Server 22.04 · 2 vCPU · 4 GB · 40 GB. VMware en **bridge al lado INTERNO**.
- Red estática (`/etc/netplan/01-lab.yaml`):

```yaml
network:
  version: 2
  ethernets:
    ens33:  # verificar nombre con: ip -brief a
      addresses: [10.10.10.11/24]
      routes:
        - to: default
          via: 10.10.10.1
      nameservers:
        addresses: [10.10.10.14]
        search: [uni.lab]
```

```bash
sudo netplan apply
ping -c 2 10.10.10.1 && ping -c 2 10.10.10.12 && ping -c 2 10.10.10.13
```

## 2. Servicios (versiones FIJADAS como vulnerables)

```bash
# Dependencias de compilación (con Internet ANTES de aislar)
sudo apt update && sudo apt install -y build-essential pkg-config \
  apr apr-util libapr1-dev libaprutil1-dev pcre2-utils libpcre2-dev \
  libxml2-dev libsqlite3-dev libcurl4-openssl-dev libonig-dev libzip-dev \
  libpng-dev libjpeg-dev libfreetype6-dev libicu-dev unzip nfs-common

# Apache 2.4.49 EXACTO (W3: CVE-2021-41773) con mod_so para cargar PHP
tar xzf httpd-2.4.49.tar.gz && cd httpd-2.4.49
./configure --prefix=/usr/local/apache2 --enable-so --enable-cgi --enable-rewrite --enable-status
make -j$(nproc) && sudo make install
/usr/local/apache2/bin/httpd -v   # debe decir 2.4.49

# PHP 8.4.26 como mod_php (W2: PHP2Shell, SAPI Apache2Handler)
cd .. && tar xzf php-8.4.26.tar.gz && cd php-8.4.26
./configure --with-apxs2=/usr/local/apache2/bin/apxs \
  --with-mysqli --with-pdo-mysql --with-curl --with-openssl --with-zip \
  --enable-mbstring --enable-intl --enable-gd --with-external-gd \
  --with-jpeg --with-freetype --enable-exif --with-sodium \
  --enable-opcache --with-zlib
make -j$(nproc) && sudo make install
php -v   # debe decir 8.4.26
# /usr/local/lib/php.ini: session.upload_progress.enabled=On (defecto, vulnerable)

# Activar PHP en Apache
echo 'LoadModule php_module modules/libphp.so
AddType application/x-httpd-php .php
DirectoryIndex index.php index.html' | sudo tee /usr/local/apache2/conf/extra/php.conf
echo 'Include conf/extra/php.conf' | sudo tee -a /usr/local/apache2/conf/httpd.conf
sudo /usr/local/apache2/bin/apachectl start
```

```bash
# Errores de configuración intencionales (W5-W7):
sudo a2enmod status info
# /etc/apache2/mods-enabled/status.conf -> Require all granted (W5: expuesto)
echo '<?php phpinfo();' | sudo tee /var/www/wp/info.php        # W6: disclosure
# Directory /var/www/wp/wp-content/uploads -> Options +Indexes  # W7: listado
sudo systemctl reload apache2
```

- WordPress **7.0.1** en `/var/www/wp` → `http://wp.uni.lab` (**W1: wp2shell CVE-2026-63030**; NO actualizar hasta Fase 5).
- Moodle **v5.0.11** en `/var/www/moodle` → `http://moodle.uni.lab` (admin con clave débil = W4).

```bash
cd /tmp
unzip -q -o wordpress-7.0.1.zip
sudo rm -rf /var/www/wp && sudo cp -a wordpress /var/www/wp
tar xzf moodle-v5.0.11.tar.gz
sudo rm -rf /var/www/moodle && sudo mv moodle-5.0.11 /var/www/moodle
sudo chown -R www-data:www-data /var/www/wp /var/www/moodle  # si no existe: sudo useradd -r -s /usr/sbin/nologin www-data
# y en httpd.conf: User www-data + Group www-data (el shell del PoC será uid de www-data)
# Instalación: wp-cli (WP) y admin/cli/install.php (Moodle) — ver play-m1-app.yml
# wp core version  -> debe decir 7.0.1 ; phpMyAdmin NO se instala (superficie mínima)
```
- `wp-config.php`: `DB_HOST 10.10.10.12`, `WP_HOME http://wp.uni.lab`.

## 3. NFS contra M3 (coherencia del escenario)

```bash
sudo apt install -y nfs-common
# /etc/fstab:
10.10.10.13:/srv/storage/wp-uploads  /var/www/wp/wp-content/uploads  nfs  rw,hard,_netdev  0 0
10.10.10.13:/srv/storage/moodledata  /var/www/moodledata             nfs  rw,hard,_netdev  0 0
sudo mount -a && findmnt -t nfs
```

## 4. Firewall (M1 SÍ expone web: R0 la publica fuera)

```bash
sudo ufw allow 80,443/tcp
sudo ufw allow from 10.10.10.0/24 to any port 22 proto tcp
sudo ufw enable
```

## 5. Tus vulnerabilidades (implantar y documentar)

| ID | Qué fijar | Validación esperada desde M6 |
|---|---|---|
| W1 | WP 7.0.1, REST anónima ON | PoC `/wp-json/batch/v1` → admin + plugin → shell |
| W2 | PHP 8.4.26, `X-Powered-By` visible | PoC multipart `PHP_SESSION_UPLOAD_PROGRESS` → `uid=33(www-data)` |
| W3 | Apache 2.4.49 con CGI | `curl .../%2e/cgi-bin/` → traversal/RCE |
| W4 | `wp-admin` clave débil | `wpscan --passwords` / login manual |
| W5 | `server-status` abierto | `curl …/server-status` muestra workers |
| W6 | `info.php` público | Navegar `…/info.php` → versión PHP |
| W5 | `server-status` abierto (Location + exclusión en `.htaccess` de WP) | `curl …/server-status` → 200 con workers |
| W6 | `info.php` público | Navegar `…/info.php` → 200, versión PHP |
| W7 | `+Indexes` en uploads (bloque Directory en `lab-vhosts.conf`) | `curl …/wp-content/uploads/` → 200 `Index of` |

> W5 y W7 se implantaron el 2026-10-24 (no venían activos: `mod_status` estaba cargado pero sin `Location`, y WP secuestraba `/server-status` vía `.htaccess`; uploads devolvía 403). W3 exigió descomentar `LoadModule cgid_module` (MPM event usa `cgid`, no `cgi`) — `/cgi-bin/` pasó de 404 a 403, condición del CVE-2021-41773.

## 6. Snapshots y entrega

- `estado-inicial-vulnerable` (todo lo anterior + red OK), `previo-a-<CVE>`, `estado-parcheado` (WP 7.0.2+, PHP ≥8.4.27, Apache ≥2.4.50, `server-status` restringido, `info.php` borrado, `-Indexes`).
- Entregas al informe: captura `apache2 -v` + `php -v` + `wp core version`, evidencia por cada W1–W7 y su retest.

## 7. Accesos directos (URLs y credenciales de ejemplo)

> Desde tu laptop: agrega a `hosts` (o usa el DNS `.14`): `10.10.10.11 wp.uni.lab moodle.uni.lab`. Son claves de laboratorio — cambiar al cerrar la práctica.

| Servicio | URL | Usuario | Clave |
|---|---|---|---|
| Sitio WP | `http://wp.uni.lab/` | — (público) | — |
| WP admin | `http://wp.uni.lab/wp-admin/` | `usc.admin` | `Admin13.-` |
| Campus Virtual | `http://moodle.uni.lab/` | ver tabla Moodle | ver tabla Moodle |
| Moodle admin | `http://moodle.uni.lab/login/index.php` | `moodleadmin` | `Admin13.-` |
| SSH M1 | `ssh ubuntu@10.10.10.11` | `ubuntu` | `Admin13.-` |

**Moodle — docentes** (clave común `Profesor123.`):

| Usuario | Nombre | Curso a cargo |
|---|---|---|
| `jpaye` | José Paye | ISC-1023 Seguridad de la Información |
| `mlopez` | María López | BD-204 Base de Datos II · ADM-101 Gestión de Empresas |
| `cramirez` | Carlos Ramírez | MAT-101 Cálculo I · ENF-101 Cuidado Integral de Enfermería |

**Moodle — estudiantes** (clave común `Estudiante123.`):

| Usuario | Nombre | Correo |
|---|---|---|
| `atorres` | Ana Torres | `atorres@est.usc.edu.pe` |
| `lmendoza` | Luis Mendoza | `lmendoza@est.usc.edu.pe` |
| `rquispe` | Rosa Quispe | `rquispe@est.usc.edu.pe` |
| `jflores` | Jorge Flores | `jflores@est.usc.edu.pe` |
| `mcastillo` | Marta Castillo | `mcastillo@est.usc.edu.pe` |
| `dsalazar` | Diego Salazar | `dsalazar@est.usc.edu.pe` |

Perfiles de curso: `http://moodle.uni.lab/course/view.php?id=N` (2=ISC-1023, 3=BD-204, 4=MAT-101, 5=ENF-101, 6=ADM-101).

- `estado-inicial-vulnerable` (todo lo anterior + red OK), `previo-a-<CVE>`, `estado-parcheado` (WP 7.0.2+, PHP ≥8.4.27, Apache ≥2.4.50, `server-status` restringido, `info.php` borrado, `-Indexes`).
- Entregas al informe: captura `apache2 -v` + `php -v` + `wp core version`, evidencia por cada W1–W7 y su retest.
