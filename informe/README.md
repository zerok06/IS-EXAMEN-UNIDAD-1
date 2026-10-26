# Informe · Laboratorio de servicios vulnerables

> **Capa SDD (2026-10-26):** el proceso de 7 fases + informe, el plan maestro, las specs 0–7, las plantillas y los tests están en [`../AGENTS.md`](../AGENTS.md), [`../docs/PROCESO-7-FASES.md`](../docs/PROCESO-7-FASES.md), [`../docs/`](../docs/), [`../specs/`](../specs/) y [`../templates/`](../templates/). Este informe sigue siendo la Capa A; las brechas detectadas están en [`../docs/evaluacion-guia.md`](../docs/evaluacion-guia.md) y se corrigen en las specs `006`–`008`.

**Curso:** IS-1023 Seguridad de la Información · Unidad I · Semana 07
**Grupo:** _(completar)_
**Entorno:** LAN aislada `10.10.10.0/24` · 6 VM (M1–M6) + router R0
**Fecha de inicio de evidencias:** 2026-10-24
**Estación de auditoría:** M6 Kali `10.10.10.20`

---

## 1. Qué contiene esta carpeta

Esta carpeta tiene **dos capas** para cumplir la guía sin mezclar el informe con recetas:

### Capa A · Informe oficial (entregable, secciones 1–9)

| Archivo | Sección de la guía |
|---|---|
| `00-portada.md` | 1. Carátula |
| `01-resumen-ejecutivo.md` | 2. Resumen ejecutivo |
| `02-arquitectura-red.md` | 3. Arquitectura del entorno |
| `03-metodologia.md` | 4. Metodología |
| `04-inventario-vulnerabilidades.md` | 5. Inventario de vulnerabilidades |
| `05-hallazgos.md` | 6. Hallazgos |
| `06-remediacion.md` | 7. Remediación |
| `07-retest.md` | 7. Verificación (antes/después) |
| `08-conclusiones.md` | 8. Conclusiones |
| `09-anexos.md` | 9. Anexos |

### Capa B · Anexo técnico interno (comandos y bitácora)

| Carpeta | Contenido |
|---|---|
| `fases/` | Las 7 fases del ataque, con comandos simples, explicación, salida real y evidencia |
| `servidores/` | Dossier por máquina: rol, servicios, vulnerabilidades, acceso y parche |
| `hallazgos/` | Ficha completa por vulnerabilidad (W1–W7, D1–D4, B1–B4, S1–S5, C1–C4) |
| `anexos/a-bitacora-comandos/` | Registro `CMD-...`: comando → explicación → salida → captura → hash |
| `anexos/b-indice-evidencias.md` | Índice de capturas y logs con SHA256 |
| `anexos/c-snapshots.md` | Registro de instantáneas |
| `anexos/d-configuraciones.md` | Configuraciones clave (antes/después) |
| `anexos/e-referencias-cve.md` | NVD / CVE.org / KEV / EPSS con fecha de consulta |
| `evidencias/` | `png/`, `logs/`, `hashes.txt` |

> **Regla:** los comandos del informe se describen a nivel metodológico. Los comandos exactos viven en `fases/`, `servidores/` y `anexos/a-bitacora-comandos/`.

---

## 2. Criterio de comandos: simples, sustanciosos y reproducibles

Cada comando debe poder escribirse en vivo, en una línea, y producir una salida clara. Ejemplos:

```bash
curl -sI http://wp.uni.lab
curl --path-as-is 'http://wp.uni.lab/%2e/cgi-bin/.%2e/%2e%2e/etc/passwd'
redis-cli -h 10.10.10.12 PING
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt
nxc smb 10.10.10.14 -u Administrator -p '<clave>' -x whoami
vncviewer 10.10.10.15
dig axfr uni.lab @10.10.10.14
```

No se usan en la exposición comandos como `nmap -p-`, `-sS -sV -O --min-rate`, módulos de Metasploit ni PoCs de cientos de líneas. Esos quedan como **evidencia ampliada** en la bitácora interna, ya ejecutados y capturados.

