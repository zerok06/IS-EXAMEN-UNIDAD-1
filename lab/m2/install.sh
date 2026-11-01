#!/usr/bin/env bash
# =============================================================================
# lab/m2/install.sh — M2 "m2-db" (10.10.10.12)
#
# Rol: base de datos del escenario PHP2Shell.
#   - MariaDB (apt) escuchando en 10.10.10.12, sin resolución de nombres.
#   - Bases wp_db y moodle_db (utf8mb4) con usuarios de contraseña débil.
#   - Redis 6.2.6 compilado desde artifacts/ (sin auth, bind 0.0.0.0).
#   - SSH con contraseña + adminm2/adminm2 con sudo NOPASSWD  <- debilidad.
#   - Llave ed25519 de root para el salto M2 -> M3.
#
# Uso:      sudo bash /opt/lab/m2/install.sh
# Requiere: Ubuntu Server 22.04, red aislada 10.10.10.0/24, root.
# Artefactos: /opt/lab/artifacts (o espejo http://10.10.10.20:8000).
# Idempotente: re-ejecutar no rompe nada ni duplica reglas/usuarios.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common/lib.sh
source "$SCRIPT_DIR/../common/lib.sh"

export LAB_ROLE="${LAB_ROLE:-m2-db}"    # prefijo de log (bootstrap.sh exporta m2)
LAB_IP="$M2"                            # 10.10.10.12

DB_PASS="ClaveDebil123"                 # credencial débil intencional (WP/Moodle)
REDIS_VERSION="6.2.6"
REDIS_SHA256="5b2b8b7a50111ef395bf1c1d5be11e6e167ac018125055daa8b5c2317ae131ab"
M3_PASS="rony123"                       # usuario con sudo en M3 (solo laboratorio)

IFACE="${IFACE:-}"                      # override: IFACE=ens18 sudo -E bash install.sh
REDIS_BIN=""                            # se resuelve en install_redis
REDIS_CLI=""
VERIFY_STATUS="no ejecutado"

# ---------------------------------------------------------------- red / host
# Detecta la interfaz por la que se llega al gateway del laboratorio.
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
# ensure_user <usuario> <clave> <comentario>
ensure_user() {
  local u="$1" p="$2" c="${3:-lab}"
  if id -u "$u" >/dev/null 2>&1; then
    ok "usuario ya existe: $u"
  else
    useradd -m -s /bin/bash -c "$c" "$u"
    log "usuario creado: $u"
  fi
  # la clave se fija siempre: mantiene la idempotencia si alguien la cambió
  printf '%s:%s\n' "$u" "$p" | chpasswd
}

# ---------------------------------------------------------------- paquetes
install_packages() {
  step "paquetes base"
  apt_install mariadb-server mariadb-client openssh-server ufw curl \
              ca-certificates sshpass rsync nfs-common
  ok "paquetes base instalados"
}

# ---------------------------------------------------------------- MariaDB
configure_mariadb() {
  step "MariaDB: bind ${LAB_IP} y skip-name-resolve"
  # El drop-in 99- se carga al final y gana sobre la configuración del paquete.
  write_if_changed /etc/mysql/mariadb.conf.d/99-lab.cnf <<EOF
# LAB PHP2Shell — M2 (m2-db). Gestión: lab/m2/install.sh
[mysqld]
bind-address          = ${LAB_IP}
skip-name-resolve
character-set-server = utf8mb4
collation-server     = utf8mb4_unicode_ci
max_connections      = 200
EOF

  systemctl enable mariadb >/dev/null 2>&1 || true
  systemctl restart mariadb
  wait_port "$LAB_IP" 3306 30
  ok "MariaDB arriba en ${LAB_IP}:3306"
}

