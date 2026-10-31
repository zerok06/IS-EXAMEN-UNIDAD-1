# Tareas 001 · Preparación y snapshots

| ID | Tarea | Depende | Dueño | Est. | Evidencia | Estado |
|---|---|---|---|---|---|---|
| T-001-01 | Verificar IP/gateway/DNS de M1–M6 | — | Cada dueño | 30 min | `EV-001-01` | ⬜ |
| T-001-02 | Verificar aislamiento (`ping 8.8.8.8` falla) | T-001-01 | M6 | 10 min | `EV-001-02` | ⬜ |
| T-001-03 | Verificar `ping` y DNS entre VM | T-001-01 | M6 | 15 min | `LOG-001-03` | ⬜ |
| T-001-04 | Crear `~/evidence/` y sesión `script` | — | M6 | 10 min | `LOG-001-04` | ⬜ |
| T-001-05 | Tomar `00-base` en M1–M5 | T-001-01 | Cada dueño | 40 min | `EV-001-05` | ⬜ |
| T-001-06 | Tomar `01-rol-listo` en M1–M5 | Fase 1 | Cada dueño | 40 min | `EV-001-06` | ⬜ |
| T-001-07 | Tomar `estado-inicial-vulnerable` | Fase 2 | Cada dueño | 40 min | `EV-001-07` | ⬜ |
| T-001-08 | Clonar full M1–M5 | T-001-07 | Cada dueño | 60 min | `EV-001-08` | ⬜ |
| T-001-09 | Completar registro de snapshots | T-001-05–08 | Coordinador | 30 min | `c-snapshots.md` | ⬜ |
| T-001-10 | Completar matriz de credenciales | — | Coordinador | 15 min | `MEMORY.md` §3 | ⬜ |
| T-001-11 | Declarar VMware vs VirtualBox | — | Coordinador | 10 min | `03-arquitectura` | ⬜ |
| T-001-12 | Ejecutar `tests/check-lab.ps1` | T-001-01 | M6 | 10 min | `LOG-001-12` | ⬜ |

## Checklist de cierre

- [ ] T-001-01 a T-001-12 en ✅.
- [ ] Snapshots y clones visibles.
- [ ] Registro completo.
- [ ] `MEMORY.md` actualizado.
- [ ] Coordinador valida la fase.
