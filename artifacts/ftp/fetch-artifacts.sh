#!/usr/bin/env bash
# fetch-artifacts.sh <rol> · descarga los artefactos del rol desde M6
# Roles: m1, m1-fixed, m2, m2-fixed, m3, m3-fixed, m5, m6, checksums
# Uso: ./ftp/fetch-artifacts.sh m1

set -euo pipefail

HOST="${FTP_HOST:-10.10.10.20}"
PORT="${FTP_PORT:-2121}"
USER="${FTP_USER:-lab}"
PASS="${FTP_PASS:-lab123}"
DEST="${DEST:-$HOME/artifacts}"
ROLE="${1:-m1}"

mkdir -p "$DEST"

fetch() {
  local rel="$1"
  mkdir -p "$DEST/$(dirname "$rel")"
  echo "GET  $rel"
  curl -sS --fail --retry 2 -u "$USER:$PASS" -o "$DEST/$rel" "ftp://$HOST:$PORT/$rel"
}

case "$ROLE" in
  m1)
    fetch vulnerable/wordpress-7.0.1.zip
    fetch vulnerable/php-8.4.26.tar.gz
    fetch vulnerable/httpd-2.4.49.tar.gz
    fetch vulnerable/moodle-5.0.11.tar.gz
    fetch pocs/wp2shell-vulhub-poc.py
    fetch pocs/wp2shell-poc-main.zip
    fetch pocs/php2shell-poc-main.zip
    ;;
  m1-fixed)
    fetch fixed/wordpress-7.0.2.zip
    fetch fixed/php-8.4.27.tar.gz
    fetch fixed/httpd-2.4.51.tar.gz
    ;;
  m2)
    fetch vulnerable/redis-6.2.6.tar.gz
    ;;
  m2-fixed)
    fetch fixed/redis-6.2.7.tar.gz
    ;;
  m3)
    fetch vulnerable/samba-4.5.9.tar.gz
    fetch vulnerable/vsftpd-2.3.4.tar.gz
    ;;
  m3-fixed)
    fetch fixed/samba-4.5.10.tar.gz
    fetch fixed/vsftpd-3.0.5.tar.gz
    ;;
  m5)
    fetch vulnerable/tightvnc-2.8.90-gpl-setup-64bit.msi
    ;;
  m6)
    fetch pocs/wp2shell-vulhub-poc.py
    fetch pocs/wp2shell-poc-main.zip
    fetch pocs/php2shell-poc-main.zip
    fetch pocs/ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz
    fetch pocs/ligolo-ng_agent_0.9.2_linux_amd64.tar.gz
    ;;
  checksums)
    fetch checksums.sha256
    ;;
  *)
    echo "Rol inválido: $ROLE" >&2
    echo "Roles: m1, m1-fixed, m2, m2-fixed, m3, m3-fixed, m5, m6, checksums" >&2
    exit 1
    ;;
esac

fetch checksums.sha256 || true

echo ""
echo "Descargado en: $DEST"
if [ -f "$DEST/checksums.sha256" ]; then
  echo "Verificando..."
  (cd "$DEST" && sha256sum -c --ignore-missing checksums.sha256)
else
  echo "Sin checksums.sha256; verificar manualmente contra artifacts/checksums.sha256"
fi
