#!/usr/bin/env bash
# w2-check.sh — evidencia de precondiciones W2: Apache prefork + PHP 8.4.26 NTS + php.ini + offsets.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

./informe/tools/vm.sh m1 '
echo "== Apache prefork (8080) =="
/home/ubuntu/w2/httpd-prefork/bin/httpd -V | grep -E "Server MPM|threaded|forked"
echo
echo "== PHP NTS (CLI) =="
/home/ubuntu/w2/php826-nts/bin/php -v | head -2
echo
echo "== php.ini efectivo (web 8080) =="
curl -s http://127.0.0.1:8080/info.php | sed "s/<[^>]*>/ /g" | tr -s " " | \
  grep -iE "Thread Safety|Server API|memory_limit|display_errors|max_input_vars|session.upload_progress.enabled|session.use_cookies|session.use_strict_mode" | head -12
echo
echo "== offsets libphp.so =="
nm /home/ubuntu/w2/httpd-prefork/modules/libphp.so | grep -E " (zif_system|zval_ptr_dtor)$"
echo
echo "== target de sesion =="
curl -s -o /dev/null -w "session.php HTTP %{http_code}\n" http://127.0.0.1:8080/session.php
'
