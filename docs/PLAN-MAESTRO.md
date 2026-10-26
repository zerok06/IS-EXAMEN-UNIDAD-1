# Plan maestro · Laboratorio IS-1023

> Documento de contexto y dirección. Las specs ejecutables están en [`../specs/`](../specs/). El informe oficial no lleva este documento ni sus comandos: lleva metodología, impacto y evidencia.
>
> **Proceso oficial:** [`PROCESO-7-FASES.md`](./PROCESO-7-FASES.md). **Plantillas:** [`../templates/`](../templates/).

## 0. Resumen ejecutivo

El laboratorio está **bien montado y documentado**, pero la evaluación de la guía no premia la cantidad de hallazgos: premia **criticidad demostrada, alcance en la red, profundidad por máquina y remediación verificada**. Hoy el proyecto tiene 24 hallazgos, 5/5 máquinas con presencia y una cadena real basada en configuraciones débiles, pero:

- **0 RCE de los CVE estrella** (W1 wp2shell, W2 PHP2Shell, W3 Apache 2.4.49).
- **0 versiones parcheadas**; la remediación fue solo configuración.
- **0 privesc real en M4** desde un acceso limitado.
- Varios CVE del inventario son inválidos o no aplicables (B1, B2, S1, C1).
- El retest y la remediación se contradicen entre documentos.

La corrección no es rehacer el laboratorio: es **convertir “validado” en “explotado con evidencia”**, **“mitigado por configuración” en “parcheado por versión + retest”** y **“documentado” en “demostrable en vivo”**.

## 1. Contexto

### 1.1 Curso y escenario

- **Curso:** IS-1023 Seguridad de la Información · Unidad I · Semana 07.
- **Docente:** Mgr. Juan Carlos Valero Gómez.
- **Entorno:** laboratorio aislado `10.10.10.0/24`, 6 VM + router MitraStar R0, sin Internet mientras los servicios vulnerables están activos.
- **Objetivo:** identificar CVE, reproducirlos, explotarlos, remediarlos y verificar la remediación, con evidencia fechada y réplica en vivo.

### 1.2 Máquinas

| VM | Rol | Concreción |
|---|---|---|
| M1 `.11` | Aplicación | Ubuntu 22.04, Apache 2.4.49, PHP 8.4.26, WordPress 7.0.1, Moodle 5.0.11 |
| M2 `.12` | Base de datos | MariaDB 10.11.19, Redis 6.2.6, SNMP `public/private` |
| M3 `.13` | Respaldos | NFS, Samba 4.5.10, vsftpd 2.3.4, FTP anónimo, `credenciales.txt` |
| M4 `.14` | Windows heredado | WS2016 build 14393, DNS standalone, SMBv1/Spooler, admin débil |
| M5 `.15` | Estación cliente | Win10 19045, SMBv1, RDP sin NLA, VNC 2.8.90 sin clave |
| M6 `.20` | Auditoría | Kali, `nmap`, `wpscan`, `nxc`, MSF, `proxychains`, `ligolo` |
| R0 `.1` | Router | MitraStar, DHCP off, sin DSL, transporte |

### 1.3 Activos existentes

- Arquitectura v4.1 con diagrama, direccionamiento y separación lógica por firewall de host.
- Guías por máquina (`guias/guia-M1…M6`), router y base VMware.
- Informe con las 9 secciones de la guía, inventario de 24 hallazgos y fichas.
- Evidencias en `informe/evidencias/` con logs, capturas y hashes.
- Anexos de snapshots, configuraciones y referencias CVE.
- Playbook de ataque y guion de sustentación.

### 1.4 Qué se demostró y qué no

**Demostrado:** login admin W4, SSH root en M1, Redis sin auth + dump de MariaDB, SNMP, FTP anónimo, NFS `no_root_squash`, S3/S4/S5 en M4, VNC sin clave y marcador en M5.

