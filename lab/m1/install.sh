#!/usr/bin/env bash
# lab/m1/install.sh — M1 app: nginx(TLS) → Apache 2.4.49 prefork + PHP 8.4.26 NTS mod_php
#                    + WordPress 7.0.1 + Moodle 5.0.11 + sink LFI (legacy-download)
# Ejecutar como root en Ubuntu 22.04. Idempotente.

set -euo pipefail
LAB_ROLE="m1"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/lib.sh
source "$HERE/../common/lib.sh"

require_root
require_ubuntu
lab_banner

IFACE="${IFACE:-$(ip route get "$LAB_GW" 2>/dev/null | awk '/dev/{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')}"
[[ -n "$IFACE" ]] || die "no pude detectar la interfaz; exporta IFACE=ens33"

APACHE_PREFIX=/usr/local/apache2
PHP_PREFIX=/usr/local
HTTPD_SRC=/usr/src/httpd-2.4.49
PHP_SRC=/usr/src/php-8.4.26
PHP_TARBALL=/usr/src/php-8.4.26.tar.gz
HTTPD_TARBALL=/usr/src/httpd-2.4.49.tar.gz
HTTPD_SHA256=345d3b9b218b1974d1cebd5ae72f6a661d83b52d839310222ff9ec94abb62205
PHP_SHA256=c248abaebc4bb777b80968f0760da0da8e989836e896c9ff637b6775d7d37662
WP_SHA256=f171740cf45b1f5a1bf52194ca914787cd9d8ea078599b430eca951b62b2d000
MOODLE_SHA256=1e79e8568719034ba570074ecd073ebba0b35c8063458135412d5c27fa01551f
APP_BASE=/var/www
WP_DIR=$APP_BASE/wp
MOODLE_DIR=$APP_BASE/moodle
TLS_DIR=/etc/nginx/tls

# ---------------------------------------------------------------- 1. red
step "1/12 red y hostname"
set_static_ip "$M1" "$IFACE"
hostnamectl set-hostname m1-app
grep -q 'm1-app' /etc/hosts || echo "127.0.1.1 m1-app" >> /etc/hosts
ok "hostname: $(hostname) · ip: $(hostname -I)"

# ---------------------------------------------------------------- 2. apache de distro fuera
step "2/12 retirar Apache de la distribución (evita el :80 fantasma)"
if systemctl list-unit-files 2>/dev/null | grep -q '^apache2\.service'; then
  systemctl disable --now apache2 >/dev/null 2>&1 || true
  ok "apache2 de distro deshabilitado"
else
  ok "sin apache2 de distro"
fi
ss -lntp 2>/dev/null | grep -E ':(80|8080)\b' && warn "algo escucha en 80/8080; revisa antes de continuar" || true

# ---------------------------------------------------------------- 3. dependencias
step "3/12 dependencias de compilación y ejecución"
apt_install build-essential pkg-config autoconf libtool bison re2c \
  libapr1-dev libaprutil1-dev libpcre2-dev libssl-dev zlib1g-dev libexpat1-dev \
  libxml2-dev libsqlite3-dev libcurl4-openssl-dev libzip-dev libonig-dev \
  libicu-dev libsodium-dev libgd-dev libjpeg-dev libfreetype6-dev libpng-dev \
  libwebp-dev nginx nfs-common default-mysql-client openssl curl unzip ca-certificates \
  python3 ufw
ok "dependencias listas"

# ---------------------------------------------------------------- 4. Apache 2.4.49
step "4/12 Apache 2.4.49 (prefork, estático)"
if [[ -x $APACHE_PREFIX/bin/httpd ]] && $APACHE_PREFIX/bin/httpd -v 2>/dev/null | grep -q '2\.4\.49'; then
  ok "Apache 2.4.49 ya instalado"
else
  fetch_artifact "vulnerable/httpd-2.4.49.tar.gz" "$HTTPD_TARBALL"
  sha256_check "$HTTPD_TARBALL" "$HTTPD_SHA256"
  rm -rf "$HTTPD_SRC"
  tar xzf "$HTTPD_TARBALL" -C /usr/src
  pushd "$HTTPD_SRC" >/dev/null
  ./configure --prefix="$APACHE_PREFIX" \
    --with-apr=/usr/bin/apr-1-config --with-apr-util=/usr/bin/apu-1-config \
    --with-mpm=prefork --enable-so --enable-cgi --enable-rewrite \
    --enable-headers --enable-status --enable-mime --enable-dir \
    --enable-env --enable-setenvif --enable-authz-core --enable-authz-host \
    --enable-log-config --enable-unixd --enable-mods-shared=most
  make -j"$(nproc)"
  make install
  popd >/dev/null
