#!/usr/bin/env bash
# ============================================================================
#  lab/m6/serve.sh — servidor HTTP de despliegue del laboratorio (M6:8000)
# ----------------------------------------------------------------------------
#  Publica /srv, donde lab/m6/install.sh deja:
#    /srv/bootstrap.sh      → arranque de las VM Ubuntu (M1/M2/M3/M6)
#    /srv/bootstrap.ps1     → arranque de las VM Windows (M4/M5)
#    /srv/lab.tar.gz        → paquete que baja bootstrap.sh
#    /srv/lab.zip           → paquete que baja bootstrap.ps1
#    /srv/lab/              → copia del repo (scripts, PoCs, docs)
#    /srv/artifacts         → enlace a /srv/lab/artifacts
#
#  Corre en foreground para ver las peticiones durante la demo. Ctrl-C para
#  parar.
#
#  Uso:
#    sudo bash lab/m6/serve.sh          # :8000 sobre /srv
#    bash lab/m6/serve.sh 8080         # otro puerto
#    LAB_SERVE_ROOT=/tmp/x bash lab/m6/serve.sh --port 8000
#
#  Como servicio (opcional), en vez de este script:
#    sudo bash lab/m6/install.sh --service
#  que escribe /etc/systemd/system/lab-serve.service y hace:
#    systemctl enable --now lab-serve   /   systemctl status lab-serve
#  (unidad equivalente si se arma a mano)
#    [Unit]
#    Description=Lab deploy mirror (M6)
#    After=network-online.target
#    [Service]
#    ExecStart=/usr/bin/python3 -m http.server 8000 --directory /srv
#    Restart=on-failure
#    [Install]
#    WantedBy=multi-user.target
# ============================================================================

set -euo pipefail

ROOT="${LAB_SERVE_ROOT:-/srv}"
PORT="${LAB_SERVE_PORT:-8000}"
BIND="${LAB_SERVE_BIND:-0.0.0.0}"
URL_HOST="${LAB_URL_HOST:-10.10.10.20}"

usage() {
  cat <<'EOF'
Uso: bash lab/m6/serve.sh [PUERTO] [opciones]

  --port N    puerto de escucha (def. 8000)
  --root DIR  directorio publicado (def. /srv)
  --bind IP   interfaz de escucha (def. 0.0.0.0)
  -h, --help  esta ayuda

Nota: en foreground. Para servicio: sudo bash lab/m6/install.sh --service
EOF
}

while (($#)); do
  case "$1" in
    --port)  PORT="${2:?--port necesita un número}"; shift 2 ;;
    --port=*) PORT="${1#*=}"; shift ;;
    --root)  ROOT="${2:?--root necesita una ruta}"; shift 2 ;;
    --root=*) ROOT="${1#*=}"; shift ;;
    --bind)  BIND="${2:?--bind necesita una IP}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *[!0-9]*) die "argumento inválido: $1 (ver --help)" ;;
    *) PORT="$1"; shift ;;
  esac
done

[[ "$PORT" =~ ^[0-9]+$ ]] || { echo "puerto inválido: $PORT" >&2; exit 2; }
[[ -d "$ROOT" ]] || { echo "no existe el directorio a publicar: $ROOT" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "falta python3" >&2; exit 1; }

for f in bootstrap.sh bootstrap.ps1 lab.tar.gz; do
  [[ -s "$ROOT/$f" ]] || echo "[WARN] falta $ROOT/$f (¿corriste lab/m6/install.sh?)" >&2
done

cat <<EOF
────────────────────────────────────────────────────────
  Servidor de despliegue · lab uni.lab · M6
  raíz:   $ROOT
  escucha: http://$BIND:$PORT  (desde la LAN: http://$URL_HOST:$PORT)

  Ubuntu : curl -fsSL http://$URL_HOST:$PORT/bootstrap.sh | sudo bash -s m1
  Windows: iwr http://$URL_HOST:$PORT/bootstrap.ps1 -UseBasicParsing -OutFile \$env:TEMP\\bootstrap.ps1
  paquete: http://$URL_HOST:$PORT/lab.tar.gz

  Ctrl-C para detener. Servicio: sudo bash lab/m6/install.sh --service
────────────────────────────────────────────────────────
EOF

# exec reemplaza este shell: las señales (Ctrl-C) llegan directo al servidor.
exec python3 -m http.server "$PORT" --bind "$BIND" --directory "$ROOT"
