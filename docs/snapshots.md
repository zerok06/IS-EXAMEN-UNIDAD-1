# Snapshots · procedimiento manual y registro

> El snapshot es el “botón de rebobinar”. Sin él no hay réplica en vivo, no hay reintentos seguros y no hay antes/después. Es un proceso **manual desde el host VMware**, no desde dentro de la VM.

## 1. Cuándo tomarlos

| Snapshot | Cuándo | Para qué | Tipo |
|---|---|---|---|
| `00-base` | SO + red + IP estática OK | Punto cero | Frío |
| `01-<rol>-listo` | Servicios instalados, sin vulns | Reinstalar rápido | Frío |
| `estado-inicial-vulnerable` | Vulns implantadas + red verificada | **Snapshot de oro** | Frío |
| `previo-a-<ID>` | Antes de **cada** PoC | Reintentar sin reconstruir | Frío si el PoC es agresivo |
| `estado-comprometido` | Tras impacto (opcional) | Mostrar el “antes” | Frío |
| `estado-parcheado` | Tras Fase 5 + retest | Mostrar el “después” | Frío |

**Regla de oro:** después de explotar, **restaura `estado-inicial-vulnerable` antes de parchear**. No parches el estado comprometido.

## 2. Procedimiento en VMware

1. Cierra lo que escriba mucho. En Linux: `sudo sync`. En Windows: apaga la VM.
2. Con la VM seleccionada: `VM → Snapshots → Take Snapshot…`
3. Nombre exacto + descripción con fecha UTC:
   `M1 + WP 7.0.1 + PHP 8.4.26 + Apache 2.4.49, 2026-10-26`
4. `Take Snapshot` y espera. No apagues el host a medias.
5. Verifica en `VM → Snapshots → Snapshot Manager` que aparece con fecha/hora.

## 3. Restaurar

1. Cierra lo que estés haciendo en la VM o apágala si el PoC la dejó colgada.
2. `VM → Snapshots → Snapshot Manager` → selecciona el snapshot → `Go To`.
3. Confirma. VMware revierte disco y memoria al momento guardado.
4. Arranca y verifica: `ping`, servicio arriba, `curl` a M1.
5. Para la demo: restaura `estado-inicial-vulnerable` delante del público; al final, `estado-parcheado`.

## 4. Clon full

- `VM → Manage → Clone → Full Clone`.
- Guárdalo en disco externo, con nombre `M1-<rol>-<fecha>`.
- El clon es respaldo independiente; el snapshot es rollback de la misma VM.
- Hazlo **antes de la Fase 2**, cuando el estado vulnerable ya está verificado.

## 5. Registro

Cada entrada debe tener:

| Campo | Ejemplo |
|---|---|
| Máquina | M1 |
| Nombre lógico | `estado-inicial-vulnerable` |
| Nombre real en VMware | `m1-vuln-2026-10-26` |
| Fecha UTC | `2026-10-26 14:30` |
| Propósito | Demo de W1 y retest |
| Responsable | Estudiante 1 |
| Observación | Incluye W1–W7 y SSH `Admin13.-` |

Actualiza [`../informe/anexos/c-snapshots.md`](../informe/anexos/c-snapshots.md) y `MEMORY.md`.

## 6. Errores típicos

- Cadena de 15 snapshots: consolida; restaura el bueno y borra los intermedios viejos.
- Snapshot a medio PoC: siempre sobre estado limpio y verificado.
- Quedarse sin disco: cada snapshot crece; deja ≥20 GB por VM.
- No mapear el nombre real: en la demo no sabrás cuál restaurar.
- Olvidar `previo-a-<ID>`: un PoC fallido sin snapshot obliga a reconstruir.
- Parchear el estado comprometido: contamina el retest.

## 7. Snapshots mínimos por máquina

| VM | `estado-inicial-vulnerable` | `previo-a-<ID>` | `estado-parcheado` |
|---|---|---|---|
| M1 | W1–W7 + SSH | W1, W2, W3, W4 | WP/PHP/Apache/SSH |
| M2 | Redis/DB/SNMP | D1, M2-config | Redis/DB/UFW/SNMP |
| M3 | FTP/NFS/Samba | B1, B2, B3/B4 | Samba/FTP/NFS |
| M4 | DNS/SMB/Spooler | S1, S2, S3 | MS17-010/Spooler/claves |
| M5 | SMB/RDP/VNC | C2, C3, C4 | Parches/NLA/VNC |

## 8. Checklist de cierre

- [ ] `00-base` en M1–M5.
- [ ] `01-rol-listo` en M1–M5.
- [ ] `estado-inicial-vulnerable` en M1–M5.
- [ ] `previo-a-<ID>` de cada PoC ejecutado.
- [ ] `estado-parcheado` en M1–M5.
- [ ] Clon full de M1–M5.
- [ ] Registro con nombre real, fecha, propósito y responsable.
- [ ] `MEMORY.md` actualizado.