fi
$APACHE_PREFIX/bin/httpd -V 2>&1 | grep -E 'Server version|Server MPM|forked'
$APACHE_PREFIX/bin/httpd -V 2>&1 | grep -q 'Server MPM: *prefork' || die "Apache no quedó en prefork"

# ---------------------------------------------------------------- 5. PHP 8.4.26 NTS
step "5/12 PHP 8.4.26 NTS (mod_php, sin ZTS)"
if [[ -x $PHP_PREFIX/bin/php ]] && $PHP_PREFIX/bin/php -v 2>/dev/null | grep -q '8\.4\.26'; then
  ok "PHP 8.4.26 ya instalado"
else
  fetch_artifact "vulnerable/php-8.4.26.tar.gz" "$PHP_TARBALL"
  sha256_check "$PHP_TARBALL" "$PHP_SHA256"
  rm -rf "$PHP_SRC"
  tar xzf "$PHP_TARBALL" -C /usr/src
  pushd "$PHP_SRC" >/dev/null
  ./configure --prefix="$PHP_PREFIX" \
    --with-apxs2="$APACHE_PREFIX/bin/apxs" \
    --with-config-file-path="$PHP_PREFIX/lib" \
    --disable-zts \
    --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-curl --with-openssl --with-zlib --with-zip \
    --enable-mbstring --enable-intl \
    --enable-gd --with-external-gd --with-jpeg --with-freetype \
    --enable-exif --with-sodium --enable-opcache \
    --enable-sockets --enable-fileinfo --enable-xml
  make -j"$(nproc)"
  make install
  popd >/dev/null
fi
$PHP_PREFIX/bin/php -v | head -1
$PHP_PREFIX/bin/php -i | grep -q 'Thread Safety => disabled' || die "PHP quedó ZTS; el PoC exige NTS"
[[ -f $APACHE_PREFIX/modules/libphp.so ]] || die "no se generó libphp.so (revisa apxs)"

# ---------------------------------------------------------------- 6. configuración PHP/Apache
step "6/12 php.ini y httpd.conf"
install -d -m 0755 "$PHP_PREFIX/lib"
install -m 0644 "$HERE/conf/php-lab.ini" "$PHP_PREFIX/lib/php.ini"
install -m 0644 "$HERE/conf/httpd-lab.conf" "$APACHE_PREFIX/conf/httpd.conf"

install -d -m 1777 -o root -g root /tmp
touch /var/log/php_errors.log
chown www-data:www-data /var/log/php_errors.log

cat > /etc/systemd/system/apache-lab.service <<'EOF'
[Unit]
Description=Apache 2.4.49 prefork (lab php2shell)
After=network.target

[Service]
Type=forking
PIDFile=/usr/local/apache2/logs/httpd.pid
ExecStart=/usr/local/apache2/bin/apachectl start
ExecStop=/usr/local/apache2/bin/apachectl stop
ExecReload=/usr/local/apache2/bin/apachectl graceful
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
enable_now apache-lab
sleep 1
$APACHE_PREFIX/bin/apachectl -t || die "httpd.conf inválido"

# ---------------------------------------------------------------- 7. TLS
step "7/12 certificado TLS para *.uni.lab"
install -d -m 0755 "$TLS_DIR"
if [[ -f "$LAB_REPO_DIR/lab/pki/out/app-chain.crt" && -f "$LAB_REPO_DIR/lab/pki/out/app.key" ]]; then
  install -m 0644 "$LAB_REPO_DIR/lab/pki/out/app-chain.crt" "$TLS_DIR/app-chain.crt"
  install -m 0600 "$LAB_REPO_DIR/lab/pki/out/app.key"       "$TLS_DIR/app.key"
  ok "certificado de la CA del lab instalado"
else
  warn "no hay CA del lab; genero autofirmado (el PoC usa -k / verify=False)"
  openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
    -keyout "$TLS_DIR/app.key" -out "$TLS_DIR/app-chain.crt" \
    -subj "/CN=app.uni.lab" \
    -addext "subjectAltName=DNS:app.uni.lab,DNS:wp.uni.lab,DNS:moodle.uni.lab,IP:10.10.10.11" >/dev/null 2>&1
fi
chmod 600 "$TLS_DIR/app.key"

# ---------------------------------------------------------------- 8. nginx
step "8/12 nginx (443 → 127.0.0.1:8080)"
rm -f /etc/nginx/sites-enabled/default
install -m 0644 "$HERE/conf/nginx-lab.conf" /etc/nginx/sites-available/lab.conf
ln -sf /etc/nginx/sites-available/lab.conf /etc/nginx/sites-enabled/lab.conf
nginx -t
enable_now nginx
systemctl reload nginx

