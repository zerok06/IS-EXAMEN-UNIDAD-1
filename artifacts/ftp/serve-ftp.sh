#!/usr/bin/env bash
# serve-ftp.sh · servidor FTP de artefactos en M6 (LAN aislada)
# Uso: ./ftp/serve-ftp.sh
# Requiere: pyftpdlib (python3 -m pip install pyftpdlib)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${FTP_PORT:-2121}"
USER="${FTP_USER:-lab}"
PASS="${FTP_PASS:-lab123}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 no instalado" >&2
  exit 1
fi

if ! python3 -c 'import pyftpdlib' 2>/dev/null; then
  echo "pyftpdlib no instalado." >&2
  echo "  sudo apt install -y python3-pyftpdlib" >&2
  echo "  o: python3 -m pip install pyftpdlib" >&2
  echo "" >&2
  echo "Alternativa HTTP:" >&2
  echo "  python3 -m http.server 8080 --directory \"$ROOT\"" >&2
  exit 1
fi

echo "== FTP artefactos =="
echo "Raíz:    $ROOT"
echo "URL:     ftp://10.10.10.20:$PORT"
echo "Usuario: $USER"
echo "Clave:   $PASS"
echo "Detener: Ctrl+C"
echo ""

exec python3 -m pyftpdlib -p "$PORT" -d "$ROOT" -u "$USER" -P "$PASS"
