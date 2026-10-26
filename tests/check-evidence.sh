#!/usr/bin/env bash
# check-evidence.sh · integridad documental del repo (read-only)
# Uso: ./tests/check-evidence.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

pass=0; fail=0; warn=0
pass() { printf 'PASS  %s\n' "$1"; pass=$((pass+1)); }
fail() { printf 'FAIL  %s\n' "$1"; fail=$((fail+1)); }
warn() { printf 'WARN  %s\n' "$1"; warn=$((warn+1)); }

echo "== Repo IS-1023 · integridad documental =="
date -u
echo

[ -d informe/evidencias/logs ] && pass "carpeta de logs" || fail "falta informe/evidencias/logs"
[ -d informe/evidencias/png ] && pass "carpeta de capturas" || fail "falta informe/evidencias/png"
[ -f informe/evidencias/hashes.txt ] && pass "hashes.txt" || fail "falta hashes.txt"

logs=$(find informe/evidencias/logs -type f 2>/dev/null | wc -l | tr -d ' ')
pngs=$(find informe/evidencias/png -type f 2>/dev/null | wc -l | tr -d ' ')
echo "INFO  logs=$logs capturas=$pngs"

if [ "$logs" -gt 0 ] && [ "$pngs" -gt 0 ]; then
  pass "evidencias presentes"
else
  fail "evidencias vacías"
fi

if [ -f informe/anexos/c-snapshots.md ]; then
  placeholders=$(grep -c '___' informe/anexos/c-snapshots.md || true)
  if [ "$placeholders" -gt 0 ]; then
    fail "c-snapshots.md tiene $placeholders placeholders sin completar"
  else
    pass "c-snapshots.md completo"
  fi
else
  fail "falta informe/anexos/c-snapshots.md"
fi

if [ -f informe/06-remediacion.md ] && [ -f informe/07-retest.md ]; then
  if grep -Eq '⬜|pendiente' informe/06-remediacion.md && grep -q 'retest ejecutado' informe/07-retest.md; then
    fail "contradicción: 06 tiene pendientes y 07 dice retest ejecutado"
  else
    pass "06 y 07 sin contradicción evidente"
  fi
else
  fail "faltan 06-remediacion.md o 07-retest.md"
fi

if [ -d specs ]; then
  pending=$(grep -R '⬜' specs --include='tasks.md' 2>/dev/null | wc -l | tr -d ' ')
  echo "INFO  tareas pendientes (⬜): $pending"
else
  fail "falta specs/"
fi

for f in AGENTS.md MEMORY.md docs/constitution.md docs/PLAN-MAESTRO.md; do
  [ -f "$f" ] && pass "$f" || fail "falta $f"
done

echo
echo "== Resumen: PASS=$pass FAIL=$fail WARN=$warn =="
[ "$fail" -eq 0 ]