**Formato de cada comando:**

1. Qué hace y por qué.
2. Comando exacto (una línea si es posible).
3. Salida esperada.
4. **Salida real** (copiada del log, nunca inventada).
5. Evidencia (`EV-...png` + `LOG-...txt`).
6. Interpretación: qué demuestra y a qué máquina permite llegar.

---

## 3. Estado actual de la evidencia

| ID | Fase | Qué demuestra | Log | Captura | Estado |
|---|---|---|---|---|---|
| F01-001 | 1 | Identidad y red de M6 | `F01-001.log` | `F01-001.png` | ✅ |
| F01-002 | 1 | DNS `uni.lab` | `F01-002.log` | `F01-002.png` | ✅ |
| F01-003 | 1 | Cabeceras HTTP de M1 | `F01-003.log` | `F01-003.png` | ✅ |
| F01-004 | 1 | Fingerprint Apache/PHP/WP | `F01-004.log` | `F01-004.png` | ✅ |
| F01-005 | 1 | Descubrimiento de hosts | `F01-005.log` | `F01-005.png` | ✅ |
| F01-006 | 1 | M1: `ping` sí, `nmap -sn` no | `F01-006.log` | `F01-006.png` | ✅ |
| F02-001 | 2 | Puertos M2–M5 | `F02-001.log` | `F02-001.png` | ✅ |
| F02-001b | 2 | Puertos M1 | `F02-001b.log` | `F02-001b.png` | ✅ |
| F02-002 | 2 | `nmap -sV` M1 | `F02-002.log` | `F02-002.png` | ✅ |
| F02-003 | 2 | WPScan parcial | `F02-003.log` | `F02-003.png` | ⚠️ interrumpido |
| F02-003b | 2 | WP 7.0.1 + `usc-admin` | `F02-003b.log` | `F02-003b.png` | ✅ |
| F02-004 | 2 | W5/W6/W7 | `F02-004.log` | `F02-004.png` | ✅ |
| F03-001 | 3 | W1 ruta + login W4 | `F03-001.log` | `F03-001.png` | ✅ |
| F03-002 | 3 | W3 403/503 | `F03-002.log` | `F03-002.png` | ⚠️ no explotable |
| F04-000 | 3/4 | SSH a M1 | `F04-000.log` | `F04-000.png` | ✅ |
| F04-000b | 3/4 | M1 root por sudo | `F04-000b.log` | `F04-000b.png` | ✅ |
| F04-001 | 4 | Redis sin auth | `F04-001.log` | `F04-001.png` | ✅ |
| F04-001b | 4 | Redis datos + CVE-2022-0543 | `F04-001b.log` | `F04-001b.png` | ⚠️ RCE no |
| F04-002 | 4 | FTP anónimo + credenciales | `F04-002.log` | `F04-002.png` | ✅ |
| F04-003 | 4 | MariaDB por túnel | `F04-003.log` | `F04-003.png` | ✅ |
| F04-004 | 4 | `wp-config.php` | `F04-004.log` | `F04-004.png` | ✅ |
| F04-004b | 4 | Moodle 487 tablas | `F04-004b.log` | `F04-004b.png` | ✅ |
| F04-005 | 4 | SMB shares M3 | `F04-005.log` | `F04-005.png` | ✅ |
| F04-006 | 4 | NFS `no_root_squash` | `F04-006.log` | `F04-006.png` | ✅ |
| F04-008 | 4 | M5 VNC sin auth | `F04-008.log` | `F04-008.png` | ✅ |
| F04-009 | 4 | M5 escritorio VNC | `F04-009.log` | `F04-009.png` | ✅ |
| F04-010 | 4 | M5 interacción remota | — | `F04-010.png` | ✅ |
| F04-011 | 4 | M5 `whoami` en consola | — | `F04-011.png` | ✅ |
| F05-001 | 5 | M5 marcador `PWNED-M5` | — | `F05-001.png` | ✅ |
| F04-007 | 4 | M5 SMB autenticado por túnel | `F04-007.log` | `F04-007.png` | ✅ |
| F04-012 | 4 | M4 AXFR (S4) | `F04-012.log` | `F04-012.png` | ✅ |
| F04-013 | 4 | M4 signing desactivado (S5) | `F04-013.log` | `F04-013.png` | ✅ |
| F04-014 | 4 | M4 auth fallida `Admin13.-` | `F04-014.log` | `F04-014.png` | ⚠️ clave no válida |
| F05-002 | 5 | M1 marcador en uploads | `F05-002.log` | `F05-002.png` | ✅ |
| F04-015 | 4 | M4 admin `Administrador`/`password_2026` (S3) | `F04-015.log` | `F04-015.png` | ✅ |
| F04-016 | 4 | M4 PrintNightmare check vulnerable / run sin sesión (S2) | `F04-016.log` | `F04-016.png` | 🟡 |
| F04-017 | 4 | M4 SYSTEM vía tarea programada (WinRM) | `F04-017.log` | `F04-017.png` | ✅ |
| F05-003 | 5 | M4 marcador en `LegacyShare` | `F05-003.log` | `F05-003.png` | ✅ |
| F05-003b | 5 | M4 `PWNED-M4.txt` leído por SMB | `F05-003b.log` | `F05-003b.png` | ✅ |
| F07-001 | 7 | Retest M1: W1/W2/W3/W5/W6/W7 | `F07-001.log` | `F07-001.png` | 🟡 versiones sin cambiar |
| F07-002 | 7 | Retest M3: B2/B3/B4 | `F07-002.log` | `F07-002.png` | ✅ |
| F07-003 | 7 | Retest M4: S1/S2/S3/S4/S5 | `F07-003.log` | `F07-003.png` | ✅ |
| F07-004 | 7 | Retest M5: VNC/SMB/RDP | `F07-004.log` | `F07-004.png` | ✅ |
| F04-018 | 4 | M2: D1/D2/D3 validados | `F04-018.log` | `F04-018.png` | ✅ |
| F04-019 | 4 | M2: D4 (`public`/`private`) | `F04-019.log` | `F04-019.png` | ✅ |
| F06-008 | 6 | M2: mitigación D1/D2/D3/D4 | `F06-008.log` | `F06-008.png` | ✅ |
| F07-005 | 7 | Retest M2 | `F07-005.log` | `F07-005.png` | ✅ |

