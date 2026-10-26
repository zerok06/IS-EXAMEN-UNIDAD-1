# Proceso de 7 fases + informe final

> Este es el proceso maestro. Las specs ejecutables están en [`../specs/`](../specs/); las plantillas en [`../templates/`](../templates/); las reglas en [`constitution.md`](./constitution.md).

## 0. Idea central

El proyecto se ejecuta en **7 fases técnicas (0–6)** y una **Fase 7 de informe final**. Cada fase usa los **7 pasos SDD**:

```text
Constitución → Spec → Clarificación → Plan → Tareas → Implementación → Validación → Loop
```

La diferencia con la versión anterior: **la validación de versiones es una puerta obligatoria en cada fase**. No se avanza si no está claro:

- qué versión está instalada,
- qué rango es vulnerable,
- qué versión corrige,
- qué evidencia demuestra que la versión es la correcta,
- y qué comando de retest la verifica.

## 1. Los 7 pasos SDD

| Paso | Artefacto | Pregunta que responde | Terminado cuando |
|---|---|---|---|
| 1. Constitución | `docs/constitution.md` | ¿Qué reglas no se negocian? | Está aprobada y es la referencia |
| 2. Spec | `specs/<fase>/spec.md` | ¿Qué debe pasar, en EARS? | Cada requisito es verificable |
| 3. Clarificación | `specs/CLARIFICACIONES.md` | ¿Qué ambigüedad hay que resolver? | Las decisiones están registradas |
| 4. Plan | `specs/<fase>/plan.md` | ¿Cómo se implementa? | Hay pasos, comandos, snapshots y rollback |
| 5. Tareas | `specs/<fase>/tasks.md` | ¿Quién hace qué y en qué orden? | Hay IDs, dependencias y evidencia |
| 6. Implementación | Laboratorio + evidencias | ¿Se ejecutó? | Hay log, captura y hash |
| 7. Validación | `tests/` + retest | ¿Funciona y cumple? | El test pasa o la limitación está documentada |

Si un requisito cambia, se vuelve al paso 2. Ese es el **loop**.

## 2. Las 7 fases técnicas + informe

| Fase | Nombre | Objetivo | Version gate | Spec |
|---|---|---|---|---|
| Pre-0 | Artefactos | Descargar versiones, verificar SHA256 y servir por FTP | Manifiesto + checksums | `000` |
| 0 | Preparación y snapshots | Red aislada, snapshots, clones, credenciales, línea base de versiones | Registrar versiones base de cada VM | `001` |
| 1 | Montaje del entorno | Servicios y dependencias | Confirmar versiones instaladas | `002` |
| 2 | Implementación de vulnerabilidades | ≥3 vulns por máquina | Fijar versión vulnerable y versión que corrige | `003` |
| 3 | Reconocimiento y enumeración | Hosts, puertos, servicios, versiones | Fingerprint externo de versiones | `004` |
| 4 | Validación y explotación | Explotar, encadenar, medir impacto | Confirmar que la versión es explotable y capturar PoC | `005` |
| 5 | Remediación | Parchear o mitigar | Actualizar a la versión corregida o documentar mitigación | `006` |
| 6 | Retest | Verificar el antes/después | Confirmar versión corregida y PoC fallando | `007` |
| 7 | Informe final | Informe, plantillas, diapositivas y demo | Tabla de versiones antes/después en el informe | `008` |

> Nota: la guía numera 0–7. Aquí las fases 0–6 son técnicas y la 7 es el informe. Es la misma secuencia, con el informe separado para que no se mezcle con la ejecución.

### 2.1 Pre-fase 0 · Artefactos

Antes de la Fase 0 se ejecuta la spec [`000-artefactos`](../specs/000-artefactos/):

1. Descargar las versiones exactas en `artifacts/vulnerable/`, `artifacts/fixed/` y los PoCs en `artifacts/pocs/`.
2. Verificar `artifacts/checksums.sha256`.
3. Copiar `artifacts/` a M6.
4. Servir por FTP en `10.10.10.20:2121`.
5. Descargar por rol en M1–M5.
6. Verificar SHA256 antes de instalar.

Sin este paso, la Fase 2 instala versiones equivocadas y el version gate no se puede cerrar.

## 3. Version gate por fase

| Fase | Qué se valida | Comando/Evidencia | Criterio |
|---|---|---|---|
| 0 | Versiones base | `httpd -v`, `php -v`, `wp core version`, `redis-server --version`, `smbd --version`, `winver` | Tabla base completa |
| 1 | Versiones instaladas | `curl -sI`, `nmap -sV`, CLI de cada servicio | Coinciden con la matriz |
| 2 | Versión vulnerable vs. fix | Ficha NVD + `--version` + comparación | Instalada dentro del rango vulnerable y **menor** que el fix |
| 3 | Fingerprint externo | `curl`, `wpscan`, `nmap -sV`, `smbclient`, `dig` | La versión se ve desde fuera |
| 4 | Explotabilidad | PoC + `id`/`whoami` + log | La versión vulnerable responde al PoC |
| 5 | Versión corregida | `wp core version`, `php -v`, `httpd -v`, `redis-server --version`, `smbd --version` | Instalada **igual o mayor** que el fix |
| 6 | Retest de versión | Mismo comando de Fase 4 | La versión es la corregida y el PoC falla |
| 7 | Informe | Tabla de versiones | Cada hallazgo tiene antes/después y NVD |