# ---------------------------------------------------------------- 9. aplicaciones
step "9/12 WordPress 7.0.1 y Moodle 5.0.11"
install -d "$APP_BASE" "$WP_DIR" "$MOODLE_DIR" /var/moodledata /var/www/app
if [[ ! -f /var/www/app/index.php ]]; then
  printf '%s\n' '<?php echo "lab app\n";' > /var/www/app/index.php
fi
if [[ ! -f "$WP_DIR/wp-load.php" ]]; then
  fetch_artifact "vulnerable/wordpress-7.0.1.zip" /usr/src/wordpress-7.0.1.zip
  sha256_check /usr/src/wordpress-7.0.1.zip "$WP_SHA256"
  rm -rf /usr/src/wp-extract && mkdir -p /usr/src/wp-extract
  unzip -q /usr/src/wordpress-7.0.1.zip -d /usr/src/wp-extract
  cp -a /usr/src/wp-extract/wordpress/. "$WP_DIR"/
fi
if [[ ! -f "$MOODLE_DIR/version.php" ]]; then
  fetch_artifact "vulnerable/moodle-5.0.11.tar.gz" /usr/src/moodle-5.0.11.tar.gz
  sha256_check /usr/src/moodle-5.0.11.tar.gz "$MOODLE_SHA256"
  tar xzf /usr/src/moodle-5.0.11.tar.gz -C /usr/src
  cp -a /usr/src/moodle-5.0.11/. "$MOODLE_DIR"/
fi
find "$APP_BASE" -xdev -exec chown www-data:www-data {} +
find /var/moodledata -xdev -exec chown www-data:www-data {} +
find "$APP_BASE" -xdev -type d -exec chmod 755 {} +
find "$APP_BASE" -xdev -type f -exec chmod 644 {} +

# ---------------------------------------------------------------- 10. sink LFI + harness
step "10/12 plugin legacy-download y harness de sesión"
PLUGIN="$WP_DIR/wp-content/plugins/legacy-download"
rm -rf "$PLUGIN"
cp -a "$HERE/app/legacy-download" "$PLUGIN"
install -d -m 0755 "$WP_DIR/lab"
cp -a "$HERE/app/lab/." "$WP_DIR/lab/"
chown -R www-data:www-data "$PLUGIN" "$WP_DIR/lab"
ok "sink: /wp-content/plugins/legacy-download/dl.php?file=  ·  harness: /lab/session.php"

# ---------------------------------------------------------------- 11. NFS
step "11/12 NFS desde M3 (no_root_squash en backups)"
install -d -m 2775 -o www-data -g www-data "$WP_DIR/wp-content/uploads"
if ! grep -q "$M3:/srv/storage/wp-uploads" /etc/fstab; then
  cat >> /etc/fstab <<EOF
$M3:/srv/storage/wp-uploads  $WP_DIR/wp-content/uploads  nfs  rw,soft,timeo=100,retrans=3,bg,nofail,_netdev,noatime,x-systemd.device-timeout=10s  0 0
$M3:/srv/storage/moodledata  /var/moodledata             nfs  rw,soft,timeo=100,retrans=3,bg,nofail,_netdev,noatime,x-systemd.device-timeout=10s  0 0
EOF
fi
if (exec 3<>"/dev/tcp/$M3/2049") 2>/dev/null; then
  exec 3>&-
  mount -a || warn "mount -a falló; revisa exportfs en M3"
  findmnt -t nfs -o TARGET,SOURCE,OPTIONS || true
else
  warn "M3:2049 no responde todavía; los montajes quedan en fstab"
fi

# ---------------------------------------------------------------- 12. firewall + apps
step "12/12 firewall y aplicaciones"
ufw allow 22/tcp   >/dev/null 2>&1 || true
ufw allow 443/tcp  >/dev/null 2>&1 || true
ufw allow 80/tcp   >/dev/null 2>&1 || true
ufw --force enable >/dev/null 2>&1 || true

if (exec 3<>"/dev/tcp/$M2/3306") 2>/dev/null; then
  exec 3>&-
  bash "$HERE/install-apps.sh" || warn "instalación de apps incompleta; re-ejecuta m1/install-apps.sh"
else
  warn "M2:3306 no responde; instala M2 y luego: sudo bash $HERE/install-apps.sh"
fi

bash "$HERE/verify.sh" || die "verify de M1 falló"

cat <<EOF

M1 listo.
  https://wp.uni.lab/            (WordPress 7.0.1)
  https://moodle.uni.lab/        (Moodle 5.0.11)
  https://wp.uni.lab/lab/session.php   (harness)
  https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php?file=default.php

  Apache: $( $APACHE_PREFIX/bin/httpd -v | head -1 )
  PHP:    $( $PHP_PREFIX/bin/php -v | head -1 )
EOF
