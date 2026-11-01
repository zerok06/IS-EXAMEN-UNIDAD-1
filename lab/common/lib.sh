#!/usr/bin/env bash
# lab/common/lib.sh — utilidades compartidas por todos los instaladores.
# Uso:  source "$(dirname "$0")/../common/lib.sh"

set -euo pipefail

# ---------------------------------------------------------------- constantes
LAB_DOMAIN="${LAB_DOMAIN:-uni.lab}"
LAB_NET="${LAB_NET:-10.10.10.0/24}"
LAB_GW="${LAB_GW:-10.10.10.1}"
LAB_REPO_DIR="${LAB_REPO_DIR:-/opt/lab}"
LAB_ARTIFACTS="${LAB_ARTIFACTS:-$LAB_REPO_DIR/artifacts}"
LAB_MIRROR="${LAB_MIRROR:-http://10.10.10.20:8000}"

R0=10.10.10.1
M1=10.10.10.11
M2=10.10.10.12
M3=10.10.10.13
M4=10.10.10.14
M5=10.10.10.15
M6=10.10.10.20

LAB_LOG="${LAB_LOG:-/var/log/lab-install.log}"

# ---------------------------------------------------------------- logging
_c_reset=$'\033[0m'; _c_red=$'\033[31m'; _c_grn=$'\033[32m'
_c_yel=$'\033[33m'; _c_blu=$'\033[36m'

_ts() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
log()  { printf '%s [%s] %s\n' "$(_ts)" "${LAB_ROLE:-lab}" "$*" | tee -a "$LAB_LOG" >&2; }
ok()   { printf '%s %s\n' "${_c_grn}[ OK ]${_c_reset}" "$*" | tee -a "$LAB_LOG" >&2; }
warn() { printf '%s %s\n' "${_c_yel}[WARN]${_c_reset}" "$*" | tee -a "$LAB_LOG" >&2; }
die()  { printf '%s %s\n' "${_c_red}[FAIL]${_c_reset}" "$*" | tee -a "$LAB_LOG" >&2; exit 1; }
step() { printf '\n%s== %s ==%s\n' "${_c_blu}" "$*" "${_c_reset}" | tee -a "$LAB_LOG" >&2; }

trap 'die "fallo en ${BASH_SOURCE[0]}:${LINENO} (cmd: ${BASH_COMMAND})"' ERR

# ---------------------------------------------------------------- básicos
require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || die "ejecutar como root (sudo)"
  mkdir -p "$(dirname "$LAB_LOG")"; touch "$LAB_LOG"
}

require_ubuntu() {
  . /etc/os-release 2>/dev/null || die "no es Ubuntu/Debian"
  [[ ${ID:-} == ubuntu || ${ID:-} == debian ]] || die "SO no soportado: ${ID:-?}"
}

# apt sin preguntas ni recomendados; no falla si ya está instalado
apt_install() {
  export DEBIAN_FRONTEND=noninteractive
  local pkgs=("$@")
  local missing=()
  for p in "${pkgs[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  ((${#missing[@]})) || { ok "paquetes ya presentes: ${pkgs[*]}"; return 0; }
  log "apt install: ${missing[*]}"
  apt-get update -qq
  apt-get install -y -qq --no-install-recommends "${missing[@]}"
}

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "falta comando: $1"; }

# ---------------------------------------------------------------- red
set_static_ip() {
  local ip="$1" iface="${2:-ens33}"
  local cidr="${ip}/24"
  step "red estática ${cidr} en ${iface} (gw ${LAB_GW}, dns ${M4})"
  if command -v netplan >/dev/null 2>&1; then
    cat > /etc/netplan/99-lab.yaml <<EOF
network:
  version: 2
  ethernets:
    ${iface}:
      dhcp4: false
      addresses: [${cidr}]
      routes:
        - to: default
          via: ${LAB_GW}
      nameservers:
        addresses: [${M4}]
EOF
    chmod 600 /etc/netplan/99-lab.yaml
    netplan apply
  else
    die "netplan no disponible; configurar IP a mano"
  fi
  ip -brief addr show "$iface" | tee -a "$LAB_LOG"
}

# ---------------------------------------------------------------- artefactos
# fetch_artifact <ruta-relativa-en-artifacts> <destino>
# Nunca descarga de Internet: primero local, luego espejo de M6.
fetch_artifact() {
  local rel="$1" dst="$2"
  [[ -s "$dst" ]] && { ok "artefacto presente: $dst"; return 0; }
  mkdir -p "$(dirname "$dst")"
  if [[ -f "$LAB_ARTIFACTS/$rel" ]]; then
    cp -f "$LAB_ARTIFACTS/$rel" "$dst"
  else
    log "artefacto $rel no está local; bajando de $LAB_MIRROR/artifacts/$rel"
    curl -fsSL --retry 3 -o "$dst.part" "$LAB_MIRROR/artifacts/$rel" \
      || die "no se pudo obtener $rel (¿M6 arriba y sirviendo?)"
    mv -f "$dst.part" "$dst"
  fi
  ok "artefacto listo: $dst ($(du -h "$dst" | cut -f1))"
}

sha256_check() {
  local file="$1" want="$2"
  local got; got=$(sha256sum "$file" | awk '{print $1}')
  [[ "$got" == "$want" ]] || die "SHA256 no coincide para $file
  esperado: $want
  obtenido: $got"
  ok "SHA256 OK: $(basename "$file")"
}

# ---------------------------------------------------------------- idempotencia
# write_if_changed <archivo> <<'EOF' ... EOF
write_if_changed() {
  local f="$1" tmp; tmp=$(mktemp)
  cat > "$tmp"
  if [[ -f "$f" ]] && cmp -s "$tmp" "$f"; then
    rm -f "$tmp"; ok "sin cambios: $f"
  else
    install -D -m 0644 "$tmp" "$f"; rm -f "$tmp"; log "escrito: $f"
  fi
}

ensure_line() { # ensure_line <archivo> <línea>
  local f="$1" line="$2"
  grep -qxF -- "$line" "$f" 2>/dev/null || printf '%s\n' "$line" >> "$f"
}

# ---------------------------------------------------------------- servicios
enable_now() {
  if systemctl enable --now "$1" >/dev/null 2>&1; then
    ok "servicio: $1"
    return 0
  fi
  systemctl status --no-pager -l "$1" >&2 || true
  die "el servicio $1 no arrancó"
}

wait_port() { # wait_port <host> <port> [segundos]
  local host="$1" port="$2" secs="${3:-30}" i=0
  while ((i < secs)); do
    if (exec 3<>"/dev/tcp/$host/$port") 2>/dev/null; then
      exec 3>&-
      ok "puerto $host:$port abierto"
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  die "timeout esperando $host:$port"
}

# ---------------------------------------------------------------- evidencia
mark() {
  local tag="$1" msg="${2:-}"
  printf 'MARK %s %s %s %s\n' "$tag" "$(hostname)" "$(_ts)" "$msg" | tee -a "$LAB_LOG"
}

# ---------------------------------------------------------------- resumen
lab_banner() {
  cat <<EOF
────────────────────────────────────────────────────────
  LAB PHP2SHELL · ${LAB_DOMAIN} · rol: ${LAB_ROLE:-?}
  repo: ${LAB_REPO_DIR}   mirror: ${LAB_MIRROR}
  log:  ${LAB_LOG}
────────────────────────────────────────────────────────
EOF
}
