#!/usr/bin/env bash
# ============================================================================
#  lab/bootstrap.sh — arranque de una VM Ubuntu del laboratorio (M1/M2/M3/M6)
# ----------------------------------------------------------------------------
#  Se ejecuta EN la VM, desde su consola, apuntando al servidor de M6:
#
#    curl -fsSL http://10.10.10.20:8000/bootstrap.sh | sudo bash -s m1
#    curl -fsSL http://10.10.10.20:8000/bootstrap.sh | sudo bash -s m2
#
#  Qué hace:
#    1. exige root y comprueba curl + tar
#    2. descarga http://10.10.10.20:8000/lab.tar.gz a /tmp
#    3. extrae el paquete en un stage y reemplaza /opt/lab
#    4. ejecuta /opt/lab/<rol>/install.sh
#
#  Idempotente: se puede reejecutar cuantas veces haga falta. El paquete nuevo
#  se valida ANTES de tocar /opt/lab, y si el role no viene en el paquete se
#  aborta sin destruir la instalación previa. Si el reemplazo no llega a
#  completarse, el trap restaura el /opt/lab anterior; si lo que falla es el
#  instalador, se conserva el código nuevo y el respaldo en /opt/lab.old.<pid>.
#
#  No usa lab/common/lib.sh a propósito: la lib viaja dentro del propio
#  tarball que este script descarga, así que aquí se replica el logging mínimo.
#  Los instaladores sí usan la lib.
# ============================================================================

set -euo pipefail

MIRROR="${LAB_MIRROR:-http://10.10.10.20:8000}"
DEST="${LAB_REPO_DIR:-/opt/lab}"
ROLE=""
STAGE=""
OLD=""
TMPFILE=""

# --------------------------------------------------------------- logging
_ts()  { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
say()  { printf '%s [bootstrap] %s\n' "$(_ts)" "$*" >&2; }
ok()   { printf '[ OK ] %s\n' "$*" >&2; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die()  { printf '[FAIL] %s\n' "$*" >&2; exit 1; }
step() { printf '\n== %s ==\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Uso:
  curl -fsSL http://10.10.10.20:8000/bootstrap.sh | sudo bash -s <rol>

Roles Linux válidos: m1 | m2 | m3 | m6
  (M4 y M5 son Windows: usar bootstrap.ps1)

Opciones (después del rol):
  --mirror URL    servidor de despliegue (def. http://10.10.10.20:8000)
  --dest DIR      destino de extracción (def. /opt/lab)
  -h, --help      esta ayuda

Ejemplos:
  curl -fsSL http://10.10.10.20:8000/bootstrap.sh | sudo bash -s m1
  curl -fsSL http://10.10.10.20:8000/bootstrap.sh | sudo bash -s m3 --mirror http://10.10.10.20:8000
EOF
}

# --------------------------------------------------------------- limpieza
cleanup() {
  local rc=$?
  [[ -n "$TMPFILE" && -f "$TMPFILE" ]] && rm -f "$TMPFILE" "$TMPFILE.sha256"
  [[ -n "$STAGE" && -d "$STAGE" ]] && rm -rf "$STAGE"
  if [[ -n "$OLD" && -d "$OLD" ]]; then
    if (( rc != 0 )) && [[ ! -e "$DEST" ]]; then
      mv "$OLD" "$DEST" && warn "instalación anterior restaurada en $DEST"
    elif (( rc != 0 )); then
      warn "el instalador falló; el código nuevo quedó en $DEST y el anterior en $OLD"
    else
      rm -rf "$OLD"
    fi
  fi
  exit "$rc"
}
trap cleanup EXIT

# --------------------------------------------------------------- argumentos
while (($#)); do
  case "$1" in
    --mirror)   MIRROR="${2:?--mirror necesita una URL}"; shift 2 ;;
    --mirror=*) MIRROR="${1#*=}"; shift ;;
    --dest)     DEST="${2:?--dest necesita una ruta}"; shift 2 ;;
    --dest=*)   DEST="${1#*=}"; shift ;;
    -h|--help)  usage; exit 0 ;;
    -*)         die "opción desconocida: $1 (ver --help)" ;;
    *)          [[ -z "$ROLE" ]] || die "argumento de más: $1"; ROLE="$1"; shift ;;
  esac
done

[[ -n "$ROLE" ]] || { usage >&2; die "falta el rol (m1, m2, m3 o m6)"; }

case "$ROLE" in
  m1|m2|m3|m6) ;;
  m4|m5) die "el rol '$ROLE' es Windows: usar bootstrap.ps1 -Role $ROLE" ;;
  *)     die "rol inválido: '$ROLE' (válidos: m1, m2, m3, m6)" ;;
esac

# --------------------------------------------------------------- pre-vuelo
step "pre-vuelo"
[[ ${EUID:-$(id -u)} -eq 0 ]] || die "ejecutar como root: curl -fsSL $MIRROR/bootstrap.sh | sudo bash -s $ROLE"
ok "root"

command -v curl >/dev/null 2>&1 || die "falta curl en la VM (apt-get install -y curl desde el medio local)"
command -v tar  >/dev/null 2>&1 || die "falta tar en la VM"
command -v gzip >/dev/null 2>&1 || die "falta gzip en la VM"
command -v sha256sum >/dev/null 2>&1 || die "falta sha256sum en la VM (coreutils)"
ok "curl, tar, gzip y sha256sum presentes"

if [[ -e "$DEST" && ! -d "$DEST" ]]; then
  die "$DEST existe y no es un directorio; revisar a mano"
fi

