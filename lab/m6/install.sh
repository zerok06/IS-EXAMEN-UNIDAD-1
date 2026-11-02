#!/usr/bin/env bash
# ============================================================================
#  lab/m6/install.sh — convierte a M6 (Kali, 10.10.10.20) en el servidor de
#  despliegue y en el puesto de ataque del laboratorio.
# ----------------------------------------------------------------------------
#  Qué hace:
#    1. instala las herramientas de ataque/enumera­ción (desde el repo local de
#       Kali; el laboratorio está aislado y no se descarga nada de Internet)
#    2. copia el repo a /srv/lab  (rsync -a --exclude .git ./ /srv/lab/)
#    3. empaqueta el despliegue: /srv/lab.tar.gz y /srv/lab.zip
#    4. publica bootstrap.sh / bootstrap.ps1 y /srv/artifacts en la raíz HTTP
#    5. aplica la red de M6: eth1 en 10.10.10.20/24 sin gateway y DNS partido
#       (*.uni.lab -> M4, resto -> NAT). Con LAB_HOSTS=1 añade además /etc/hosts
#       como plan B (por defecto NO: taparía al DNS de M4)
#    6. deja lab/m6/serve.sh listo (y, con --service, una unidad systemd)
#
#  Uso:
#    sudo bash lab/m6/install.sh
#    sudo bash lab/m6/install.sh --repo /ruta/al/repo --no-tar
#    sudo bash lab/m6/install.sh --service        # servidor HTTP como servicio
#
#  Idempotente: se puede reejecutar; rehace la copia y los paquetes.
# ============================================================================

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# La lib espera el layout del repo: artefactos al lado de lab/.
LAB_REPO_DIR="${LAB_REPO_DIR:-$(cd "$HERE/../.." 2>/dev/null && pwd || echo /opt/lab)}"
LAB_ARTIFACTS="${LAB_ARTIFACTS:-$LAB_REPO_DIR/artifacts}"
export LAB_REPO_DIR LAB_ARTIFACTS

# shellcheck source=../common/lib.sh
. "$HERE/../common/lib.sh"

LAB_ROLE=m6
export LAB_ROLE

SERVE_ROOT="${LAB_SERVE_ROOT:-/srv}"
DEST="${LAB_DEPLOY_DIR:-$SERVE_ROOT/lab}"
TARBALL="$SERVE_ROOT/lab.tar.gz"
ZIPFILE="$SERVE_ROOT/lab.zip"
SRC=""
MAKE_TAR=1
WITH_SERVICE=0

# Los paquetes que el laboratorio necesita sí o sí en M6.
PKGS=(
  nmap curl openssl sshpass hydra python3 python3-pip netcat-openbsd
  smbclient ftp dnsutils proxychains4 jq git redis-tools
)
# Paquetes de apoyo para la cadena (04/05 y el pivote). Si Kali no los trae,
# se avisa y se continúa.
PKGS_OPT=(
  nfs-common default-mysql-client freerdp2-x11 tigervnc-viewer zip
  metasploit-framework
  python3-impacket impacket-scripts evil-winrm netexec
)

usage() {
  cat <<'EOF'
Uso: sudo bash lab/m6/install.sh [opciones]

  --repo DIR     raíz del repo a publicar (def. autodetectada)
  --dest DIR     destino de la copia (def. /srv/lab)
  --no-tar       no regenerar lab.tar.gz / lab.zip
  --service      crear y habilitar lab-serve.service (python http.server :8000)
  -h, --help     esta ayuda
EOF
}

while (($#)); do
  case "$1" in
    --repo)   SRC="${2:?--repo necesita una ruta}"; shift 2 ;;
    --repo=*) SRC="${1#*=}"; shift ;;
    --dest)   DEST="${2:?--dest necesita una ruta}"; shift 2 ;;
    --dest=*) DEST="${1#*=}"; shift ;;
    --no-tar) MAKE_TAR=0; shift ;;
    --service) WITH_SERVICE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "opción desconocida: $1 (ver --help)" ;;
  esac
done

# --------------------------------------------------------------- pre-vuelo
require_root
need_cmd apt-get
need_cmd rsync

