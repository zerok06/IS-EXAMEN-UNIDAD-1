#!/usr/bin/env bash
# versiones.sh — inventario simple y replicable de versiones instaladas.
# Uso: ./informe/tools/versiones.sh
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

echo "== Fecha =="; date -u
echo
echo "== M1 (10.10.10.11) =="
./informe/tools/vm.sh m1 'hostname; wp core version --allow-root --path=/var/www/wp; php -v | head -1; /usr/local/apache2/bin/httpd -v | head -1; /usr/local/apache2/bin/httpd -V | grep -i "Server MPM"'
echo
echo "== M2 (10.10.10.12) =="
./informe/tools/vm.sh m2 'hostname; redis-server --version; mysql --version'
echo
echo "== M3 (10.10.10.13) =="
./informe/tools/vm.sh m3 'hostname; /usr/local/samba/sbin/smbd --version; (printf "" | nc -w 2 127.0.0.1 21 | head -1)'
echo
echo "== M4 (10.10.10.14) =="
nxc smb 10.10.10.14 2>/dev/null | tail -1
echo
echo "== M5 (10.10.10.15) =="
nmap -Pn -T4 --host-timeout 10s -p445,3389,5900 10.10.10.15 2>/dev/null | grep -E "^[0-9]+/tcp|Host is up"