### 3.1 Regla de oro

Si la versión instalada **es igual o mayor** que la versión que corrige, el CVE **no es explotable**. Se documenta como “no aplica” o se reemplaza por otra vulnerabilidad. No se cuenta como profundidad.

### 3.2 Regla de evidencia

Cada fila de la tabla de versiones debe tener:

1. CVE/CWE.
2. Producto y versión instalada.
3. Rango vulnerable.
4. Versión que corrige.
5. CVSS y métrica.
6. Fuente NVD/CVE.org con fecha.
7. Evidencia de presencia.
8. Evidencia de explotación o de no explotabilidad.
9. Remediación aplicada.
10. Retest.

## 4. Flujo end-to-end

```text
[0] Preparación ──► [1] Montaje ──► [2] Vulnerabilidades
                                            │
                                            ▼
[3] Reconocimiento ──► [4] Explotación ──► [5] Remediación
                                            │
                                            ▼
[6] Retest ──► [7] Informe final ──► Loop (mantenimiento)
```

En cada flecha hay un **version gate**. Si falla, no se avanza.

## 5. Artefactos

| Artefacto | Ruta | Uso |
|---|---|---|
| Constitución | `docs/constitution.md` | Reglas |
| Plan maestro | `docs/PLAN-MAESTRO.md` | Contexto |
| Proceso | `docs/PROCESO-7-FASES.md` | Este documento |
| Matriz de versiones | `docs/version-matrix.md` | Fuente de verdad de versiones |
| Snapshots | `docs/snapshots.md` | Procedimiento manual |
| Specs | `specs/001…008/` | EARS + plan + tareas |
| Clarificaciones | `specs/CLARIFICACIONES.md` | Decisiones |
| Plantillas | `templates/` | Informe, hallazgo, version gate, snapshot, deck |
| Tests | `tests/` | Validación read-only |
| Evidencias | `informe/evidencias/` | Logs, capturas, hashes |
| Informe | `informe/` | Entregable |

## 6. Plantillas

| Plantilla | Para qué |
|---|---|
| [`templates/informe.md`](../templates/informe.md) | Informe de 9 secciones |
| [`templates/hallazgo.md`](../templates/hallazgo.md) | Ficha por vulnerabilidad |
| [`templates/version-gate.md`](../templates/version-gate.md) | Checklist de versiones por fase |
| [`templates/snapshot.md`](../templates/snapshot.md) | Registro de snapshots |
| [`templates/diapositivas.md`](../templates/diapositivas.md) | Deck con slide previa por réplica |

## 7. Definición de terminado por fase

### Pre-0
- [ ] 19 artefactos descargados.
- [ ] `checksums.sha256` verificado.
- [ ] `artifacts/` copiado a M6.
- [ ] FTP funcionando.
- [ ] Cada VM con sus artefactos.

### Fase 0
- [ ] Red aislada y verificada.
- [ ] Snapshots `00-base`, `01-rol-listo`, `estado-inicial-vulnerable`.
- [ ] Clon full.
- [ ] Tabla base de versiones.

### Fase 1
- [ ] Servicios arriba.
- [ ] Dependencias verificadas.
- [ ] Versiones instaladas registradas.

### Fase 2
- [ ] ≥3 vulnerabilidades por máquina.
- [ ] Versión vulnerable < versión que corrige.
- [ ] Evidencia de presencia.

### Fase 3
- [ ] Hosts, puertos, servicios y versiones.
- [ ] Correlación CVE/CWE.
- [ ] Fingerprint externo.

### Fase 4
- [ ] Explotación real o limitación documentada.
- [ ] `id`/`whoami`/marcador.
- [ ] Cadena 5/5.
- [ ] M4 con privesc desde acceso limitado.

### Fase 5
- [ ] Versión corregida o mitigación documentada.
- [ ] Registro de cambios.
- [ ] `estado-parcheado`.

### Fase 6
- [ ] Mismo comando antes/después.
- [ ] Versión corregida confirmada.
- [ ] PoC falla.
- [ ] `06` y `07` coherentes.

### Fase 7
- [ ] Informe con 9 secciones.
- [ ] Plantilla de hallazgo aplicada.
- [ ] Tabla de versiones antes/después.
- [ ] Deck con slide previa.
- [ ] Demo ensayada.

## 8. Loop

Al terminar la Fase 7, el proyecto no se cierra: se mantiene.

- Si aparece un CVE nuevo, se crea una spec nueva.
- Si cambia una versión, se actualiza `version-matrix.md`.
- Si cambia un requisito, se actualiza spec/plan/tasks.
- Si cambia una decisión, se registra en `CLARIFICACIONES.md` y `MEMORY.md`.

## 9. Regla de oro final

**Una versión sin evidencia es una suposición. Una suposición no vale para la nota.**