**No demostrado:** W1, W2, W3, D1 RCE, B1, B2, S1, C1, privesc real M4.

## 2. Evaluación de la guía

### 2.1 Las fases correctas

La guía tiene **8 fases numeradas 0–7**:

| Fase | Nombre | Qué exige |
|---|---|---|
| 0 | Preparación y clonación | Snapshots y clones antes de tocar |
| 1 | Montaje del entorno | 6 VM, servicios y dependencias |
| 2 | Implementación de CVE | ≥3 vulns por máquina, privesc M4 |
| 3 | Reconocimiento, escaneo y enumeración | Hosts, puertos, versiones, CVE |
| 4 | Validación | Explotabilidad real, impacto, alcance, evidencia |
| 5 | Remediación | Parche, reconfiguración o mitigación |
| 6 | Verificación | Mismo comando, antes/después |
| 7 | Informe final y sustentación | Informe, plantillas, diapositivas y réplica |

### 2.2 Mapeo con el proyecto

| Guía | Proyecto | Veredicto |
|---|---|---|
| Fase 0 | Snapshots iniciales, `estado-parcheado` pendiente | Parcial |
| Fase 1 | Montaje completo | Bien |
| Fase 2 | 24 hallazgos, varios inválidos, privesc M4 no real | Parcial |
| Fase 3 | `fases/fase-01` y `fase-02` | Bien |
| Fase 4 | `fases/fase-03`, `fase-04`, `fase-05`; CVE estrella no | Parcial |
| Fase 5 | `fase-06`; solo configuración | Débil |
| Fase 6 | `fase-07`; contradictorio | Inconsistente |
| Fase 7 | Informe y guion; sin deck ni demo ensayada | Parcial |

### 2.3 Las seis brechas

1. **Numeración:** el informe llama “Fase 1” al reconocimiento; la guía llama “Fase 1” al montaje. Renumerar 0–7.
2. **CVE estrella:** W1/W2/W3 no se ejecutaron. Sin `id`/`whoami`, no cuentan como demostrados.
3. **M4:** `Administrador` → tarea SYSTEM no es privesc; la guía pide acceso limitado → administrativo.
4. **CVE inválidos:** B1 (4.5.10 es fix), B2 (tarball limpio), S1 (SMB1 off), C1 (19045 no afectado).
5. **Remediación:** solo configuración; WP/PHP/Apache/Redis tienen versión corregida.
6. **Retest:** `07-retest.md` dice ejecutado y `06-remediacion.md` dice pendiente; versiones sin cambiar.

## 3. Prioridad de vectores

| Prioridad | Vector | Por qué | Probabilidad | Tiempo | Respaldo |
|---|---|---|---|---|---|
| 1 | **W1 wp2shell** (9.8, KEV) | PoC público, sin auth, admin + plugin + RCE | Alta | 1–2 h | W4 |
| 2 | **W4 admin débil → plugin** | Ya validado, 100% reproducible | Muy alta | 30 min | — |
| 3 | **W3 Apache 2.4.49** (9.8) | El 503 es CGI mal configurado; se corrige | Alta | 1–2 h | W1 |
| 4 | **W2 PHP2Shell** (9.8/9.2) | Prestigio técnico; exige prefork/NTS/offsets | Media-baja | 3–4 h | W1/W3 |
| 5 | **M1-SSH root** | Pivote garantizado | Muy alta | 10 min | — |
| 6 | **D2/D3/D4 + Redis sin auth** | Dump de BD y SNMP; D1 10.0 solo con paquete distro | Alta | 1–2 h | — |
| 7 | **B3/B4** | Credenciales de M4/M5 y escritura root | Muy alta | 1 h | — |
| 8 | **S3/S4/S5** | Acceso admin, AXFR, signing | Alta | 1–2 h | — |
| 9 | **S2 PrintNightmare LPE** | Privesc obligatorio; necesita sesión limitada | Media | 2–3 h | Otro LPE |
| 10 | **C2/C4/C3** | Clave reutilizada, VNC, RDP | Muy alta | 1–2 h | — |
| 11 | **B1 Samba 4.5.9** | Bajar a 4.5.9; luego 4.5.10 | Media | 2–3 h | SSH débil |
| 12 | **S1 EternalBlue** | Solo si SMB1 + build sin MS17-010 | Baja | 1 h | S2/S3 |

