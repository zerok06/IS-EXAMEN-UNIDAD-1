#!/usr/bin/env bash
# download.sh · descarga los artefactos versionados y genera checksums.sha256
# Uso: ./artifacts/download.sh [--force]

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

mkdir -p "$ROOT"/{vulnerable,fixed,pocs,os,ftp}

items=(
  "vulnerable|wordpress-7.0.1.zip|https://wordpress.org/wordpress-7.0.1.zip"
  "vulnerable|php-8.4.26.tar.gz|https://www.php.net/distributions/php-8.4.26.tar.gz"
  "vulnerable|httpd-2.4.49.tar.gz|https://archive.apache.org/dist/httpd/httpd-2.4.49.tar.gz"
  "vulnerable|redis-6.2.6.tar.gz|https://download.redis.io/releases/redis-6.2.6.tar.gz"
  "vulnerable|samba-4.5.9.tar.gz|https://download.samba.org/pub/samba/stable/samba-4.5.9.tar.gz"
  "vulnerable|vsftpd-2.3.4.tar.gz|https://security.appspot.com/downloads/vsftpd-2.3.4.tar.gz"
  "vulnerable|moodle-5.0.11.tar.gz|https://github.com/moodle/moodle/archive/refs/tags/v5.0.11.tar.gz"
  "vulnerable|tightvnc-2.8.90-gpl-setup-64bit.msi|https://www.tightvnc.com/download/2.8.90/tightvnc-2.8.90-gpl-setup-64bit.msi"
  "fixed|wordpress-7.0.2.zip|https://wordpress.org/wordpress-7.0.2.zip"
  "fixed|php-8.4.27.tar.gz|https://www.php.net/distributions/php-8.4.27.tar.gz"
  "fixed|httpd-2.4.51.tar.gz|https://archive.apache.org/dist/httpd/httpd-2.4.51.tar.gz"
  "fixed|redis-6.2.7.tar.gz|https://download.redis.io/releases/redis-6.2.7.tar.gz"
  "fixed|samba-4.5.10.tar.gz|https://download.samba.org/pub/samba/stable/samba-4.5.10.tar.gz"
  "fixed|vsftpd-3.0.5.tar.gz|https://security.appspot.com/downloads/vsftpd-3.0.5.tar.gz"
  "pocs|wp2shell-vulhub-poc.py|https://raw.githubusercontent.com/vulhub/vulhub/master/wordpress/CVE-2026-63030/poc.py"
  "pocs|wp2shell-poc-main.zip|https://github.com/DeadExpl0it/wp2shell-poc/archive/refs/heads/main.zip"
  "pocs|php2shell-poc-main.zip|https://github.com/eness/php2shell-cve-2026-109618-cve-2026-109619-poc/archive/refs/heads/main.zip"
  "pocs|ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz|https://github.com/nicocha30/ligolo-ng/releases/download/v0.9.2/ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz"
  "pocs|ligolo-ng_agent_0.9.2_linux_amd64.tar.gz|https://github.com/nicocha30/ligolo-ng/releases/download/v0.9.2/ligolo-ng_agent_0.9.2_linux_amd64.tar.gz"
)

for item in "${items[@]}"; do
  IFS='|' read -r dir name url <<< "$item"
  out="$ROOT/$dir/$name"
  if [ -s "$out" ] && [ "$FORCE" -eq 0 ]; then
    echo "SKIP  $name"
    continue
  fi
  echo "GET   $name"
  if ! curl -L --fail --retry 3 --retry-delay 2 --silent --show-error -o "$out" "$url"; then
    echo "ERROR $url" >&2
    exit 1
  fi
  size=$(du -h "$out" | cut -f1)
  echo "OK    $name ($size)"
done

cd "$ROOT"
find vulnerable fixed pocs -type f -print0 | sort -z | xargs -0 sha256sum > checksums.sha256
echo ""
echo "Checksums: $ROOT/checksums.sha256"
wc -l < checksums.sha256 | awk '{print "Archivos:  "$1}'
