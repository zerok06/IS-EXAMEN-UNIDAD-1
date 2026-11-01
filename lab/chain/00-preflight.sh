#!/usr/bin/env bash
# ============================================================================
#  lab/chain/00-preflight.sh — comprueba que cada salto tiene su condición
# ----------------------------------------------------------------------------
#  Se ejecuta desde M6 ANTES de la demo. No explota nada: solo verifica que
#  los instaladores dejaron las configuraciones que la cadena necesita.
#
#  Uso:
#    bash lab/chain/00-preflight.sh           # rápido (puertos + HTTP + Redis)
#    bash lab/chain/00-preflight.sh --full    # añade MS17-010 (nmap, ~30 s)
#
#  Salida: PASS / FAIL / WARN por condición, con la acción correctiva.
# ============================================================================

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_REPO_DIR="${LAB_REPO_DIR:-$(cd "$HERE/../.." && pwd)}"
LAB_LOG="${LAB_LOG:-${TMPDIR:-/tmp}/lab-chain.log}"
export LAB_REPO_DIR LAB_LOG
. "$HERE/../common/lib.sh"
LAB_ROLE=preflight

FULL=0
while (($#)); do
  case "$1" in
    --full) FULL=1; shift ;;
    -h|--help) echo "Uso: $0 [--full]"; exit 0 ;;
    *) die "opción desconocida: $1" ;;
  esac
done

PASS=0; FAIL=0; WARN=0; FIXES=()
pass() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
fail() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }
warn() { WARN=$((WARN+1)); printf '  [WARN] %s\n' "$*"; }
fix()  { FIXES+=("$*"); }

port_open() { (exec 3<>"/dev/tcp/$1/$2") 2>/dev/null; }

ssh_admin() { # ssh_admin host user pass comando
  local h="$1" u="$2" p="$3"; shift 3
  sshpass -p "$p" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=6 "$u@$h" "$*" 2>/dev/null
}

lab_banner
step "preflight · comprobando condiciones de los 5 saltos"

# ---------------------------------------------------------------- M1
step "M1 (${M1}) · PHP2Shell"
if port_open "$M1" 443; then
  pass "443/tcp abierto"
else
  fail "443/tcp cerrado"; fix "M1: sudo bash lab/m1/install.sh (nginx/apache-lab)"
fi

c="$(curl -ks -o /dev/null -w '%{http_code}' "https://wp.uni.lab/lab/session.php" 2>/dev/null || true)"
[[ "$c" == "200" ]] && pass "harness /lab/session.php → 200" \
                    || { fail "harness /lab/session.php → ${c:-sin respuesta}"; fix "M1: revisar vhost wp.uni.lab y /var/www/wp/lab"; }

info="$(curl -ks "https://wp.uni.lab/lab/session.php?info=1" 2>/dev/null || true)"
grep -q '^session.save_path=/tmp$' <<<"$info" \
  && pass "session.save_path=/tmp" \
  || { fail "session.save_path != /tmp"; fix "M1: /usr/local/lib/php.ini (session.save_path)"; }
grep -q '^session.upload_progress.enabled=On$' <<<"$info" \
  && pass "upload_progress On" \
  || { fail "upload_progress Off"; fix "M1: php.ini session.upload_progress.enabled=On"; }
grep -q '^session.upload_progress.cleanup=Off$' <<<"$info" \
  && pass "upload_progress.cleanup Off" \
  || { fail "cleanup On (borra la sesión antes del LFI)"; fix "M1: php.ini cleanup=Off"; }

sink="$(curl -ks "https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php?file=default.php" 2>/dev/null || true)"
grep -q 'Plantilla base' <<<"$sink" \
  && pass "sink legacy-download responde" \
  || { fail "sink legacy-download no responde"; fix "M1: activar el plugin legacy-download"; }

# ---------------------------------------------------------------- M2
step "M2 (${M2}) · Redis sin auth"
if port_open "$M2" 6379; then
  pass "6379/tcp abierto"
else
  fail "6379/tcp cerrado"; fix "M2: sudo bash lab/m2/install.sh"
fi

if command -v redis-cli >/dev/null 2>&1; then
  pong="$(redis-cli -h "$M2" --no-auth-warning PING 2>/dev/null || true)"
  [[ "$pong" == "PONG" ]] && pass "Redis responde sin auth" \
                          || { fail "Redis no responde sin auth"; fix "M2: bind 0.0.0.0 + protected-mode no"; }
  cfg="$(redis-cli -h "$M2" --no-auth-warning CONFIG GET dir 2>/dev/null | tail -n1 || true)"
  [[ -n "$cfg" ]] && pass "CONFIG GET dir permitido (dir=$cfg)" \
                  || { fail "CONFIG SET/GET no permitido"; fix "M2: Redis sin requirepass"; }
else
  warn "sin redis-cli en M6 (lo instala lab/m6/install.sh)"
fi

