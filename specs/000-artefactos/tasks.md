# Tareas 000 · Artefactos y transferencia FTP

| ID | Tarea | Depende | Dueño | Est. | Evidencia | Estado |
|---|---|---|---|---|---|---|
| T-000-01 | Descargar artefactos | — | Coordinador | 30 min | `LOG-000-01` | ✅ |
| T-000-02 | Verificar SHA256 | T-000-01 | Coordinador | 10 min | `LOG-000-02` | ✅ |
| T-000-03 | Revisar manifiesto y versiones | T-000-01 | Coordinador | 15 min | `MANIFEST.md` | ✅ |
| T-000-04 | Copiar `artifacts/` a M6 | T-000-02 | Coordinador | 20 min | `LOG-000-04` | ✅ |
| T-000-05 | Levantar FTP en M6 | T-000-04 | M6 | 10 min | `LOG-000-05` | ✅ |
| T-000-06 | Descargar en M1 | T-000-05 | M1 | 10 min | `LOG-000-06` | ✅ |
| T-000-07 | Descargar en M2 | T-000-05 | M2 | 5 min | `LOG-000-07` | ✅ |
| T-000-08 | Descargar en M3 | T-000-05 | M3 | 10 min | `LOG-000-08` | ✅ |
| T-000-09 | Descargar en M5 | T-000-05 | M5 | 5 min | `LOG-000-09` | ⬜ |
| T-000-10 | Verificar versiones instaladas | T-000-06–09 | Cada dueño | 20 min | `EV-000-10` | ✅ |
| T-000-11 | Actualizar `version-gate.md` | T-000-10 | Coordinador | 15 min | `version-gate-2026-10-27` | ✅ |
| T-000-12 | Cerrar FTP | T-000-09 | M6 | 5 min | `LOG-000-12` | ⬜ |

## Checklist de cierre

- [x] 19 artefactos descargados.
- [x] SHA256 verificado.
- [x] FTP probado.
- [ ] Cada VM con sus artefactos (M5 pendiente).
- [x] Versiones instaladas registradas.
- [ ] `MEMORY.md` actualizado.
