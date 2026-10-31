#!/usr/bin/env bash
# =============================================================================
# lab/m3/verify.sh — comprobaciones de M3 (m3-bkp, 10.10.10.13)
#
# Solo lectura: no instala, no reinicia, no cambia configuración.
# La única escritura posible es la del cliente SSH en ~/.ssh/known_hosts, que
# se desactiva con UserKnownHostsFile=/dev/null.
# Salida: exit 0 si todo pasa; exit != 0 si algo falla.
#
# Uso: sudo bash /opt/lab/m3/verify.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/lib.sh
source "$SCRIPT_DIR/../common/lib.sh"

export LAB_ROLE="${LAB_ROLE:-m3-bkp}"
trap - ERR   # aquí se acumulan fallos: no se aborta en la primera comprobación

LAB_IP="$M3"
VSFTPD_VERSION="2.3.4"
STORAGE="/srv/storage"

require_root

PASS=0
FAIL=0
pass() { ok "$*"; PASS=$((PASS + 1)); }
fail() { warn "FALLA: $*"; FAIL=$((FAIL + 1)); }

listening() {
  ss -ltn 2>/dev/null | awk 'NR > 1 { print $4 }' | grep -qE "[:.]$1\$"
}

# Lee la primera línea (banner) del puerto indicado sin usar cliente FTP.
banner_de() {
  timeout 5 bash -c "exec 3<>/dev/tcp/127.0.0.1/$1; IFS= read -r -t 4 line <&3; printf '%s' \"\$line\"" \
    2>/dev/null || true
}

lab_banner
step "servicio vsftpd"

if [[ -x /usr/local/sbin/vsftpd ]]; then
  vbin=$(/usr/local/sbin/vsftpd -v 2>&1 | head -n1 || true)
  if grep -q "$VSFTPD_VERSION" <<<"$vbin"; then
    pass "binario vsftpd ${VSFTPD_VERSION}: ${vbin}"
  else
    fail "binario vsftpd inesperado: ${vbin:-sin versión}"
  fi
else
  fail "no existe /usr/local/sbin/vsftpd (¿se instaló el paquete apt en su lugar?)"
fi

if systemctl is-active --quiet vsftpd-lab; then
  pass "servicio vsftpd-lab activo"
else
  fail "servicio vsftpd-lab inactivo"
fi

if listening 21; then pass "21/tcp escuchando"; else fail "21/tcp no escucha"; fi

# ---- banner ---------------------------------------------------------------
step "banner"
banner=$(banner_de 21 | tr -d '\r')
if grep -qE '^220[ -].*vsFTPd 2\.3\.4' <<<"$banner"; then
  pass "banner correcto: ${banner}"
else
  fail "banner inesperado: '${banner:-sin respuesta}'"
fi

# ---- login anónimo --------------------------------------------------------
step "acceso anónimo"
if curl -sS --max-time 10 -o /dev/null "ftp://anonymous:anon@127.0.0.1/" 2>/dev/null; then
  pass "login anónimo y LIST de /srv/ftp"
else
  fail "login anónimo falló (curl ftp://anonymous@127.0.0.1/)"
fi

vconf=/etc/vsftpd-lab.conf
if [[ -f "$vconf" ]]; then
  for opt in "anonymous_enable=YES" "anon_upload_enable=YES" "anon_mkdir_write_enable=YES" \
             "local_enable=YES" "write_enable=YES" "secure_chroot_dir=/usr/share/empty" \
             "pasv_min_port=40000" "pasv_max_port=40100"; do
    if grep -qxF "$opt" "$vconf"; then pass "config: $opt"; else fail "config sin '${opt}'"; fi
  done
else
  fail "no existe ${vconf}"
fi

# ---- NFS ------------------------------------------------------------------
step "NFS"
if systemctl is-active --quiet nfs-kernel-server; then
  pass "servicio nfs-kernel-server activo"
else
  fail "servicio nfs-kernel-server inactivo"
fi
if listening 2049; then pass "2049/tcp escuchando"; else fail "2049/tcp no escucha"; fi

exports=$(exportfs -v 2>/dev/null || true)
if grep -q "^${STORAGE}/backups" <<<"$exports"; then
  pass "${STORAGE}/backups exportado"
else
  fail "${STORAGE}/backups no aparece en exportfs -v"
fi
if grep "^${STORAGE}/backups" <<<"$exports" | grep -q 'no_root_squash'; then
  pass "backups con no_root_squash (privesc por NFS)"
else
  fail "backups sin no_root_squash"
fi
if grep "^${STORAGE}/backups" <<<"$exports" | grep -q '10\.10\.10\.0/24'; then
  pass "backups exportado a 10.10.10.0/24"
