# Registro de snapshots · plantilla

> Se completa en Fase 0 y se actualiza antes de cada PoC y al final de la remediación. Procedimiento: [`../docs/snapshots.md`](../docs/snapshots.md).

## 1. Registro

| VM | Nombre lógico | Nombre real en VMware | Fecha UTC | Propósito | Responsable | Observación |
|---|---|---|---|---|---|---|
| M1 | `00-base` | {{...}} | {{...}} | Punto cero | {{...}} | SO + red |
| M1 | `01-rol-listo` | {{...}} | {{...}} | Servicios | {{...}} | Sin vulns |
| M1 | `estado-inicial-vulnerable` | {{...}} | {{...}} | Demo | {{...}} | W1–W7 |
| M1 | `previo-a-W1` | {{...}} | {{...}} | Rollback | {{...}} | Antes del PoC |
| M1 | `estado-parcheado` | {{...}} | {{...}} | Después | {{...}} | WP/PHP/Apache |
| M2 | `estado-inicial-vulnerable` | {{...}} | {{...}} | Demo | {{...}} | Redis/DB/SNMP |
| M2 | `estado-parcheado` | {{...}} | {{...}} | Después | {{...}} | Redis/auth/UFW |
| M3 | `estado-inicial-vulnerable` | {{...}} | {{...}} | Demo | {{...}} | FTP/NFS/Samba |
| M3 | `estado-parcheado` | {{...}} | {{...}} | Después | {{...}} | Samba/FTP/NFS |
| M4 | `estado-inicial-vulnerable` | {{...}} | {{...}} | Demo | {{...}} | DNS/SMB/Spooler |
| M4 | `previo-a-S2` | {{...}} | {{...}} | Rollback | {{...}} | Antes de PrintNightmare |
| M4 | `estado-parcheado` | {{...}} | {{...}} | Después | {{...}} | MS17-010/Spooler |
| M5 | `estado-inicial-vulnerable` | {{...}} | {{...}} | Demo | {{...}} | SMB/RDP/VNC |
| M5 | `estado-parcheado` | {{...}} | {{...}} | Después | {{...}} | NLA/VNC |

## 2. Clones

| VM | Nombre del clon | Ruta | Fecha UTC | Responsable |
|---|---|---|---|---|
| M1 | {{M1-full-2026-...}} | {{...}} | {{...}} | {{...}} |
| M2 | {{...}} | {{...}} | {{...}} | {{...}} |
| M3 | {{...}} | {{...}} | {{...}} | {{...}} |
| M4 | {{...}} | {{...}} | {{...}} | {{...}} |
| M5 | {{...}} | {{...}} | {{...}} | {{...}} |

## 3. Checklist

- [ ] `00-base` en M1–M5.
- [ ] `01-rol-listo` en M1–M5.
- [ ] `estado-inicial-vulnerable` en M1–M5.
- [ ] `previo-a-<ID>` de cada PoC.
- [ ] `estado-parcheado` en M1–M5.
- [ ] Clon full de M1–M5.
- [ ] Nombres reales mapeados.
- [ ] Fechas UTC.
- [ ] Responsables.
