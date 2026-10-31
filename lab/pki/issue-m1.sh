#!/usr/bin/env bash
# ============================================================================
#  lab/pki/issue-m1.sh — certificado TLS de la aplicación (M1)
# ----------------------------------------------------------------------------
#  Emite con la CA del laboratorio un certificado de servidor para:
#    CN  = app.uni.lab
#    SAN = DNS:app.uni.lab, DNS:wp.uni.lab, DNS:moodle.uni.lab, IP:10.10.10.11
#    clave RSA 2048, validez 825 días
#
#  Salida en <out>/:
#    ca.crt        CA raíz (para instalar en M5/M6)
#    ca.key        clave de la CA (solo laboratorio)
#    app.key       clave privada del servidor (0600)
#    app.crt       certificado del servidor
#    app-chain.crt app.crt + ca.crt (cadena para nginx)
#
#  Uso:
#    bash lab/pki/issue-m1.sh
#    bash lab/pki/issue-m1.sh --force
#
#  Idempotente: si el certificado existente valida contra la CA, cubre el SAN
#  completo, la clave es la pareja correcta y no caduca en 30 días, no se toca.
# ============================================================================

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_LOG="${LAB_LOG:-${TMPDIR:-/tmp}/lab-pki.log}"
export LAB_LOG

# shellcheck source=../common/lib.sh
. "$HERE/../common/lib.sh"

LAB_ROLE=pki

OUT="${PKI_OUT:-$HERE/out}"
CA_KEY="$OUT/ca.key"
CA_CRT="$OUT/ca.crt"
APP_KEY="$OUT/app.key"
APP_CRT="$OUT/app.crt"
APP_CHAIN="$OUT/app-chain.crt"

CN="${APP_CN:-app.uni.lab}"
CA_ORG="${CA_ORG:-uni.lab}"
APP_DAYS="${APP_DAYS:-825}"
APP_BITS="${APP_BITS:-2048}"
SAN="DNS:app.uni.lab,DNS:wp.uni.lab,DNS:moodle.uni.lab,IP:10.10.10.11"
FORCE=0

usage() {
  cat <<'EOF'
Uso: bash lab/pki/issue-m1.sh [opciones]

  --out DIR    directorio de salida (def. lab/pki/out)
  --days N     vigencia en días (def. 825)
  --force      reemitir aunque el certificado actual sea válido
  -h, --help   esta ayuda
EOF
}

while (($#)); do
  case "$1" in
    --out)   OUT="${2:?--out necesita una ruta}"; shift 2 ;;
    --out=*) OUT="${1#*=}"; shift ;;
    --days)  APP_DAYS="${2:?--days necesita un número}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "opción desconocida: $1 (ver --help)" ;;
  esac
done

CA_KEY="$OUT/ca.key"
CA_CRT="$OUT/ca.crt"
APP_KEY="$OUT/app.key"
APP_CRT="$OUT/app.crt"
APP_CHAIN="$OUT/app-chain.crt"

need_cmd openssl

# --------------------------------------------------------------- utilidades
leaf_ok() {
  [[ -s "$APP_KEY" && -s "$APP_CRT" && -s "$APP_CHAIN" ]] || return 1

  openssl verify -CAfile "$CA_CRT" "$APP_CRT" >/dev/null 2>&1 || return 1
  openssl x509 -in "$APP_CRT" -noout -checkend $((30 * 86400)) >/dev/null 2>&1 || return 1

  # clave y certificado deben ser pareja
  local pub_crt pub_key
  pub_crt=$(openssl x509 -in "$APP_CRT" -noout -pubkey 2>/dev/null | openssl dgst -sha256) || return 1
  pub_key=$(openssl pkey -in "$APP_KEY" -pubout 2>/dev/null | openssl dgst -sha256) || return 1
  [[ -n "$pub_crt" && "$pub_crt" == "$pub_key" ]] || return 1

  # CN correcto
  openssl x509 -in "$APP_CRT" -noout -subject 2>/dev/null \
    | grep -Eq 'CN[[:space:]]*=[[:space:]]*app\.uni\.lab' || return 1

  # SAN completo (se normaliza "IP Address:" a "IP:" y se quitan espacios)
  local san_norm
  san_norm=$(openssl x509 -in "$APP_CRT" -noout -ext subjectAltName 2>/dev/null \
             | sed -e 's/IP Address:/IP:/g' -e 's/[[:space:]]//g')
  local want
  for want in DNS:app.uni.lab DNS:wp.uni.lab DNS:moodle.uni.lab IP:10.10.10.11; do
    grep -q -- "$want" <<<"$san_norm" || return 1
  done

  # la cadena debe llevar exactamente hoja + CA
  [[ "$(grep -c 'BEGIN CERTIFICATE' "$APP_CHAIN")" -eq 2 ]] || return 1

  return 0
}

