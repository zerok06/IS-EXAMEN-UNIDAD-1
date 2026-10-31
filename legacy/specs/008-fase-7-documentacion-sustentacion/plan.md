# Plan 008 · Informe final y sustentación

## 1. Enfoque

Primero se ordena el informe con las 9 secciones y las fases 0–7. Después se construye el deck con una slide previa por réplica. Al final se ensaya la demo con snapshots y planes B.

## 2. Estructura del informe

| Sección | Contenido |
|---|---|
| 1. Carátula | Curso, grupo, integrantes, roles, fecha |
| 2. Resumen ejecutivo | Escenario, hallazgos, estado final |
| 3. Arquitectura | Diagrama, direccionamiento, roles, VMware |
| 4. Metodología | Fases 0–7, herramientas, criterios |
| 5. Inventario | CVE/CWE, servicio, versión, CVSS, máquina |
| 6. Hallazgos | Descripción, impacto, evidencia, NVD |
| 7. Remediación y verificación | Medida, versión final, antes/después |
| 8. Conclusiones | Lecciones y recomendaciones |
| 9. Anexos | Capturas, configuraciones, snapshots, hashes |

## 3. Estructura del deck

| # | Slide | Contenido |
|---|---|---|
| 1 | Portada | Curso, grupo, título |
| 2 | Escenario | 6 VM, red, objetivo |
| 3 | Arquitectura | Diagrama y roles |
| 4 | Metodología | Fases 0–7 |
| 5 | Inventario | CVE y CVSS |
| 6 | **Slide previa W1** | Qué se muestra, máquina, resultado esperado |
| 7 | W1 demo | Shell `www-data` |
| 8 | **Slide previa M4** | Acceso limitado → SYSTEM |
| 9 | M4 demo | `whoami` SYSTEM |
| 10 | **Slide previa VNC** | Escritorio sin clave |
| 11 | VNC demo | Escritorio |
| 12 | Remediación | Versiones y configuraciones |
| 13 | Retest | Antes/después |
| 14 | Conclusiones | Lecciones |
| 15 | Cierre | Gracias / preguntas |

## 4. Guion de demo

1. **Slide previa:** qué se muestra, máquina y resultado esperado.
2. Restaurar `estado-inicial-vulnerable` delante del público.
3. Ejecutar **un** PoC (2–3 min): W1 o W4.
4. Mostrar `id`/`whoami` y el marcador.
5. Restaurar `estado-parcheado`.
6. Repetir el mismo comando: debe fallar.
7. Cada integrante explica su máquina.
8. Cierre: cadena, remediación y lecciones.

## 5. Reparto

| Minuto | Quién | Qué |
|---|---|---|
| 0–1 | Coordinador | Escenario y alcance |
| 1–2 | M6 | Recon y modelo de red |
| 2–3 | M1 | W1/W4 y credenciales |
| 3–4 | M2 | Redis y DB |
| 4–5 | M3 | FTP/NFS/Samba |
| 5–7 | M4 | Acceso limitado → SYSTEM |
| 7–8 | M5 | Clave reutilizada y VNC |
| 8–10 | Todos | Remediación, retest y conclusiones |

## 6. Planes B

| Falla | Plan B |
|---|---|
| W1 no sale | W4 login + plugin + `id` |
| M4 no responde | Mostrar evidencia `EV-005-M4-*` y explicar |
| VNC no conecta | Mostrar `EV-005-M5-*` y `nmap --script vnc-info` |
| W2 no reproduce | Mostrar versión y limitación; usar W1/W3 |
| Una VM está apagada | Usar captura grabada y explicar |

## 7. Checklist de entregables

- [ ] Informe PDF con 9 secciones.
- [ ] Deck PDF/PPTX con slide previa por réplica.
- [ ] Registro de snapshots.
- [ ] Diagrama de red.
- [ ] Evidencias y hashes.
- [ ] Guion de demo.
- [ ] Ensayo cronometrado.

## 8. Definición de terminado

- [ ] Informe renumerado 0–7.
- [ ] Sin recetas en el informe.
- [ ] Deck listo.
- [ ] Demo ensayada.
- [ ] Snapshots restaurables.
- [ ] Todos explican su VM.

## 9. Estimación

| Actividad | Horas |
|---|---|
| Ordenar informe | 2.0 |
| Deck | 1.5 |
| Ensayo | 1.0 |
| **Total** | **4.5** |
