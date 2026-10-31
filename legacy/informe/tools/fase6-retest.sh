#!/usr/bin/env bash
# fase6-retest.sh — Fase 6: retest de M1-M5 con el mismo comando antes/después.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1
export M1_PASS='M1_Ubuntu_2026!'
export M3_PASS='M3_Backup_2026!'
VM=./informe/tools/vm.sh

echo "== M1 · versiones =="
$VM m1 'wp core version --allow-root --path=/var/www/wp; php -v | head -1; /usr/local/apache2/bin/httpd -v | head -1; php -i | grep -E "^session.upload_progress.enabled|^display_errors"'
echo
echo "== M1 · W1/W3/W5/W6/W7 =="
echo -n "W1_batch="; curl -s -o /dev/null -w '%{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{}' http://10.10.10.11/wp-json/batch/v1
echo -n "W3_RCE="; curl -s --path-as-is -X POST 'http://10.10.10.11/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh' -d 'echo Content-Type: text/plain; echo; id' | head -1
echo -n "W5="; curl -s -o /dev/null -w '%{http_code}\n' http://10.10.10.11/server-status
echo -n "W6="; curl -s -o /dev/null -w '%{http_code}\n' http://10.10.10.11/info.php
echo -n "W7="; curl -s -o /dev/null -w '%{http_code}\n' http://10.10.10.11/wp-content/uploads/
echo -n "W2_lfi="; curl -s -o /dev/null -w '%{http_code}\n' http://10.10.10.11/lfi.php
echo
echo "== M1 · W4 =="
echo -n "W4_old="; curl -s -o /dev/null -w '%{http_code}\n' -d 'log=usc.admin&pwd=Admin13.-&wp-submit=Log+In&testcookie=1' http://10.10.10.11/wp-login.php
curl -s -c /tmp/opencode/r.cookies -o /dev/null http://10.10.10.11/wp-login.php
echo -n "W4_new="; curl -s -b /tmp/opencode/r.cookies -c /tmp/opencode/r.cookies -o /dev/null -w '%{http_code}\n' -d 'log=usc.admin&pwd=Uni2026!Admin&wp-submit=Log+In&testcookie=1' http://10.10.10.11/wp-login.php
echo
echo "== M1 · SSH =="
echo -n "SSH_old="; M1_PASS='Admin13.-' $VM m1 'id' 2>&1 | tail -1
echo -n "SSH_new="; $VM m1 'id; hostname'
echo
echo "== M2 =="
$VM m2 'redis-server --version; echo -n "redis_sin_auth="; redis-cli PING 2>&1 | head -1; echo -n "redis_con_auth="; redis-cli -a "UniRedis2026!" PING 2>&1 | tail -1'
echo "-- puertos desde M6 --"
nmap -Pn -p3306,6379 10.10.10.12 2>/dev/null | grep -E '^3306|^6379'
nmap -sU -Pn -p161 10.10.10.12 2>/dev/null | grep -E '^161'
echo
echo "== M1 · D2 (credenciales DB) =="
cat > /tmp/opencode/dbtest.php <<'PHP'
<?php
mysqli_report(MYSQLI_REPORT_OFF);
foreach ([['old','wp_pass123'],['new','Wp_Uni_2026!']] as $c) {
  $l=@new mysqli('10.10.10.12','wp_user',$c[1],'wordpress');
  echo $c[0].'='.($l->connect_errno?'ERR':'OK')."\n";
}
PHP
B64=$(base64 -w0 /tmp/opencode/dbtest.php)
$VM m1 "echo $B64 | base64 -d > /tmp/dbtest.php; php /tmp/dbtest.php; rm -f /tmp/dbtest.php"
echo
echo "== M3 =="
$VM m3 '/usr/local/samba/sbin/smbd --version; grep -E "^anonymous_enable|^local_enable" /etc/vsftpd.conf; echo M3_Backup_2026! | sudo -S exportfs -v | grep -A1 backups'
echo -n "FTP_anon="; timeout 5 curl -s -o /dev/null -w '%{http_code}\n' ftp://anonymous:anonymous@10.10.10.13/ 2>/dev/null || echo "530/denegado"
echo -n "SSH_old="; M3_PASS='rony123' $VM m3 'id' 2>&1 | tail -1
echo -n "SSH_new="; $VM m3 'id; hostname'
echo
echo "== M4 =="
nxc smb 127.0.0.1 --port 1445 2>/dev/null | tail -1
echo -n "admin_old="; nxc smb 127.0.0.1 --port 1445 -u Administrador -p 'password_2026' 2>/dev/null | tail -1
echo -n "admin_new="; nxc smb 127.0.0.1 --port 1445 -u Administrador -p 'M4_Admin_2026!' 2>/dev/null | tail -1
nxc winrm 127.0.0.1 --port 15985 -u Administrador -p 'M4_Admin_2026!' -X '(Get-Service Spooler).Status; (Get-SmbServerConfiguration).EnableSMB1Protocol; (Get-SmbServerConfiguration).RequireSecuritySignature; Get-LocalUser | Select-Object -ExpandProperty Name' 2>/dev/null | tail -6
echo -n "AXFR="; dig +time=3 +tries=1 axfr uni.lab @10.10.10.14 2>&1 | grep -E 'XFR size|Transfer failed|REFUSED' | head -1
echo
echo "== M5 =="
nmap -Pn -T4 --host-timeout 10s -p445,3389,5900 10.10.10.15 2>/dev/null | grep -E 'Host is up|^[0-9]+/tcp' || echo "M5 sin respuesta"