**Decisión:** W1 primero, W2 en paralelo con time-box, W3 después, W4 como red de seguridad. No poner W2 como único camino.

### 3.1 Por qué W2 no es el primer movimiento

El PoC público de PHP2Shell exige:

- mod_php con **Apache prefork** (no event).
- Probablemente **PHP NTS** (no ZTS).
- `display_errors=1`, `memory_limit=8M`, `session.upload_progress=On`, `max_input_vars=1000`.
- Offsets de `libphp.so` (`zif_system`, `zval_ptr_dtor`, `htdata`) y un comando de máximo 14 bytes.

El build actual es **ZTS + MPM event**, así que tal cual no funciona. W1, en cambio, solo necesita REST API reachable, sin object cache persistente y al menos un post publicado: ya está.

## 4. Plan por fases

### 4.0 Version gate

Cada fase tiene una puerta de versiones. No se avanza si no está claro qué versión está instalada, cuál es el rango vulnerable, cuál es el fix y cómo se verifica. La tabla se completa en [`../templates/version-gate.md`](../templates/version-gate.md) y la fuente de verdad es [`version-matrix.md`](./version-matrix.md).

### Fase 0 · Preparación y snapshots

**Objetivo:** laboratorio aislado, estable, con snapshots, clones, credenciales y kit de evidencia.

**Actividades:**

0. Descargar y verificar los artefactos con la spec [`000-artefactos`](../specs/000-artefactos/); servir por FTP desde M6.
1. Encender R0 y M1–M6; verificar IP, gateway, DNS y `ping` entre máquinas.
2. Verificar que no hay Internet: `ping 8.8.8.8` falla; `curl http://10.10.10.11` responde.
3. Tomar `00-base`, `01-rol-listo` y `estado-inicial-vulnerable` por VM.
4. Clon full de M1–M5 antes de la Fase 2.
5. Crear `~/evidence/{m1,m2,m3,m4,m5,parcheado}` y una sesión `script`.
6. Completar la matriz de credenciales y el registro de snapshots.

**Snapshot:** `00-base`, `01-<rol>-listo`, `estado-inicial-vulnerable`.

**Salida:** red verificada, snapshots y clones, registro completo.

**Spec:** [`specs/001-fase-0-preparacion-snapshots`](../specs/001-fase-0-preparacion-snapshots/).

### Fase 1 · Montaje del entorno

**Objetivo:** servicios por rol y dependencias coherentes.

**Actividades:**

- M1: Apache + PHP + WP + Moodle; DB en M2; NFS en M3.
- M2: MariaDB, Redis, SNMP; backups hacia M3.
- M3: NFS, Samba, vsftpd, `credenciales.txt`.
- M4: DNS standalone, SMBv1/Spooler, `legacy`, admin débil.
- M5: cliente, navegador, SMBv1, RDP sin NLA, VNC sin clave.
- M6: Kali con `nmap`, `wpscan`, `nxc`, MSF, `proxychains`, `ligolo`.
- R0: DHCP off, sin DSL, WPA2, UPnP/WPS off.

**Verificación:** `curl` M1, `DB_OK`, `findmnt -t nfs`, backups en M3, DNS `uni.lab`, puertos M4/M5.

**Salida:** servicios arriba y versiones registradas.

**Spec:** [`specs/002-fase-1-montaje-entorno`](../specs/002-fase-1-montaje-entorno/).

### Fase 2 · Implementación de vulnerabilidades

