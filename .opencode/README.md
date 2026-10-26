# .opencode · capa de agente del proyecto

Este proyecto usa **SDD**. Un agente que trabaje aquí debe leer, en este orden:

1. [`../AGENTS.md`](../AGENTS.md)
2. [`../docs/constitution.md`](../docs/constitution.md)
3. La spec de la fase: [`../specs/`](../specs/)
4. [`../MEMORY.md`](../MEMORY.md)

## Reglas para el agente

- No modificar `informe/evidencias/`.
- No borrar logs ni backups.
- No ejecutar nada fuera de `10.10.10.0/24`.
- No cambiar versiones sin snapshot.
- No declarar RCE sin `id`/`whoami`/archivo.
- No mezclar comandos de exploit en el informe oficial.
- Actualizar `tasks.md` y `MEMORY.md` al cerrar una tarea.
- Si un requisito cambia, actualizar `spec.md`, `plan.md` y `tasks.md`.

## Comandos de contexto

```bash
cat AGENTS.md
cat docs/constitution.md
cat specs/005-fase-4-validacion-explotacion/spec.md
cat MEMORY.md
```

## Dónde escribir

| Tipo | Ruta |
|---|---|
| Requisitos | `specs/<fase>/spec.md` |
| Plan técnico | `specs/<fase>/plan.md` |
| Tareas | `specs/<fase>/tasks.md` |
| Decisiones | `MEMORY.md` |
| Evidencia | `informe/evidencias/` |
| Informe | `informe/` |

## Tests

```bash
./tests/check-versions.sh
./tests/check-version-gates.sh vuln
./tests/check-version-gates.sh patched
./tests/check-retest.sh
./tests/check-evidence.sh
```
