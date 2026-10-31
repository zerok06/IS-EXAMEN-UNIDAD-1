# Spec 001 · Fase 0 · Preparación y snapshots

## Metadata

| Campo | Valor |
|---|---|
| ID | `001` |
| Fase guía | 0 |
| Nombre | Preparación, aislamiento, snapshots y clones |
| Estado | `lista` |
| Dueño | Coordinador + cada dueño de VM |
| Dependencias | `000` |
| Specs relacionadas | `002`, `003` |
| Fuente | Guía §8 Fase 0; `docs/PLAN-MAESTRO.md` §4 |

## 1. Propósito

Dejar el laboratorio **aislado, estable y reversible** antes de implementar o explotar nada: red verificada, snapshots, clones, credenciales y kit de evidencia.

## 2. Alcance

**Incluye:** encendido, red, IP estática, DNS, aislamiento, snapshots, clones, registro, credenciales y kit de evidencia.

**No incluye:** implementación de vulnerabilidades, escaneo, explotación.

## 3. Actores y precondiciones

- Actores: coordinador, dueños M1–M5, auditor M6, docente.
- Precondiciones: guía leída, `docs/constitution.md` aceptada, VMs creadas.

## 3.1 Version gate

| VM | Versión base |
|---|---|
| M1 | WordPress 7.0.1 · PHP 8.4.26 · Apache 2.4.49 |
| M2 | MariaDB 10.11.19 · Redis 6.2.6 |
| M3 | Samba 4.5.10 · vsftpd 2.3.4 |
| M4 | Windows Server 2016 build 14393 |
| M5 | Windows 10 19045 · TightVNC 2.8.90 |

Verificación: `wp core version`, `php -v`, `httpd -v`, `mariadb --version`, `redis-server --version`, `smbd --version`, `winver`.

## 4. Requisitos EARS

### Red y aislamiento

- **REQ-001-01 (Ubicuo).** El laboratorio DEBE usar la red `10.10.10.0/24` con IP estática en M1–M6 y R0 en `10.10.10.1`.
  - Verificación: `ip -brief a` en Linux; `ipconfig /all` en Windows.
- **REQ-001-02 (Estado).** MIENTRAS los servicios vulnerables estén activos, el laboratorio DEBE estar sin salida a Internet y sin conexión a la red universitaria.
  - Verificación: `ping 8.8.8.8` falla; `curl http://10.10.10.11` responde.
- **REQ-001-03 (Evento).** CUANDO se enciendan las 6 VM, el laboratorio DEBE permitir `ping` entre M1–M6 y resolver `*.uni.lab` por M4.
  - Verificación: `ping` desde M6 a `.11`–`.15`; `dig wp.uni.lab @10.10.10.14`.
- **REQ-001-04 (No deseado).** SI una VM no responde o una IP está duplicada, ENTONCES el laboratorio DEBE detener la fase y documentar el incidente.
  - Verificación: tabla de estado con la VM y el error.

### Snapshots y clones

- **REQ-001-05 (Evento).** CUANDO el SO y la red estén verificados, cada VM DEBE tener el snapshot `00-base`.
  - Verificación: `Snapshot Manager` muestra `00-base`.
- **REQ-001-06 (Evento).** CUANDO los servicios de rol estén instalados, cada VM DEBE tener el snapshot `01-<rol>-listo`.
  - Verificación: `Snapshot Manager` muestra el nombre.
- **REQ-001-07 (Evento).** CUANDO las vulnerabilidades estén implantadas y verificadas, cada VM DEBE tener `estado-inicial-vulnerable`.
  - Verificación: snapshot visible + checklist de servicios.
- **REQ-001-08 (Evento).** Antes de la Fase 2, cada VM DEBE tener un clon full independiente.
  - Verificación: `VM → Manage → Clone → Full Clone`; carpeta externa.
- **REQ-001-09 (Ubicuo).** El proyecto DEBE registrar cada snapshot con máquina, nombre lógico, nombre real en VMware, fecha UTC, propósito y responsable.
  - Verificación: `informe/anexos/c-snapshots.md` completo.

### Evidencia y credenciales

- **REQ-001-10 (Ubicuo).** El equipo DEBE tener `~/evidence/` con subcarpetas `m1`–`m5` y `parcheado`, y una sesión `script` activa.
  - Verificación: `tree ~/evidence`; `script` inicia.
- **REQ-001-11 (Ubicuo).** El equipo DEBE disponer de una matriz de credenciales de laboratorio, marcada como ficticia y rotable.
  - Verificación: `MEMORY.md` §3 y `guias/validacion-versiones.md`.
- **REQ-001-12 (Opcional).** DONDE se use VMware en lugar de VirtualBox, el proyecto DEBE declararlo en el informe y usar la ruta de snapshots de VMware.
  - Verificación: nota en `03-arquitectura` y capturas de VMware.

## 5. Criterios de aceptación

- [ ] Artefactos descargados y verificados (spec `000`).
- [ ] M1–M6 con IP correcta y `ping` entre ellas.
- [ ] Sin Internet ni red universitaria.
- [ ] `00-base`, `01-rol-listo` y `estado-inicial-vulnerable` en M1–M5.
- [ ] Clon full de M1–M5.
- [ ] Registro de snapshots completo.
- [ ] `~/evidence/` creado y `script` funcionando.
- [ ] Credenciales documentadas.
- [ ] Version gate: versiones base registradas en `templates/version-gate.md`.

## 6. Trazabilidad

| REQ | Test/evidencia | Tarea |
|---|---|---|
| REQ-001-01 | `tests/check-lab.ps1` | T-001-01 |
| REQ-001-02 | `ping 8.8.8.8` falla | T-001-02 |
| REQ-001-03 | `ping` + `dig` | T-001-03 |
| REQ-001-05–08 | `Snapshot Manager` | T-001-05–08 |
| REQ-001-09 | `c-snapshots.md` | T-001-09 |
| REQ-001-10 | `tree ~/evidence` | T-001-10 |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| Snapshots con nombres inconsistentes | Usar la tabla de `docs/snapshots.md` |
| Host sin disco | Liberar ≥20 GB por VM antes de empezar |
| IP duplicada | Escanear la LAN y corregir antes de continuar |
| Internet activo | Desconectar DSL/NAT y evidenciar el fallo de `ping` |

## 8. Fuera de alcance

- Implementar vulnerabilidades.
- Escanear o explotar.
- Parchear.
