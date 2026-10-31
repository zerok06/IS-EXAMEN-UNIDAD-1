#!/usr/bin/env bash
# ============================================================================
#  lab/tests/smoke.sh — prueba de humo del laboratorio, desde M6
# ----------------------------------------------------------------------------
#  Comprueba que el escenario está arriba y alcanzable desde M6 (10.10.10.20):
#    M1  443                     (nginx TLS → Apache/mod_php)
#    M2  3306, 6379              (MariaDB, Redis)
#    M3  21, 2049                (vsftpd, NFS)
#    M4  53, 445, 5985           (DNS, SMB, WinRM)
#    M5  445, 3389               (SMB, RDP)
#    DNS wp.uni.lab @M4 → 10.10.10.11
#    HTTPS https://wp.uni.lab responde
#
#  Salida: una línea PASS/FAIL por comprobación; exit != 0 si algo falla.
#  Sólo lectura: no explota, no escribe en las VM.
#
#  Uso:
#    bash lab/tests/smoke.sh
#    bash lab/tests/smoke.sh --timeout 8
#    bash lab/tests/smoke.sh --no-http
# ============================================================================

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_LOG="${LAB_LOG:-${TMPDIR:-/tmp}/lab-smoke.log}"
export LAB_LOG

# shellcheck source=../common/lib.sh
. "$HERE/../common/lib.sh"

LAB_ROLE=smoke

TIMEOUT=4
DO_HTTP=1

usage() {
  cat <<'EOF'
Uso: bash lab/tests/smoke.sh [opciones]

  --timeout N   segundos por puerto (def. 4)
  --no-http     omite la comprobación HTTPS
  -h, --help    esta ayuda

Código de salida: 0 si todo pasa, 1 si hay algún FAIL.
EOF
}

while (($#)); do
  case "$1" in
    --timeout)  TIMEOUT="${2:?--timeout necesita segundos}"; shift 2 ;;
    --timeout=*) TIMEOUT="${1#*=}"; shift ;;
    --no-http)  DO_HTTP=0; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) die "opción desconocida: $1 (ver --help)" ;;
  esac
done

[[ "$TIMEOUT" =~ ^[0-9]+$ ]] || die "--timeout debe ser un número de segundos"

OK=0
FAILS=0
FAIL_LIST=()

pass() { printf 'PASS  %s\n' "$*"; OK=$((OK + 1)); }
fail() {
  printf 'FAIL  %s\n' "$*"
  FAILS=$((FAILS + 1))
  FAIL_LIST+=("$*")
}

# --------------------------------------------------------------- puertos
check_port() {
  local label="$1" host="$2" port="$3" msg
  msg=$(printf '%-11s %s:%s/tcp' "$label" "$host" "$port")
  if timeout "$TIMEOUT" bash -c "exec 3<>/dev/tcp/$host/$port" 2>/dev/null; then
    pass "$msg"
  else
    fail "$msg (sin respuesta en ${TIMEOUT}s)"
  fi
}

# --------------------------------------------------------------- DNS
check_dns() {
  if ! command -v dig >/dev/null 2>&1; then
    fail "$(printf '%-11s' 'DNS') dig no está instalado en M6"
    return
  fi
  local out
  out="$(dig +short +time=2 +tries=1 "wp.$LAB_DOMAIN" "@$M4" 2>/dev/null || true)"
  if grep -q "$M1" <<<"$out"; then
    pass "$(printf '%-11s' 'DNS') wp.$LAB_DOMAIN → $M1  (vía $M4)"
  else
    fail "$(printf '%-11s' 'DNS') wp.$LAB_DOMAIN no resuelve a $M1 (salida: ${out//$'\n'/ })"
  fi
}

# --------------------------------------------------------------- HTTPS
check_https() {
  if ! command -v curl >/dev/null 2>&1; then
    fail "HTTPS  curl no está instalado en M6"
    return
  fi

  # Si la CA del laboratorio está generada, se valida de verdad; si no, -k.
  local ca curl_args=() code extra=""
  ca="$(cd "$HERE/../.." && pwd)/lab/pki/out/ca.crt"
  if [[ -s "$ca" ]]; then
    curl_args=(--cacert "$ca")
    extra=" (CA del lab)"
  else
    curl_args=(-k)
    extra=" (-k: CA no generada)"
  fi

  code="$(curl "${curl_args[@]}" -s -o /dev/null -w '%{http_code}' \
      --max-time "$TIMEOUT" --resolve "wp.$LAB_DOMAIN:443:$M1" \
      "https://wp.$LAB_DOMAIN/" 2>/dev/null || true)"

  if [[ "$code" =~ ^[1-5][0-9][0-9]$ ]]; then
    pass "$(printf '%-11s' 'HTTPS') https://wp.$LAB_DOMAIN → HTTP $code$extra"
  else
    fail "$(printf '%-11s' 'HTTPS') https://wp.$LAB_DOMAIN sin respuesta (code=${code:-000})$extra"
  fi
}

# --------------------------------------------------------------- ejecución
lab_banner
printf 'Prueba de humo desde M6 (%s) · timeout %ss\n\n' "$M6" "$TIMEOUT" >&2

check_port "M1 web" "$M1" 443

check_port "M2 MariaDB" "$M2" 3306
check_port "M2 Redis" "$M2" 6379

check_port "M3 FTP" "$M3" 21
check_port "M3 NFS" "$M3" 2049

check_port "M4 DNS" "$M4" 53
check_port "M4 SMB" "$M4" 445
check_port "M4 WinRM" "$M4" 5985

check_port "M5 SMB" "$M5" 445
check_port "M5 RDP" "$M5" 3389

check_dns

if (( DO_HTTP )); then
  check_https
fi

# --------------------------------------------------------------- resumen
printf '\n%s\n' "──────────────────────────────────────────────"
printf 'Resultado: %d PASS, %d FAIL\n' "$OK" "$FAILS"

if (( FAILS > 0 )); then
  printf '\nFallos:\n'
  printf '  - %s\n' "${FAIL_LIST[@]}"
  printf '\nPistas:\n'
  printf '  · VM apagada o IP distinta      → revisar VMware y el plan de red\n'
  printf '  · M5 con 445/3389 filtrados     → el diseño permite 445 sólo desde M1;\n'
  printf '                                    validar SMB desde la sesión de M1\n'
  printf '  · M1 sin 443                    → nginx parado o certificado sin instalar\n'
  printf '  · DNS sin respuesta             → servicio DNS de M4 o zona uni.lab\n'
  printf '  · HTTPS 000 pero 443 abierto    → nginx sin vhost para wp.uni.lab\n'
  exit 1
fi

printf 'Todo el escenario responde desde M6.\n'
exit 0
