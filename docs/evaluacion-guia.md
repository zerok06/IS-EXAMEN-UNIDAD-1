# Evaluación de la guía del docente

> Matriz de cumplimiento y brechas. Sirve para la defensa: qué pide la guía, qué tiene el proyecto, qué falta y en qué spec se resuelve.

## 1. Veredicto general

El proyecto **cumple la infraestructura, la documentación y el alcance**, pero **no cumple todavía la parte que más pesa**: demostrar explotación real de CVE críticos, alcanzar todas las máquinas con una cadena clara, aplicar parches de versión y verificar el antes/después sin contradicciones.

| Dimensión | Peso de la guía | Estado | Comentario |
|---|---|---|---|
| Criticidad de vulnerabilidades | Alto | Parcial | W1/W2/W3/D1 no demostrados; B1/B2/S1/C1 inválidos |
| Alcance en la red | Alto | Bien | 5/5 con presencia, pero por configuraciones |
| Profundidad por máquina | Alto | Parcial | M3 y M5 con 2 demostrables; M4 sin privesc real |
| Remediación y verificación | Alto | Débil | Solo configuración; retest contradictorio |
| Informe y sustentación | Medio | Parcial | Informe completo, pero fases mal numeradas y sin deck |

## 2. Fases 0–7

| Fase | Qué pide la guía | Qué tiene el proyecto | Brecha | Spec |
|---|---|---|---|---|
| 0 | Clon/snapshot inicial y parcheado; documentar fecha, descripción y propósito | Snapshots iniciales; `estado-parcheado` pendiente; nombres sin mapear | Completar registro y snapshot final | `001` |
| 1 | 6 VM, servicios, dependencias, red aislada | Montaje completo y verificado | M4 inestable; VMware vs VirtualBox | `002` |
| 2 | ≥3 vulns por máquina, privesc M4, CVE verificados | 24 hallazgos, pero varios inválidos | Bajar Samba, arreglar CGI, usuario limitado M4 | `003` |
| 3 | Descubrir, escanear, enumerar, correlacionar | Fases 1–2 del proyecto; buen detalle | firewall desviado; versiones sin actualizar | `004` |
| 4 | Validar explotabilidad, impacto, alcance, evidencia | Configuraciones validadas; CVE estrella no | Ejecutar W1/W2/W3/D1; privesc M4 | `005` |
| 5 | Parche, reconfiguración o mitigación por hallazgo | Solo configuración; versiones intactas | Actualizar WP/PHP/Apache/Redis | `006` |
| 6 | Repetir validación, antes/después, versión final | Retest por configuración; contradictorio | Unificar y rehacer | `007` |
| 7 | Informe, diapositivas, réplica en vivo | Informe y guion; sin deck | Renumerar, separar anexo, ensayar | `008` |

## 3. Secciones del informe (guía §11)

| Sección | Estado | Acción |
|---|---|---|
| 1. Carátula | Bien | Completar grupo e integrantes |
| 2. Resumen ejecutivo | Parcial | Actualizar con lo demostrado y lo pendiente |
| 3. Arquitectura | Bien | Declarar VMware y la separación lógica |
| 4. Metodología | Mal numerada | Renumerar 0–7 |
| 5. Inventario | Bien, con errores | Corregir CVSS y CVE inválidos |
| 6. Hallazgos | Parcial | Agregar W1/W2/W3/M4 privesc |
| 7. Remediación y verificación | Débil | Versiones + antes/después |
| 8. Conclusiones | Bien | Agregar lecciones de versiones y snapshots |
| 9. Anexos | Parcial | Completar snapshots, hashes y configuraciones |

## 4. Las preguntas que puede hacer el docente

1. **“¿Dónde está el `id` de wp2shell o PHP2Shell?”**  
   Hoy no existe. Hay que ejecutarlo o declararlo como limitación con evidencia del intento.

2. **“M4: ¿partiendo de qué acceso limitado obtuvieron SYSTEM?”**  
   Hoy: de `Administrador`. No es privesc. Hay que crear `soporte`, obtener sesión limitada y usar PrintNightmare local.