# Restos de ejecuciones anteriores (stage/backup huérfanos por un fallo previo).
for stale in "$DEST".stage.* "$DEST".old.*; do
  [[ -e "$stale" ]] || continue
  warn "limpiando resto de una ejecución anterior: $stale"
  rm -rf "$stale"
done

# --------------------------------------------------------------- descarga
step "descarga del paquete"
TMPFILE=$(mktemp /tmp/lab.tar.gz.XXXXXX)
say "GET $MIRROR/lab.tar.gz"
curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 5 --max-time 600 \
     -o "$TMPFILE" "$MIRROR/lab.tar.gz" \
  || die "no se pudo descargar $MIRROR/lab.tar.gz (¿M6 arriba y sirviendo en :8000?)"
[[ -s "$TMPFILE" ]] || die "lab.tar.gz llegó vacío"
ok "paquete descargado: $(du -h "$TMPFILE" | cut -f1)"

# Integridad: si el espejo publica lab.tar.gz.sha256, se verifica antes de
# extraer nada. Es obligatorio que exista en un despliegue normal; si falta,
# se avisa y se sigue (el espejo puede ser un repo recién empaquetado a mano).
step "integridad del paquete"
if curl -fsSL --connect-timeout 5 --max-time 30 -o "$TMPFILE.sha256" \
     "$MIRROR/lab.tar.gz.sha256" 2>/dev/null; then
  want=$(awk '{print $1; exit}' "$TMPFILE.sha256")
  got=$(sha256sum "$TMPFILE" | awk '{print $1}')
  [[ -n "$want" && "$want" == "$got" ]] || die "SHA256 de lab.tar.gz no coincide
  esperado: $want
  obtenido: $got"
  ok "SHA256 OK: $got"
else
  warn "el espejo no publica lab.tar.gz.sha256; se continúa sin verificar"
fi
rm -f "$TMPFILE.sha256"

# --------------------------------------------------------------- validación
step "validación del paquete"
listing=$(tar tzf "$TMPFILE" 2>/dev/null) || die "lab.tar.gz corrupto o no es un tar.gz"
[[ -n "$listing" ]] || die "lab.tar.gz sin entradas"

# El paquete puede traer el laboratorio en la raíz (m1/install.sh) o el repo
# completo (lab/m1/install.sh). Se aceptan ambos; el instalador se resuelve luego.
INST_REL=""
for cand in "$ROLE/install.sh" "lab/$ROLE/install.sh"; do
  if grep -qx -- "$cand" <<<"$(sed 's|^\./||' <<<"$listing")"; then
    INST_REL="$cand"; break
  fi
done
[[ -n "$INST_REL" ]] || die "el paquete no trae el rol '$ROLE' (falta $ROLE/install.sh o lab/$ROLE/install.sh).
  Roles incluidos: $(sed 's|^\./||' <<<"$listing" | awk -F/ '$NF=="install.sh"{print $(NF-1)}' | sort -u | paste -sd' ' -)"
ok "rol '$ROLE' presente en el paquete ($INST_REL)"

# --------------------------------------------------------------- extracción
step "extracción en $DEST"
STAGE="${DEST}.stage.$$"
rm -rf "$STAGE"
mkdir -p "$STAGE"
tar xzf "$TMPFILE" -C "$STAGE" --no-same-owner || die "falló la extracción"
[[ -f "$STAGE/$INST_REL" ]] || die "el paquete no dejó $INST_REL tras extraer"
ok "extraído en $STAGE"

# Reemplazo atómico: el stage ya está completo y validado.
if [[ -d "$DEST" ]]; then
  OLD="${DEST}.old.$$"
  say "reemplazando $DEST (respaldo temporal en $OLD)"
  mv "$DEST" "$OLD"
fi
mv "$STAGE" "$DEST"
STAGE=""
ok "instalado en $DEST"

# --------------------------------------------------------------- instalador
step "instalador del rol $ROLE"
INST="$DEST/$INST_REL"
chmod +x "$INST" 2>/dev/null || true

# Los instaladores esperan el layout del repo (artefactos al lado de lab/).
# Se prueban los dos layouts posibles; si no hay artefactos locales, la lib
# los bajará del espejo.
ART=""
for cand in "$DEST/artifacts" "$DEST/lab/artifacts" "$(dirname "$DEST/$INST_REL")/../artifacts"; do
  if [[ -d "$cand" ]]; then ART="$(cd "$cand" && pwd)"; break; fi
done
[[ -n "$ART" ]] || ART="$DEST/artifacts"

# shellcheck disable=SC2086
LAB_ROLE="$ROLE" \
LAB_MIRROR="$MIRROR" \
LAB_REPO_DIR="$DEST" \
LAB_ARTIFACTS="$ART" \
  bash "$INST"

# El instalador corrió bien: se descarta el respaldo anterior.
if [[ -n "$OLD" && -d "$OLD" ]]; then
  rm -rf "$OLD"
  OLD=""
fi

# --------------------------------------------------------------- resumen
step "resumen"
ok "rol $ROLE instalado desde $MIRROR"
printf 'repo:   %s\n' "$DEST" >&2
printf 'log:    %s\n' "${LAB_LOG:-/var/log/lab-install.log}" >&2

VERIFY="$(dirname "$INST")/verify.sh"
if [[ -f "$VERIFY" ]]; then
  printf '\nSiguiente paso:\n  sudo bash %s\n' "$VERIFY" >&2
else
  printf '\nSin verify.sh para este rol; revisar el log del instalador.\n' >&2
fi

if [[ "$ROLE" == m6 ]]; then
  printf '  sudo bash %s/m6/serve.sh\n' "$(dirname "$DEST/$INST_REL")" >&2
fi
