#!/usr/bin/env bash
# ============================================================================
#  lab/pki/gen-ca.sh — CA raíz del laboratorio uni.lab
# ----------------------------------------------------------------------------
#  Crea (o reutiliza) una CA propia RSA 4096, 10 años, CN "Lab Root CA".
#  Todo se genera en local con openssl: no hay descargas de Internet.
#
#  Uso:
#    bash lab/pki/gen-ca.sh              # crea si falta; reutiliza si es válida
#    bash lab/pki/gen-ca.sh --force      # rota la CA (reemitir TODOS los certs)
#    bash lab/pki/gen-ca.sh --out /tmp/x
#
#  Salida: <out>/ca.key (0600) y <out>/ca.crt (0644)
#  Idempotente: si ca.crt y ca.key ya son una pareja válida y no caducan en
#  30 días, no se toca nada.
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
CA_CN="${CA_CN:-Lab Root CA}"
CA_ORG="${CA_ORG:-uni.lab}"
CA_DAYS="${CA_DAYS:-3650}"
CA_BITS="${CA_BITS:-4096}"
FORCE=0

usage() {
  cat <<'EOF'
Uso: bash lab/pki/gen-ca.sh [opciones]

  --out DIR    directorio de salida (def. lab/pki/out)
  --days N     vigencia en días (def. 3650 = 10 años)
  --force      regenerar aunque ya exista una CA válida
  -h, --help   esta ayuda
EOF
}

while (($#)); do
  case "$1" in
    --out)   OUT="${2:?--out necesita una ruta}"; shift 2 ;;
    --out=*) OUT="${1#*=}"; shift ;;
    --days)  CA_DAYS="${2:?--days necesita un número}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "opción desconocida: $1 (ver --help)" ;;
  esac
done

CA_KEY="$OUT/ca.key"
CA_CRT="$OUT/ca.crt"

need_cmd openssl

# --------------------------------------------------------------- utilidades
# ¿Hay una CA utilizable y coherente con lo que espera el laboratorio?
ca_ok() {
  [[ -s "$CA_KEY" && -s "$CA_CRT" ]] || return 1

  # no debe caducar en los próximos 30 días
  openssl x509 -in "$CA_CRT" -noout -checkend $((30 * 86400)) >/dev/null 2>&1 || return 1

  # clave y certificado deben ser pareja
  local pub_crt pub_key
  pub_crt=$(openssl x509 -in "$CA_CRT" -noout -pubkey 2>/dev/null | openssl dgst -sha256) || return 1
  pub_key=$(openssl pkey -in "$CA_KEY" -pubout 2>/dev/null | openssl dgst -sha256) || return 1
  [[ -n "$pub_crt" && "$pub_crt" == "$pub_key" ]] || return 1

  # debe estar marcada como CA
  openssl x509 -in "$CA_CRT" -noout -text 2>/dev/null | grep -q 'CA:TRUE' || return 1

  # 4096 bits como mínimo
  local bits
  bits=$(openssl x509 -in "$CA_CRT" -noout -text 2>/dev/null \
         | awk '/Public-Key:/{gsub(/[()]/, "", $2); print $2; exit}')
  [[ -n "$bits" && "$bits" =~ ^[0-9]+$ && "$bits" -ge 4096 ]] || return 1

  return 0
}

print_ca() {
  openssl x509 -in "$CA_CRT" -noout -subject -issuer -dates
  openssl x509 -in "$CA_CRT" -noout -fingerprint -sha256
  printf 'clave: %s (%s bits)\n' "$CA_KEY" "$(openssl pkey -in "$CA_KEY" -noout -text 2>/dev/null | awk '/Private-Key:/{print $3; exit}')"
}

# --------------------------------------------------------------- principal
lab_banner

step "CA raíz · $CA_CN"
mkdir -p "$OUT"

# OpenSSL >= 1.1.1 (Ubuntu 22.04, Kali) trae -addext; sin él, las extensiones
# de CA habría que ponerlas con un archivo de configuración.
if ! openssl req -help 2>&1 | grep -q -- '-addext'; then
  die "OpenSSL sin soporte -addext (se requiere >= 1.1.1)"
fi

if (( FORCE == 0 )) && ca_ok; then
  ok "CA existente reutilizada: $CA_CRT"
  print_ca
  exit 0
fi

if [[ -e "$CA_KEY" || -e "$CA_CRT" ]]; then
  warn "regenerando CA (los certificados emitidos con la anterior dejan de validar)"
fi

step "generando clave RSA $CA_BITS y certificado autofirmado ($CA_DAYS días)"
( umask 077; openssl genrsa -out "$CA_KEY" "$CA_BITS" ) >/dev/null 2>&1 \
  || die "no se pudo generar $CA_KEY"
chmod 600 "$CA_KEY"

openssl req -x509 -new -key "$CA_KEY" -sha256 -days "$CA_DAYS" \
  -subj "/C=EC/O=$CA_ORG/OU=Laboratorio/CN=$CA_CN" \
  -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -addext "subjectKeyIdentifier=hash" \
  -out "$CA_CRT" 2>/dev/null \
  || die "no se pudo generar $CA_CRT"
chmod 644 "$CA_CRT"

ca_ok || die "la CA recién generada no pasó la validación"

ok "CA lista: $CA_CRT"
print_ca

step "siguiente paso"
printf '  bash %s/issue-m1.sh     # certificado de app.uni.lab\n' "$HERE" >&2
printf '  (el material de pki/out se copia a M1 — ver pki/README.md)\n' >&2
