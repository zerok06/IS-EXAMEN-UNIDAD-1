#!/usr/bin/env bash
# =============================================================================
# lab/m2/verify.sh — comprobaciones de M2 (m2-db, 10.10.10.12)
#
# Solo lectura: no instala, no reinicia, no cambia configuración.
# Salida: exit 0 si todo pasa; exit != 0 si algo falla.
#
# Uso: sudo bash /opt/lab/m2/verify.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/lib.sh
source "$SCRIPT_DIR/../common/lib.sh"

export LAB_ROLE="${LAB_ROLE:-m2-db}"
trap - ERR   # aquí se acumulan fallos: no se aborta en la primera comprobación

LAB_IP="$M2"
DB_PASS="ClaveDebil123"
REDIS_VERSION="6.2.6"

require_root

PASS=0
FAIL=0
pass() { ok "$*"; PASS=$((PASS + 1)); }
fail() { warn "FALLA: $*"; FAIL=$((FAIL + 1)); }

# ¿Hay un socket TCP escuchando en ese puerto?
listening() {
  ss -ltn 2>/dev/null | awk 'NR > 1 { print $4 }' | grep -qE "[:.]$1\$"
}

# Versión de redis: preferimos el binario compilado en /usr/local.
redis_server_bin() {
  if [[ -x /usr/local/bin/redis-server ]]; then
    printf '%s' /usr/local/bin/redis-server
  else
    command -v redis-server 2>/dev/null || true
  fi
}

redis_cli_bin() {
  if [[ -x /usr/local/bin/redis-cli ]]; then
    printf '%s' /usr/local/bin/redis-cli
  else
    command -v redis-cli 2>/dev/null || true
  fi
}

lab_banner
step "versiones"

# ---- MariaDB ---------------------------------------------------------------
maria_ver=$( (mariadb --version 2>/dev/null || mysql --version 2>/dev/null) | head -n1 || true)
if [[ -n "$maria_ver" ]]; then
  pass "mariadb presente: ${maria_ver}"
  if grep -q 'MariaDB' <<<"$maria_ver" && grep -qE 'Distrib 10\.' <<<"$maria_ver"; then
    pass "MariaDB 10.x (Ubuntu 22.04 entrega 10.6; el README dice 10.11)"
  else
    fail "MariaDB inesperado: ${maria_ver}"
  fi
else
  fail "no se encontró el cliente mariadb/mysql"
fi

# ---- Redis -----------------------------------------------------------------
RBIN=$(redis_server_bin)
RCLI=$(redis_cli_bin)
if [[ -n "$RBIN" ]]; then
  redis_ver=$("$RBIN" --version 2>/dev/null | head -n1 || true)
  if grep -q "v=${REDIS_VERSION}" <<<"$redis_ver"; then
    pass "redis-server ${REDIS_VERSION}: ${redis_ver}"
  else
    fail "redis-server no es ${REDIS_VERSION}: ${redis_ver:-sin versión}"
  fi
else
  fail "redis-server no instalado"
fi
[[ -n "$RCLI" ]] && pass "redis-cli disponible: $RCLI" || fail "redis-cli no instalado"

# ---- puertos ---------------------------------------------------------------
step "puertos"
if listening 3306; then pass "3306/tcp escuchando (MariaDB)"; else fail "3306/tcp no escucha"; fi
if listening 6379; then pass "6379/tcp escuchando (Redis)"; else fail "6379/tcp no escucha"; fi

if ss -ltn 2>/dev/null | grep -qE "10\.10\.10\.12:3306|0\.0\.0\.0:3306|\*:3306"; then
  pass "MariaDB expuesto en 3306 (no solo loopback)"
else
  fail "MariaDB no parece escuchar en ${LAB_IP}:3306"
fi

# ---- login SQL -------------------------------------------------------------
step "login SQL"
for u in wp_user moodle_user; do
  out=$(mysql -h "$LAB_IP" -u "$u" -p"$DB_PASS" -N -B -e 'SELECT 1' 2>/dev/null || true)
  if [[ "$out" == "1" ]]; then
    pass "login ${u} en ${LAB_IP} (SELECT 1)"
  else
    fail "login ${u} en ${LAB_IP} (respuesta: '${out:-vacía}')"
  fi