**Objetivo:** ≥3 vulnerabilidades presentes por máquina, con versión/configuración y evidencia.

**Correcciones clave:**

- **M1:** WP 7.0.1, PHP 8.4.26, Apache 2.4.49, W4 débil, W5–W7. Para W2: mod_php prefork y, si se puede, NTS. Para W3: `mod_cgi` + `ScriptAlias` + `+ExecCGI`.
- **M2:** Redis 6.2.6 **del paquete distro** si se quiere D1; si no, documentar que el build de fuente no es vulnerable. D2/D3/D4.
- **M3:** **Samba 4.5.9**, no 4.5.10; B3/B4; B5 SSH débil si B1/B2 no son reales.
- **M4:** S3 con usuario limitado `soporte` además de admin débil; S2 Spooler; S4/S5; S1 solo si SMB1 y build vulnerable.
- **M5:** C2/C3/C4; C1 solo si el build es vulnerable (19045 no lo es).

**Regla:** si la versión instalada es la que corrige el CVE, se baja o se reemplaza. No se cuenta como vulnerabilidad.

**Salida:** cada máquina con ≥3 vulnerabilidades “presentes” y evidencia de versión/config.

**Spec:** [`specs/003-fase-2-implementacion-vulnerabilidades`](../specs/003-fase-2-implementacion-vulnerabilidades/).

### Fase 3 · Reconocimiento, escaneo y enumeración

**Objetivo:** desde M6, descubrir hosts, puertos, versiones y correlacionar CVE.

**Comandos base:**

```bash
ip -brief a
ping -c 2 10.10.10.11
nmap -sn 10.10.10.0/24
nmap -sV -Pn -p 22,80,443,3306,6379,21,139,445,2049,53,3389,5900 10.10.10.11-15
curl -sI http://10.10.10.11
wpscan --url http://10.10.10.11 --enumerate u
whatweb http://10.10.10.11
nikto -h http://10.10.10.11
dig axfr uni.lab @10.10.10.14
```

**Evidencia:** `F01-*` y `F02-*`; tabla de hosts, puertos y versiones; correlación NVD.

**Salida:** inventario y correlación; desviaciones de firewall documentadas.

**Spec:** [`specs/004-fase-3-reconocimiento-enumeracion`](../specs/004-fase-3-reconocimiento-enumeracion/).

### Fase 4 · Validación, explotación y cadena

**Objetivo:** demostrar explotabilidad, obtener acceso, encadenar a todas las máquinas y medir impacto.

**Orden recomendado:**

1. **M1 · W1 wp2shell:** PoC público → admin → plugin → `id`.
2. **M1 · W4:** login admin → plugin → `id` (respaldo).
3. **M1 · W3:** traversal `/etc/passwd` → RCE `/bin/sh`.
4. **M1 · W2:** con time-box; si falla, documentar.
5. **M1 · SSH:** `ubuntu`/`Admin13.-` → `sudo id` → root.
6. **Pivote:** SSH `-L` o ligolo; ejecutar M4 desde M1.
7. **M2:** Redis sin auth, dump MariaDB, SNMP.
8. **M3:** FTP anónimo, NFS `no_root_squash`, Samba 4.5.9 si aplica.
9. **M4:** S3/S4/S5, S2 LPE desde `soporte`, S1 si aplica.
10. **M5:** C2/C4/C3; C1 no aplica.
11. **Impacto:** marcadores, datos, hashes.

**Regla:** cada exploit con `previo-a-<ID>`; cada éxito con `id`/`whoami`/archivo; cada fallo con limitación y fallback.

**Salida:** 5/5 presencia, al menos un RCE/root real, privesc M4 desde acceso limitado, evidencia.

**Spec:** [`specs/005-fase-4-validacion-explotacion`](../specs/005-fase-4-validacion-explotacion/).

### Fase 5 · Remediación

**Objetivo:** aplicar la medida correcta por hallazgo y registrar el cambio.