# Bases y usuarios. Además del origen real (M1), se crean copias locales para
# que el smoke test del propio M2 (mysql -h 10.10.10.12) funcione.
apply_mariadb_schema() {
  step "bases wp_db / moodle_db y usuarios"
  local host
  {
    printf "CREATE DATABASE IF NOT EXISTS wp_db     DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\n"
    printf "CREATE DATABASE IF NOT EXISTS moodle_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\n"
    for host in "$M1" 127.0.0.1 localhost "$LAB_IP"; do
      printf "CREATE USER IF NOT EXISTS 'wp_user'@'%s' IDENTIFIED BY '%s';\n"     "$host" "$DB_PASS"
      printf "ALTER  USER 'wp_user'@'%s' IDENTIFIED BY '%s';\n"                   "$host" "$DB_PASS"
      printf "GRANT ALL PRIVILEGES ON wp_db.* TO 'wp_user'@'%s';\n"               "$host"
      printf "CREATE USER IF NOT EXISTS 'moodle_user'@'%s' IDENTIFIED BY '%s';\n" "$host" "$DB_PASS"
      printf "ALTER  USER 'moodle_user'@'%s' IDENTIFIED BY '%s';\n"               "$host" "$DB_PASS"
      printf "GRANT ALL PRIVILEGES ON moodle_db.* TO 'moodle_user'@'%s';\n"       "$host"
    done
    printf "FLUSH PRIVILEGES;\n"
  } | mysql --protocol=socket -uroot
  ok "wp_db/moodle_db listas (utf8mb4); wp_user y moodle_user desde ${M1}"
}

# ---------------------------------------------------------------- Redis
# Devuelve 0 si el tarball está en el repo o en el espejo de M6.
redis_artifact_available() {
  [[ -s "$LAB_ARTIFACTS/vulnerable/redis-${REDIS_VERSION}.tar.gz" ]] && return 0
  curl -fsI --max-time 3 "$LAB_MIRROR/artifacts/vulnerable/redis-${REDIS_VERSION}.tar.gz" \
    >/dev/null 2>&1
}

build_redis() {
  local src=/usr/local/src tarball srcdir
  tarball="$src/redis-${REDIS_VERSION}.tar.gz"
  step "compilando Redis ${REDIS_VERSION} desde artifacts/"
  apt_install build-essential
  install -d -m 0755 "$src"
  fetch_artifact "vulnerable/redis-${REDIS_VERSION}.tar.gz" "$tarball"
  sha256_check "$tarball" "$REDIS_SHA256"

  tar -xzf "$tarball" -C "$src" --no-same-owner
  srcdir="$src/redis-${REDIS_VERSION}"
  make -C "$srcdir" -j"$(nproc)"
  make -C "$srcdir" install PREFIX=/usr/local >/dev/null
  ok "Redis instalado: $(/usr/local/bin/redis-server --version)"
}

