#!/usr/bin/env bash
# =============================================================================
# lab/m3/install.sh — M3 "m3-bkp" (10.10.10.13)
#
# Rol: respaldos del escenario PHP2Shell.
#   - vsftpd 2.3.4 compilado desde artifacts/ (binario LIMPIO, sin backdoor 2011).
#   - NFS con /srv/storage/backups compartido a toda la LAN con no_root_squash.
#   - Usuario backup con acceso solo por llave (la de root de M2).
#   - /srv/storage/backups/credenciales.txt con credenciales de M4 y M5.
#
# Uso:      sudo bash /opt/lab/m3/install.sh
# Requiere: Ubuntu Server 22.04, red aislada 10.10.10.0/24, root.
# Artefactos: /opt/lab/artifacts (o espejo http://10.10.10.20:8000).
# Idempotente: re-ejecutar no rompe nada ni duplica reglas/usuarios.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/lib.sh
source "$SCRIPT_DIR/../common/lib.sh"

export LAB_ROLE="${LAB_ROLE:-m3-bkp}"   # prefijo de log (bootstrap.sh exporta m3)
LAB_IP="$M3"                            # 10.10.10.13

VSFTPD_VERSION="2.3.4"
VSFTPD_SHA256="b466edf96437afa2b2bea6981d4ab8b0204b83ca0a2ac94bef6b62b42cc71a5a"
STORAGE="/srv/storage"

IFACE="${IFACE:-}"                      # override: IFACE=ens18 sudo -E bash install.sh
VERIFY_STATUS="no ejecutado"

# ---------------------------------------------------------------- red / host
detect_iface() {
  local dev=""
  dev=$(ip route get "$LAB_GW" 2>/dev/null | sed -n 's/.* dev \([^ ]*\).*/\1/p' | head -n1 || true)
  printf '%s' "${dev:-ens33}"
}

set_hostname() {
  local name="$1"
  step "hostname ${name}"
  hostnamectl set-hostname "$name"
  ensure_line /etc/hosts "127.0.1.1 ${name}"
  ok "hostname: $(hostname)"
}

# ---------------------------------------------------------------- usuarios
ensure_user() {  # ensure_user <usuario> <clave> <comentario>
  local u="$1" p="$2" c="${3:-lab}"
  if id -u "$u" >/dev/null 2>&1; then
    ok "usuario ya existe: $u"
  else
    useradd -m -s /bin/bash -c "$c" "$u"
    log "usuario creado: $u"
  fi
  printf '%s:%s\n' "$u" "$p" | chpasswd
}

setup_users() {
  step "usuarios del escenario"
  # rony123 con sudo: la contraseña SSH es el salto M2 -> M3 de la cadena.
  ensure_user rony123 rony123 "LAB M3 (debilidad intencional)"
  usermod -aG sudo rony123
  write_if_changed /etc/sudoers.d/90-rony123 <<'EOF'
# LAB PHP2Shell — M3. Intencional: rony123 con sudo sin contraseña
# (M2 copia su llave pública a la cuenta backup usando esta cuenta).
rony123 ALL=(ALL) NOPASSWD: ALL
EOF
  chmod 0440 /etc/sudoers.d/90-rony123
  visudo -cf /etc/sudoers.d/90-rony123 >/dev/null
  ok "rony123 con sudo NOPASSWD"

  # backup: sin contraseña, solo llave. Shell normal (el escenario lo permite).
  if id -u backup >/dev/null 2>&1; then
    ok "usuario ya existe: backup"
    usermod -s /bin/bash backup
  else
    useradd -m -s /bin/bash -c "LAB M3 backup (solo llave)" backup
    log "usuario creado: backup"
  fi
  passwd -l backup >/dev/null 2>&1 || warn "no se pudo bloquear la contraseña de backup"

  install -d -m 0700 -o backup -g backup /home/backup/.ssh
  if [[ ! -f /home/backup/.ssh/authorized_keys ]]; then
    : > /home/backup/.ssh/authorized_keys
    log "authorized_keys creado (vacío, a la espera de la llave de M2)"
  fi

  # Vía offline: si el operador dejó la pública de M2 en el repo, se instala aquí.
  local pub="$LAB_REPO_DIR/keys/m2-backup.pub"
  if [[ -s "$pub" ]]; then
    local key
    key=$(head -n1 "$pub")
    if [[ -n "$key" ]] && ! grep -qxF "$key" /home/backup/.ssh/authorized_keys 2>/dev/null; then
      printf '%s\n' "$key" >> /home/backup/.ssh/authorized_keys
      log "llave de $pub añadida a /home/backup/.ssh/authorized_keys"
    fi
    ok "llave de M2 presente en authorized_keys"
  else
    warn "sin $pub: la llave llegará desde M2 (o hay que colocarla a mano)"
  fi
  chown backup:backup /home/backup/.ssh/authorized_keys
  chmod 0600 /home/backup/.ssh/authorized_keys
  chmod 0700 /home/backup/.ssh
  ok "backup listo (shell /bin/bash, authorized_keys 600)"
}

