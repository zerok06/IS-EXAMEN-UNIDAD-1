#!/usr/bin/env bash
# lab/m1/verify.sh — comprobaciones reales de M1. exit 0 = OK.

set -uo pipefail
LAB_ROLE="m1-verify"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../common/lib.sh"

fails=0; checks=0
chk() { # chk <descripción> <comando...>
  checks=$((checks+1))
  if "${@:2}" >/dev/null 2>&1; then ok "$1"; else printf '[FAIL] %s\n' "$1"; fails=$((fails+1)); fi
}

step "versiones"
chk "Apache 2.4.49"        bash -c '/usr/local/apache2/bin/httpd -v | grep -q "2\.4\.49"'
chk "MPM prefork"          bash -c '/usr/local/apache2/bin/httpd -V | grep -q "Server MPM: *prefork"'
chk "PHP 8.4.26"           bash -c '/usr/local/bin/php -v | grep -q "8\.4\.26"'
chk "PHP NTS"              bash -c '/usr/local/bin/php -i | grep -q "Thread Safety => disabled"'
chk "libphp.so presente"   test -s /usr/local/apache2/modules/libphp.so

step "servicios"
chk "apache-lab activo"    systemctl is-active --quiet apache-lab
chk "nginx activo"         systemctl is-active --quiet nginx
chk "8080 solo loopback"   bash -c "ss -lnt | grep -q '127.0.0.1:8080'"
chk "443 escuchando"       bash -c "ss -lnt | grep -q ':443 '"

step "contenido"
chk "harness /lab/session.php" bash -c "curl -ks --max-time 10 -H 'Host: wp.uni.lab' https://127.0.0.1/lab/session.php | grep -q 'sid='"
chk "sink dl.php"              bash -c "curl -ks --max-time 10 -H 'Host: wp.uni.lab' 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php?file=default.php' | grep -q 'Plantilla base'"
chk "WordPress responde"       bash -c "curl -ks --max-time 10 -H 'Host: wp.uni.lab' https://127.0.0.1/wp-login.php | grep -q 'wp-submit'"
# Moodle no es parte de la cadena: se avisa, no se falla.
if curl -ks --max-time 10 -H 'Host: moodle.uni.lab' https://127.0.0.1/ | grep -qi 'moodle'; then
  ok "Moodle responde"
else
  warn "Moodle no responde (requiere MariaDB 10.11; no afecta a la cadena)"
fi

step "php.ini del PoC"
chk "upload_progress On"   bash -c "curl -ks -H 'Host: wp.uni.lab' https://127.0.0.1/lab/session.php >/dev/null; /usr/local/bin/php -i | grep -q 'session.upload_progress.enabled => On'"
chk "save_path /tmp escribible" test -w /tmp

step "NFS (opcional si M3 no está)"
if (exec 3<>"/dev/tcp/$M3/2049") 2>/dev/null; then
  exec 3>&-
  chk "montaje wp-uploads" bash -c "findmnt -t nfs /var/www/wp/wp-content/uploads"
else
  warn "M3:2049 no responde; omito comprobación de NFS"
fi

printf '\n%d/%d comprobaciones OK\n' "$((checks-fails))" "$checks"
(( fails == 0 )) || { printf '%d fallo(s)\n' "$fails"; exit 1; }
