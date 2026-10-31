# .agents · roles del laboratorio

Este proyecto se divide en cuatro roles. Cada uno lee su spec y no invade la del otro. La coordinación se hace por `MEMORY.md` y por las evidencias.

| Rol | Specs | Responsabilidad |
|---|---|---|
| [`auditor.md`](./auditor.md) | `004`, `005` | Reconocimiento, escaneo, explotación y pivote desde M6 |
| [`implementador.md`](./implementador.md) | `002`, `003`, `006` | Montaje, vulnerabilidades y remediación en M1–M5 |
| [`verificador.md`](./verificador.md) | `007` | Retest, antes/después y control de evidencias |
| [`documentador.md`](./documentador.md) | `008` | Informe, diapositivas y réplica en vivo |

## Handoff

1. El implementador deja `estado-inicial-vulnerable` y evidencia de presencia.
2. El auditor explota y deja evidencia de impacto.
3. El implementador restaura el estado inicial y aplica la remediación.
4. El verificador repite los comandos y deja el antes/después.
5. El documentador consolida y prepara la demo.

## Regla común

Ningún rol modifica la evidencia de otro. Si encuentra un error, lo registra en `MEMORY.md` y lo escala al coordinador.
