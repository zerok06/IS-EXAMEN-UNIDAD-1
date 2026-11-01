#!/usr/bin/env bash
# lab/patch/retest.sh — desde M6: comprueba que los 5 saltos ya NO funcionan.
# Uso: bash lab/patch/retest.sh

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_REPO_DIR="${LAB_REPO_DIR:-$(cd "$HERE/../.." && pwd)}"
LAB_LOG="${LAB_LOG:-${TMPDIR:-/tmp}/lab-chain.log}"
export LAB_REPO_DIR LAB_LOG
. "$HERE/../common/lib.sh"
LAB_ROLE=retest

PASS=0; FAIL=0
okp() { PASS=$((PASS+1)); pass "$*"; }
bad() { FAIL=$((FAIL+1)); fail "$*"; }
pass() { printf '  [PASS] %s\n' "$*"; }
fail() { printf '  [FAIL] %s\n' "$*"; }

step "retest · los 5 saltos deben fallar"

# 1 · sink LFI eliminado
code=$(curl -ks --max-time 10 -o /dev/null -w '%{http_code}' -H 'Host: wp.uni.lab' \
  'https://127.0.0.1/wp-content/plugins/legacy-download/dl.php?file=default.php' 2>/dev/null || true)
[[ "$code" == "404" ]] && okp "M1: sink LFI 404" || bad "M1: sink sigue respondiendo ($code)"

phpver=$(curl -ks --max-time 10 -D - -o /dev/null https://wp.uni.lab/ 2>/dev/null | tr -d '\r' | awk -F': ' 'tolower($1)=="x-powered-by"{print $2}' | head -1)
[[ "$phpver" == *"8.4.27"* ]] && okp "M1: $phpver" || bad "M1: X-Powered-By = ${phpver:-?}"

# 2 · Redis ya no acepta sin auth
if command -v redis-cli >/dev/null 2>&1; then
  if redis-cli -h "$M2" --no-auth-warning PING 2>/dev/null | grep -q PONG; then
    bad "M2: Redis sigue sin autenticación"
  else
    okp "M2: Redis exige autenticación"
  fi
  if redis-cli -h 127.0.0.1 -a 'UniRedis2026!' --no-auth-warning PING 2>/dev/null | grep -q PONG; then
    okp "M2: Redis responde con contraseña (servicio sano)"
  else
    warn "M2: no pude validar la contraseña desde M6 (es esperado si 6379 es loopback)"
  fi
else
  warn "sin redis-cli"
fi

# 3 · NFS con root_squash
if command -v sshpass >/dev/null 2>&1; then
  if sshpass -p rony123 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
       -o ConnectTimeout=6 "rony123@$M3" 'sudo -n exportfs -v' 2>/dev/null | grep -q 'no_root_squash'; then
    bad "M3: el export sigue con no_root_squash"
  else
    okp "M3: export sin no_root_squash"
  fi
  if sshpass -p rony123 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
       -o ConnectTimeout=6 "rony123@$M3" 'test -f /etc/cron.d/lab-rotate' 2>/dev/null; then
    bad "M3: el cron sigue presente"
  else
    okp "M3: cron sobre el export eliminado"
  fi
else
  warn "sin sshpass"
fi

# 4 · SMB1 deshabilitado en M4
if command -v nmap >/dev/null 2>&1; then
  protos="$(nmap -Pn -p445 --script smb-protocols "$M4" 2>/dev/null || true)"
  if grep -qiE 'SMBv1|NT LM 0\.12' <<<"$protos"; then
    bad "M4: SMB1 sigue habilitado"
  else
    okp "M4: SMB1 deshabilitado"
  fi
else
  warn "sin nmap"
fi

# 5 · VNC ya no acepta sin auth / 5900 cerrado
if command -v nmap >/dev/null 2>&1; then
  vnc="$(nmap -Pn -p5900 --script vnc-info "$M5" 2>/dev/null || true)"
  if grep -qi 'Authentication: *None' <<<"$vnc"; then
    bad "M5: VNC sigue sin autenticación"
  else
    okp "M5: VNC sin None (o 5900 cerrado)"
  fi
fi

printf '\n%d PASS, %d FAIL\n' "$PASS" "$FAIL"
(( FAIL == 0 )) || exit 1
