#!/usr/bin/env bash
#  lab/m6/net.sh — red de M6 (Kali): dos NIC, dos mundos, un DNS partido.
#
#    eth0 (NAT)     -> Internet, ruta por defecto, DNS del NAT.
#    eth1 (bridge)  -> laboratorio 10.10.10.0/24, IP fija 10.10.10.20.
#    127.0.0.1:53   -> resolvedor partido: *.uni.lab -> M4, el resto -> NAT.
#
#  Por qué partido y no "nameserver 10.10.10.14" a secas:
#    M4 (10.10.10.14) es el DNS autoritativo de uni.lab, pero su rol se instala
#    **sin reenviadores** (lab/m4/install.ps1, Disable-DnsForwarders): no resuelve
#    nombres de Internet. Si M6 lo usa como único resolver, apt/curl dejan de
#    funcionar y cada consulta externa espera timeout. El resolvedor local manda
#    solo uni.lab a M4 y el resto al DNS del NAT.
#
#  Otras reglas:
#   * La NIC del laboratorio NO lleva gateway (la ruta por defecto es del NAT).
#   * R0 (10.10.10.1) es el router/NAT interno; M6 es 10.10.10.20.
#   * Nada de /etc/hosts para uni.lab por defecto: taparía a M4. Con LAB_HOSTS=1
#     se añade el bloque como plan B (útil con el laboratorio apagado).
#
#  Uso:
#    sudo bash lab/m6/net.sh            # aplica red + DNS partido
#    bash lab/m6/net.sh --check         # solo informa, sin cambios
#
#  Variables: LAB_IF, LAB_IP, LAB_PREFIX, LAB_GW, LAB_DNS, LAB_CON, LAB_HOSTS,
#             LAB_DNSMASQ_CONF, LAB_DNS_UNIT.
set -euo pipefail

LAB_IF="${LAB_IF:-}"
LAB_IP="${LAB_IP:-10.10.10.20}"
LAB_PREFIX="${LAB_PREFIX:-24}"
LAB_GW="${LAB_GW:-10.10.10.1}"
LAB_DNS="${LAB_DNS:-10.10.10.14}"
LAB_CON="${LAB_CON:-lab-m6}"
LAB_HOSTS="${LAB_HOSTS:-0}"
LAB_DOMAIN="${LAB_DOMAIN:-uni.lab}"
LAB_DNSMASQ_CONF="${LAB_DNSMASQ_CONF:-/etc/dnsmasq.d/lab-split.conf}"
LAB_DNS_UNIT="${LAB_DNS_UNIT:-/etc/systemd/system/lab-dns.service}"

CHECK=0
[[ "${1:-}" == "--check" ]] && CHECK=1

TMPD=""
cleanup() { if [[ -n "${TMPD:-}" && -d "$TMPD" ]]; then rm -rf -- "$TMPD"; fi; return 0; }
trap cleanup EXIT

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%SZ)" "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

[[ $EUID -eq 0 ]] || [[ $CHECK -eq 1 ]] || die "ejecuta con sudo"

# ---------------------------------------------------------------- detección
def_if=$(ip route show default 2>/dev/null | awk '/^default/{print $5; exit}')
def_if="${def_if:-}"
nat_gw=$(ip route show default 2>/dev/null | awk '/^default/{print $3; exit}')
nat_gw="${nat_gw:-}"