print_leaf() {
  openssl x509 -in "$APP_CRT" -noout -subject -issuer -dates
  openssl x509 -in "$APP_CRT" -noout -ext subjectAltName 2>/dev/null | sed 's/^/  /'
  openssl x509 -in "$APP_CRT" -noout -fingerprint -sha256
}

# --------------------------------------------------------------- principal
lab_banner

step "CA del laboratorio"
mkdir -p "$OUT"
if [[ ! -s "$CA_CRT" || ! -s "$CA_KEY" ]]; then
  log "CA ausente; generándola con gen-ca.sh"
  bash "$HERE/gen-ca.sh" --out "$OUT"
else
  ok "CA presente: $CA_CRT"
fi

# Si la CA no valida, no se emite nada: se avisa en vez de firmar con basura.
openssl x509 -in "$CA_CRT" -noout -text 2>/dev/null | grep -q 'CA:TRUE' \
  || die "$CA_CRT no es una CA válida (regenerar con gen-ca.sh --force)"

step "certificado de servidor · $CN"
if (( FORCE == 0 )) && leaf_ok; then
  ok "certificado existente reutilizado: $APP_CRT"
  print_leaf
  exit 0
fi

if [[ -e "$APP_KEY" || -e "$APP_CRT" ]]; then
  warn "reemitiendo certificado de $CN"
fi

# --------------------------------------------------------------- emisión
umask 077

openssl genrsa -out "$APP_KEY" "$APP_BITS" >/dev/null 2>&1 \
  || die "no se pudo generar $APP_KEY"
chmod 600 "$APP_KEY"

CSR="$(mktemp "${TMPDIR:-/tmp}/app.csr.XXXXXX")"
EXT="$(mktemp "${TMPDIR:-/tmp}/app.ext.XXXXXX")"
trap 'rm -f "$CSR" "$EXT"' EXIT

openssl req -new -key "$APP_KEY" -sha256 \
  -subj "/C=EC/O=$CA_ORG/OU=Laboratorio/CN=$CN" \
  -out "$CSR" 2>/dev/null \
  || die "no se pudo crear el CSR"

cat > "$EXT" <<EOF
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = $SAN
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF

openssl x509 -req -in "$CSR" -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial \
  -days "$APP_DAYS" -sha256 -extfile "$EXT" -out "$APP_CRT" 2>/dev/null \
  || die "no se pudo firmar el certificado"

chmod 644 "$APP_CRT"
cat "$APP_CRT" "$CA_CRT" > "$APP_CHAIN"
chmod 644 "$APP_CHAIN"

umask 022

# --------------------------------------------------------------- verificación
leaf_ok || die "el certificado emitido no pasó la validación"
openssl verify -CAfile "$CA_CRT" "$APP_CRT"

ok "certificado emitido: $APP_CRT"
print_leaf
ok "cadena lista para nginx: $APP_CHAIN"
printf '  key:  %s (0600)\n' "$APP_KEY" >&2
printf '  CA:   %s\n' "$CA_CRT" >&2
printf '\nInstalación en M1 y CA en M5/M6: ver %s/README.md\n' "$HERE" >&2
