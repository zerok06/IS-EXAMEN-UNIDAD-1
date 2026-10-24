# Anexo A · Bitácora de comandos

**Qué es:** el registro de cada comando ejecutado, con su explicación, salida real, evidencia y lectura.
**Regla:** no se inventan salidas. Si un comando no se ejecutó, queda `⬜ pendiente` y se dice por qué.

## Formato

| Campo | Contenido |
|---|---|
| `CMD-F0X-NNN` | Identificador único |
| Comando | Línea exacta, simple y reproducible |
| Explicación | Qué hace y por qué se usa |
| Salida real | Texto copiado del log (resumen si es largo) |
| Evidencia | `EV-...png` + `LOG-...log` + hash |
| Lectura | Qué demuestra y a qué máquina permite llegar |

## Índice

| Archivo | Fase | Comandos |
|---|---|---|
| [`01-recon.md`](./01-recon.md) | 1 · Reconocimiento | F01-001 … F01-006 |
| [`02-escaneo.md`](./02-escaneo.md) | 2 · Escaneo y enumeración | F02-001 … F02-004 |
| [`03-acceso-m1.md`](./03-acceso-m1.md) | 3 · Acceso inicial | F03-001 … F03-002, F04-000 |
| [`04-lateral.md`](./04-lateral.md) | 4 · Movimiento lateral | F04-001 … F04-006 |
| `05-impacto.md` | 5 · Impacto | ⬜ pendiente (F05-001…F05-003b en fases) |
| [`06-mitigacion.md`](./06-mitigacion.md) | 6 · Mitigación (M2) | ✅ |
| [`07-retest.md`](./07-retest.md) | 7 · Retest (todas) | ✅ |

## Convención de comandos

- **Demo:** una línea, pocos flags, salida clara; es el que se teclea en vivo.
- **Evidencia:** el mismo comando con `-oA`, `tee` o captura; no se usa en la exposición.
- Los comandos completos y sus logs están en `evidencias/logs/`.
