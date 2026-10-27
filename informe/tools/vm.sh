#!/usr/bin/env bash
# vm.sh — ejecuta un comando simple por SSH en una VM del laboratorio.
# Uso: ./vm.sh <m1|m2|m3|m6> "<comando>"
# Motivación: comandos replicables y legibles para las capturas del informe.
set -uo pipefail

TARGET="${1:?uso: vm.sh <m1|m2|m3|m6> \"<comando>\"}"
CMD="${2:?falta el comando}"

case "$TARGET" in
  m1) HOST=10.10.10.11; USER=ubuntu;  PASS='Admin13.-' ;;
  m2) HOST=10.10.10.12; USER=adminm2; PASS='adminm2' ;;
  m3) HOST=10.10.10.13; USER=rony123; PASS='rony123' ;;
  m6) HOST=10.10.10.20; USER=kali;    PASS='' ;;          # local, sin SSH
  *)  echo "Destino inválido: $TARGET (m1|m2|m3|m6)" >&2; exit 2 ;;
esac

if [ "$TARGET" = "m6" ]; then
  bash -c "$CMD"
  exit $?
fi

python3 - "$HOST" "$USER" "$PASS" "$CMD" <<'PY'
import sys, paramiko
host, user, pwd, cmd = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect(host, username=user, password=pwd, timeout=10,
          allow_agent=False, look_for_keys=False)
_, out, err = c.exec_command(cmd, timeout=120)
sys.stdout.write(out.read().decode(errors="replace"))
e = err.read().decode(errors="replace")
if e.strip():
    sys.stderr.write(e)
rc = out.channel.recv_exit_status()
c.close()
sys.exit(rc)
PY
