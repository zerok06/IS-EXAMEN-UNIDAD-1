#!/usr/bin/env bash
# check-retest.sh · verifica el estado PARCHEADO (read-only)
# Uso: ./tests/check-retest.sh
# Sale 0 si todo lo comprobable está cerrado; 1 si algo sigue abierto.

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

echo "== Lab IS-1023 · retest del estado parcheado =="
date -u
echo

if have curl; then
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$M1/wp-json/batch/v1" 2>/dev/null || true)
  if [ "$code" = "403" ] || [ "$code" = "404" ]; then pass "W1 batch bloqueado ($code)"; else fail "W1 batch responde $code"; fi

  hdr=$(curl -sI --max-time 5 "http://$M1" 2>/dev/null || true)
  echo "$hdr" | grep -qi 'PHP/8.4.27\|PHP/8.4.28\|PHP/8.4.29' || hdr=$(curl -sI --max-time 5 "http://$M1/wp-login.php" 2>/dev/null || true)
  if echo "$hdr" | grep -qi 'PHP/8.4.27\|PHP/8.4.28\|PHP/8.4.29'; then
    pass "W2 PHP corregido"
  else
    fail "W2 PHP no reporta 8.4.27+"
  fi

  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 --path-as-is \
    "http://$M1/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd" 2>/dev/null || true)
  if [ "$code" = "400" ] || [ "$code" = "403" ] || [ "$code" = "404" ]; then pass "W3 traversal cerrado ($code)"; else fail "W3 traversal responde $code"; fi

  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
    -d 'log=usc.admin&pwd=Admin13.-&wp-submit=Log+In&testcookie=1' \
    "http://$M1/wp-login.php" 2>/dev/null || true)
  if [ "$code" = "302" ]; then fail "W4 login viejo sigue funcionando"; else pass "W4 login viejo falla ($code)"; fi

  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$M1/server-status" 2>/dev/null || true)
  if [ "$code" = "403" ] || [ "$code" = "404" ]; then pass "W5 server-status cerrado"; else fail "W5 server-status responde $code"; fi

  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$M1/info.php" 2>/dev/null || true)
  if [ "$code" = "404" ]; then pass "W6 info.php borrado"; else fail "W6 info.php responde $code"; fi

  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$M1/wp-content/uploads/" 2>/dev/null || true)
  if [ "$code" = "403" ] || [ "$code" = "404" ]; then pass "W7 uploads sin listado"; else fail "W7 uploads responde $code"; fi

  out=$(curl -s --max-time 5 "ftp://anonymous:anonymous@$M3/backups/credenciales.txt" 2>&1 || true)
  if [ -z "$out" ] || echo "$out" | grep -qi '530\|denied\|failed'; then pass "B3 FTP anónimo cerrado"; else fail "B3 FTP anónimo sigue entregando datos"; fi
else
  warn "curl no instalado"
fi

echo
if have redis-cli; then
  out=$(timeout 5 redis-cli -h "$M2" --no-raw PING 2>&1 || true)
  if [ -z "$out" ] || echo "$out" | grep -qi 'NOAUTH\|refused\|timed out\|error'; then pass "D1 Redis exige auth o está filtrado"; else fail "D1 Redis responde: $out"; fi
else
  warn "redis-cli no instalado"
fi

if have dig; then
  out=$(dig +time=3 +tries=1 axfr uni.lab "@$M4" 2>&1 || true)
  if echo "$out" | grep -qi 'failed\|refused\|transfer failed'; then pass "S4 AXFR cerrado"; else fail "S4 AXFR sigue respondiendo"; fi
else
  warn "dig no instalado"
fi

if have nmap; then
  out=$(nmap -sT --host-timeout 8s --script smb-security-mode -p 445 "$M4" 2>/dev/null || true)
  if echo "$out" | grep -qi 'signing:.*True\|message_signing: required\|required'; then
    pass "S5 SMB signing requerido"
  elif [ -z "$out" ] || echo "$out" | grep -qi 'filtered\|closed'; then
    warn "S5 no verificable desde M6 (M4 filtrado; verificar por túnel)"
  else
    fail "S5 SMB signing no requerido"
  fi

  out=$(nmap -sT --host-timeout 8s --script vnc-info -p 5900 "$M5" 2>/dev/null || true)
  if echo "$out" | grep -qi 'Authentication: VNC\|VNC Authentication'; then
    pass "C4 VNC exige auth"
  elif echo "$out" | grep -qi 'closed\|filtered'; then
    pass "C4 VNC cerrado/filtrado"
  else
    fail "C4 VNC sigue sin auth"
  fi

  out=$(nmap -sT --host-timeout 8s --script smb-protocols -p 445 "$M4" 2>/dev/null || true)
  if echo "$out" | grep -qi 'NT LM 0.12\|SMBv1'; then
    fail "S1 SMBv1 sigue activo"
  elif [ -z "$out" ] || echo "$out" | grep -qi 'filtered\|closed'; then
    warn "S1 no verificable desde M6 (M4 filtrado; verificar por túnel)"
  else
    pass "S1 SMBv1 deshabilitado"
  fi

  out=$(nmap -sT --host-timeout 8s --script rdp-enum-encryption -p 3389 "$M5" 2>/dev/null || true)
  if echo "$out" | grep -qi 'CredSSP (NLA)\|NLA'; then
    pass "C3 RDP con NLA"
  else
    warn "C3 NLA no verificable con este script"
  fi
else
  warn "nmap no instalado"
fi

echo
if have showmount; then
  out=$(timeout 5 showmount -e "$M3" 2>&1 || true)
  echo "INFO  B4 exportaciones: $(echo "$out" | tr '\n' ' ')"
  echo "INFO  B4 verifica 'root_squash' manualmente en M3: exportfs -v"
else
  warn "showmount no instalado"
fi

echo
echo "== Resumen: PASS=$pass FAIL=$fail WARN=$warn =="
[ "$fail" -eq 0 ]
