# AGENTS.md · Laboratorio IS-1023

## 1. Contexto

Este repositorio contiene el **Trabajo Final de la Unidad I** de **IS-1023 Seguridad de la Información** (UNAM/EPISI, Semana 07). El entregable es un **informe técnico + sustentación con réplica en vivo**; el laboratorio de 6 VM es el medio para demostrar el ciclo completo: identificar, explotar, remediar y verificar.

- Guía del docente: [`Guía_Trabajo_Final (1).pdf`](./Gu%C3%ADa_Trabajo_Final%20%281%29.pdf)
- Red: `10.10.10.0/24`, aislada, sin Internet mientras los servicios vulnerables están activos.
- Máquinas: M1 app `.11`, M2 DB `.12`, M3 respaldos `.13`, M4 Windows `.14`, M5 cliente `.15`, M6 Kali `.20`, R0 router `.1`.
- El proyecto ya tiene arquitectura, guías, informe, evidencias y inventario; el objetivo de esta capa SDD es **convertir documentación en requisitos verificables y ejecución demostrable**.

## 2. Reglas no negociables

1. **Alcance:** solo `10.10.10.0/24`, solo VM del grupo, solo con autorización del docente.
2. **Aislamiento:** sin Internet y sin red universitaria mientras los servicios vulnerables estén activos.
3. **Ética:** nada de terceros, DoS, ransomware, cifrado simulado, borrado de backups ni datos reales.
4. **Snapshots:** antes de cada cambio o PoC; `estado-inicial-vulnerable` y `estado-parcheado` son obligatorios.
5. **Verdad:** no se inventan salidas. Si un PoC falla, se documenta la limitación y el fallback.
6. **Evidencia:** no se afirma RCE sin `id`, `whoami`, archivo de prueba o captura verificable.
7. **Separación:** el informe oficial lleva metodología, impacto y evidencia; los comandos y PoCs viven en el **anexo interno**.
8. **Remediación:** no se parchea el estado comprometido; se restaura `estado-inicial-vulnerable` y se parchea desde ahí.
9. **CVSS:** no se mezclan métricas v3.1 y v4.0; cada ficha declara la métrica.
10. **CVE:** cada hallazgo debe tener NVD/CVE.org, versión afectada, versión corregida, CVSS, evidencia y retest.
11. **Version gate:** no se avanza si la versión instalada no está comparada con el rango vulnerable y la versión que corrige. Si la instalada es igual o mayor que el fix, el CVE no se cuenta.
12. **Artefactos:** solo se instala lo que está en `artifacts/` con SHA256 verificado. No se descarga nada durante la explotación; no se guardan binarios troyanizados ni malware.
13. **Revalidación:** no se cuentan como profundidad las vulnerabilidades no reproducibles (D1, B2) ni las no aplicables (S1, C1). El estado real está en `docs/VALIDACION-VULNERABILIDADES.md`.

## 3. Orden de lectura para un agente

1. [`docs/constitution.md`](./docs/constitution.md) — reglas del proyecto.
2. [`docs/PROCESO-7-FASES.md`](./docs/PROCESO-7-FASES.md) — 7 fases + informe y version gate.
3. [`docs/VALIDACION-VULNERABILIDADES.md`](./docs/VALIDACION-VULNERABILIDADES.md) — qué vuln es real y cuál no.
4. [`specs/<fase>/spec.md`](./specs/) — requisitos EARS de la fase.
5. [`specs/<fase>/plan.md`](./specs/) — cómo se implementa.
6. [`specs/005-fase-4-validacion-explotacion/vulns/`](./specs/005-fase-4-validacion-explotacion/vulns/) — flujo por vulnerabilidad.
7. [`specs/<fase>/tasks.md`](./specs/) — tareas y estado.
8. [`MEMORY.md`](./MEMORY.md) — estado, decisiones, credenciales y limitaciones.
9. [`docs/PLAN-MAESTRO.md`](./docs/PLAN-MAESTRO.md) — contexto completo y plan de ataque.
10. [`templates/`](./templates/) — plantillas de informe, hallazgo y version gate.

## 4. Flujo SDD

```text
Constitución → Spec → Clarificación → Plan → Tareas → Implementación → Validación → Loop
```

