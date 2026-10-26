# Plantilla de spec · EARS

> Copia esta carpeta a `specs/NNN-nombre/` y reemplaza los campos. Borra esta nota en la copia.

## Metadata

| Campo | Valor |
|---|---|
| ID | `NNN` |
| Fase guía | `N` |
| Nombre | `...` |
| Estado | `borrador` / `lista` / `en progreso` / `validada` |
| Dueño | `...` |
| Dependencias | `...` |
| Specs relacionadas | `...` |
| Fuente | Guía §X; `docs/PLAN-MAESTRO.md` §Y |
| Version gate | Obligatorio: [`templates/version-gate.md`](../../templates/version-gate.md) |

## 1. Propósito

Una frase: qué logra esta fase y por qué importa para la guía.

## 2. Alcance

**Incluye:** ...

**No incluye:** ...

## 3. Actores y precondiciones

- Actores: M6 auditor, dueño de máquina, coordinador, docente.
- Precondiciones: snapshots, laboratorio encendido, herramientas.

## 3.1 Version gate

| Campo | Valor |
|---|---|
| Versión instalada | ... |
| Rango vulnerable | ... |
| Versión que corrige | ... |
| ¿La instalada es vulnerable? | sí / no |
| Evidencia | comando + captura |
| Estado | ⬜ / 🟡 / ✅ |

## 4. Requisitos EARS

### Funcionales

- **REQ-NNN-00 (Ubicuo).** El laboratorio DEBE completar el version gate antes de ejecutar la fase.
  - Verificación: `templates/version-gate.md` completo.

- **REQ-NNN-01 (Ubicuo).** El laboratorio DEBE ...
  - Verificación: ...
- **REQ-NNN-02 (Evento).** CUANDO ..., el laboratorio DEBE ...
  - Verificación: ...
- **REQ-NNN-03 (Estado).** MIENTRAS ..., el laboratorio DEBE ...
  - Verificación: ...
- **REQ-NNN-04 (No deseado).** SI ..., ENTONCES el laboratorio DEBE ...
  - Verificación: ...
- **REQ-NNN-05 (Opcional).** DONDE ..., el laboratorio DEBE ...
  - Verificación: ...

### Evidencia y calidad

- **REQ-NNN-06.** Cada hallazgo DEBE tener captura fechada, log y SHA256.
  - Verificación: ...
- **REQ-NNN-07.** SI un PoC falla, ENTONCES el laboratorio DEBE documentar la limitación y el fallback.
  - Verificación: ...

## 5. Criterios de aceptación

- [ ] ...
- [ ] ...

## 6. Trazabilidad

| REQ | Test/evidencia | Tarea |
|---|---|---|
| REQ-NNN-01 | `tests/...` | T-NNN-01 |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| ... | ... |

## 8. Fuera de alcance

- ...
