#!/usr/bin/env bash
# capture.sh — ejecuta un comando en una terminal, guarda log completo y captura la ventana.
# Uso: ./capture.sh <ID> "<Título>" "<comando>" [segundos_visibles]
# Requiere: xdotool + import (ImageMagick) y xterm o qterminal.
set -uo pipefail

ROOT="/home/kali/IS-EXAMEN-UNIDAD-1/informe"
ID="${1:?ID requerido}"
TITLE="${2:?Título requerido}"
CMD="${3:?Comando requerido}"
HOLD="${4:-20}"

LOG="$ROOT/evidencias/logs/${ID}.log"
PNG="$ROOT/evidencias/png/${ID}.png"
TMP="/tmp/opencode/cap-${ID}.sh"
DONE="/tmp/opencode/cap-${ID}.done"
CMD_B64="$(printf '%s' "$CMD" | base64 -w0)"

mkdir -p "$ROOT/evidencias/logs" "$ROOT/evidencias/png" /tmp/opencode
rm -f "$DONE" "$LOG" "$PNG"

cat > "$TMP" <<EOF
#!/usr/bin/env bash
printf '\\033]0;${ID}\\007'
export PS1='[\\u@\\h \\D{%F %T} UTC]\\$ '
CMD="\$(printf '%s' '${CMD_B64}' | base64 -d)"
clear
{
  printf '=== %s · %s ===\\n' '${ID}' '${TITLE}'
  printf 'Host: %s · Fecha UTC: %s\\n' "\$(hostname)" "\$(date -u +%FT%TZ)"
  printf 'Comando:\\n%s\\n' "\$CMD"
  printf '%s\\n' '----------------------------------------------------------------------'
  bash -c "\$CMD" 2>&1
  rc=\$?
  printf '%s\\n' '----------------------------------------------------------------------'
  printf '[exit=%s] · Evidencia: %s\\n' "\$rc" '${PNG}'
  date -u +'Cierre UTC: %FT%TZ'
} | tee '${LOG}'
touch '${DONE}'
sleep ${HOLD}
EOF
chmod +x "$TMP"

if command -v xterm >/dev/null 2>&1; then
  xterm -T "$ID" -geometry 170x45+10+10 -fa 'DejaVu Sans Mono' -fs 10 -e bash "$TMP" >/dev/null 2>&1 &
elif command -v qterminal >/dev/null 2>&1; then
  qterminal -e bash "$TMP" >/dev/null 2>&1 &
else
  echo "ERROR: no hay xterm ni qterminal" >&2
  exit 1
fi
XPID=$!

for _ in $(seq 1 240); do
  [ -f "$DONE" ] && break
  sleep 0.5
done

WIN=$(xdotool search --name "$ID" 2>/dev/null | head -1)
if [ -n "${WIN:-}" ]; then
  xdotool windowsize "$WIN" 1600 700 2>/dev/null || true
  xdotool windowmove "$WIN" 0 0 2>/dev/null || true
  xdotool mousemove 1200 760 2>/dev/null || true
  sleep 2
  import -window "$WIN" "$PNG" 2>/dev/null || true
fi

pkill -f "cap-${ID}.sh" 2>/dev/null || true
kill "$XPID" 2>/dev/null || true
pkill -f "qterminal -e bash ${TMP}" 2>/dev/null || true

echo "LOG=$LOG"
echo "PNG=$PNG"
if [ -f "$LOG" ]; then
  echo "---- últimas líneas ----"
  tail -20 "$LOG"
fi
