# Spec 007 · Fase 6 · Verificación y retest

## Metadata

| Campo | Valor |
|---|---|
| ID | `007` |
| Fase guía | 6 |
| Nombre | Verificación de la remediación (antes/después) |
| Estado | `lista` |
| Dueño | Verificador + dueños de VM |
| Dependencias | `006` |
| Specs relacionadas | `008` |
| Fuente | Guía §8 Fase 6 y §11; `docs/PLAN-MAESTRO.md` §4 |

## 1. Propósito

Demostrar, con el **mismo comando** de la Fase 4, que la vulnerabilidad ya no está presente, y dejar el contraste antes/después en el informe.

## 2. Alcance

**Incluye:** repetición de validaciones, capturas después, versión/config final, cierre o riesgo residual, coherencia documental.

**No incluye:** nuevos exploits, cambios de arquitectura, nuevas vulnerabilidades.

## 3. Actores y precondiciones

- Actores: verificador, dueños, coordinador.
- Precondiciones: Fase 5 cerrada; `estado-parcheado`; evidencia del antes.

## 3.1 Version gate de retest

| ID | Fix | Comando | Esperado |
|---|---|---|---|
| W1 | 7.0.2 | `wp core version` + PoC | 7.0.2; PoC falla |
| W2 | 8.4.27 | `curl -sI` + PoC | `PHP/8.4.27`; PoC falla |
| W3 | 2.4.51+ | traversal | 403/404 |
| D1 | 6.2.7+ | `redis-cli PING` | NOAUTH |
| B1 | 4.5.10 | `smb-vuln*` | limpio |
| B2 | 3.0.5 | `nc 6200` | cerrado |
| S2 | Spooler off | `Get-Service Spooler` | Stopped |
| C4 | password | `vnc-info` | VNC auth |

## 4. Requisitos EARS

- **REQ-007-01 (Ubicuo).** El retest DEBE usar el mismo comando, la misma máquina y el mismo procedimiento que la Fase 4.
  - Verificación: comparación de comandos.
- **REQ-007-02 (Ubicuo).** Cada hallazgo DEBE tener evidencia del antes y del después.
  - Verificación: `EV-<ID>-antes` y `EV-<ID>-despues`.
- **REQ-007-03 (Ubicuo).** Cada hallazgo DEBE registrar la versión/configuración final.
  - Verificación: tabla de retest.
- **REQ-007-04 (No deseado).** SI un hallazgo no se puede cerrar, ENTONCES el laboratorio DEBE documentar el riesgo residual y la mitigación compensatoria.
  - Verificación: ficha del hallazgo.
- **REQ-007-05 (Ubicuo).** El retest DEBE reflejarse de forma coherente en `06-remediacion.md` y `07-retest.md`.
  - Verificación: revisión cruzada.
- **REQ-007-06 (Evento).** CUANDO se complete el retest, el laboratorio DEBE confirmar `estado-parcheado`.
  - Verificación: snapshot y checklist.
- **REQ-007-07 (No deseado).** SI el mismo comando sigue funcionando, ENTONCES el laboratorio DEBE corregir la remediación y repetir.
  - Verificación: registro de reintento.
- **REQ-007-08 (Ubicuo).** El retest DEBE dejar el laboratorio listo para la demo: vulnerable y parcheado restaurables.
  - Verificación: `Snapshot Manager` + ensayo.

## 5. Criterios de aceptación

- [ ] Cada hallazgo con antes/después.
- [ ] Versión/config final registrada.
- [ ] Hallazgos cerrados o con riesgo residual.
- [ ] `06` y `07` coherentes.
- [ ] `estado-parcheado` confirmado.
- [ ] Demo ensayada.
- [ ] Version gate: versión corregida confirmada y PoC fallando.

## 6. Trazabilidad

| REQ | Evidencia | Tarea |
|---|---|---|
| REQ-007-01/02 | `EV-007-*` | T-007-01–05 |
| REQ-007-03 | tabla de retest | T-007-06 |
| REQ-007-04 | riesgo residual | T-007-07 |
| REQ-007-05 | `06`/`07` | T-007-08 |
| REQ-007-06/08 | snapshots + ensayo | T-007-09 |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| El comando cambió | Repetir con el original |
| La versión no cambió | Declarar mitigación, no parche |
| El servicio no arranca | Restaurar `estado-inicial-vulnerable` y repetir |
| Contradicción documental | Una sola fuente de verdad |

## 8. Fuera de alcance

- Nuevos exploits.
- Cambios de arquitectura.
- Reemplazo de la Fase 4.