done
for db in wp_db moodle_db; do
  out=$(mysql -h "$LAB_IP" -u wp_user -p"$DB_PASS" -N -B \
        -e "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='${db}'" 2>/dev/null || true)
  if [[ "$out" == "1" ]]; then
    pass "base ${db} existe"
  else
    fail "base ${db} no existe o no es visible para wp_user"
  fi
done

# ---- Redis sin auth --------------------------------------------------------
step "Redis sin autenticación"
if [[ -n "$RCLI" ]]; then
  pong=$("$RCLI" -h 127.0.0.1 -p 6379 ping 2>/dev/null || true)
  if [[ "$pong" == "PONG" ]]; then
    pass "PING sin contraseña devuelve PONG"
  else
    fail "PING sin contraseña falló (respuesta: '${pong:-vacía}')"
  fi
fi
if grep -qiE '^[[:space:]]*requirepass[[:space:]]+.' /etc/redis-lab/redis.conf 2>/dev/null; then
  fail "/etc/redis-lab/redis.conf define requirepass"
else
  pass "redis.conf sin requirepass"
fi
if grep -qiE '^[[:space:]]*protected-mode[[:space:]]+no' /etc/redis-lab/redis.conf 2>/dev/null; then
  pass "redis.conf con protected-mode no"
else
  fail "redis.conf sin 'protected-mode no'"
fi
if systemctl is-active --quiet redis-lab; then pass "servicio redis-lab activo"; else fail "servicio redis-lab inactivo"; fi

# ---- sudo débil de adminm2 -------------------------------------------------
step "cuenta adminm2"
if id -u adminm2 >/dev/null 2>&1; then
  pass "usuario adminm2 existe"
  if runuser -u adminm2 -- sudo -n true 2>/dev/null; then
    pass "adminm2 ejecuta sudo -n (NOPASSWD)"
  else
    fail "adminm2 no tiene sudo sin contraseña"
  fi
else
  fail "usuario adminm2 no existe"
fi

# ---- SSH y llave -----------------------------------------------------------
step "SSH"
if sshd -T 2>/dev/null | grep -qiE '^passwordauthentication yes'; then
  pass "sshd con PasswordAuthentication yes"
else
  fail "sshd sin PasswordAuthentication yes"
fi
if [[ -f /root/.ssh/id_ed25519 ]]; then
  pass "llave root presente: /root/.ssh/id_ed25519"
  if ssh-keygen -y -f /root/.ssh/id_ed25519 >/dev/null 2>&1; then
    pass "llave root legible con la clave pública derivada"
  else
    fail "llave root ilegible"
  fi
else
  fail "no existe /root/.ssh/id_ed25519 (necesaria para el salto a M3)"
fi

# ---- firewall y configuración ---------------------------------------------
step "firewall y configuración"
if ufw status 2>/dev/null | grep -qi '^Status: active'; then
  pass "UFW activo"
  if ufw status 2>/dev/null | grep -q '^22/tcp'; then pass "22/tcp permitido"; else fail "22/tcp no permitido en UFW"; fi
  if ufw status 2>/dev/null | grep -q '3306'; then pass "regla 3306 presente"; else fail "sin regla para 3306"; fi
else
  fail "UFW inactivo"
fi
if grep -qE '^[[:space:]]*bind-address[[:space:]]*=[[:space:]]*10\.10\.10\.12' \
     /etc/mysql/mariadb.conf.d/99-lab.cnf 2>/dev/null; then
  pass "bind-address = 10.10.10.12"
else
  fail "bind-address no es 10.10.10.12 en 99-lab.cnf"
fi
if grep -qE '^[[:space:]]*skip-name-resolve' /etc/mysql/mariadb.conf.d/99-lab.cnf 2>/dev/null; then
  pass "skip-name-resolve presente"
else
  fail "skip-name-resolve ausente"
fi

# ---- resultado -------------------------------------------------------------
step "resultado M2"
printf '  %d comprobaciones OK · %d fallos\n' "$PASS" "$FAIL"
if (( FAIL > 0 )); then
  warn "M2 NO está como espera el escenario (${FAIL} fallo(s))"
  exit 1
fi
ok "M2 verificado: MariaDB ${LAB_IP}:3306, Redis ${REDIS_VERSION}:6379 sin auth, adminm2 con sudo"