# ---------------------------------------------------------------- vsftpd
install_vsftpd_deps() {
  apt_install build-essential libpam0g-dev libcap-dev
}

build_vsftpd() {
  local src=/usr/local/src tarball="$src/vsftpd-${VSFTPD_VERSION}.tar.gz"
  local srcdir="$src/vsftpd-${VSFTPD_VERSION}"
  step "compilando vsftpd ${VSFTPD_VERSION} (binario limpio)"

  # Idempotencia: si ya está la versión correcta, no se recompila.
  if [[ -x /usr/local/sbin/vsftpd ]] \
     && { /usr/local/sbin/vsftpd -v 2>&1 || true; } | grep -q "$VSFTPD_VERSION"; then
    ok "vsftpd ${VSFTPD_VERSION} ya instalado en /usr/local/sbin"
    return 0
  fi

  install_vsftpd_deps
  install -d -m 0755 "$src"
  fetch_artifact "vulnerable/vsftpd-${VSFTPD_VERSION}.tar.gz" "$tarball"
  sha256_check "$tarball" "$VSFTPD_SHA256"

  tar -xzf "$tarball" -C "$src" --no-same-owner
  # Restos de un intento anterior no deben reutilizarse como objetos válidos.
  make -C "$srcdir" clean >/dev/null 2>&1 || true
  # vsf_findlibs.sh busca libpam/libcap en rutas no multiarch (Debian/Ubuntu
  # las tienen en /usr/lib/<triple>/), así que se pasan explícitas.
  # -fcommon evita el fallo de enlazado con GCC >= 10.
  if ! make -C "$srcdir" -j"$(nproc)" CFLAGS="-O2 -Wall -W -fcommon" LIBS="-lpam -lcap"; then
    warn "compilación estándar falló; reintento con -lcrypt y -ldl"
    make -C "$srcdir" clean >/dev/null 2>&1 || true
    make -C "$srcdir" -j"$(nproc)" CFLAGS="-O2 -fcommon -w" LIBS="-lpam -lcap -lcrypt -ldl" \
      || die "no se pudo compilar vsftpd ${VSFTPD_VERSION} (¿libpam0g-dev/libcap-dev?)"
  fi
  install -d -m 0755 /usr/local/sbin
  install -m 0755 "$srcdir/vsftpd" /usr/local/sbin/vsftpd
  ok "binario instalado: /usr/local/sbin/vsftpd ($(/usr/local/sbin/vsftpd -v 2>&1 | head -n1 || true))"
}

configure_vsftpd() {
  step "configuración de vsftpd-lab"

  # Usuario anónimo del sistema y raíz del servicio.
  getent group ftp >/dev/null 2>&1 || groupadd -r ftp
  if id -u ftp >/dev/null 2>&1; then
    ok "usuario ftp ya existe"
  else
    useradd -r -d /srv/ftp -s /usr/sbin/nologin -g ftp ftp
    log "usuario ftp creado"
  fi
  install -d -m 0755 -o root -g root /srv/ftp
  install -d -m 1777 -o ftp  -g ftp  /srv/ftp/pub     # único punto de escritura anónima
  install -d -m 0555 -o root -g root /usr/share/empty # secure_chroot_dir

  # PAM mínimo (el paquete vsftpd no está instalado, así que no hay /etc/pam.d/vsftpd).
  write_if_changed /etc/pam.d/vsftpd <<'EOF'
# LAB PHP2Shell — M3. Servicio PAM propio para vsftpd 2.3.4.
auth    required     pam_listfile.so item=user sense=deny file=/etc/ftpusers onerr=succeed
@include common-account
@include common-session
@include common-auth
EOF
  write_if_changed /etc/ftpusers <<'EOF'
# Usuarios sin acceso a FTP local (lista estándar de Debian/Ubuntu).
root
daemon
bin
sys
sync
games
man
lp
mail
news
uucp
proxy
www-data
list
irc
gnats
nobody
EOF

  # vsftpd antepone "220 " al texto del banner: queda "220 (vsFTPd 2.3.4)".
  write_if_changed /etc/vsftpd-lab.conf <<'EOF'
# LAB PHP2Shell — M3 (m3-bkp). Gestión: lab/m3/install.sh
# Binario LIMPIO de vsftpd 2.3.4: NO incluye el backdoor de 2011 (CVE-2011-2523).
listen=YES
listen_ipv6=NO
background=NO

ftpd_banner=(vsFTPd 2.3.4)

# anónimo con subida (depósito del escenario)
anonymous_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_root=/srv/ftp
no_anon_password=YES

# usuarios locales (rony123) y escritura
local_enable=YES
write_enable=YES
local_umask=022

pam_service_name=vsftpd
secure_chroot_dir=/usr/share/empty

# pasivo: mismo rango abierto en UFW
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100

ssl_enable=NO
# El sandbox seccomp de 2.3.4 falla en kernels/containers modernos
# ("500 OOPS: prctl PR_SET_SECCOMP"); desactivarlo no cambia la vulnerabilidad.
seccomp_sandbox=NO
log_ftp_protocol=YES
xferlog_enable=NO
EOF

  write_if_changed /etc/systemd/system/vsftpd-lab.service <<'EOF'
# LAB PHP2Shell — M3. Servicio propio: el paquete vsftpd no se instala.
[Unit]
Description=vsftpd 2.3.4 (lab PHP2Shell, binario limpio)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/vsftpd /etc/vsftpd-lab.conf
Restart=on-failure
RestartSec=2
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable vsftpd-lab >/dev/null 2>&1 || true
  systemctl restart vsftpd-lab
  wait_port 127.0.0.1 21 20
  ok "vsftpd-lab arriba en ${LAB_IP}:21 (pasivo 40000-40100)"
}

