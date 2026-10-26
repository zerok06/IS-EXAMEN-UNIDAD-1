#!/usr/bin/env bash
# check-artifacts.sh · verifica presencia y SHA256 de los artefactos (read-only)
# Uso: ./tests/check-artifacts.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ART="$ROOT/artifacts"

pass=0; fail=0; warn=0
pass() { printf 'PASS  %s\n' "$1"; pass=$((pass+1)); }
fail() { printf 'FAIL  %s\n' "$1"; fail=$((fail+1)); }
warn() { printf 'WARN  %s\n' "$1"; warn=$((warn+1)); }

echo "== Artefactos IS-1023 =="
date -u
echo

if [ ! -d "$ART" ]; then
  fail "falta artifacts/"
  echo "== Resumen: PASS=$pass FAIL=$fail WARN=$warn =="
  exit 1
fi

required=(
  vulnerable/wordpress-7.0.1.zip
  vulnerable/php-8.4.26.tar.gz
  vulnerable/httpd-2.4.49.tar.gz
  vulnerable/moodle-5.0.11.tar.gz
  vulnerable/redis-6.2.6.tar.gz
  vulnerable/samba-4.5.9.tar.gz
  vulnerable/vsftpd-2.3.4.tar.gz
  vulnerable/tightvnc-2.8.90-gpl-setup-64bit.msi
  fixed/wordpress-7.0.2.zip
  fixed/php-8.4.27.tar.gz
  fixed/httpd-2.4.51.tar.gz
  fixed/redis-6.2.7.tar.gz
  fixed/samba-4.5.10.tar.gz
  fixed/vsftpd-3.0.5.tar.gz
  pocs/wp2shell-vulhub-poc.py
  pocs/wp2shell-poc-main.zip
  pocs/php2shell-poc-main.zip
  pocs/ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz
  pocs/ligolo-ng_agent_0.9.2_linux_amd64.tar.gz
)

for f in "${required[@]}"; do
  if [ -s "$ART/$f" ]; then
    pass "$f"
  else
    fail "falta o vacío: $f"
  fi
done

echo
if [ ! -f "$ART/checksums.sha256" ]; then
  fail "falta checksums.sha256"
else
  if out=$(cd "$ART" && sha256sum -c --ignore-missing checksums.sha256 2>&1); then
    n=$(echo "$out" | wc -l | tr -d ' ')
    pass "SHA256 OK ($n archivos)"
  else
    fail "SHA256 con errores"
    echo "$out" | grep -v ': OK$' || true
  fi
fi

echo
echo "== Resumen: PASS=$pass FAIL=$fail WARN=$warn =="
[ "$fail" -eq 0 ]
