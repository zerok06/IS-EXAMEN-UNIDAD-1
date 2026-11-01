#!/usr/bin/env bash
# lab/patch/m1-php.sh — parchea M1: PHP 8.4.27 + upload_progress Off + sink fuera.
# Ejecutar como root DESPUÉS de restaurar el snapshot estado-inicial.

set -euo pipefail
LAB_ROLE=patch-m1
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../common/lib.sh"

require_root
require_ubuntu

PHP_SRC=/usr/src/php-8.4.27
PHP_TARBALL=/usr/src/php-8.4.27.tar.gz
PHP_SHA256=5bafed9994c1a49796b25b5f61c22c9183bfe046b6acc7b363842d03c77f972f
APACHE_PREFIX=/usr/local/apache2

step "1/5 PHP 8.4.27 (NTS, mod_php)"
if /usr/local/bin/php -v 2>/dev/null | grep -q '8\.4\.27'; then
  ok "PHP 8.4.27 ya instalado"
else
  fetch_artifact "fixed/php-8.4.27.tar.gz" "$PHP_TARBALL"
  sha256_check "$PHP_TARBALL" "$PHP_SHA256"
  rm -rf "$PHP_SRC"
  tar xzf "$PHP_TARBALL" -C /usr/src
  pushd "$PHP_SRC" >/dev/null
  ./configure --prefix=/usr/local \
    --with-apxs2="$APACHE_PREFIX/bin/apxs" \
    --with-config-file-path=/usr/local/lib \
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
/usr/local/bin/php -v | head -1

step "2/5 php.ini: upload_progress Off"
if grep -q '^session.upload_progress.enabled' /usr/local/lib/php.ini; then
  sed -i 's/^session.upload_progress.enabled.*/session.upload_progress.enabled = Off/' /usr/local/lib/php.ini
else
  echo 'session.upload_progress.enabled = Off' >> /usr/local/lib/php.ini
fi
ok "session.upload_progress.enabled = Off"

step "3/5 eliminar el sink LFI y el harness"
rm -rf /var/www/wp/wp-content/plugins/legacy-download
rm -rf /var/www/wp/lab
ok "plugin legacy-download y /lab eliminados"

step "4/5 reiniciar servicios"
enable_now apache-lab
systemctl reload nginx 2>/dev/null || true

step "5/5 verificación"
/usr/local/bin/php -v | grep -q '8\.4\.27' || die "PHP no quedó en 8.4.27"
/usr/local/bin/php -i | grep -q 'session.upload_progress.enabled => Off' || die "upload_progress sigue On"
code=$(curl -ks -o /dev/null -w '%{http_code}' -H 'Host: wp.uni.lab' \
  'https://127.0.0.1/wp-content/plugins/legacy-download/dl.php?file=default.php')
[[ "$code" == "404" ]] || die "el sink sigue respondiendo ($code)"
ok "M1 parcheado: PHP 8.4.27, upload_progress Off, sink 404"

cat <<EOF

Retest esperado desde M6:
  curl -k -o /dev/null -w '%{http_code}\\n' 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php?file=default.php'
  # 404
EOF
