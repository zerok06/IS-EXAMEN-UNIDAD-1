# Diapositivas · plantilla de sustentación

> 8–10 minutos. Una slide previa por cada réplica en vivo. Sin comandos largos.

## 1. Estructura

| # | Slide | Contenido | Quién |
|---|---|---|---|
| 1 | Portada | Curso, grupo, título | Coordinador |
| 2 | Escenario | 6 VM, red, objetivo | Coordinador |
| 3 | Arquitectura | Diagrama y roles | Coordinador |
| 4 | Metodología | Fases 0–7 | Coordinador |
| 5 | Inventario | CVE, CVSS, versiones | Coordinador |
| 6 | **Slide previa W1** | Qué se muestra, máquina, resultado esperado | M1 |
| 7 | W1 demo | Admin/plugin/`id` | M1 |
| 8 | **Slide previa M4** | Acceso limitado → SYSTEM | M4 |
| 9 | M4 demo | `whoami` SYSTEM | M4 |
| 10 | **Slide previa VNC** | Escritorio sin clave | M5 |
| 11 | VNC demo | Escritorio | M5 |
| 12 | Remediación | Versiones y configuraciones | M2/M3 |
| 13 | Retest | Antes/después | Verificador |
| 14 | Conclusiones | Lecciones | Coordinador |
| 15 | Cierre | Gracias / preguntas | Todos |

## 2. Slide previa (obligatoria)

Cada slide previa debe responder:

- **Qué** se va a mostrar.
- **En qué máquina**.
- **Qué se espera ver**.
- **Qué se verá después** (parcheado).

Ejemplo:

> **W1 · wp2shell en M1**  
> Máquina: M1 `10.10.10.11` (WordPress 7.0.1).  
> Se mostrará: creación de admin no autenticada y ejecución de `id`.  
> Se espera: `uid=33(www-data)`.  
> Después: mismo PoC contra WP 7.0.2, debe fallar.

## 3. Guion de demo

1. Slide previa.
2. Restaurar `estado-inicial-vulnerable`.
3. Ejecutar un PoC (2–3 min).
4. Mostrar `id`/`whoami`/marcador.
5. Restaurar `estado-parcheado`.
6. Repetir el comando: falla.
7. Cada integrante explica su VM.
8. Cierre.

## 4. Planes B

| Falla | Plan B |
|---|---|
| W1 no sale | W4 login + plugin + `id` |
| M4 no responde | Evidencia `EV-005-M4-*` |
| VNC no conecta | `nmap --script vnc-info` + evidencia |
| W2 no reproduce | Mostrar versión y limitación |
| VM apagada | Captura grabada |

## 5. Checklist

- [ ] Slide previa por réplica.
- [ ] 8–10 minutos.
- [ ] Cada integrante habla.
- [ ] Snapshots restaurables.
- [ ] Planes B probados.
- [ ] Cierre con lecciones.