3. **“Samba 4.5.10 no es vulnerable a SambaCry, ¿por qué está en el inventario?”**  
   Es la versión que corrige. Hay que bajar a 4.5.9 o retirarlo.

4. **“vsftpd 2.3.4 del tarball oficial no tiene backdoor, ¿cómo lo demostraron?”**  
   No se demostró. Hay que usar el binario troyanizado o retirarlo.

5. **“Windows 10 19045 no es vulnerable a EternalBlue, ¿por qué está?”**  
   No aplica. Hay que retirarlo y sostener M5 con C2/C4/C3.

6. **“¿Qué versión corrige W1/W2/W3/D1 y dónde está el retest?”**  
   Está en la matriz, pero el retest actual no cambió versiones. Hay que actualizar y repetir.

7. **“¿Por qué el informe dice retest ejecutado y remediación pendiente?”**  
   Es una contradicción documental. Hay que unificar.

8. **“¿Por qué el informe incluye comandos de ataque?”**  
   La guía pide metodología e impacto, no recetas. Hay que moverlos al anexo interno.

## 5. Brechas priorizadas

| # | Brecha | Impacto | Acción | Spec |
|---|---|---|---|---|
| 1 | W1/W2/W3 sin RCE | Pierde criticidad | Ejecutar W1; W3 con CGI; W2 time-box | `005` |
| 2 | M4 sin privesc real | Pierde requisito obligatorio | `soporte` + PrintNightmare local | `005` |
| 3 | Versiones sin parchear | Pierde remediación | WP/PHP/Apache/Redis a versión corregida | `006` |
| 4 | Retest contradictorio | Pierde credibilidad | Unificar `06` y `07`; mismo comando | `007` |
| 5 | CVE inválidos | Pierde rigor | Retirar B1/B2/S1/C1 o bajarlos | `003` |
| 6 | Fases mal numeradas | Pierde estructura | Renumerar 0–7 | `008` |
| 7 | Recetas en el informe | Pierde forma | Mover a anexo interno | `008` |
| 8 | Sin diapositivas | Pierde sustentación | Crear deck con slide previa | `008` |
| 9 | Versiones sin comparar con el fix | Pierde rigor y remediación | Version gate obligatorio en cada fase | `001`–`007` |

> La nueva capa SDD separa **7 fases técnicas (0–6) + Fase 7 de informe final** y hace obligatorio el **version gate**. Ver [`PROCESO-7-FASES.md`](./PROCESO-7-FASES.md).
>
> **Revalidación 2026-10-26:** 22 hallazgos demostrables, 2 no reproducibles (D1 Redis de fuente, B2 tarball limpio) y 2 no aplicables (S1 por SMB1 off, C1 por Windows 10 19045). Ver [`VALIDACION-VULNERABILIDADES.md`](./VALIDACION-VULNERABILIDADES.md) y el flujo por vuln en [`specs/005-fase-4-validacion-explotacion/vulns/`](../specs/005-fase-4-validacion-explotacion/vulns/).

## 6. Lo que ya está bien y hay que conservar

- Arquitectura y direccionamiento claros.
- Guías por máquina y bitácora de comandos.
- Evidencias fechadas y hashes.
- Inventario amplio y fichas por hallazgo.
- Cadena real M1 → M2 → M3 → M4/M5.
- Honestidad al marcar lo que no se pudo explotar.
- Aislamiento y ética documentados.

## 7. Criterio de cierre

El proyecto se considera alineado con la guía cuando:

- [ ] W1 (o W2/W3) tiene `id` real y evidencia.
- [ ] M4 tiene un privesc desde acceso limitado con `whoami` SYSTEM.
- [ ] Cada máquina tiene ≥3 vulnerabilidades demostradas o justificadas.
- [ ] Cada hallazgo tiene versión corregida o mitigación compensatoria.
- [ ] El retest usa el mismo comando y tiene antes/después.
- [ ] El informe está renumerado 0–7 y sin recetas.
- [ ] El deck tiene slide previa por réplica.
- [ ] La demo se ensayó con snapshots.