Se aplica a **7 fases técnicas (0–6) + Fase 7 de informe final**. Cada fase tiene un **version gate** obligatorio.

- No se implementa sin `spec.md` aprobada.
- No se cierra una tarea sin evidencia.
- Al terminar cada fase: actualizar `tasks.md`, `MEMORY.md` y el registro de evidencias.
- Si cambia un requisito: actualizar `spec.md`, `plan.md`, `tasks.md` y registrar la decisión en `MEMORY.md`.

## 5. Fases y specs

| Fase guía | Spec | Objetivo |
|---|---|---|
| Pre-0 | [`specs/000-artefactos`](./specs/000-artefactos/) | Descargar, verificar y servir artefactos por FTP |
| 0 | [`specs/001-fase-0-preparacion-snapshots`](./specs/001-fase-0-preparacion-snapshots/) | Preparación, aislamiento, snapshots y clones |
| 1 | [`specs/002-fase-1-montaje-entorno`](./specs/002-fase-1-montaje-entorno/) | Montaje de las 6 VM y servicios |
| 2 | [`specs/003-fase-2-implementacion-vulnerabilidades`](./specs/003-fase-2-implementacion-vulnerabilidades/) | Implementar vulnerabilidades corregidas |
| 3 | [`specs/004-fase-3-reconocimiento-enumeracion`](./specs/004-fase-3-reconocimiento-enumeracion/) | Reconocimiento, escaneo y enumeración |
| 4 | [`specs/005-fase-4-validacion-explotacion`](./specs/005-fase-4-validacion-explotacion/) | Validación, explotación, cadena e impacto |
| 5 | [`specs/006-fase-5-remediacion`](./specs/006-fase-5-remediacion/) | Remediación por versión o configuración |
| 6 | [`specs/007-fase-6-verificacion-retest`](./specs/007-fase-6-verificacion-retest/) | Retest y antes/después |
| 7 | [`specs/008-fase-7-documentacion-sustentacion`](./specs/008-fase-7-documentacion-sustentacion/) | Informe final, plantillas, diapositivas y réplica en vivo |

## 6. Convenciones

- Requisitos: `REQ-<spec>-NN`.
- Tareas: `T-<spec>-NN`.
- Evidencias: `EV-F0X-NNN.png`, `LOG-F0X-NNN.txt`, `CMD-F0X-NNN`.
- Snapshots: `00-base`, `01-<rol>-listo`, `estado-inicial-vulnerable`, `previo-a-<ID>`, `estado-parcheado`.
- Horas en **UTC**.
- Cada evidencia: captura + log + SHA256.
- Nombres de máquinas: `M1`…`M6`, `R0`.

## 7. Estado actual (2026-10-26)

- Laboratorio apagado; no responde ningún `10.10.10.x` desde el host.
- 24 hallazgos documentados: 9 CVE + 15 configuraciones.
- 5/5 máquinas con presencia, pero **0 RCE de los CVE estrella** y **0 versiones parcheadas**.
- M4 no tiene privesc real desde acceso limitado.
- B1/B2/S1/C1 son inválidos o no aplicables tal como están.
- Prioridad: **W1 wp2shell** → W4/W3 de respaldo → **W2 PHP2Shell** con time-box; M4 con usuario limitado + PrintNightmare; M3 con Samba 4.5.9; upgrades de versión.

## 8. Validación

```bash
tests/check-artifacts.sh             # presencia y SHA256 de artefactos
tests/check-versions.sh              # inventario de versiones desde M6
tests/check-version-gates.sh vuln    # versión vulnerable vs. fix
tests/check-version-gates.sh patched # versión corregida vs. fix
tests/check-retest.sh                # estado parcheado
tests/check-evidence.sh              # integridad de evidencias
tests/check-lab.ps1                  # conectividad desde el host Windows
```

Todos los tests son **read-only**. No explotan, no borran y no cambian configuración.

## 9. Qué no hacer

- No editar `informe/evidencias/` a mano.
- No borrar logs reales.
- No cambiar versiones sin snapshot.
- No usar `nmap -p-` en la demo; solo en la bitácora interna.
- No incluir comandos de exploit en el informe oficial.
- No declarar “parcheado” si solo se bloqueó una ruta o se deshabilitó una función.