**Versiones objetivo:**

- WP 7.0.2; PHP 8.4.27; Apache 2.4.51+; Redis 6.2.7+; Samba 4.5.10+; vsftpd limpio/3.x; WS2016 con MS17-010/Spooler; Win10 con NLA y VNC con clave.
- Configuración: claves únicas, 2FA, UFW, SNMPv3, FTP anónimo off, `root_squash`, AXFR restringido, signing on, LLMNR/NBT-NS off, VNC localhost.

**Regla:** restaurar `estado-inicial-vulnerable` antes de parchear; no parchear el estado comprometido.

**Salida:** registro de cambios, versión/config final, `estado-parcheado`.

**Spec:** [`specs/006-fase-5-remediacion`](../specs/006-fase-5-remediacion/).

### Fase 6 · Verificación y retest

**Objetivo:** repetir exactamente las validaciones de la Fase 4 sobre el estado parcheado y demostrar que ya no funcionan.

**Método:** mismo comando, misma máquina, misma evidencia; antes/después lado a lado; versión/config final; hash.

**Salida:** cada hallazgo cerrado o con riesgo residual; `estado-parcheado`; informe coherente.

**Spec:** [`specs/007-fase-6-verificacion-retest`](../specs/007-fase-6-verificacion-retest/).

### Fase 7 · Informe final y sustentación

**Objetivo:** consolidar el informe, las diapositivas y la réplica en vivo.

**Reglas:**

- Informe con las 9 secciones de la guía y fases 0–7.
- Cada hallazgo: descripción, impacto, evidencia, NVD/CVE.org, CVSS, remediación, retest.
- Sin recetas en el informe oficial; comandos en anexo interno.
- Una diapositiva previa por cada réplica en vivo.
- Demo: restaurar vulnerable → explotar → restaurar parcheado → mostrar fallo.
- Cada integrante explica su máquina.

**Salida:** informe, deck, registro de snapshots, diagrama, demo ensayada.

**Spec:** [`specs/008-fase-7-documentacion-sustentacion`](../specs/008-fase-7-documentacion-sustentacion/).

## 5. Matriz de versiones

| ID | Instalado | Rango vulnerable | Corrige | CVSS | Demostrable |
|---|---|---|---|---|---|
| W1 | WordPress 7.0.1 | 6.9.0–6.9.4 · 7.0.0–7.0.1 | 6.9.5 / 7.0.2 | 9.8 | Sí, PoC público |
| W2 | PHP 8.4.26 | 8.4.x < 8.4.27; 8.2 < 8.2.35; 8.3 < 8.3.36; 8.5 < 8.5.12 | 8.4.27 | 9.8 v3.1 / 9.2 v4.0 | Con prefork/NTS/offsets |
| W3 | Apache 2.4.49 | 2.4.49 (41773); 2.4.50 (42013) | 2.4.50 / 2.4.51+ | 9.8 | Sí, corrigiendo CGI |
| D1 | Redis 6.2.6 fuente | paquete Debian/Ubuntu 5.0–5.0.14, 6.0–6.0.16, 6.2–6.2.6 | 5.0.15 / 6.0.17 / 6.2.7 | 10.0 | Solo con paquete distro |
| B1 | Samba 4.5.10 | 3.5.0–4.6.3, 4.5.0–4.5.9, 4.4.0–4.4.13 | 4.6.4 / 4.5.10 / 4.4.14 | 9.8 | Bajar a 4.5.9 |
| B2 | vsftpd 2.3.4 limpio | tarball troyanizado 2011-06-30…07-03 | 2.3.4 limpio / 3.x | 9.8 | Solo con binario troyanizado |
| S1 | WS2016 14393 | WS2016 sin MS17-010; Win10 1507/1511/1607 | MS17-010 | 8.8 | Condicional |
| S2 | WS2016 Spooler | builds bajo umbral | KB / Spooler off | 8.8 | Check sí; LPE real pendiente |
| C1 | Win10 19045 | solo 1507/1511/1607 | MS17-010 | 8.8 | No aplica |
| C4 | TightVNC 2.8.90 | configuración | password + localhost + FW | ~9.8 ambiental | Sí |

