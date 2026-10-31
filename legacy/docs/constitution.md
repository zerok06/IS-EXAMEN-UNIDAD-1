# Constitución del proyecto · Laboratorio IS-1023

> Documento fundacional. Una vez por proyecto. Todo agente, spec, plan y tarea debe cumplirlo. Si una acción contradice esta constitución, no se ejecuta.

## Artículo 1 · Propósito y alcance

El proyecto tiene como fin **demostrar el ciclo completo de gestión de vulnerabilidades** en un laboratorio aislado y autorizado: identificar CVE, reproducirlos, explotarlos, remediarlos y verificar la remediación, con evidencia reproducible.

- Alcance técnico: `10.10.10.0/24`, VM M1–M6 y router R0 del grupo.
- Alcance documental: informe técnico, anexos, diapositivas y réplica en vivo.
- Fuera de alcance: sistemas de terceros, Internet, red universitaria, datos reales, acciones destructivas.

## Artículo 2 · Aislamiento y ética

1. El laboratorio debe estar **físicamente aislado** de Internet y de la red universitaria mientras los servicios vulnerables estén activos.
2. Solo se ataca a las VM del propio grupo, con autorización del docente.
3. No se ejecutan DoS, ransomware, cifrado simulado, borrado de backups ni exfiltración de datos reales.
4. Los datos del escenario son ficticios; las credenciales son de laboratorio y se rotan al cerrar.
5. Al terminar, el entorno vulnerable se apaga, se aísla o se desmonta.

## Artículo 3 · Verdad y evidencia

1. **No se inventan salidas.** Si un comando falla, se documenta el fallo, la causa y el fallback.
2. No se declara RCE sin `id`, `whoami`, archivo de prueba o captura verificable.
3. No se declara “parcheado” si solo se bloqueó una ruta, se deshabilitó una función o se cambió una configuración.
4. Cada afirmación del informe se respalda con una captura fechada, un log completo y un SHA256.
5. La evidencia se conserva; no se edita a mano ni se borra.

## Artículo 4 · Snapshots y reversibilidad

1. Antes de cada cambio o PoC se toma un snapshot `previo-a-<ID>`.
2. `estado-inicial-vulnerable` y `estado-parcheado` son obligatorios.
3. No se parchea el estado comprometido: se restaura `estado-inicial-vulnerable` y se parchea desde ahí.
4. Cada snapshot se registra con máquina, nombre lógico, nombre real en VMware, fecha UTC, propósito y responsable.
5. Un clon full por VM se guarda antes de la Fase 2 como respaldo independiente.

## Artículo 5 · Versiones y CVE

1. Cada vulnerabilidad de versión debe declarar: CVE, producto, versión instalada, rango afectado, versión corregida, CVSS y métrica.
2. La fuente primaria es **NVD** y **CVE.org**; se cita la URL y la fecha de consulta.
3. No se mezclan CVSS v3.1 y v4.0 en la misma fila.
4. Si la versión instalada es la que corrige el CVE, la vulnerabilidad **no es explotable** y se retira o se reemplaza.
5. Si el CVE es específico de un empaquetado (por ejemplo, Redis en Debian/Ubuntu), se declara y se reproduce con ese empaquetado.
6. Cada fase tiene un **version gate**: no se avanza sin comparar la versión instalada con el rango vulnerable y la versión que corrige. Si la instalada es igual o mayor que el fix, el CVE no se cuenta.

## Artículo 6 · Ciclo SDD

1. **Constitución** → **Spec** → **Clarificación** → **Plan** → **Tareas** → **Implementación** → **Validación** → **Loop**.
2. No se implementa sin una `spec.md` aprobada.
3. No se cierra una tarea sin evidencia y sin actualizar `tasks.md`.
4. Si cambia un requisito, se actualizan `spec.md`, `plan.md`, `tasks.md` y `MEMORY.md`.
5. Los requisitos se escriben en **EARS**: una frase = un comportamiento verificable.
6. El proceso se organiza en **7 fases técnicas (0–6) + Fase 7 de informe final**; cada fase usa el **version gate**.

## Artículo 7 · Roles

| Rol | Responsabilidad |
|---|---|
| Coordinador | Integración de las 6 VM, coherencia de red, consolidación del informe |
| Dueño de máquina | Configuración, vulnerabilidades, evidencia y parche de su VM |
| Auditor M6 | Reconocimiento, escaneo, explotación y pivote |
| Verificador | Retest, antes/después y control de evidencias |
| Docente | Autorización, supervisión y evaluación |

## Artículo 8 · Entregables y separación

1. **Informe oficial:** secciones 1–9 de la guía, metodología, impacto, evidencia, remediación y retest. Sin recetas paso a paso.
2. **Anexo interno:** comandos, PoCs, bitácora, reintentos y notas. No se entrega como parte del informe.
3. **Diapositivas:** incluyen una slide previa por cada réplica en vivo.
4. **Registro de snapshots:** nombres reales, fechas y propósito.
5. **Diagrama de red:** topología y plan de direccionamiento.

## Artículo 9 · Puertas de calidad

Cada fase tiene una puerta de calidad. No se avanza si no se cumple:

- **Fase 0:** red aislada, snapshots y clones, registro completo.
- **Fase 1:** servicios arriba, dependencias coherentes, versiones registradas.
- **Fase 2:** ≥3 vulnerabilidades presentes por máquina, con evidencia de versión/config.
- **Fase 3:** inventario de hosts, puertos, versiones y correlación CVE.
- **Fase 4:** al menos un acceso real por máquina; M4 con privesc desde acceso limitado; evidencia fechada.
- **Fase 5:** cada hallazgo con medida aplicada, versión/config final y registro de cambio.
- **Fase 6:** mismo comando antes/después; cada hallazgo cerrado o con riesgo residual documentado.
- **Fase 7:** informe, diapositivas, registro de snapshots y demo ensayada.

## Artículo 10 · Gestión de cambios

1. Todo cambio se registra con fecha UTC, máquina, antes, después, responsable y evidencia.
2. Los cambios de versión se hacen sobre `estado-inicial-vulnerable`, no sobre el estado comprometido.
3. Los cambios de configuración se documentan con el archivo y la línea modificada.
4. Si un cambio rompe el laboratorio, se restaura el snapshot y se documenta el incidente.

## Artículo 11 · Riesgos y limitaciones

1. Se documentan las limitaciones reales: PoC no reproducible, CVE no aplicable, versión ya corregida, firewall que desvía el modelo.
2. Una limitación documentada vale más que un éxito inventado.
3. Los riesgos residuales se registran con su mitigación compensatoria.

## Artículo 12 · Definición de terminado

Un hallazgo está terminado cuando:

- [ ] Tiene CVE/CWE, servicio, versión y CVSS verificado.
- [ ] Tiene evidencia de presencia (fingerprint o validación).
- [ ] Tiene evidencia de explotación o de no explotabilidad documentada.
- [ ] Tiene remediación aplicada (versión o configuración).
- [ ] Tiene retest con el mismo comando y evidencia antes/después.
- [ ] Está registrado en el informe y en el anexo interno.
- [ ] Su snapshot previo y el `estado-parcheado` existen.
