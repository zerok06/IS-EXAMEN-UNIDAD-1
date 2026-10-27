# Tareas 006 · Remediación

| ID | Tarea | Depende | Dueño | Est. | Evidencia | Estado |
|---|---|---|---|---|---|---|
| T-006-01 | Restaurar `estado-inicial-vulnerable` | T-005-20 | Cada dueño | 20 min | `EV-006-00` | ✅ |
| T-006-02 | WP 7.0.2 + limpiar admins/plugins | T-006-01 | M1 | 45 min | `EV-006-M1-01` | ✅ |
| T-006-03 | PHP 8.4.27 o `upload_progress=Off` | T-006-01 | M1 | 60 min | `EV-006-M1-02` | ✅ |
| T-006-04 | Apache 2.4.51+ y W4/SSH/W5–W7 | T-006-01 | M1 | 60 min | `EV-006-M1-03` | ✅ |
| T-006-05 | Redis 6.2.7+ + requirepass | T-006-01 | M2 | 30 min | `EV-006-M2-01` | ✅ |
| T-006-06 | Rotar claves DB + actualizar M1 | T-006-05 | M2/M1 | 30 min | `EV-006-M2-02` | ✅ |
| T-006-07 | UFW + SNMPv3/ACL | T-006-05 | M2 | 30 min | `EV-006-M2-03` | ✅ |
| T-006-08 | Samba 4.5.10+ | T-006-01 | M3 | 30 min | `EV-006-M3-01` | ✅ |
| T-006-09 | vsftpd limpio/3.x + backups cifrados | T-006-01 | M3 | 30 min | `EV-006-M3-02` | ✅ |
| T-006-10 | NFS `root_squash` + SSH | T-006-01 | M3 | 20 min | `EV-006-M3-03` | ✅ |
| T-006-11 | MS17-010 + SMB1 off | T-006-01 | M4 | 45 min | `EV-006-M4-01` | ✅ |
| T-006-12 | Spooler off/parcheado | T-006-01 | M4 | 20 min | `EV-006-M4-02` | ✅ |
| T-006-13 | Claves M4 + AXFR + signing/LLMNR | T-006-01 | M4 | 40 min | `EV-006-M4-03` | ✅ |
| T-006-14 | Parches M5 + SMB1 off + clave | T-006-01 | M5 | 30 min | `EV-006-M5-01` | ✅ |
| T-006-15 | NLA + VNC | T-006-14 | M5 | 20 min | `EV-006-M5-02` | ⬜ |
| T-006-16 | Completar registro de cambios | T-006-02–15 | Coordinador | 30 min | `06-remediacion.md` | ✅ |
| T-006-17 | Tomar `estado-parcheado` | T-006-16 | Cada dueño | 40 min | `EV-006-SNAP` | ✅ |

## Checklist de cierre

- [ ] Cada hallazgo con medida.
- [ ] Versiones/configuración final.
- [ ] Registro completo.
- [ ] `estado-parcheado` tomado.
- [ ] `MEMORY.md` actualizado.
- [ ] Coordinador valida.