> NVD consultado el **2026-10-26**. W1 y W3 son **9.8**, no 7.5. No mezclar métricas.

La tabla ampliada, con URLs y comandos de verificación, está en [`version-matrix.md`](./version-matrix.md).

## 6. Plan por vulnerabilidad

| ID | Explotación | Snapshot | Evidencia | Remediación | Retest |
|---|---|---|---|---|---|
| W1 | PoC wp2shell → admin → plugin → `id` | `previo-a-W1` | batch, admin, plugin, `uid=33` | WP 7.0.2 + bloquear `/batch/v1` | PoC falla; `wp core version` 7.0.2 |
| W2 | PoC 109618 → `id` | `previo-a-W2`, `previo-a-W2-rebuild` | OOM, cookie, `p1.txt` | PHP 8.4.27 + `upload_progress=Off` temporal | Header 8.4.27; PoC falla |
| W3 | Traversal + RCE `/bin/sh` | `previo-a-W3` | `root:x:0:0`, `uid=` | Apache 2.4.51+ + denegar CGI | 403/404 |
| W4 | Login + plugin + `id` | `previo-a-W4` | 302 + cookie, plugin | Clave fuerte + 2FA | Login viejo falla |
| M1-SSH | `ssh` + `sudo id` | `previo-a-SSH` | `uid=0(root)` | Clave única, sudo restringido | SSH viejo falla |
| D1 | `redis-cli` + PoC Lua (distro) | `previo-a-D1` | `PONG`, `INFO`, `id` | Redis 6.2.7+ + requirepass | `NOAUTH` |
| D2/D3/D4 | Dump, `nmap`, `snmpwalk` | `previo-a-M2` | 12/487 tablas, puertos, SNMP | Claves únicas, UFW, SNMPv3 | Login viejo falla |
| B1 | Samba 4.5.9 + SambaCry | `previo-a-B1` | `smbd --version`, shell | Samba 4.5.10+ | `smb-vuln*` limpio |
| B2 | Binario troyanizado + `nc 6200` | `previo-a-B2` | banner, shell | 2.3.4 limpio / 3.x | `:6200` cerrado |
| B3/B4 | FTP anónimo, NFS | `previo-a-B3` | `credenciales.txt`, archivo root | Anónimo off, `root_squash` | `530`; denegado |
| S1 | SMB1 + EternalBlue | `previo-a-S1` | `smb-vuln-ms17-010` | MS17-010 + SMB1 off | Limpio |
| S2 | `soporte` + PrintNightmare local | `previo-a-S2` | `whoami` SYSTEM | KB + Spooler off | PoC falla |
| S3 | `nxc smb` admin débil | `previo-a-S3` | `Pwn3d!`, shares | Clave larga/LAPS | `nxc` denegado |
| S4/S5 | AXFR, signing | `previo-a-S4` | Zona, signing disabled | AXFR restringido, signing on | `REFUSED` |
| C2 | `nxc smb` clave reutilizada | `previo-a-C2` | Acceso, shares | Clave única | `nxc` denegado |
| C3 | `xfreerdp` sin NLA | `previo-a-C3` | Escritorio | NLA on | NLA requerido |
| C4 | `vncviewer` sin clave | `previo-a-C4` | Escritorio, `whoami` | Password + localhost/FW | Pide clave |
| W5–W7 | `server-status`, `info.php`, `uploads` | `previo-a-W5` | 200, Index of | Restringir, borrar, `-Indexes` | 403/404 |