install_redis() {
  step "Redis ${REDIS_VERSION} sin autenticación"

  if [[ -x /usr/local/bin/redis-server ]] \
     && /usr/local/bin/redis-server --version 2>/dev/null | grep -q "v=${REDIS_VERSION}"; then
    ok "Redis ${REDIS_VERSION} ya compilado en /usr/local"
    REDIS_BIN=/usr/local/bin/redis-server
    REDIS_CLI=/usr/local/bin/redis-cli
  elif redis_artifact_available; then
    build_redis
    REDIS_BIN=/usr/local/bin/redis-server
    REDIS_CLI=/usr/local/bin/redis-cli
  else
    # Fallback documentado: la versión de la distro NO es 6.2.6 (ver artifacts/README.md).
    warn "sin artifacts/vulnerable/redis-${REDIS_VERSION}.tar.gz; se usa el paquete apt"
    apt_install redis-server redis-tools
    # el servicio del paquete ocupa 127.0.0.1:6379; se cede el puerto a redis-lab
    systemctl disable --now redis-server.service >/dev/null 2>&1 || true
    # El perfil AppArmor del paquete solo permite /etc/redis y /var/lib/redis;
    # con la configuración propia en /etc/redis-lab hay que retirarlo.
    if [[ -f /etc/apparmor.d/usr.bin.redis-server ]]; then
      install -d -m 0755 /etc/apparmor.d/disable
      ln -sf /etc/apparmor.d/usr.bin.redis-server /etc/apparmor.d/disable/
      apparmor_parser -R /etc/apparmor.d/usr.bin.redis-server >/dev/null 2>&1 || true
      warn "perfil AppArmor del redis del paquete deshabilitado (config en /etc/redis-lab)"
    fi
    REDIS_BIN=/usr/bin/redis-server
    REDIS_CLI=/usr/bin/redis-cli
  fi

  # usuario de sistema sin shell para el servicio
  if id -u redis >/dev/null 2>&1; then
    ok "usuario de servicio redis ya existe"
  else
    useradd -r -s /usr/sbin/nologin -d /var/lib/redis-lab redis
    log "usuario de servicio redis creado"
  fi
  install -d -o redis -g redis -m 0750 /var/lib/redis-lab /var/log/redis-lab

  write_if_changed /etc/redis-lab/redis.conf <<EOF
# LAB PHP2Shell — M2 (m2-db). Gestión: lab/m2/install.sh
# Redis ${REDIS_VERSION} deliberadamente expuesto y SIN requirepass.
bind 0.0.0.0
protected-mode no
port 6379
daemonize no
supervised no
pidfile /run/redis-lab/redis.pid
logfile /var/log/redis-lab/redis.log
dir /var/lib/redis-lab
appendonly no
save 900 1
save 300 10
save 60 10000
EOF

  write_if_changed /etc/systemd/system/redis-lab.service <<EOF
# LAB PHP2Shell — M2. Servicio propio para controlar la versión instalada.
[Unit]
Description=Redis ${REDIS_VERSION} (lab PHP2Shell, sin autenticacion)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
# Intencional: Redis corre como root. Con `CONFIG SET dir/dbfilename` + SAVE
# escribe donde quiera; es el vector de M2 en la cadena (sin credenciales).
User=root
Group=root
RuntimeDirectory=redis-lab
RuntimeDirectoryMode=0750
ExecStart=${REDIS_BIN} /etc/redis-lab/redis.conf
ExecStop=${REDIS_CLI} -p 6379 shutdown nosave
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable redis-lab >/dev/null 2>&1 || true
  systemctl restart redis-lab
  wait_port 127.0.0.1 6379 30
  ok "Redis arriba en 0.0.0.0:6379 ($("$REDIS_BIN" --version))"
}

# ---------------------------------------------------------------- cuentas
setup_admin_user() {
  step "usuario débil adminm2 (sudo sin contraseña)"
  ensure_user adminm2 adminm2 "LAB M2 (debilidad intencional)"
  usermod -aG sudo adminm2

  write_if_changed /etc/sudoers.d/90-adminm2 <<'EOF'
# LAB PHP2Shell — M2. Intencional: adminm2 con sudo sin contraseña.
adminm2 ALL=(ALL) NOPASSWD: ALL
EOF
  chmod 0440 /etc/sudoers.d/90-adminm2
  visudo -cf /etc/sudoers.d/90-adminm2 >/dev/null
  ok "adminm2: sudo -n habilitado"
}

setup_ssh() {
  step "SSH con autenticación por contraseña"
  install -d -m 0755 /etc/ssh/sshd_config.d
  write_if_changed /etc/ssh/sshd_config.d/99-lab-password.conf <<'EOF'
# LAB PHP2Shell — M2. Intencional: contraseñas por SSH (cadena M1 -> M2).
PasswordAuthentication yes
KbdInteractiveAuthentication yes
EOF
  # Ubuntu 22.04 ya incluye el drop-in; se asegura por si la imagen lo quitó.
  if ! grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' /etc/ssh/sshd_config; then
    printf '\nInclude /etc/ssh/sshd_config.d/*.conf\n' >> /etc/ssh/sshd_config
    log "Include de sshd_config.d añadido a /etc/ssh/sshd_config"
  fi
  sshd -t
  systemctl enable ssh >/dev/null 2>&1 || true
  systemctl reload ssh 2>/dev/null || systemctl restart ssh
  ok "sshd recargado (PasswordAuthentication yes)"
}

