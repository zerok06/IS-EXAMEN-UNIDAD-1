#!/usr/bin/env bash
# check-version-gates.sh [vuln|patched]
# Verifica que la versión instalada cumpla el version gate de la fase.
# read-only. No explota, no modifica.

set -uo pipefail

MODE="${1:-vuln}"
M1="${M1:-10.10.10.11}"
M2="${M2:-10.10.10.12}"
M3="${M3:-10.10.10.13}"
M4="${M4:-10.10.10.14}"
M5="${M5:-10.10.10.15}"

pass=0; fail=0; warn=0
pass() { printf 'PASS  %s\n' "$1"; pass=$((pass+1)); }
fail() { printf 'FAIL  %s\n' "$1"; fail=$((fail+1)); }
warn() { printf 'WARN  %s\n' "$1"; warn=$((warn+1)); }
have() { command -v "$1" >/dev/null 2>&1; }
ver_ge() {
  [ -n "${1:-}" ] && [ -n "${2:-}" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]
}
ver_lt() { ! ver_ge "$1" "$2"; }

wp_vuln() {
  case "${1:-}" in
    6.9.*) ver_lt "$1" "6.9.5" ;;
    7.0.*) ver_lt "$1" "7.0.2" ;;
    *) false ;;
  esac
}

echo "== Version gates · MODE=$MODE =="
date -u
echo

# W1 · WordPress
if have wpscan; then
  wpver=$(wpscan --url "http://$M1" --no-banner --format cli-no-colors 2>/dev/null \
    | grep -oE 'WordPress version [0-9.]+' | head -1 | awk '{print $3}')
  if [ -n "${wpver:-}" ]; then
    if [ "$MODE" = "vuln" ]; then
      if wp_vuln "$wpver"; then pass "W1 WP $wpver dentro del rango vulnerable"; else fail "W1 WP $wpver no es vulnerable (fix 6.9.5/7.0.2)"; fi
    else
      if wp_vuln "$wpver"; then fail "W1 WP $wpver sigue vulnerable"; else pass "W1 WP $wpver corregido o fuera del rango"; fi
    fi
  else
    warn "W1 no se pudo leer la versión de WP con wpscan"
  fi
else
  warn "wpscan no instalado; W1 no verificable"
fi

# W2 · PHP
if have curl; then
  phpver=$(curl -sI --max-time 5 "http://$M1" 2>/dev/null | grep -ioE 'PHP/[0-9.]+' | head -1 | cut -d/ -f2)
  if [ -n "${phpver:-}" ]; then
    if [ "$MODE" = "vuln" ]; then
      if ver_lt "$phpver" "8.4.27"; then pass "W2 PHP $phpver < 8.4.27"; else fail "W2 PHP $phpver >= 8.4.27 (no vulnerable)"; fi
    else
      if ver_ge "$phpver" "8.4.27"; then pass "W2 PHP $phpver >= 8.4.27"; else fail "W2 PHP $phpver < 8.4.27"; fi
    fi
  else
    warn "W2 no se pudo leer X-Powered-By"
  fi

  # W3 · Apache
  httpdver=$(curl -sI --max-time 5 "http://$M1" 2>/dev/null | grep -ioE 'Apache/[0-9.]+' | head -1 | cut -d/ -f2)
  if [ -n "${httpdver:-}" ]; then
    if [ "$MODE" = "vuln" ]; then
      if [ "$httpdver" = "2.4.49" ]; then pass "W3 Apache 2.4.49"; else fail "W3 Apache $httpdver no es 2.4.49"; fi
    else
      if ver_ge "$httpdver" "2.4.51"; then pass "W3 Apache $httpdver >= 2.4.51"; else fail "W3 Apache $httpdver < 2.4.51 (2.4.50 solo corrige 41773)"; fi
    fi
  else
    warn "W3 no se pudo leer Server"
  fi
else
  warn "curl no instalado"
fi

# D1 · Redis
if have redis-cli; then
  out=$(redis-cli -h "$M2" INFO server 2>&1 || true)
  redisver=$(echo "$out" | grep -oE 'redis_version:[0-9.]+' | head -1 | cut -d: -f2)
  if [ -n "${redisver:-}" ]; then
    if [ "$MODE" = "vuln" ]; then
      if ver_lt "$redisver" "6.2.7"; then pass "D1 Redis $redisver < 6.2.7"; else fail "D1 Redis $redisver >= 6.2.7 (no vulnerable)"; fi
    else
      if ver_ge "$redisver" "6.2.7"; then pass "D1 Redis $redisver >= 6.2.7"; else fail "D1 Redis $redisver < 6.2.7"; fi
      auth=$(redis-cli -h "$M2" PING 2>&1 || true)
      echo "INFO  D1 auth: $auth"
    fi
  else
    echo "INFO  D1 Redis no expone versión: $(echo "$out" | head -1)"
  fi
else
  warn "redis-cli no instalado"
fi

# B1 · Samba
if have nmap; then
  out=$(nmap -sV -Pn -T4 -p445 "$M3" 2>/dev/null || true)
  sambaver=$(echo "$out" | grep -oE 'Samba [0-9.]+' | head -1 | awk '{print $2}')
  if [ -n "${sambaver:-}" ]; then
    if [ "$MODE" = "vuln" ]; then
      if ver_lt "$sambaver" "4.5.10"; then pass "B1 Samba $sambaver < 4.5.10"; else fail "B1 Samba $sambaver >= 4.5.10 (fix)"; fi
    else
      if ver_ge "$sambaver" "4.5.10"; then pass "B1 Samba $sambaver >= 4.5.10"; else fail "B1 Samba $sambaver < 4.5.10"; fi
    fi
  else
    warn "B1 no se pudo leer la versión de Samba con nmap"
  fi
else
  warn "nmap no instalado; B1 no verificable"
fi

# B2 · vsftpd backdoor (supply-chain gate, no version gate)
if have nc; then
  if nc -z -w 2 "$M3" 6200 >/dev/null 2>&1; then
    if [ "$MODE" = "vuln" ]; then pass "B2 puerto 6200 abierto (backdoor presente)"; else fail "B2 puerto 6200 abierto en patched"; fi
  else
    if [ "$MODE" = "vuln" ]; then warn "B2 puerto 6200 cerrado (tarball limpio; CVE no presente)"; else pass "B2 puerto 6200 cerrado"; fi
  fi
fi

# C4 · VNC
if have nmap; then
  out=$(nmap -sT --script vnc-info -p5900 "$M5" 2>/dev/null || true)
  if echo "$out" | grep -qi 'Authentication: None'; then
    if [ "$MODE" = "vuln" ]; then pass "C4 VNC sin autenticación"; else fail "C4 VNC sin autenticación en patched"; fi
  elif echo "$out" | grep -qi 'Authentication: VNC\|closed\|filtered'; then
    if [ "$MODE" = "vuln" ]; then warn "C4 VNC no está sin auth"; else pass "C4 VNC cerrado o con auth"; fi
  else
    warn "C4 no verificable con nmap"
  fi
fi

echo
echo "INFO  S2 (PrintNightmare) requiere Get-Service Spooler + MSF check; no se valida solo con puertos."
echo "== Resumen: PASS=$pass FAIL=$fail WARN=$warn =="
[ "$fail" -eq 0 ]
