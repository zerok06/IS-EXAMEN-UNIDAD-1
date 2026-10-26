# Specs · índice y flujo SDD

Esta carpeta contiene las **8 specs de fase + 1 spec de artefactos**. Cada spec tiene:

> Proceso: [`../docs/PROCESO-7-FASES.md`](../docs/PROCESO-7-FASES.md). Plantillas: [`../templates/`](../templates/).

```text
specs/<fase>/
├── spec.md    # requisitos EARS verificables
├── plan.md    # cómo se implementa
└── tasks.md   # tareas, dependencias y estado
```

## 1. Orden de trabajo

```text
Constitución → Spec → Clarificación → Plan → Tareas → Implementación → Validación → Loop
```

1. Leer [`../docs/constitution.md`](../docs/constitution.md).
2. Abrir `spec.md` de la fase.
3. Resolver dudas en [`CLARIFICACIONES.md`](./CLARIFICACIONES.md) antes de ejecutar.
4. Completar el **version gate** en [`../templates/version-gate.md`](../templates/version-gate.md).
5. Ejecutar `plan.md` y marcar `tasks.md` en orden.
6. Validar con `../tests/`.
7. Actualizar `tasks.md`, `../MEMORY.md` y el informe.
8. Si cambia algo, volver al paso 2.

## 2. Fases

| Spec | Fase guía | Estado |
|---|---|---|
| [`000-artefactos`](./000-artefactos/) | Pre-0 | Lista |
| [`001-fase-0-preparacion-snapshots`](./001-fase-0-preparacion-snapshots/) | 0 | Lista |
| [`002-fase-1-montaje-entorno`](./002-fase-1-montaje-entorno/) | 1 | Lista |
| [`003-fase-2-implementacion-vulnerabilidades`](./003-fase-2-implementacion-vulnerabilidades/) | 2 | Lista |
| [`004-fase-3-reconocimiento-enumeracion`](./004-fase-3-reconocimiento-enumeracion/) | 3 | Lista |
| [`005-fase-4-validacion-explotacion`](./005-fase-4-validacion-explotacion/) | 4 | Lista |
| [`006-fase-5-remediacion`](./006-fase-5-remediacion/) | 5 | Lista |
| [`007-fase-6-verificacion-retest`](./007-fase-6-verificacion-retest/) | 6 | Lista |
| [`008-fase-7-documentacion-sustentacion`](./008-fase-7-documentacion-sustentacion/) | 7 | Lista |

## 3. EARS en español

| Tipo | Plantilla | Ejemplo |
|---|---|---|
| Ubicuo | `El laboratorio DEBE <respuesta>.` | El laboratorio DEBE operar sin Internet. |
| Evento | `CUANDO <disparador>, el laboratorio DEBE <respuesta>.` | CUANDO se inicia un PoC, el laboratorio DEBE tener un snapshot previo. |
| Estado | `MIENTRAS <estado>, el laboratorio DEBE <respuesta>.` | MIENTRAS el servicio vulnerable esté activo, el laboratorio DEBE estar aislado. |
| No deseado | `SI <condición>, ENTONCES el laboratorio DEBE <respuesta>.` | SI el PoC falla, ENTONCES el laboratorio DEBE registrar la limitación. |
| Opcional | `DONDE <característica>, el laboratorio DEBE <respuesta>.` | DONDE se use VMware, el laboratorio DEBE documentar el snapshot. |
| Complejo | `MIENTRAS <estado>, CUANDO <evento>, SI <condición>, ENTONCES ...` | Usar con moderación. |

**Regla:** una frase = un comportamiento. Si una frase tiene “y” o “o” con dos comportamientos, se divide en dos requisitos.

## 4. Convenciones

- `REQ-<spec>-NN`: requisito.
- `T-<spec>-NN`: tarea.
- `EV-F0X-NNN`: captura.
- `LOG-F0X-NNN`: log.
- `CMD-F0X-NNN`: comando de bitácora.
- Estados: ⬜ pendiente · 🟡 en progreso · ✅ hecho · ⛔ bloqueado.

## 5. Plantilla

Copia [`000-plantilla/`](./000-plantilla/) para una nueva spec. No borres la plantilla.