lab_banner
. /etc/os-release 2>/dev/null || true
step "sistema"
log "SO: ${PRETTY_NAME:-desconocido}"
[[ "${ID:-}" == kali ]] || warn "se esperaba Kali en M6; detectado: ${ID:-?} (se continúa)"
need_cmd python3 || die "python3 es obligatorio para serve.sh"

# --------------------------------------------------------------- herramientas
step "herramientas de ataque y enumeración"
# apt_install (lib) aborta si apt no puede resolver; en un lab aislado eso pasa
# cuando falta un paquete y no hay espejo. Se intenta y, si falla, se sigue:
# la verificación posterior decide qué es realmente imprescindible.
ERR_TRAP="$(trap -p ERR)"
try_apt() {
  trap - ERR
  set +e
  apt_install "$@"
  local rc=$?
  set -e
  eval "$ERR_TRAP"
  return "$rc"
}

missing=()
for p in "${PKGS[@]}"; do
  dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
done
if ((${#missing[@]} == 0)); then
  ok "herramientas ya presentes"
else
  log "faltan paquetes: ${missing[*]}"
  if try_apt "${missing[@]}"; then
    ok "paquetes instalados"
  else
    warn "apt no pudo instalar todo (lab aislado, sin Internet)."
    warn "faltan: ${missing[*]} — instalarlos desde el medio local de Kali."
  fi
fi

# Opcionales: solo se piden si el índice local de Kali los conoce.
opt_ok=()
for p in "${PKGS_OPT[@]}"; do
  if apt-cache show "$p" >/dev/null 2>&1; then
    opt_ok+=("$p")
  else
    warn "paquete no disponible en este Kali: $p (se omite)"
  fi
done
if ((${#opt_ok[@]})); then
  missing_opt=()
  for p in "${opt_ok[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing_opt+=("$p")
  done
  if ((${#missing_opt[@]})); then
    try_apt "${missing_opt[@]}" || warn "no se pudieron instalar opcionales: ${missing_opt[*]}"
  else
    ok "opcionales ya presentes"
  fi
fi

step "verificación de binarios"
missing_bin=()
for c in nmap curl openssl sshpass hydra python3 nc smbclient ftp dig proxychains4 jq git; do
  command -v "$c" >/dev/null 2>&1 || missing_bin+=("$c")
done
if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
  ok "pip presente"
else
  missing_bin+=("pip3")
fi
if ((${#missing_bin[@]})); then
  warn "binarios ausentes: ${missing_bin[*]}"
else
  ok "todos los binarios base presentes"
fi
# Sin python3/curl/tar no hay servidor de despliegue posible.
need_cmd python3
need_cmd curl

# Herramientas de la cadena que se usan si existen (no son obligatorias para
# desplegar, sí para la demo de los saltos 4 y 5).
for c in impacket-wmiexec.py impacket-psexec.py evil-winrm nxc netexec xfreerdp; do
  if command -v "$c" >/dev/null 2>&1; then
    ok "extra: $c"
  else
    warn "extra ausente: $c (los saltos 04/05 lo usan si está)"
  fi
done

# --------------------------------------------------------------- origen
step "origen del despliegue"
is_repo_root() { [[ -f "$1/lab/bootstrap.sh" && -d "$1/artifacts" ]]; }
is_lab_root()  { [[ -f "$1/bootstrap.sh" && -d "$1/m6" ]]; }

if [[ -z "$SRC" ]]; then
  for cand in "$HERE/../.." "$HERE/.." "$PWD" /srv/lab "$LAB_REPO_DIR"; do
    [[ -n "$cand" && -d "$cand" ]] || continue
    cand="$(cd "$cand" && pwd)"
    if is_repo_root "$cand" || is_lab_root "$cand"; then SRC="$cand"; break; fi
  done
fi
[[ -n "$SRC" && -d "$SRC" ]] || die "no se encontró el repo (usar --repo DIR)"
SRC="$(cd "$SRC" && pwd)"
log "origen: $SRC"
if is_repo_root "$SRC"; then
  ok "layout: repo completo (lab/ + artifacts/)"
elif is_lab_root "$SRC"; then
  warn "layout: solo lab/ (sin artifacts/); los instaladores no tendrán artefactos locales"
else
  die "$SRC no parece la raíz del repo (falta lab/bootstrap.sh o artifacts/)"
fi

mkdir -p "$SERVE_ROOT"

# --------------------------------------------------------------- copia
step "copia del repo a $DEST"
if [[ "$SRC" == "$DEST" ]]; then
  ok "el repo ya vive en $DEST; no se copia sobre sí mismo"
else
  mkdir -p "$DEST"
  # --delete mantiene /srv/lab igual al repo; .git nunca se publica.
  # pki/out se protege de borrado: son certificados ya emitidos que no deben
  # desaparecer al reejecutar el instalador (se copian si vienen en el repo).
  rsync -a --delete \
    --exclude '.git/' --exclude 'lab.tar.gz' \
    --exclude 'legacy/' --exclude 'artifacts/fixed/' \
    --filter 'P lab/pki/out/***' --filter 'P pki/out/***' \
    "$SRC/" "$DEST/"
  ok "repo copiado: $(du -sh "$DEST" | cut -f1)"
fi

# Layout del laboratorio dentro de la copia: <repo>/lab o <repo> (solo lab/).
LAB_DIR="$DEST/lab"
[[ -d "$LAB_DIR" ]] || LAB_DIR="$DEST"

[[ -d "$DEST/artifacts" ]] || warn "sin $DEST/artifacts: fetch_artifact dependerá del espejo"

# --------------------------------------------------------------- publicación
step "publicación HTTP en la raíz $SERVE_ROOT"
install -m 0755 "$LAB_DIR/bootstrap.sh"  "$SERVE_ROOT/bootstrap.sh"
install -m 0644 "$LAB_DIR/bootstrap.ps1" "$SERVE_ROOT/bootstrap.ps1"
ok "bootstrap.sh / bootstrap.ps1 publicados"

# fetch_artifact pide $LAB_MIRROR/artifacts/<rel>; el symlink lo resuelve.
if [[ -d "$DEST/artifacts" ]]; then
  ln -sfn "$DEST/artifacts" "$SERVE_ROOT/artifacts"
  ok "artifacts/ enlazado en $SERVE_ROOT/artifacts"
else
  warn "no se creó el enlace artifacts/ (no existe el directorio)"
fi

chmod +x \
  "$LAB_DIR/bootstrap.sh" \
  "$LAB_DIR/m6/serve.sh" 2>/dev/null || true
# Los scripts de cadena, PKI y tests se ejecutan desde M6: bits de ejecución.
find "$LAB_DIR" -type f \( -path '*/chain/*.sh' -o -path '*/pki/*.sh' \
  -o -path '*/tests/*.sh' -o -path '*/m6/*.sh' \) -exec chmod +x {} + 2>/dev/null || true
ok "bits de ejecución aplicados"

# --------------------------------------------------------------- empaquetado
if (( MAKE_TAR )); then
  step "empaquetado del despliegue"
  log "tar czf $TARBALL -C $DEST ."
  tar czf "$TARBALL" -C "$DEST" --exclude='./.git' --exclude='./legacy' --exclude='./artifacts/fixed' . \
    || die "falló el empaquetado tar"
  chmod 0644 "$TARBALL"
  ok "tar: $TARBALL ($(du -h "$TARBALL" | cut -f1))"

  # Huella del paquete: bootstrap.sh la verifica antes de extraer.
  ( cd "$SERVE_ROOT" && sha256sum "$(basename "$TARBALL")" > "$(basename "$TARBALL").sha256" )
  chmod 0644 "$TARBALL.sha256"
  ok "sha256: $(cat "$TARBALL.sha256")"

  if command -v zip >/dev/null 2>&1; then
    log "zip -qr $ZIPFILE . (en $DEST)"
    rm -f "$ZIPFILE"
    ( cd "$DEST" && zip -qr "$ZIPFILE" . -x '.git/*' 'legacy/*' 'artifacts/fixed/*' ) \
      || warn "falló zip; M4/M5 pueden usar el tarball manualmente"
    if [[ -s "$ZIPFILE" ]]; then
      chmod 0644 "$ZIPFILE"
      ( cd "$SERVE_ROOT" && sha256sum "$(basename "$ZIPFILE")" > "$(basename "$ZIPFILE").sha256" )
      chmod 0644 "$ZIPFILE.sha256"
      ok "zip: $ZIPFILE ($(du -h "$ZIPFILE" | cut -f1))"
    fi
  else
    warn "falta 'zip': no se generó $ZIPFILE (bootstrap.ps1 lo necesita)"
    warn "instalar con: sudo apt-get install -y zip   (o servir el .zip desde el medio local)"
  fi
else
  ok "empaquetado omitido (--no-tar)"
fi

# --------------------------------------------------------------- red y DNS
# M6 tiene dos NIC: NAT (Internet + ruta por defecto) y bridge (10.10.10.0/24).
# El DNS de uni.lab es M4 (10.10.10.14), que se instala sin reenviadores, así que
# se usa un resolvedor partido en 127.0.0.1 (lab/m6/net.sh) en lugar de poner a
# M4 como resolver global. Todo eso lo aplica net.sh.
if [[ -x "$HERE/net.sh" || -f "$HERE/net.sh" ]]; then
  step "red y DNS partido (m6/net.sh)"
  if bash "$HERE/net.sh"; then
    ok "eth1 en $M6 y uni.lab resuelto vía M4 ($M4)"
  else
    warn "net.sh falló; revisa la NIC del bridge y vuelve a ejecutarlo"
  fi
fi

# --------------------------------------------------------------- /etc/hosts
# Solo plan B: un registro en /etc/hosts gana sobre el DNS (nsswitch: files dns)
# y taparía a M4, que es la fuente de verdad de la zona. Se activa con
# LAB_HOSTS=1 para trabajar con el laboratorio apagado.
if [[ "${LAB_HOSTS:-0}" == "1" ]]; then
  step "/etc/hosts del laboratorio (plan B, LAB_HOSTS=1)"
  HOSTS=/etc/hosts
  ensure_line "$HOSTS" "10.10.10.11 app.uni.lab"
  ensure_line "$HOSTS" "10.10.10.11 wp.uni.lab"
  ensure_line "$HOSTS" "10.10.10.11 moodle.uni.lab"
  ensure_line "$HOSTS" "10.10.10.12 db.uni.lab"
  ensure_line "$HOSTS" "10.10.10.13 bkp.uni.lab"
  ensure_line "$HOSTS" "10.10.10.14 srvold.uni.lab"
  ensure_line "$HOSTS" "10.10.10.15 pc-est01.uni.lab"
  ok "nombres de $LAB_DOMAIN añadidos (plan B)"
else
  step "/etc/hosts del laboratorio"
  ok "sin entradas: uni.lab se resuelve por M4 (usa LAB_HOSTS=1 para el plan B)"
fi

# --------------------------------------------------------------- servicio
if (( WITH_SERVICE )); then
  step "servicio systemd lab-serve"
  if ! command -v systemctl >/dev/null 2>&1; then
    warn "sin systemd: usar $LAB_DIR/m6/serve.sh en foreground"
  else
    write_if_changed /etc/systemd/system/lab-serve.service <<EOF
[Unit]
Description=Lab deploy mirror (M6, 10.10.10.20:8000)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$SERVE_ROOT
ExecStart=/usr/bin/python3 -m http.server 8000 --bind 0.0.0.0 --directory $SERVE_ROOT
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    enable_now lab-serve.service
  fi
fi

# --------------------------------------------------------------- resumen
step "resumen"
printf 'repo publicado:  %s\n' "$DEST" >&2
printf 'paquetes:        %s\n' "$TARBALL" >&2
[[ -s "$ZIPFILE" ]] && printf '                 %s\n' "$ZIPFILE" >&2
printf 'artefactos:      %s/artifacts\n' "$SERVE_ROOT" >&2

cat <<EOF >&2

Arrancar el servidor de despliegue:
  sudo bash $LAB_DIR/m6/serve.sh
  # opcional como servicio: sudo bash lab/m6/install.sh --service

Desde cada VM:
  Ubuntu : curl -fsSL http://10.10.10.20:8000/bootstrap.sh | sudo bash -s m1
  Windows: iwr http://10.10.10.20:8000/bootstrap.ps1 -UseBasicParsing -OutFile \$env:TEMP\\bootstrap.ps1
           powershell -NoProfile -ExecutionPolicy Bypass -File \$env:TEMP\\bootstrap.ps1 -Role m4

Prueba de humo desde M6:
  bash $LAB_DIR/tests/smoke.sh

EOF

if ss -ltn 2>/dev/null | grep -q ':8000 '; then
  warn "el puerto 8000 ya está en uso (¿otro serve.sh corriendo?)"
fi