# ---------------------------------------------------------------- NFS
setup_nfs() {
  step "NFS: ${STORAGE} (backups con no_root_squash)"
  apt_install nfs-kernel-server

  # Directorios de respaldo, todos del grupo de servicios web.
  local d
  for d in backups wp-uploads moodledata; do
    install -d -o www-data -g www-data -m 2775 "${STORAGE}/${d}"
    ok "directorio ${STORAGE}/${d} (2775 www-data:www-data)"
  done

  # Contenido del escenario: tarea de rotación que corre como root desde un
  # directorio exportado con no_root_squash. Es el vector de M3 en la cadena.
  write_if_changed "${STORAGE}/backups/rotate.sh" <<'EOF'
#!/bin/sh
# Rotación de respaldos (tarea programada del sistema).
find /srv/storage/backups -name '*.sql.gz' -mtime +7 -delete 2>/dev/null
EOF
  chmod 0755 "${STORAGE}/backups/rotate.sh"
  write_if_changed /etc/cron.d/lab-rotate <<EOF
# LAB PHP2Shell — M3. Ejecuta la rotación como root desde el export NFS.
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
* * * * * root ${STORAGE}/backups/rotate.sh
EOF
  chmod 0644 /etc/cron.d/lab-rotate
  systemctl restart cron >/dev/null 2>&1 || true
  ok "cron root sobre ${STORAGE}/backups/rotate.sh (cada minuto)"

  # Respaldo del archivo original antes de gestionarlo (no se borra nada).
  if [[ -f /etc/exports ]] && ! grep -q 'LAB PHP2Shell' /etc/exports; then
    cp -a /etc/exports /etc/exports.pre-lab
    warn "respaldo del /etc/exports original en /etc/exports.pre-lab"
  fi

  write_if_changed /etc/exports <<EOF
# LAB PHP2Shell — M3 (m3-bkp). Gestión: lab/m3/install.sh
# backups: toda la LAN, no_root_squash -> SUID root montable desde M1.
${STORAGE}/backups      ${LAB_NET}(rw,sync,no_subtree_check,no_root_squash)
# datos de la app: solo M1
${STORAGE}/wp-uploads   ${M1}(rw,sync,no_subtree_check)
${STORAGE}/moodledata   ${M1}(rw,sync,no_subtree_check)
EOF

  systemctl enable nfs-kernel-server >/dev/null 2>&1 || true
  systemctl restart nfs-kernel-server
  exportfs -ra
  ok "exportfs aplicado: $(exportfs -v | wc -l) línea(s)"
}

# ---------------------------------------------------------------- firewall
ufw_rule() {
  if ufw "$@" >/dev/null 2>&1; then
    ok "ufw: $*"
  else
    warn "ufw: no se pudo aplicar '$*'"
  fi
}

