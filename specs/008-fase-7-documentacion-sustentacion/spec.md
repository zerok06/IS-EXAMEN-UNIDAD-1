# Spec 008 · Fase 7 · Informe final y sustentación

## Metadata

| Campo | Valor |
|---|---|
| ID | `008` |
| Fase guía | 7 |
| Nombre | Informe final, plantillas, diapositivas y réplica en vivo |
| Estado | `lista` |
| Dueño | Coordinador + todos |
| Dependencias | `007` |
| Specs relacionadas | — |
| Fuente | Guía §11, §12 y §13; `docs/PLAN-MAESTRO.md` §4 |

## 1. Propósito

Consolidar el **informe técnico**, las **diapositivas** y la **réplica en vivo** con evidencia reproducible y sin contradicciones.

## 2. Alcance

**Incluye:** informe de 9 secciones, deck, guion de demo, registro de snapshots, diagrama, checklist de entregables.

**No incluye:** nuevos exploits, cambios de laboratorio, nuevas vulnerabilidades.

## 3. Actores y precondiciones

- Actores: coordinador, todos los integrantes, docente.
- Precondiciones: Fases 0–6 cerradas; `estado-inicial-vulnerable` y `estado-parcheado`.

## 4. Requisitos EARS

### Informe

- **REQ-008-01 (Ubicuo).** El informe DEBE seguir las **9 secciones** de la guía §11.
  - Verificación: índice del informe.
- **REQ-008-02 (Ubicuo).** El informe DEBE usar las **fases 0–7** de la guía, no el ciclo de ataque interno.
  - Verificación: `03-metodologia.md` renumerado.
- **REQ-008-03 (Ubicuo).** Cada hallazgo DEBE incluir descripción, impacto, evidencia, NVD/CVE.org, CVSS, remediación y retest.
  - Verificación: ficha por hallazgo.
- **REQ-008-04 (No deseado).** SI el informe incluye comandos de exploit, ENTONCES el laboratorio DEBE moverlos al anexo interno.
  - Verificación: revisión del informe.
- **REQ-008-05 (Ubicuo).** El informe DEBE declarar limitaciones y CVE no aplicables con evidencia.
  - Verificación: sección de limitaciones.
- **REQ-008-06 (Ubicuo).** El informe DEBE incluir el registro de snapshots y el diagrama de red.
  - Verificación: anexos.

### Diapositivas y demo

- **REQ-008-07 (Evento).** CUANDO se prepare una réplica en vivo, el equipo DEBE mostrar una **diapositiva previa** con qué se mostrará, en qué máquina y qué se espera.
  - Verificación: deck + ensayo.
- **REQ-008-08 (Evento).** CUANDO se inicie la demo, el equipo DEBE restaurar `estado-inicial-vulnerable` delante del público.
  - Verificación: `Snapshot Manager`.
- **REQ-008-09 (Evento).** CUANDO se muestre el después, el equipo DEBE restaurar `estado-parcheado` y repetir el mismo comando.
  - Verificación: contraste.
- **REQ-008-10 (Ubicuo).** Cada integrante DEBE explicar su máquina y su remediación.
  - Verificación: reparto de la exposición.
- **REQ-008-11 (Ubicuo).** La demo DEBE tener fallbacks si una VM no responde.
  - Verificación: tabla de planes B.
- **REQ-008-12 (No deseado).** SI una demo falla, ENTONCES el equipo DEBE mostrar la evidencia grabada y explicar la limitación.
  - Verificación: carpeta de evidencia.

### Entregables

- **REQ-008-13 (Ubicuo).** El equipo DEBE entregar informe, diapositivas, registro de snapshots y diagrama.
  - Verificación: checklist.
- **REQ-008-14 (Ubicuo).** El equipo DEBE declarar el uso de VMware en lugar de VirtualBox.
  - Verificación: nota en arquitectura.
- **REQ-008-15 (Ubicuo).** El equipo DEBE respetar la ética y el aislamiento en la demo.
  - Verificación: guion + capturas.

### Plantillas y versiones

- **REQ-008-16 (Ubicuo).** El informe DEBE construirse con [`templates/informe.md`](../../templates/informe.md) y cada hallazgo con [`templates/hallazgo.md`](../../templates/hallazgo.md).
  - Verificación: revisión del informe.
- **REQ-008-17 (Ubicuo).** El informe DEBE incluir la tabla de versiones **antes/después** por hallazgo, con versión vulnerable y versión corregida.
  - Verificación: sección 7 del informe.

## 5. Criterios de aceptación

- [ ] Informe con 9 secciones y fases 0–7.
- [ ] Cada hallazgo completo.
- [ ] Sin recetas en el informe oficial.
- [ ] Deck con slide previa por réplica.
- [ ] Demo ensayada con snapshots.
- [ ] Cada integrante explica su VM.
- [ ] Registro de snapshots y diagrama.
- [ ] Plantillas aplicadas.
- [ ] Tabla de versiones antes/después.
- [ ] Sin contradicciones.

## 6. Trazabilidad

| REQ | Evidencia | Tarea |
|---|---|---|
| REQ-008-01–06 | informe | T-008-01–04 |
| REQ-008-07–12 | deck + ensayo | T-008-05–08 |
| REQ-008-13–15 | checklist | T-008-09–10 |
| REQ-008-16–17 | plantillas + tabla de versiones | T-008-02/03 |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| El informe se contradice | Una sola fuente de verdad |
| La demo falla | Evidencia grabada + plan B |
| Falta una slide previa | Checklist por réplica |
| El deck es muy largo | 8–10 min; una idea por slide |

## 8. Fuera de alcance

- Nuevos exploits.
- Cambios de laboratorio.
- Nuevas vulnerabilidades.