if command -v sshpass >/dev/null 2>&1; then
  user="$(ssh_admin "$M2" adminm2 adminm2 'ps -o user= -C redis-server' || true)"
  user="$(echo "$user" | tr -d '[:space:]')"
  [[ "$user" == "root" ]] && pass "Redis corre como root" \
                          || { fail "Redis corre como '${user:-?}' (se necesita root)"; fix "M2: unit redis-lab con User=root"; }
  ssh_admin "$M2" adminm2 adminm2 'sudo -n test -d /root/.ssh' \
    && pass "/root/.ssh existe (destino del SAVE)" \
    || { fail "/root/.ssh no existe"; fix "M2: mkdir -p /root/.ssh && chmod 700 /root/.ssh"; }
else
  warn "sin sshpass: no puedo verificar el usuario de Redis ni /root/.ssh"
fi

# ---------------------------------------------------------------- M3
step "M3 (${M3}) · NFS no_root_squash + cron"
if port_open "$M3" 2049; then
  pass "2049/tcp abierto"
else
  fail "2049/tcp cerrado"; fix "M3: sudo bash lab/m3/install.sh"
fi

if command -v sshpass >/dev/null 2>&1; then
  exports="$(ssh_admin "$M3" rony123 rony123 'exportfs -v' || true)"
  grep -q 'no_root_squash' <<<"$exports" \
    && pass "export con no_root_squash" \
    || { fail "export sin no_root_squash"; fix "M3: /etc/exports + exportfs -ra"; }
  ssh_admin "$M3" rony123 rony123 'cat /etc/cron.d/lab-rotate' >/dev/null 2>&1 \
    && pass "cron /etc/cron.d/lab-rotate presente" \
    || { fail "falta /etc/cron.d/lab-rotate"; fix "M3: reinstalar (lab/m3/install.sh)"; }
  ssh_admin "$M3" rony123 rony123 'test -x /srv/storage/backups/rotate.sh' \
    && pass "rotate.sh ejecutable" \
    || { fail "rotate.sh ausente o sin +x"; fix "M3: reinstalar"; }
else
  warn "sin sshpass: no puedo verificar export/cron de M3"
fi

# ---------------------------------------------------------------- M4
step "M4 (${M4}) · MS17-010"
for p in 445 5985 53; do
  port_open "$M4" "$p" && pass "${p}/tcp abierto" || { fail "${p}/tcp cerrado"; fix "M4: firewall / rol DNS+WinRM"; }
done

if command -v nmap >/dev/null 2>&1; then
  protos="$(nmap -Pn -p445 --script smb-protocols "$M4" 2>/dev/null || true)"
  if grep -qiE 'SMBv1|NT LM 0\.12' <<<"$protos"; then
    pass "SMBv1 habilitado"
  else
    fail "SMBv1 no detectado"
    fix "M4: Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol"
  fi
  if (( FULL )); then
    vuln="$(nmap -Pn -p445 --script smb-vuln-ms17-010 "$M4" 2>/dev/null || true)"
    if grep -qi 'VULNERABLE' <<<"$vuln"; then
      pass "MS17-010: VULNERABLE (EternalBlue viable)"
    else
      warn "MS17-010 no marcado vulnerable (¿build parcheado?) → usar PrintNightmare con soporte"
      fix "M4: si el ISO trae el parche, salto 4 con PrintNightmare (CVE-2021-34527)"
    fi
  fi
else
  warn "sin nmap: no puedo verificar SMBv1/MS17-010"
fi

# ---------------------------------------------------------------- M5
step "M5 (${M5}) · VNC sin auth"
if port_open "$M5" 5900; then
  pass "5900/tcp abierto"
else
  fail "5900/tcp cerrado"; fix "M5: instalar TightVNC y abrir 5900"
fi

if command -v nmap >/dev/null 2>&1; then
  vnc="$(nmap -Pn -p5900 --script vnc-info "$M5" 2>/dev/null || true)"
  grep -qi 'Authentication: *None' <<<"$vnc" \
    && pass "VNC sin autenticación (None)" \
    || { warn "VNC no confirma None"; fix "M5: UseVncAuthentication=0"; }
else
  warn "sin nmap: no puedo verificar vnc-info"
fi

# ---------------------------------------------------------------- resumen
step "resumen"
printf '  PASS=%d  FAIL=%d  WARN=%d\n' "$PASS" "$FAIL" "$WARN"
if (( FAIL > 0 )); then
  printf '\nAcciones correctivas:\n'
  printf '  - %s\n' "${FIXES[@]}"
  printf '\nNo iniciar la demo hasta que FAIL=0.\n'
  exit 1
fi

printf '\nTodo listo. Orden de la demo:\n'
printf '  bash %s/01-m1-php2shell.sh --run\n' "$HERE"
printf '  bash %s/02-m1-to-m2.sh --run\n' "$HERE"
printf '  bash %s/03-m2-to-m3.sh --run\n' "$HERE"
printf '  bash %s/04-m3-to-m4.sh --run\n' "$HERE"
printf '  bash %s/05-m4-to-m5.sh --run\n' "$HERE"