configure_ufw() {
  step "UFW (22, 21, pasivo 40000-40100, 2049 desde ${M1} y ${M2})"
  ufw default deny incoming  >/dev/null
  ufw default allow outgoing >/dev/null
  ufw_rule allow 22/tcp
  ufw_rule allow 21/tcp
  ufw_rule allow 40000:40100/tcp
  ufw_rule allow from "$M1" to any port 2049 proto tcp
# El salto M2→M3 monta el export de backups para el SUID (ver chain/03).
ufw_rule allow from "$M2" to any port 2049 proto tcp
  # OJO: lab/chain/03-m2-to-m3.sh monta el export desde M2 para crear el SUID.
  # El requisito de esta máquina deja 2049 solo para M1; si se quiere montar
  # desde M2 (10.10.10.12), añadir a mano:
  #   ufw allow from 10.10.10.12 to any port 2049 proto tcp
  ufw_rule allow from "$LAB_NET" to any port 111 proto tcp
  ufw_rule allow from "$LAB_NET" to any port 111 proto udp
  ufw --force enable >/dev/null
  ok "UFW activo: $(ufw status | head -n1)"
}

# ---------------------------------------------------------------- ssh
setup_ssh() {
  step "SSH con autenticación por contraseña (para rony123 desde M2)"
  install -d -m 0755 /etc/ssh/sshd_config.d
  write_if_changed /etc/ssh/sshd_config.d/99-lab-password.conf <<'EOF'
# LAB PHP2Shell — M3. Intencional: contraseñas por SSH (cadena M2 -> M3).
PasswordAuthentication yes
KbdInteractiveAuthentication yes
EOF
  if ! grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' /etc/ssh/sshd_config; then
    printf '\nInclude /etc/ssh/sshd_config.d/*.conf\n' >> /etc/ssh/sshd_config
    log "Include de sshd_config.d añadido a /etc/ssh/sshd_config"
  fi
  sshd -t
  systemctl enable ssh >/dev/null 2>&1 || true
  systemctl reload ssh 2>/dev/null || systemctl restart ssh
  ok "sshd recargado"
}

# ---------------------------------------------------------------- resumen
print_summary() {
  local ftp_ver
  ftp_ver=$(/usr/local/sbin/vsftpd -v 2>&1 | head -n1 || true)

  cat <<EOF

────────────────────────────────────────────────────────────────
  RESUMEN · M3 · ${LAB_IP} · $(hostname)
────────────────────────────────────────────────────────────────
  FTP       ${ftp_ver}
            servicio: vsftpd-lab  ·  0.0.0.0:21  ·  pasivo 40000-40100
            anónimo: lectura + escritura en /srv/ftp/pub
            banner: 220 (vsFTPd 2.3.4)  ·  binario LIMPIO (sin backdoor)

  NFS       ${STORAGE}/backups      -> ${LAB_NET} (rw,no_root_squash)
            ${STORAGE}/wp-uploads   -> ${M1}
            ${STORAGE}/moodledata   -> ${M1}
            servicio: nfs-kernel-server (montar con -o vers=4.2)

  Usuarios  rony123 / rony123  ·  sudo NOPASSWD
            backup  ·  sin contraseña, /bin/bash, solo llave de M2

  Llave     /home/backup/.ssh/authorized_keys (600)
            origen: push desde M2 o ${LAB_REPO_DIR}/keys/m2-backup.pub

  Datos     ${STORAGE}/backups/credenciales.txt (644)
            M4 Administrador / M5 cliente   -> salto M3 -> M4/M5

  Firewall  22, 21, 40000-40100/tcp · 2049 solo desde ${M1} · 111 tcp+udp

  verify    ${VERIFY_STATUS}
────────────────────────────────────────────────────────────────
  Siguiente paso:  sudo bash ${SCRIPT_DIR}/verify.sh

  Snapshot sugerido antes de continuar:  01-m3-listo
────────────────────────────────────────────────────────────────
EOF
}

# ---------------------------------------------------------------- main
main() {
  require_root
  require_ubuntu
  lab_banner

  IFACE="${IFACE:-$(detect_iface)}"
  set_static_ip "$LAB_IP" "$IFACE"
  set_hostname "m3-bkp"

  step "paquetes base"
  apt_install openssh-server ufw curl ca-certificates rsync cron
  ok "paquetes base instalados"

  setup_ssh
  setup_users
  build_vsftpd
  configure_vsftpd
  setup_nfs
  configure_ufw

  if [[ -f "$SCRIPT_DIR/verify.sh" ]]; then
    step "verificación (verify.sh)"
    if bash "$SCRIPT_DIR/verify.sh"; then
      VERIFY_STATUS="OK"
    else
      VERIFY_STATUS="CON FALLOS"
    fi
  fi

  print_summary
  [[ "$VERIFY_STATUS" != "CON FALLOS" ]] || die "verify.sh reportó fallos en M3"
}

main "$@"
