#!/usr/bin/env bash
# lab/tests/check-versions.sh — compara lo instalado con lab/VERSIONES.md.
# Uso: bash lab/tests/check-versions.sh [m1|m2|m3|m6]
# Sin argumento, detecta el rol por el hostname.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROLE=check
source "$HERE/../common/lib.sh"

ROLE="${1:-}"
if [[ -z "$ROLE" ]]; then
  case "$(hostname)" in
    m1*) ROLE=m1 ;;
    m2*) ROLE=m2 ;;
    m3*) ROLE=m3 ;;
    m6*|kali*) ROLE=m6 ;;
    *) die "no detecto el rol; pasa m1|m2|m3|m6" ;;
  esac
fi

fails=0; checks=0
chk() { # chk <desc> <esperado> <comando...>
  local desc="$1" want="$2"; shift 2
  checks=$((checks+1))
  local got; got="$("$@" 2>/dev/null | head -n1 | tr -d '\r')"
  if [[ "$got" == *"$want"* ]]; then
    printf '  [PASS] %-32s %s\n' "$desc" "$got"
  else
    printf '  [FAIL] %-32s esperado "%s", obtenido "%s"\n' "$desc" "$want" "${got:-nada}"
    fails=$((fails+1))
  fi
}

step "rol $ROLE · $(hostname)"
. /etc/os-release 2>/dev/null || true
chk "Ubuntu" "22.04" bash -c '. /etc/os-release; echo "$VERSION_ID"'

case "$ROLE" in
  m1)
    chk "Apache"    "2.4.49"  bash -c '/usr/local/apache2/bin/httpd -v 2>&1'
    chk "PHP"       "8.4.26"  bash -c '/usr/local/bin/php -v 2>&1'
    chk "PHP NTS"   "disabled" bash -c '/usr/local/bin/php -i | grep "Thread Safety"'
    chk "nginx"     "1.18"    bash -c 'nginx -v 2>&1'
    chk "WordPress" "7.0.1"   bash -c 'grep "wp_version =" /var/www/wp/wp-includes/version.php'
    if [[ -f /var/www/moodle/version.php ]]; then
      chk "Moodle" "5.0.11" bash -c 'grep "release" /var/www/moodle/version.php'
    else
      warn "Moodle no instalado (INSTALL_MOODLE=0)"
    fi
    ;;
  m2)
    chk "Redis"     "6.2.6"   bash -c '/usr/local/bin/redis-server --version 2>/dev/null || redis-server --version'
    chk "MariaDB"   "10.6"    bash -c 'mariadb --version || mysql --version'
    chk "OpenSSH"   "8.9p1"   bash -c 'ssh -V 2>&1'
    ;;
  m3)
    chk "vsftpd"    "2.3.4"   bash -c '/usr/local/sbin/vsftpd -v 2>&1 || true'
    chk "OpenSSH"   "8.9p1"   bash -c 'ssh -V 2>&1'
    chk "nfs"       "2.6"     bash -c 'rpc.nfsd --version 2>&1 | head -1'
    ;;
  m6)
    chk "nmap"      "7."      bash -c 'nmap --version'
    chk "Metasploit" "6."     bash -c 'msfconsole --version 2>/dev/null || echo "no instalado"'
    ;;
  *) die "rol inválido: $ROLE" ;;
esac

printf '\n%d/%d comprobaciones OK\n' "$((checks-fails))" "$checks"
(( fails == 0 )) || { printf '%d fallo(s)\n' "$fails"; exit 1; }
