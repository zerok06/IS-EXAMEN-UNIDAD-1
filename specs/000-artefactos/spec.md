# Spec 000 · Pre-fase 0 · Artefactos y transferencia FTP

## Metadata

| Campo | Valor |
|---|---|
| ID | `000` |
| Fase | Pre-0 |
| Nombre | Descarga, verificación y transferencia FTP de versiones |
| Estado | `lista` |
| Dueño | Coordinador + M6 |
| Dependencias | Ninguna |
| Specs relacionadas | `001`, `002`, `003`, `006` |
| Fuente | `docs/PLAN-MAESTRO.md`; `artifacts/` |
| Version gate | Obligatorio: [`templates/version-gate.md`](../../templates/version-gate.md) |

## 1. Propósito

Tener **todas las versiones exactas** descargadas, verificadas y transferibles por FTP antes de aislar la red, para que M1–M5 instalen lo correcto en Fase 2 y lo corregido en Fase 5.

## 2. Alcance

**Incluye:** descarga de versiones vulnerables y corregidas, PoCs, manifiesto, SHA256, servidor FTP en M6, descarga por rol y verificación.

**No incluye:** ISOs de sistemas operativos (ver `artifacts/os/README.md`), explotación, remediación.

## 3. Actores y precondiciones

- Actores: coordinador, M6, dueños de VM.
- Precondiciones: host con Internet **antes** de aislar; espacio en disco; `curl`; `sha256sum` o `Get-FileHash`.

## 4. Requisitos EARS

- **REQ-000-01 (Ubicuo).** El proyecto DEBE tener un manifiesto con artefacto, versión, URL, SHA256, VM destino y propósito.
  - Verificación: `artifacts/MANIFEST.md`.
- **REQ-000-02 (Evento).** CUANDO se prepare el laboratorio, el equipo DEBE descargar las versiones vulnerables, corregidas y los PoCs en `artifacts/`.
  - Verificación: `download.ps1` / `download.sh`.
- **REQ-000-03 (Ubicuo).** Cada artefacto DEBE tener SHA256 en `artifacts/checksums.sha256`.
  - Verificación: `sha256sum -c checksums.sha256`.
- **REQ-000-04 (Evento).** CUANDO se transfieran artefactos, M6 DEBE servir FTP en `10.10.10.20:2121` con usuario `lab` y clave `lab123`.
  - Verificación: `ftp/serve-ftp.sh`.
- **REQ-000-05 (Ubicuo).** Cada VM DEBE descargar solo los artefactos de su rol.
  - Verificación: `ftp/fetch-artifacts.sh m1|m2|m3|m5|m6`.
- **REQ-000-06 (Evento).** CUANDO termine una descarga, la VM DEBE verificar el SHA256 antes de instalar.
  - Verificación: `sha256sum -c --ignore-missing checksums.sha256`.
- **REQ-000-07 (Ubicuo).** Cada artefacto DEBE instalarse en la ruta definida en `artifacts/README.md`.
  - Verificación: `--version` / `wp core version` / `php -v`.
- **REQ-000-08 (Ubicuo).** Cada versión instalada DEBE registrarse en `templates/version-gate.md`.
  - Verificación: tabla de versiones.
- **REQ-000-09 (No deseado).** SI un artefacto es un binario troyanizado o malware, ENTONCES el laboratorio NO DEBE instalarlo.
  - Verificación: manifiesto y revisión.
- **REQ-000-10 (Opcional).** DONDE se necesiten ISOs, el equipo DEBE descargarlas aparte y verificar su hash oficial.
  - Verificación: `artifacts/os/README.md`.
- **REQ-000-11 (Estado).** MIENTRAS se transfieran artefactos, el laboratorio DEBE estar en la LAN aislada, sin Internet.
  - Verificación: `ping 8.8.8.8` falla; FTP responde.
- **REQ-000-12 (No deseado).** SI un SHA256 no coincide, ENTONCES el equipo DEBE borrar el archivo, re-descargarlo y verificar de nuevo.
  - Verificación: log de re-descarga.

## 5. Criterios de aceptación

- [ ] Manifiesto completo.
- [ ] 19 artefactos descargados.
- [ ] `checksums.sha256` verificado.
- [ ] FTP funcionando en M6.
- [ ] Cada VM con sus artefactos.
- [ ] Versiones instaladas registradas.
- [ ] Sin artefactos troyanizados.
- [ ] Sin Internet durante la transferencia.

## 6. Trazabilidad

| REQ | Test/evidencia | Tarea |
|---|---|---|
| REQ-000-01 | `MANIFEST.md` | T-000-03 |
| REQ-000-02 | `download.ps1`/`download.sh` | T-000-01 |
| REQ-000-03 | `tests/check-artifacts.sh` | T-000-02 |
| REQ-000-04/05 | `serve-ftp.sh`/`fetch-artifacts.sh` | T-000-04–09 |
| REQ-000-06 | `sha256sum -c` | T-000-05–09 |
| REQ-000-07/08 | `version-gate.md` | T-000-10–11 |
| REQ-000-09/10 | manifiesto | T-000-03 |
| REQ-000-11/12 | log de transferencia | T-000-05–09 |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| URL cambia | Usar el SHA256 del manifiesto |
| Descarga lenta | Descargar antes de aislar; `--retry` |
| Defender bloquea un PoC | Usar MSF; no guardar el .ps1 |
| FTP no disponible | Alternativa HTTP `python3 -m http.server` |
| Disco lleno | Reservar ≥5 GB para artefactos + snapshots |
| Artefacto corrupto | Re-descargar y verificar |

## 8. Fuera de alcance

- ISOs de SO (aparte).
- Explotación.
- Remediación.
- Instalación de servicios (Fase 1/2).
