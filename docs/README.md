# Documentación · índice

Esta carpeta contiene la capa de **gobierno y contexto** del proyecto. Las specs ejecutables viven en [`../specs/`](../specs/).

| Documento | Para qué sirve |
|---|---|
| [`constitution.md`](./constitution.md) | Reglas no negociables, ética, evidencia, snapshots, calidad y definición de terminado |
| [`PROCESO-7-FASES.md`](./PROCESO-7-FASES.md) | 7 fases técnicas + Fase 7 informe, pasos SDD y version gate |
| [`PLAN-MAESTRO.md`](./PLAN-MAESTRO.md) | Contexto completo, evaluación de la guía, prioridades, plan de ataque, remediación y cronograma |
| [`evaluacion-guia.md`](./evaluacion-guia.md) | Matriz de cumplimiento de las fases 0–7 y brechas detectadas |
| [`version-matrix.md`](./version-matrix.md) | Versiones vulnerables, versiones corregidas, CVSS, NVD y comandos de verificación |
| [`snapshots.md`](./snapshots.md) | Procedimiento manual de snapshots, clones, restauración y registro |
| [`../templates/`](../templates/) | Plantillas de informe, hallazgo, version gate, snapshot y deck |
| [`../artifacts/`](../artifacts/) | Versiones exactas, PoCs, SHA256 y FTP |

## Cómo se usa

1. Leer `constitution.md`.
2. Leer `PLAN-MAESTRO.md` para el contexto.
3. Abrir la spec de la fase en `specs/`.
4. Ejecutar `plan.md` y marcar `tasks.md`.
5. Validar con `tests/`.
6. Actualizar `MEMORY.md` y el informe.

## Regla de oro

El **informe oficial** no lleva recetas. Los comandos, PoCs y reintentos viven en el **anexo interno** y en las specs. El informe lleva metodología, impacto, evidencia fechada, remediación y retest.