> Mitigación aplicada por **configuración + endurecimiento** en M1/M2/M3/M4/M5. **Versiones no cambiadas** en ningún servicio. W4 y M1-SSH sin rotación: requieren dueño. Claves nuevas de M2/M4/M5 son de laboratorio (ver logs).
>
> Las capturas están en `evidencias/png/`; los logs completos en `evidencias/logs/`. El manifiesto SHA256 está en `evidencias/hashes.txt` y el índice en `anexos/b-indice-evidencias.md`.

---

## 4. Convenciones

- `W1…W7` = vulnerabilidades de M1; `D1…D4` M2; `B1…B4` M3; `S1…S5` M4; `C1…C4` M5.
- `CMD-F0X-NNN` = comando de la fase X.
- `EV-F0X-NNN` = captura de la fase X.
- `LOG-F0X-NNN` = log completo de la fase X.
- Horas en **UTC**.
- Snapshots: `estado-inicial-vulnerable`, `previo-a-<ID>`, `estado-parcheado`.

---

## 5. Reglas del laboratorio

- Solo se trabaja sobre `10.10.10.0/24`, máquinas del propio grupo.
- La red vulnerable no debe tener salida a Internet durante la explotación.
- Nada de DoS, ransomware, borrado de backups ni datos reales.
- La fase de “cubrir huellas” se documenta **solo en el anexo interno** y se prueba sobre un log de prueba con snapshot; no se borran logs reales.
- Todo hallazgo sin evidencia fechada no cuenta.