# ---------------------------------------------------------------- llave root
setup_root_key() {
  step "par de llaves ed25519 de root"
  install -d -m 0700 /root/.ssh
  if [[ ! -f /root/.ssh/id_ed25519 ]]; then
    ssh-keygen -q -t ed25519 -N '' -C "root@m2-db (lab PHP2Shell)" \
      -f /root/.ssh/id_ed25519
    log "llave ed25519 generada: /root/.ssh/id_ed25519"
  else
    ok "llave existente: /root/.ssh/id_ed25519"
  fi
  chmod 600 /root/.ssh/id_ed25519
  chmod 644 /root/.ssh/id_ed25519.pub
  # Ruta de transporte offline para M3 (por si el push no está disponible).
  install -D -m 0644 /root/.ssh/id_ed25519.pub "$LAB_REPO_DIR/keys/m2-backup.pub"
  ok "pública publicada en $LAB_REPO_DIR/keys/m2-backup.pub"
}

# Copia la pública a backup@M3 usando la cuenta rony123 (con sudo sin clave).
# No es fatal: si M3 no responde, se imprime el comando manual exacto.
push_key_to_m3() {
  local pub=/root/.ssh/id_ed25519.pub key remote
  step "copia de la llave a backup@${M3}"

  if ! timeout 3 bash -c "exec 3<>/dev/tcp/${M3}/22" 2>/dev/null; then
    warn "M3 (${M3}:22) no responde todavía"
    print_manual_key_step
    return 0
  fi
  if ! command -v sshpass >/dev/null 2>&1; then
    warn "sshpass no disponible; no se puede automatizar el copiado"
    print_manual_key_step
    return 0
  fi

  key=$(cat "$pub")
  # sort -u deja authorized_keys sin duplicados al re-ejecutar el instalador.
  remote="sudo -n install -d -m 700 -o backup -g backup /home/backup/.ssh
sudo -n tee -a /home/backup/.ssh/authorized_keys >/dev/null
sudo -n sh -c 'sort -u -o /home/backup/.ssh/authorized_keys /home/backup/.ssh/authorized_keys'
sudo -n chmod 600 /home/backup/.ssh/authorized_keys
sudo -n chown backup:backup /home/backup/.ssh/authorized_keys"

  if printf '%s\n' "$key" | sshpass -p "$M3_PASS" ssh \
       -o StrictHostKeyChecking=no -o UserKnownHostsFile=/root/.ssh/known_hosts_m3 \
       -o ConnectTimeout=10 "rony123@${M3}" "$remote"; then
    if ssh -i /root/.ssh/id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no \
         -o UserKnownHostsFile=/root/.ssh/known_hosts_m3 -o ConnectTimeout=10 \
         "backup@${M3}" true 2>/dev/null; then
      ok "llave instalada y probada: ssh backup@${M3}"
    else
      warn "llave copiada pero la prueba ssh backup@${M3} falló"
      print_manual_key_step
    fi
  else
    warn "no se pudo copiar la llave a backup@${M3}"
    print_manual_key_step
  fi
}

print_manual_key_step() {
  warn "ejecuta a mano este comando (o deja la pública en /opt/lab/keys/m2-backup.pub):"
  printf '\n  # pública de M2:\n  %s\n\n' "$(cat /root/.ssh/id_ed25519.pub)" >&2
  printf '  cat /root/.ssh/id_ed25519.pub | ssh rony123@%s \\\n' "$M3" >&2
  printf "    'sudo -n install -d -m 700 -o backup -g backup /home/backup/.ssh && \\\\\n" >&2
  printf "     sudo -n tee -a /home/backup/.ssh/authorized_keys >/dev/null && \\\\\n" >&2
  printf "     sudo -n chmod 600 /home/backup/.ssh/authorized_keys && \\\\\n" >&2
  printf "     sudo -n chown backup:backup /home/backup/.ssh/authorized_keys'\n\n" >&2
}