if [[ -z "$LAB_IF" ]]; then
  # Primera ethernet distinta de la de salida a Internet y sin IPv4 asignada.
  for d in /sys/class/net/*; do
    n=$(basename "$d")
    [[ "$n" == "lo" || "$n" == "$def_if" ]] && continue
    [[ -e "$d/device" ]] || continue                      # descarta bridges/túneles
    ip -4 -brief addr show dev "$n" | grep -q ' [0-9]' && continue
    LAB_IF="$n"; break
  done
  LAB_IF="${LAB_IF:-eth1}"
fi

[[ -e "/sys/class/net/$LAB_IF" ]] || die "no existe la interfaz $LAB_IF"
[[ "$LAB_IF" != "$def_if" ]] || die "$LAB_IF es la NIC con la ruta por defecto (Internet); elige otra con LAB_IF="
[[ "$LAB_IP" != "$LAB_GW" ]] || die "$LAB_IP es el router R0; M6 va en 10.10.10.20"

log "NAT/internet : ${def_if:-ninguna} -> gw ${nat_gw:-?} ($(ip route show default 2>/dev/null | head -1))"
log "laboratorio  : $LAB_IF -> $LAB_IP/$LAB_PREFIX (gw $LAB_GW, sin ruta por defecto)"
log "DNS          : *.${LAB_DOMAIN} -> $LAB_DNS (M4) | resto -> ${nat_gw:-NAT}"

# ---------------------------------------------------------------- comprobación
if [[ $CHECK -eq 1 ]]; then
  ip -4 -brief addr show dev "$LAB_IF"
  ip route | grep -E "^(default|10\.10\.10\.)" || true
  printf -- '--- resolver\n'; cat /etc/resolv.conf
  printf -- '--- lab-dns\n'; systemctl is-enabled lab-dns.service 2>&1 || true
  systemctl is-active lab-dns.service 2>&1 || true
  command -v ss >/dev/null && { ss -lunp 2>/dev/null | grep ':53' || echo "53/udp sin escucha"; }
  if command -v dig >/dev/null; then
    printf -- '--- dig (resolvedor del sistema)\n'
    dig +short +time=1 +tries=1 "wp.$LAB_DOMAIN" 2>&1 | sed 's/^/    /' || true
    printf -- '--- dig (directo a M4)\n'
    dig +short +time=1 +tries=1 "wp.$LAB_DOMAIN" "@$LAB_DNS" 2>&1 | sed 's/^/    /' || true
  fi
  exit 0
fi

# Aviso de IP duplicada antes de asignarla (no bloquea, solo informa).
if ping -c1 -W1 -I "$LAB_IF" "$LAB_IP" >/dev/null 2>&1; then
  log "AVISO: $LAB_IP ya responde en el segmento; revisa que no esté en uso"
fi

# ---------------------------------------------------------------- NIC del lab
if command -v nmcli >/dev/null; then
  if nmcli -t -f NAME con show | grep -qxF "$LAB_CON"; then
    log "NetworkManager: reutiliza la conexión $LAB_CON"
  else
    ant=$(nmcli -t -f NAME,DEVICE con show | awk -F: -v d="$LAB_IF" '$2==d{print $1; exit}')
    if [[ -n "$ant" ]]; then
      log "NetworkManager: renombra '$ant' -> $LAB_CON"
      nmcli con modify "$ant" connection.id "$LAB_CON"
    else
      log "NetworkManager: crea $LAB_CON sobre $LAB_IF"
      nmcli con add type ethernet con-name "$LAB_CON" ifname "$LAB_IF"
    fi
  fi

  nmcli con modify "$LAB_CON" \
    connection.autoconnect yes \
    connection.autoconnect-priority 10 \
    ipv4.method manual \
    ipv4.addresses "$LAB_IP/$LAB_PREFIX" \
    ipv4.gateway "" \
    ipv4.never-default yes \
    ipv4.route-metric 200 \
    ipv4.dns "127.0.0.1" \
    ipv4.dns-search "$LAB_DOMAIN" \
    ipv4.dns-priority -10 \
    ipv6.method ignore

  nmcli con up "$LAB_CON" >/dev/null
  log "NetworkManager: $LAB_CON activa"
else
  # Fallback para Kali sin NetworkManager (ifupdown).
  command -v ifup >/dev/null || die "ni nmcli ni ifupdown disponibles"
  cat > "/etc/network/interfaces.d/lab-m6" <<EOF
# lab/m6/net.sh — red del laboratorio (sin gateway: Internet va por el NAT)
auto $LAB_IF
iface $LAB_IF inet static
    address $LAB_IP/$LAB_PREFIX
    dns-nameservers 127.0.0.1
    dns-search $LAB_DOMAIN
EOF
  ifup "$LAB_IF"
  log "ifupdown: /etc/network/interfaces.d/lab-m6"
fi

# ---------------------------------------------------------------- DNS partido
[[ -n "$nat_gw" ]] || die "sin ruta por defecto: no hay DNS upstream para Internet"
command -v dnsmasq >/dev/null || die "falta dnsmasq (paquete dnsmasq-base); instálalo desde el medio local"
[[ $EUID -eq 0 ]] || die "el DNS necesita root"

if command -v ss >/dev/null && ss -lun 2>/dev/null | grep -qE '(^|:)(53)\b'; then
  ss -lunp 2>/dev/null | grep ':53' >&2 || true
  log "AVISO: algo ya escucha en 53/udp (¿systemd-resolved? ¿otro dnsmasq?)"
fi

mkdir -p "$(dirname "$LAB_DNSMASQ_CONF")"
TMPD=$(mktemp -d)
cat > "$TMPD/lab-split.conf" <<EOF
# lab/m6/net.sh — DNS partido de M6. No editar a mano.
#   *.uni.lab  -> M4 (autoritativo, sin reenviadores)
#   resto      -> DNS del NAT (Internet)
port=53
listen-address=127.0.0.1
bind-interfaces
pid-file=/run/lab-dns.pid
no-resolv
no-poll
domain-needed
bogus-priv
cache-size=300
server=/${LAB_DOMAIN}/${LAB_DNS}
server=/10.10.10.in-addr.arpa/${LAB_DNS}
server=${nat_gw}
EOF

if ! cmp -s "$TMPD/lab-split.conf" "$LAB_DNSMASQ_CONF"; then
  install -m 0644 "$TMPD/lab-split.conf" "$LAB_DNSMASQ_CONF"
  log "dnsmasq: $LAB_DNSMASQ_CONF escrito"
  DNS_CHANGED=1
else
  log "dnsmasq: configuración sin cambios"
  DNS_CHANGED=0
fi

if ! command -v systemctl >/dev/null 2>&1; then
  die "sin systemd: arranca a mano: dnsmasq --conf-file=$LAB_DNSMASQ_CONF --keep-in-foreground"
fi

cat > "$TMPD/lab-dns.service" <<EOF
[Unit]
Description=DNS partido del laboratorio (uni.lab -> M4, resto -> NAT)
Documentation=file:///home/kali/IS-EXAMEN-UNIDAD-1/lab/m6/net.sh
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/sbin/dnsmasq --keep-in-foreground --conf-file=$LAB_DNSMASQ_CONF
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

if ! cmp -s "$TMPD/lab-dns.service" "$LAB_DNS_UNIT"; then
  install -m 0644 "$TMPD/lab-dns.service" "$LAB_DNS_UNIT"
  systemctl daemon-reload
  log "systemd: $LAB_DNS_UNIT escrito"
  DNS_CHANGED=1
fi

systemctl enable lab-dns.service >/dev/null 2>&1 || log "AVISO: no se pudo habilitar lab-dns"
if [[ "$DNS_CHANGED" -eq 1 ]]; then
  systemctl restart lab-dns.service
else
  systemctl start lab-dns.service 2>/dev/null || true
fi
systemctl is-active --quiet lab-dns.service || die "lab-dns no arrancó (journalctl -u lab-dns -n 20)"
log "dnsmasq: lab-dns.service activo en 127.0.0.1:53"

# ---------------------------------------------------------------- hosts (plan B)
if [[ "$LAB_HOSTS" == "1" ]]; then
  if ! grep -q '^# >>> lab uni.lab' /etc/hosts 2>/dev/null; then
    cp -a /etc/hosts "/etc/hosts.bak-$(date -u +%Y%m%dT%H%M%SZ)"
  fi
  tmp=$(mktemp)
  awk '/^# >>> lab uni\.lab/{skip=1} /^# <<< lab uni\.lab/{skip=0; next} !skip' /etc/hosts > "$tmp"
  cat >> "$tmp" <<EOF
# >>> lab uni.lab (lab/m6/net.sh LAB_HOSTS=1: solo plan B, tapa a M4)
10.10.10.11 app.$LAB_DOMAIN wp.$LAB_DOMAIN moodle.$LAB_DOMAIN
10.10.10.12 db.$LAB_DOMAIN
10.10.10.13 bkp.$LAB_DOMAIN
10.10.10.14 srvold.$LAB_DOMAIN
10.10.10.15 pc-est01.$LAB_DOMAIN
# <<< lab uni.lab
EOF
  install -m 0644 "$tmp" /etc/hosts
  rm -f "$tmp"
  log "/etc/hosts: bloque de plan B añadido (quita LAB_HOSTS=1 y réstalo si quieres DNS puro)"
fi

# ---------------------------------------------------------------- verificación
log "--- resultado"
ip -4 -brief addr show dev "$LAB_IF"
ip route | grep -E "^(default|10\.10\.10\.)" || true
printf -- '--- /etc/resolv.conf\n'; sed 's/^/    /' /etc/resolv.conf

if [[ -n "$def_if" ]]; then
  if ping -c1 -W2 "$nat_gw" >/dev/null 2>&1; then
    log "Internet: OK por $def_if (gw $nat_gw)"
  else
    log "Internet: sin respuesta de $nat_gw (¿NAT caído?)"
  fi
fi

if ping -c1 -W2 "$LAB_GW" >/dev/null 2>&1; then
  log "Laboratorio: R0 $LAB_GW responde"
else
  log "Laboratorio: R0 $LAB_GW no responde todavía (normal con el lab apagado)"
fi

if command -v dig >/dev/null; then
  vivo=$(dig +short +time=2 +tries=1 "$LAB_DNS" CH TXT version.bind 2>/dev/null | head -1 || true)
  if [[ -n "$vivo" ]]; then
    log "M4 DNS: responde ($vivo)"
    r=$(dig +short +time=2 +tries=1 "wp.$LAB_DOMAIN" 2>/dev/null | tail -1 || true)
    if [[ "$r" == "10.10.10.11" ]]; then
      log "DNS: wp.$LAB_DOMAIN -> $r (vía M4, resolvedor del sistema)"
    else
      log "AVISO: wp.$LAB_DOMAIN no resolvió (salida: ${r:-vacía}); revisa la zona en M4"
    fi
  else
    log "M4 DNS: 10.10.10.14 no responde (lab apagado); el resto sigue por el NAT"
  fi
  ext=$(dig +short +time=2 +tries=1 deb.debian.org 2>/dev/null | grep -E '^[0-9]+\.' | head -1 || true)
  if [[ -n "$ext" ]]; then
    log "DNS Internet: deb.debian.org -> $ext"
  else
    log "AVISO: el DNS del NAT no resolvió un nombre externo"
  fi
fi

log "listo: M6 = $LAB_IP en $LAB_IF, Internet por ${def_if:-NAT}, uni.lab por M4"
