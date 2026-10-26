#!/usr/bin/env bash
# check-versions.sh · inventario read-only del laboratorio IS-1023
# Uso: ./tests/check-versions.sh
# No explota, no modifica, no borra.

set -uo pipefail

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

echo "== Lab IS-1023 · inventario de versiones =="
date -u
echo

if have curl; then
  hdr=$(curl -sI --max-time 5 "http://$M1" 2>/dev/null || true)
  if echo "$hdr" | grep -qi 'Apache/2.4.49'; then pass "M1 Apache 2.4.49"; else fail "M1 Apache no reporta 2.4.49"; fi
  if echo "$hdr" | grep -qi 'PHP/8.4.26'; then pass "M1 PHP 8.4.26"; else fail "M1 PHP no reporta 8.4.26"; fi
  if echo "$hdr" | grep -qi 'WordPress'; then pass "M1 WordPress presente"; else warn "M1 no muestra WordPress en headers"; fi
  if curl -s --max-time 5 "http://$M1/wp-json/" 2>/dev/null | grep -q 'batch'; then
    pass "W1 ruta /batch/v1 presente"
  else
    fail "W1 ruta /batch/v1 no visible"
  fi
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 --path-as-is \
    "http://$M1/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd" 2>/dev/null || true)
  echo "INFO  W3 traversal HTTP $code (503 = CGI sin daemon; 200 = lectura; 403 = bloqueado)"
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$M1/server-status" 2>/dev/null || true)
  echo "INFO  W5 server-status HTTP $code"
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$M1/info.php" 2>/dev/null || true)
  echo "INFO  W6 info.php HTTP $code"
  if curl -s --max-time 5 "http://$M1/wp-content/uploads/" 2>/dev/null | grep -qi 'Index of'; then
    pass "W7 listado de uploads"
  else
    warn "W7 sin listado (puede estar mitigado)"
  fi
else
  warn "curl no instalado"
fi

echo
if have nmap; then
  echo "-- Puertos --"
  nmap -Pn -T4 -p 22,80,443,3306,6379,21,139,445,2049,53,3389,5900 \
    "$M1" "$M2" "$M3" "$M4" "$M5" 2>/dev/null | grep -E '^[0-9]+/tcp|^Nmap scan report' || warn "nmap sin salida"
else
  warn "nmap no instalado"
fi

echo
if have redis-cli; then
  out=$(redis-cli -h "$M2" --no-raw PING 2>&1 || true)
  echo "INFO  D1 Redis: $out"
else
  warn "redis-cli no instalado"
fi

if have dig; then
  out=$(dig +time=3 +tries=1 axfr uni.lab "@$M4" 2>&1 || true)
  if echo "$out" | grep -qi 'XFR size\|uni.lab.*IN'; then
    pass "S4 AXFR responde (vulnerable)"
  else
    echo "INFO  S4 AXFR: $(echo "$out" | tail -1)"
  fi
else
  warn "dig no instalado"
fi

if have smbclient; then
  if smbclient -L "//$M3" -N >/dev/null 2>&1; then
    pass "B1 SMB responde en M3"
  else
    warn "B1 SMB no responde (puede estar mitigado)"
  fi
else
  warn "smbclient no instalado"
fi

if have nc; then
  if nc -z -w 2 "$M3" 6200 >/dev/null 2>&1; then
    pass "B2 puerto 6200 abierto (backdoor presente)"
  else
    echo "INFO  B2 puerto 6200 cerrado (tarball limpio o mitigado)"
  fi
else
  warn "nc no instalado"
fi

echo
echo "== Resumen: PASS=$pass FAIL=$fail WARN=$warn =="
[ "$fail" -eq 0 ]
