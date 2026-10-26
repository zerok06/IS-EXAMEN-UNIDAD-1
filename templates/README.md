# Plantillas · índice

Plantillas reutilizables para el informe, los hallazgos, la validación de versiones, los snapshots y las diapositivas.

| Plantilla | Cuándo se usa | Spec |
|---|---|---|
| [`informe.md`](./informe.md) | Fase 7, informe final | `008` |
| [`hallazgo.md`](./hallazgo.md) | Fase 4/5/6, una ficha por vulnerabilidad | `005`–`007` |
| [`version-gate.md`](./version-gate.md) | Todas las fases, control de versiones | `001`–`008` |
| [`snapshot.md`](./snapshot.md) | Fase 0 y antes de cada PoC | `001`, `005` |
| [`diapositivas.md`](./diapositivas.md) | Fase 7, deck y demo | `008` |

## Cómo usarlas

1. Copia la plantilla a `informe/` o a la carpeta de la fase.
2. Reemplaza los `{{...}}` con datos reales.
3. No borres las columnas: son la trazabilidad con la guía.
4. Si una fila no aplica, escribe “no aplica” y la razón.
5. No inventes: si falta evidencia, deja `⬜` y explica.

## Regla

Las plantillas no sustituyen la evidencia. Una plantilla llena sin captura, log y hash no vale.
