#!/usr/bin/env bash
# lab/patch/m2-redis.sh — parchea M2: Redis 6.2.7, con contraseña, loopback y sin root.
# Ejecutar como root DESPUÉS de restaurar el snapshot estado-inicial.

set -euo pipefail
LAB_ROLE=patch-m2
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../common/lib.sh"

require_root
require_ubuntu

REDIS_VERSION=6.2.7
REDIS_SHA256=b7a79cc3b46d3c6eb52fa37dde34a4a60824079ebdfb3abfbbfa035947c55319
REDIS_PASS="${REDIS_PASS:-UniRedis2026!}"
SRC=/usr/local/src
TARBALL="$SRC/redis-${REDIS_VERSION}.tar.gz"

step "1/5 usuario redis"
if id -u redis >/dev/null 2>&1; then
  ok "usuario redis ya existe"
else
  useradd -r -s /usr/sbin/nologin -d /var/lib/redis-lab redis
  ok "usuario redis creado"
fi

step "2/5 Redis ${REDIS_VERSION}"
if /usr/local/bin/redis-server --version 2>/dev/null | grep -q "v=${REDIS_VERSION}"; then
  ok "Redis ${REDIS_VERSION} ya instalado"
else
  fetch_artifact "fixed/redis-${REDIS_VERSION}.tar.gz" "$TARBALL"
  sha256_check "$TARBALL" "$REDIS_SHA256"
  rm -rf "$SRC/redis-${REDIS_VERSION}"
  tar xzf "$TARBALL" -C "$SRC"
  make -C "$SRC/redis-${REDIS_VERSION}" -j"$(nproc)"
  make -C "$SRC/redis-${REDIS_VERSION}" install
fi
/usr/local/bin/redis-server --version

step "3/5 configuración endurecida"
install -d -o redis -g redis -m 0750 /var/lib/redis-lab /etc/redis-lab
write_if_changed /etc/redis-lab/redis.conf <<EOF
# LAB PHP2Shell — M2 parcheado
bind 127.0.0.1
protected-mode yes
port 6379
requirepass $REDIS_PASS
daemonize no
supervised no
dir /var/lib/redis-lab
appendonly no
save 900 1
EOF
chown redis:redis /etc/redis-lab/redis.conf
chmod 0640 /etc/redis-lab/redis.conf

write_if_changed /etc/systemd/system/redis-lab.service <<EOF
[Unit]
Description=Redis 6.2.7 (lab PHP2Shell, parcheado)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=redis
Group=redis
RuntimeDirectory=redis-lab
RuntimeDirectoryMode=0750
ExecStart=/usr/local/bin/redis-server /etc/redis-lab/redis.conf
ExecStop=/usr/local/bin/redis-cli -a ${REDIS_PASS} -p 6379 shutdown nosave
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

step "4/5 firewall"
ufw delete allow 6379/tcp >/dev/null 2>&1 || true
ufw delete allow from "$LAB_NET" to any port 3306 proto tcp >/dev/null 2>&1 || true
ufw allow from "$M1" to any port 3306 proto tcp >/dev/null 2>&1 || true
ufw deny 6379/tcp >/dev/null 2>&1 || true
ufw reload >/dev/null 2>&1 || true
ok "6379 solo loopback; 3306 solo desde M1"

step "5/5 reiniciar y verificar"
systemctl daemon-reload
enable_now redis-lab

if redis-cli -h 127.0.0.1 PING >/dev/null 2>&1; then
  die "Redis sigue aceptando PING sin contraseña"
fi
redis-cli -h 127.0.0.1 -a "$REDIS_PASS" --no-auth-warning PING | grep -q PONG \
  || die "Redis no responde con la contraseña"
ss -lnt | grep -q '127.0.0.1:6379' || die "Redis no escucha en loopback"
ss -lnt | grep -q '0.0.0.0:6379' && die "Redis sigue expuesto en 0.0.0.0"
ok "M2 parcheado: Redis 6.2.7, requirepass, loopback, usuario redis"
