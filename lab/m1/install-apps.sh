#!/usr/bin/env bash
# lab/m1/install-apps.sh — instala WordPress y Moodle contra M2.
# Requiere que M2:3306 esté arriba. Idempotente.

set -euo pipefail
LAB_ROLE="m1-apps"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../common/lib.sh"

require_root
WP_DIR=/var/www/wp
MOODLE_DIR=/var/www/moodle
PHP=/usr/local/bin/php
# Moodle 5.0.11 exige MariaDB 10.11 (Ubuntu 22.04 trae 10.6): por defecto NO se instala.
INSTALL_MOODLE="${INSTALL_MOODLE:-0}"

# ---------------------------------------------------------------- espera M2
step "esperando MariaDB en $M2:3306"
wait_port "$M2" 3306 60

# ---------------------------------------------------------------- wp-config
step "wp-config.php"
if [[ ! -f "$WP_DIR/wp-config.php" ]]; then
  SALTS=$(python3 - <<'PY'
import secrets, string
def k(): return ''.join(secrets.choice(string.ascii_letters+string.digits+'!@#$%^&*()-_[]{}<>~`+=,.;:/?|') for _ in range(64))
for n in ['AUTH_KEY','SECURE_AUTH_KEY','LOGGED_IN_KEY','NONCE_KEY','AUTH_SALT','SECURE_AUTH_SALT','LOGGED_IN_SALT','NONCE_SALT']:
    print(f"define('{n}', '{k()}');")
PY
)
  cat > "$WP_DIR/wp-config.php" <<EOF
<?php
define('DB_NAME', 'wp_db');
define('DB_USER', 'wp_user');
define('DB_PASSWORD', 'ClaveDebil123');
define('DB_HOST', '10.10.10.12');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
\$table_prefix = 'wp_';
$SALTS
define('WP_HOME',    'https://wp.uni.lab');
define('WP_SITEURL', 'https://wp.uni.lab');
define('WP_DEBUG', false);
define('FS_METHOD', 'direct');
define('DISALLOW_FILE_EDIT', false);
if (!defined('ABSPATH')) { define('ABSPATH', __DIR__ . '/'); }
require_once ABSPATH . 'wp-settings.php';
EOF
  chown www-data:www-data "$WP_DIR/wp-config.php"
  chmod 640 "$WP_DIR/wp-config.php"
  ok "wp-config.php escrito"
else
  ok "wp-config.php ya existe"
fi

# ---------------------------------------------------------------- WordPress
step "WordPress"
if curl -ks https://127.0.0.1/wp-admin/install.php -H 'Host: wp.uni.lab' | grep -qi 'Already Installed'; then
  ok "WordPress ya instalado"
else
  code=$(curl -ks -o /tmp/wp-install.html -w '%{http_code}' -X POST \
    'https://127.0.0.1/wp-admin/install.php?step=2' -H 'Host: wp.uni.lab' \
    --data-urlencode 'weblog_title=Campus Uni' \
    --data-urlencode 'user_name=usc.admin' \
    --data-urlencode 'admin_password=Admin13.-' \
    --data-urlencode 'admin_password2=Admin13.-' \
    --data-urlencode 'pw_weak=1' \
    --data-urlencode 'admin_email=admin@uni.lab' \
    --data-urlencode 'blog_public=0' \
    --data-urlencode 'Submit=Install WordPress')
  if grep -qi 'Success' /tmp/wp-install.html; then
    ok "WordPress instalado (admin usc.admin)"
  else
    warn "respuesta HTTP $code; revisa /tmp/wp-install.html"
  fi
fi

# plugin legacy-download activo (el sink de la cadena)
if command -v sudo >/dev/null && id www-data >/dev/null 2>&1; then
  sudo -u www-data "$PHP" -r '
    define("WP_USE_THEMES", false);
    require "/var/www/wp/wp-load.php";
    require_once ABSPATH . "wp-admin/includes/plugin.php";
    $p = "legacy-download/legacy-download.php";
    if (!is_plugin_active($p)) { activate_plugin($p); echo "plugin activado\n"; }
    else { echo "plugin ya activo\n"; }
  ' 2>/dev/null || warn "no pude activar el plugin por CLI; actívalo en wp-admin"
fi

# ---------------------------------------------------------------- Moodle
step "Moodle"
if [[ "$INSTALL_MOODLE" != "1" ]]; then
  warn "Moodle omitido (INSTALL_MOODLE=0): 5.0.11 exige MariaDB 10.11 y Ubuntu 22.04 trae 10.6"
elif [[ -f "$MOODLE_DIR/config.php" ]]; then
  ok "Moodle ya configurado"
else
  sudo -u www-data "$PHP" "$MOODLE_DIR/admin/cli/install.php" \
    --wwwroot=https://moodle.uni.lab \
    --dataroot=/var/moodledata \
    --dbtype=mariadb --dbhost=10.10.10.12 --dbname=moodle_db \
    --dbuser=moodle_user --dbpass=ClaveDebil123 \
    --fullname='Campus Uni' --shortname=UNI --lang=es \
    --adminuser=moodleadmin --adminpass='Admin13.-' --adminemail=admin@uni.lab \
    --non-interactive --agree-license \
    && ok "Moodle instalado (admin moodleadmin)" \
    || warn "Moodle CLI falló; revisa la salida"
fi

find "$WP_DIR" -xdev -exec chown www-data:www-data {} +
find "$MOODLE_DIR" -xdev -exec chown www-data:www-data {} +
find /var/moodledata -xdev -exec chown www-data:www-data {} +
ok "aplicaciones listas"