else
  fail "backups no está exportado a 10.10.10.0/24"
fi
for d in wp-uploads moodledata; do
  if grep "^${STORAGE}/${d}" <<<"$exports" | grep -q '10\.10\.10\.11'; then
    pass "${d} exportado solo a 10.10.10.11"
  else
    fail "${d} no exportado a 10.10.10.11"
  fi
done

# ---- directorios y credenciales ------------------------------------------
step "datos del escenario"
for d in backups wp-uploads moodledata; do
  path="${STORAGE}/${d}"
  if [[ -d "$path" ]]; then
    perms=$(stat -c '%a %U:%G' "$path" 2>/dev/null || true)
    if [[ "$perms" == "2775 www-data:www-data" ]]; then
      pass "${path} 2775 www-data:www-data"
    else
      fail "${path} con permisos '${perms}' (esperado 2775 www-data:www-data)"
    fi
  else
    fail "no existe ${path}"
  fi
done

rotate="${STORAGE}/backups/rotate.sh"
if [[ -x "$rotate" ]]; then
  pass "rotate.sh ejecutable (cron root del escenario)"
else
  fail "falta ${rotate} o no es ejecutable"
fi
if grep -q "${STORAGE}/backups/rotate.sh" /etc/cron.d/lab-rotate 2>/dev/null; then
  pass "cron root sobre rotate.sh (cada minuto)"
else
  fail "sin /etc/cron.d/lab-rotate apuntando a rotate.sh"
fi

# ---- usuarios y llave -----------------------------------------------------
step "cuenta backup"
if id -u backup >/dev/null 2>&1; then
  pass "usuario backup existe ($(getent passwd backup | cut -d: -f7))"
  if passwd -S backup 2>/dev/null | grep -qE '^backup L'; then
    pass "backup sin contraseña utilizable (bloqueada)"
  else
    warn "backup no está bloqueado por contraseña (se esperaba 'L')"
  fi
  ak=/home/backup/.ssh/authorized_keys
  if [[ -f "$ak" ]]; then
    perms=$(stat -c '%a %U:%G' "$ak" 2>/dev/null || true)
    if [[ "$perms" == "600 backup:backup" ]]; then
      pass "authorized_keys 600 backup:backup"
    else
      fail "authorized_keys con permisos '${perms}' (esperado 600 backup:backup)"
    fi
    if [[ -s "$ak" ]]; then
      pass "authorized_keys con $(wc -l <"$ak") llave(s)"
    else
      warn "authorized_keys vacío (M2 aún no copió su llave; no es parte de la cadena)"
    fi
  else
    fail "no existe ${ak}"
  fi
  dirperms=$(stat -c '%a' /home/backup/.ssh 2>/dev/null || true)
  [[ "$dirperms" == "700" ]] && pass "/home/backup/.ssh 700" \
                             || fail "/home/backup/.ssh con permisos '${dirperms}' (esperado 700)"
else
  fail "usuario backup no existe"
fi

# ---- llave de M2 (si está en esta máquina) --------------------------------
step "prueba de llave M2 -> backup"
if [[ -f /root/.ssh/id_ed25519 ]]; then
  if ssh -i /root/.ssh/id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
        backup@127.0.0.1 true 2>/dev/null; then
    pass "ssh backup@localhost con la llave de M2"
  else
    fail "ssh backup@localhost con /root/.ssh/id_ed25519 falló"
  fi
else
  warn "sin /root/.ssh/id_ed25519 aquí: prueba de llave omitida (se hace desde M2)"
fi

# ---- ssh y firewall -------------------------------------------------------
step "ssh y firewall"
if sshd -T 2>/dev/null | grep -qiE '^passwordauthentication yes'; then
  pass "sshd con PasswordAuthentication yes (rony123 desde M2)"
else
  fail "sshd sin PasswordAuthentication yes"
fi
if ufw status 2>/dev/null | grep -qi '^Status: active'; then
  pass "UFW activo"
  for r in '^22/tcp' '^21/tcp' '40000:40100/tcp' '2049'; do
    if ufw status 2>/dev/null | grep -qE "$r"; then
      pass "regla UFW: ${r}"
    else
      fail "sin regla UFW para ${r}"
    fi
  done
else
  fail "UFW inactivo"
fi

# ---- resultado -------------------------------------------------------------
step "resultado M3"
printf '  %d comprobaciones OK · %d fallos\n' "$PASS" "$FAIL"
if (( FAIL > 0 )); then
  warn "M3 NO está como espera el escenario (${FAIL} fallo(s))"
  exit 1
fi
ok "M3 verificado: vsFTPd 2.3.4 :21, NFS no_root_squash, cron root del export"