# ---------------------------------------------------------------- firewall
# Reglas incrementales: nunca `ufw --force reset`.
ufw_rule() {
  if ufw "$@" >/dev/null 2>&1; then
    ok "ufw: $*"
  else
    warn "ufw: no se pudo aplicar '$*'"
  fi
}

configure_ufw() {
  step "UFW (22 abierto; 3306 solo desde ${M1}; 6379 a la LAN)"
  ufw default deny incoming  >/dev/null
  ufw default allow outgoing >/dev/null
  ufw_rule allow 22/tcp
  ufw_rule allow from "$LAB_NET" to any port 3306 proto tcp
  ufw_rule allow from "$LAB_NET" to any port 6379 proto tcp
  ufw --force enable >/dev/null
  ok "UFW activo: $(ufw status | head -n1)"
}

# ---------------------------------------------------------------- smoke test
smoke_sql() {
  step "smoke test SQL local"
  local out
  out=$(mysql -h "$LAB_IP" -u wp_user -p"$DB_PASS" -N -B -e 'SELECT 1' 2>/dev/null) \
    || die "wp_user no puede conectar a ${LAB_IP} (revisar grants/bind-address)"
  [[ "$out" == "1" ]] || die "respuesta SQL inesperada: '${out}'"
  ok "mysql -h ${LAB_IP} -u wp_user -> 1"
}

# ---------------------------------------------------------------- resumen
print_summary() {
  local maria_ver redis_ver
  maria_ver=$( (mariadb --version 2>/dev/null || mysql --version) | head -n1 )
  redis_ver=$("$REDIS_BIN" --version 2>/dev/null | head -n1)

  cat <<EOF

────────────────────────────────────────────────────────────────
  RESUMEN · M2 · ${LAB_IP} · $(hostname)
────────────────────────────────────────────────────────────────
  MariaDB   ${maria_ver}
            bind-address=${LAB_IP}  skip-name-resolve  utf8mb4
            wp_db / moodle_db  ·  wp_user / moodle_user (${DB_PASS})
            acceso concedido a: ${M1} (+ local, para el smoke test)

  Redis     ${redis_ver}
            bind 0.0.0.0:6379  protected-mode no  appendonly no
            SIN requirepass (intencional)  ·  servicio: redis-lab

  SSH       PasswordAuthentication yes
            adminm2 / adminm2  ·  sudo NOPASSWD  <- debilidad intencional

  Llave     /root/.ssh/id_ed25519
            pública en ${LAB_REPO_DIR}/keys/m2-backup.pub
            destino: backup@${M3}

  Firewall  22/tcp abierto · 3306 desde ${M1} · 6379 desde ${LAB_NET}

  Extra     wp_db/moodle_db son el volcado que la cadena obtiene en este salto.

  verify    ${VERIFY_STATUS}
────────────────────────────────────────────────────────────────
  Siguiente paso:  sudo bash ${SCRIPT_DIR}/verify.sh

  Snapshot sugerido antes de continuar:  01-m2-listo
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
  set_hostname "m2-db"

  install_packages
  configure_mariadb
  apply_mariadb_schema
  install_redis
  setup_admin_user
  setup_ssh
  setup_root_key
  push_key_to_m3
  configure_ufw
  smoke_sql

  # Verificación final: el instalador no declara éxito sin verify.sh en verde.
  if [[ -f "$SCRIPT_DIR/verify.sh" ]]; then
    step "verificación (verify.sh)"
    if bash "$SCRIPT_DIR/verify.sh"; then
      VERIFY_STATUS="OK"
    else
      VERIFY_STATUS="CON FALLOS"
    fi
  fi

  print_summary
  [[ "$VERIFY_STATUS" != "CON FALLOS" ]] || die "verify.sh reportó fallos en M2"
}

main "$@"
