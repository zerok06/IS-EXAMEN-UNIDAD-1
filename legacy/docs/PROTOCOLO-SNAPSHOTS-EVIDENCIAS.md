# Protocolo de snapshots y evidencias

> Regla: **ningún PoC ni cambio de versión se ejecuta sin snapshot y sin evidencia**. El auditor avisa el punto de parada; el dueño de la VM toma el snapshot en VMware y confirma. El auditor no puede tomar snapshots por SSH.

## 1. Flujo de trabajo por punto de parada

```text
Auditor: "PAUSA · snapshot <nombre> en <VM>"
Dueño:   VMware → VM → Snapshot → Take Snapshot → nombre real + fecha UTC
Dueño:   confirma "listo, nombre real = <...>"
Auditor: verifica estado → ejecuta comando con capture.sh → muestra salida
Auditor: guarda LOG + PNG + SHA256 y actualiza el registro
```

Sin la confirmación del snapshot, el auditor **no ejecuta** el PoC.

## 2. Puntos de parada y snapshots

| # | Cuándo | VM | Nombre lógico | Contenido que debe tener | Bloquea |
|---|---|---|---|---|---|
| P0 | Antes de seguir | M1 | `estado-inicial-vulnerable` | WP 7.0.1, PHP 8.4.26, Apache 2.4.49, BD OK, W1/W5/W6/W7 abiertas | W1 |
| P0 | Antes de seguir | M2 | `estado-inicial-vulnerable` | Redis 6.2.6 sin auth, MariaDB, 6379 y 161/UDP | D2–D4 |
| P1 | Antes de bajar Samba | M3 | `previo-a-B1` | Samba 4.5.10 actual, FTP anónimo, NFS `no_root_squash` | B1 |
| P2 | Antes de crear `soporte` | M4 | `previo-a-alta-soporte` | SMB1 on, signing off, Spooler on, admin `password_2026` | S2 |
| P3 | Tras instalar Samba 4.5.9 | M3 | `estado-inicial-vulnerable` | `smbd --version` = 4.5.9 + B3/B4/B5 | Fase 4 M3 |
| P4 | Tras crear `soporte` limitado | M4 | `estado-inicial-vulnerable` | `soporte` sin privilegios + S3/S4/S5 | S2 |
| P5 | Justo antes de W1 | M1 | `previo-a-W1` | Estado P0 verificado | W1 |
| P6 | Antes de tocar CGI | M1 | `previo-a-W3` | Apache 2.4.49 con CGI actual | W3 |
| P7 | Antes del rebuild PHP | M1 | `previo-a-W2` | PHP 8.4.26 ZTS/event actual | W2 |
| P8 | Antes de PrintNightmare | M4 | `previo-a-S2` | `soporte` ya creado + sesión limitada verificada | S2 |
| P9 | Antes de C2/C3/C4 | M5 | `previo-a-C2/C3/C4` | M5 vulnerable y accesible | M5 |
| P10 | Tras Fase 5 + retest Fase 6 | M1–M5 | `estado-parcheado` | Versión ≥ fix + PoC fallando | Demo |
| P11 | Tras instalar herramientas | M6 | `01-rol-listo` | `pyftpdlib`, `capture.sh`, artefactos | Evidencias |

**M3 y M4 no tienen todavía su `estado-inicial-vulnerable` definitivo** porque les falta un cambio de Fase 2 (Samba 4.5.9 y usuario `soporte`). Por eso primero se toma el `previo-a-*` y después el de oro.

**M5:** no se toma snapshot "vulnerable" hasta comprobar que sus puertos responden. Hoy está arriba a nivel ARP pero con 445/3389/5900/5985 filtrados.

## 3. Evidencia por comando

Cada comando que sustenta el informe se ejecuta con una sola herramienta:

```bash
cd /home/kali/IS-EXAMEN-UNIDAD-1
./informe/tools/capture.sh <ID> "<título>" '<comando simple>'
```

Produce:

| Artefacto | Ruta | Uso |
|---|---|---|
| LOG completo | `informe/evidencias/logs/<ID>.log` | Salida real, fecha UTC y comando |
| Captura | `informe/evidencias/png/<ID>.png` | Prueba visual para el informe |
| Hash | se agrega a `informe/evidencias/hashes.txt` | Integridad |

Comandos remotos legibles y replicables:

```bash
./informe/tools/vm.sh m1 'wp core version --allow-root --path=/var/www/wp'
./informe/tools/vm.sh m2 'redis-cli INFO server | grep redis_version'
./informe/tools/vm.sh m3 '/usr/local/samba/sbin/smbd --version'
```

Después de cada captura:

```bash
cd informe
sha256sum evidencias/logs/<ID>.log evidencias/png/<ID>.png >> evidencias/hashes.txt
```

## 4. Capturas mínimas por vulnerabilidad

| ID | Qué debe verse en la captura | Comando base |
|---|---|---|
| W1-01 | Versión 7.0.1 y `POST /wp-json/batch/v1` = 400 | `wp core version`; `curl` |
| W1-02 | `Target is vulnerable` del PoC en modo `--check` | `python3 wp2shell... --check` |
| W1-03 | Administrador creado y verificado | PoC sin `--check` |
| W1-04 | Plugin `lab-shell` activo | `wp plugin list` o UI |
| W1-05 | `uid=33(www-data)` | `curl ...?c=id` |
| W1-06 | Marcador `PWNED-M1` servido por HTTP | `echo` + `curl` |
| W3-01 | Traversal / RCE con `uid=` | `curl --path-as-is` |
| B1-01 | `smbd --version` 4.5.9 y shell | `smbd --version`; MSF |
| S2-01 | `whoami` = `srvold\soporte` antes | `nxc winrm -X whoami` |
| S2-02 | `whoami` = `nt authority\system` después | MSF local |
| C4-01 | VNC sin clave o escritorio | `vncviewer` |

Para cada una: `LOG` + `PNG` + hash. Sin el par log/captura no se cierra el hallazgo.

## 5. Qué va en el informe y qué va al anexo interno

| Contenido | Informe oficial | Anexo interno |
|---|---|---|
| Metodología, impacto, versión, CVE, CVSS | Sí | — |
| Resultado (`uid=`, `whoami`, marcador) | Sí, resumido | Sí, completo |
| Comandos de exploit y PoCs | **No** | Sí |
| Salidas completas y capturas | Referencia `EV-*` | Sí |
| Credenciales | **No** | Solo si son ficticias y necesarias |

## 6. Registro

- Snapshots: [`../informe/anexos/c-snapshots.md`](../informe/anexos/c-snapshots.md) (nombre real de VMware, fecha UTC, propósito, responsable).
- Evidencias: [`../informe/anexos/b-indice-evidencias.md`](../informe/anexos/b-indice-evidencias.md) y `hashes.txt`.
- Estado operativo: [`../MEMORY.md`](../MEMORY.md).

## 7. Reglas

1. Snapshot en frío o con servicios detenidos; nunca a mitad de un PoC.
2. No sobrescribir `estado-inicial-vulnerable` ni `estado-parcheado`.
3. Para parchear: restaurar `estado-inicial-vulnerable`, no el estado comprometido.
4. Nombres reales mapeados; si VMware usa `snapshot1`, se anota.
5. Si un comando falla, se captura el fallo y se documenta la limitación; no se inventa salida.
6. La captura se toma con la ventana limpia y el comando visible.