> **Flujo por vulnerabilidad:** [`specs/005-fase-4-validacion-explotacion/vulns/`](../specs/005-fase-4-validacion-explotacion/vulns/). **Revalidación de versiones:** [`VALIDACION-VULNERABILIDADES.md`](./VALIDACION-VULNERABILIDADES.md): 22 demostrables, 2 no reproducibles (D1, B2) y 2 no aplicables (S1, C1).

## 7. Snapshots

Resumen; el procedimiento completo está en [`snapshots.md`](./snapshots.md).

| Snapshot | Cuándo | Para qué |
|---|---|---|
| `00-base` | SO + red | Punto cero |
| `01-<rol>-listo` | Servicios instalados | Reinstalar rápido |
| `estado-inicial-vulnerable` | Vulns + red verificadas | Demo y reintentos |
| `previo-a-<ID>` | Antes de cada PoC | Rollback |
| `estado-comprometido` | Tras impacto (opcional) | Mostrar el “antes” |
| `estado-parcheado` | Tras Fase 5 + retest | Mostrar el “después” |

**Regla:** restaurar `estado-inicial-vulnerable` antes de parchear. No parchear el estado comprometido.

## 8. Remediación y retest

- Cada hallazgo tiene una medida en [`specs/006-fase-5-remediacion`](../specs/006-fase-5-remediacion/).
- Cada hallazgo tiene un retest con el mismo comando en [`specs/007-fase-6-verificacion-retest`](../specs/007-fase-6-verificacion-retest/).
- Si no se puede actualizar la versión, se documenta la mitigación compensatoria y el riesgo residual.
- No se declara “parcheado” si solo se bloqueó una ruta.

## 9. Informe y sustentación

Checklist mínimo:

- [ ] Fases 0–7 renumeradas.
- [ ] 24 hallazgos con estado real (validado/parcial/no aplica).
- [ ] B1/B2/S1/C1 retirados o marcados.
- [ ] M4 con privesc desde acceso limitado.
- [ ] Versiones corregidas y retest.
- [ ] Evidencia antes/después por hallazgo.
- [ ] Registro de snapshots completo.
- [ ] Diagrama de red y direccionamiento.
- [ ] Referencias NVD/CVE.org con fecha.
- [ ] Sin recetas en el informe oficial.
- [ ] Diapositivas con slide previa por réplica.
- [ ] Demo ensayada y con fallbacks.

## 10. Cronograma

| Momento | Actividad | Salida |
|---|---|---|
| Día 0 (2–3 h) | Encender, verificar red, snapshots, clones, kit de evidencia | Lab congelado |
| Día 1 (6–8 h) | M1: W1, W4, W3, W2 time-box; pivote; M2 | M1 con shell/root; M2 con dump |
| Día 2 (6–8 h) | M3: B3/B4 + B1 4.5.9 o SSH; M4: S3/S4/S5 + S2 LPE; M5: C2/C4/C3; marcadores | 5/5 y privesc M4 |
| Día 3 (4–6 h) | Restaurar vulnerable, parches de versión, retest, `estado-parcheado`, informe | Antes/después |
| Día 4 (2–3 h) | Diapositivas, ensayo, snapshots, checklist | Sustentación lista |

## 11. Riesgos y decisiones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| W2 no reproduce | Se pierde la demo estrella | Time-box; W1/W4/W3 de respaldo |
| M4 PrintNightmare falla | No se cumple privesc | Usar `soporte` + módulo local; probar otro LPE |
| Samba 4.5.9 no compila | B1 no se demuestra | Usar SSH débil como tercera vuln de M3 |
| El retest se contradice | Pérdida de credibilidad | Una sola fuente de verdad; actualizar todo |
| El informe lleva recetas | Penalización | Mover comandos al anexo interno |
| Las versiones no se actualizan | Penalización en remediación | Parchear WP/PHP/Apache/Redis |

**Decisiones vigentes:** W1 principal; W2 time-box; M4 con `soporte`; M3 con Samba 4.5.9; upgrades de versión; informe renumerado.
