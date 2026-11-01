#!/usr/bin/env bash
# lab/patch/m3-nfs.sh — parchea M3: root_squash y sin cron sobre el export.
# Ejecutar como root DESPUÉS de restaurar el snapshot estado-inicial.

set -euo pipefail
LAB_ROLE=patch-m3
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../common/lib.sh"

require_root
require_ubuntu

EXPORT=/srv/storage/backups

step "1/4 quitar el cron sobre el export"
rm -f /etc/cron.d/lab-rotate
rm -f "$EXPORT/rotate.sh"
systemctl restart cron >/dev/null 2>&1 || true
ok "cron y rotate.sh eliminados"

step "2/4 root_squash en /etc/exports"
if grep -q 'no_root_squash' /etc/exports 2>/dev/null; then
  sed -i 's/no_root_squash/root_squash/g' /etc/exports
  ok "no_root_squash -> root_squash"
else
  ok "ya estaba root_squash"
fi

step "3/4 recargar exportfs"
exportfs -ra
exportfs -v | tee /tmp/exportfs-patched.txt

step "4/4 verificación"
if grep -q 'no_root_squash' /etc/exports; then
  die "queda no_root_squash en /etc/exports"
fi
[[ ! -f /etc/cron.d/lab-rotate ]] || die "el cron sigue presente"
[[ ! -f "$EXPORT/rotate.sh" ]] || die "rotate.sh sigue presente"
ok "M3 parcheado: root_squash y sin cron sobre el export"
