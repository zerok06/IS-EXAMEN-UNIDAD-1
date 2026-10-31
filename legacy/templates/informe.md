# Informe técnico · {{TÍTULO}}

> Plantilla de la Fase 7. No incluir comandos de exploit ni recetas paso a paso. Los comandos viven en el anexo interno.

## 1. Carátula

| Campo | Valor |
|---|---|
| Curso | IS-1023 Seguridad de la Información |
| Unidad | Unidad I · Semana 07 |
| Docente | {{DOCENTE}} |
| Grupo | {{GRUPO}} |
| Integrantes | {{NOMBRES}} |
| Roles | {{M1…M6}} |
| Fecha | {{FECHA}} |
| Entorno | Laboratorio aislado `10.10.10.0/24` |

## 2. Resumen ejecutivo

{{SÍNTESIS_DEL_ESCENARIO}}

**Hallazgos principales:** {{N}} ({{CVE}} CVE + {{CONFIG}} configuraciones).

**Estado final:** {{QUÉ_SE_CERRÓ}} / {{QUÉ_QUEDÓ_PENDIENTE}}.

**Conclusión:** {{LECCIÓN_PRINCIPAL}}.

## 3. Arquitectura del entorno

- Diagrama: {{ENLACE_AL_DIAGRAMA}}
- Plan de direccionamiento:

| VM | Rol | IP | SO | Servicios |
|---|---|---|---|---|
| M1 | Aplicación | `10.10.10.11` | Ubuntu 22.04 | Apache, PHP, WordPress, Moodle |
| M2 | Base de datos | `10.10.10.12` | Ubuntu 22.04 | MariaDB, Redis, SNMP |
| M3 | Respaldos | `10.10.10.13` | Ubuntu 22.04 | NFS, Samba, vsftpd |
| M4 | Windows heredado | `10.10.10.14` | WS2016 | DNS, SMB, Spooler |
| M5 | Cliente | `10.10.10.15` | Win10 | SMB, RDP, VNC |
| M6 | Auditoría | `10.10.10.20` | Kali | nmap, wpscan, nxc, MSF |
| R0 | Router | `10.10.10.1` | MitraStar | Transporte |

**Nota de virtualización:** {{VMWARE_O_VIRTUALBOX}}.

## 4. Metodología

Fases 0–7 de la guía:

| Fase | Qué se hizo | Evidencia |
|---|---|---|
| 0 | Preparación y snapshots | {{...}} |
| 1 | Montaje | {{...}} |
| 2 | Implementación de vulnerabilidades | {{...}} |
| 3 | Reconocimiento y enumeración | {{...}} |
| 4 | Validación y explotación | {{...}} |
| 5 | Remediación | {{...}} |
| 6 | Verificación | {{...}} |
| 7 | Informe y sustentación | {{...}} |

**Herramientas:** {{NMAP, WPScan, NXC, MSF, curl, redis-cli, etc.}}.

## 5. Inventario de vulnerabilidades

| ID | Máquina | CVE/CWE | Servicio | Versión instalada | Rango vulnerable | Versión que corrige | CVSS | Métrica | NVD |
|---|---|---|---|---|---|---|---|---|---|
| W1 | M1 | CVE-2026-63030 | WordPress | 7.0.1 | 6.9.0–6.9.4 / 7.0.0–7.0.1 | 6.9.5 / 7.0.2 | 9.8 | v3.1 | {{URL}} |
| W2 | M1 | CVE-2026-109618/19 | PHP | 8.4.26 | 8.4.x < 8.4.27 | 8.4.27 | 9.8/8.1 | v3.1 | {{URL}} |
| W3 | M1 | CVE-2021-41773 | Apache | 2.4.49 | 2.4.49 | 2.4.50/2.4.51+ | 9.8 | v3.1 | {{URL}} |
| D1 | M2 | CVE-2022-0543 | Redis | 6.2.6 | 6.2.x < 6.2.7 | 6.2.7 | 10.0 | v3.1 | {{URL}} |
| B1 | M3 | CVE-2017-7494 | Samba | 4.5.9 | < 4.5.10 | 4.5.10 | 9.8 | v3.1 | {{URL}} |
| B2 | M3 | CVE-2011-2523 | vsftpd | 2.3.4 | tarball troyanizado | 2.3.4 limpio | 9.8 | v3.1 | {{URL}} |
| S1 | M4 | CVE-2017-0144 | SMBv1 | WS2016 | sin MS17-010 | MS17-010 | 8.8 | v3.1 | {{URL}} |
| S2 | M4 | CVE-2021-34527 | Spooler | WS2016 | sin parche | KB / Spooler off | 8.8 | v3.1 | {{URL}} |
| C1 | M5 | CVE-2017-0144 | SMBv1 | Win10 19045 | 1507/1511/1607 | MS17-010 | 8.8 | v3.1 | {{URL}} |
| C4 | M5 | CWE-306 | TightVNC | 2.8.90 | auth None | password/localhost | ~9.8 | ambiental | — |

**Configuraciones:** W4–W7, D2–D4, B3–B4, S3–S5, C2–C3. Ver tabla de hallazgos.

## 6. Hallazgos

Para cada hallazgo, usar [`hallazgo.md`](./hallazgo.md). Mínimo:

- Descripción.
- Impacto.
- Evidencia de validación.
- Referencia NVD/CVE.org.
- A qué máquina permite llegar.
- Remediación.
- Retest.

## 7. Remediación y verificación

| ID | Medida | Versión/config final | Antes | Después | Evidencia |
|---|---|---|---|---|---|
| W1 | WP 7.0.2 | 7.0.2 | `batch/v1` | bloqueado | `EV-W1-antes/despues` |
| W2 | PHP 8.4.27 | 8.4.27 | `X-Powered-By: 8.4.26` | 8.4.27 | `EV-W2-...` |
| W3 | Apache 2.4.51+ | 2.4.51 | 503/200 | 403 | `EV-W3-...` |
| D1 | Redis 6.2.7+ | 6.2.7 | PONG | NOAUTH | `EV-D1-...` |
| B1 | Samba 4.5.10 | 4.5.10 | 4.5.9 | 4.5.10 | `EV-B1-...` |
| S2 | Spooler off | Disabled | Running | Stopped | `EV-S2-...` |
| C4 | VNC auth | password | None | VNC | `EV-C4-...` |

## 8. Conclusiones

- {{LECCIÓN_1}}
- {{LECCIÓN_2}}
- {{LECCIÓN_3}}
- Recomendaciones: {{...}}.

## 9. Anexos

- Capturas fechadas: `informe/evidencias/png/`.
- Logs: `informe/evidencias/logs/`.
- Hashes: `informe/evidencias/hashes.txt`.
- Snapshots: `informe/anexos/c-snapshots.md`.
- Configuraciones: `informe/anexos/d-configuraciones.md`.
- Referencias: `informe/anexos/e-referencias-cve.md`.

## Checklist final

- [ ] 9 secciones completas.
- [ ] Fases 0–7.
- [ ] Cada hallazgo con versión vulnerable y corregida.
- [ ] Cada hallazgo con antes/después.
- [ ] Sin recetas en el informe.
- [ ] Referencias NVD con fecha.
- [ ] Snapshots registrados.
- [ ] Diagrama de red.
