# Anexo C · Registro de snapshots

**Regla:** antes de cada PoC se toma un snapshot `previo-a-<ID>`; al terminar la mitigación se toma `estado-parcheado`. Sin snapshot no se ejecuta la prueba.

---

## C.1 Snapshots requeridos

| VM | Snapshot | Estado | Fecha | Responsable | Observación |
|---|---|---|---|---|---|
| M1 | `estado-inicial-vulnerable` | ✅ existe (mapear nombre) | — | Estudiante 1 | Debe incluir W1–W7 y SSH con `Admin13.-` |
| M1 | `previo-a-W1` / `previo-a-W4` | ✅ existe (mapear nombre) | — | Estudiante 1 | Antes de cada PoC |
| M2 | `estado-inicial-vulnerable` | ✅ existe (mapear nombre) | — | Estudiante 2 | Redis sin auth, claves DB |
| M3 | `estado-inicial-vulnerable` | ✅ existe (mapear nombre) | — | Estudiante 3 | FTP anónimo, NFS `no_root_squash` |
| M4 | `estado-inicial-vulnerable` | ✅ existe (mapear nombre) | — | Estudiante 4 | SMBv1, Spooler, DNS |
| M5 | `estado-inicial-vulnerable` | ✅ existe (mapear nombre) | — | Estudiante 5 | SMBv1, RDP, VNC sin clave |
| M1–M5 | `estado-parcheado` | ⬜ pendiente | — | Cada dueño | Después de la fase 6 |

> El snapshot se toma desde VMware (menú **VM → Snapshot → Take Snapshot**), no desde dentro de la VM. El auditor no puede tomarlo por SSH.

---

## C.2 Estados observados en la sesión

| Hora UTC | M1 | M2 | M3 | M4 | M5 | Nota |
|---|---|---|---|---|---|---|
| 16:24 | ✅ | ✅ | ✅ | ✅ (445 abierto) | ✅ (3389/5900 abiertos) | Evidencia de puertos |
| 16:44 | ✅ | ✅ | ✅ | ❌ apagada | ❌ apagada | Se detuvo la explotación de M4/M5 |
| 16:50 | ✅ | ✅ | ✅ | ❌ | ❌ | Se continuó con M1–M3 |
| 17:08 | ✅ | ✅ | ✅ | ✅ (445/445) | ✅ (5900/3389) | M5 validada; M4 auth falló |
| 17:14 | ❌ | ❌ | ❌ | ❌ | ✅ (5900) | M1/M2/M3/M4 sin respuesta; M5 sigue arriba |
| 17:21 | ✅ (SSH) | ❌ | ✅ | ✅ (445/5985) | ✅ (5900) | S4/S5 de M4; M1 marcador; M5 SMB por túnel |
| 17:25 | ✅ (SSH) | ❌ | ✅ | ❌ (445/5985 filtered) | ✅ (5900) | M4 volvió a caer |
| 17:35 | ✅ (SSH) | ❌ | ✅ | ✅ (445/5985) | ✅ (5900) | M4 arriba; `Admin_123!` falla |
| 17:45 | ✅ (SSH) | ❌ | ✅ | ✅ (445/5985) | ✅ (5900) | **S3 OK**: `Administrador`/`password_2026` (Pwn3d!); S2 check vulnerable; run sin sesión |
| 17:55 | ✅ (SSH) | ❌ | ✅ | ❌ (sin ruta) | ✅ (5900) | M4 volvió a caer tras PrintNightmare |

**Acción requerida:** M4 está inestable. S3/S4/S5 validados y S2 confirmado por `check`; queda reintentar el privesc a SYSTEM cuando M4 esté estable. M2 sigue caída; M5 permanece accesible.

---

## C.3 Nomenclatura

```text
estado-inicial-vulnerable
previo-a-W1
previo-a-W2
previo-a-W3
previo-a-W4
previo-a-D1
previo-a-B2
previo-a-S1
previo-a-S2
previo-a-C4
estado-parcheado
```

Cada entrada del registro debe incluir: máquina, nombre, fecha UTC, propósito y responsable.

### Mapeo de nombres reales (completar con lo que se ve en VMware)

| Nombre lógico | Nombre real en VMware | Máquina | Fecha UTC | Responsable |
|---|---|---|---|---|
| `estado-inicial-vulnerable` | ______________________ | M1 | — | Estudiante 1 |
| `previo-a-W2` | ______________________ | M1 | — | Estudiante 1 |
| `estado-inicial-vulnerable` | ______________________ | M2 | — | Estudiante 2 |
| `estado-inicial-vulnerable` | ______________________ | M3 | — | Estudiante 3 |
| `estado-inicial-vulnerable` | ______________________ | M4 | — | Estudiante 4 |
| `previo-a-S1` | ______________________ | M4 | — | Estudiante 4 |
| `estado-inicial-vulnerable` | ______________________ | M5 | — | Estudiante 5 |
| `estado-parcheado` | ______________________ | M1–M5 | — | Cada dueño |

> **Cómo leerlo:** si el nombre real es distinto (`snapshot1`, `base`, `antes-W2`, etc.), se anota en la segunda columna y se usa ese nombre al restaurar. El nombre lógico es el que aparece en este informe.

### Snapshots mínimos para el movimiento lateral

| Salto | Snapshot que protege | Por qué |
|---|---|---|
| M6 → M1 | `estado-inicial-vulnerable` (M1) | Si W1/W2/W4 rompe Apache/PHP |
| M1 → M2 | `estado-inicial-vulnerable` (M2) | Si Redis/DB se corrompe |
| M1 → M3 | `estado-inicial-vulnerable` (M3) | Si FTP/NFS deja el storage inconsistente |
| M1 → M4 | `estado-inicial-vulnerable` (M4) + `previo-a-S1` | EternalBlue/PrintNightmare pueden crashear |
| M4 → M5 | `estado-inicial-vulnerable` (M5) | Si VNC/clave deja la estación inaccesible |
| Cierre | `estado-parcheado` (M1–M5) | Demo antes/después |
