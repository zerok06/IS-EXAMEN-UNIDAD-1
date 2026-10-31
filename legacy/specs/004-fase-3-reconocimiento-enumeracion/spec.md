# Spec 004 · Fase 3 · Reconocimiento, escaneo y enumeración

## Metadata

| Campo | Valor |
|---|---|
| ID | `004` |
| Fase guía | 3 |
| Nombre | Reconocimiento, escaneo y enumeración desde M6 |
| Estado | `lista` |
| Dueño | Auditor M6 + dueños de VM |
| Dependencias | `003` |
| Specs relacionadas | `005` |
| Fuente | Guía §8 Fase 3; `docs/PLAN-MAESTRO.md` §4 |

## 1. Propósito

Confirmar desde fuera los hosts, puertos, servicios y versiones, y **correlacionar cada servicio con su CVE/CWE** antes de explotar.

## 2. Alcance

**Incluye:** descubrimiento, escaneo de puertos, versiones, enumeración web/SMB/DNS/NFS/FTP, correlación NVD y evidencia.

**No incluye:** explotación, cambios de configuración, remediación.

## 3. Actores y precondiciones

- Actores: M6, dueños de VM, coordinador.
- Precondiciones: `estado-inicial-vulnerable`; red aislada; M6 con herramientas.

## 3.1 Version gate

| Servicio | Comando | Esperado |
|---|---|---|
| WordPress | `wpscan --url http://10.10.10.11` | 7.0.1 |
| PHP | `curl -sI http://10.10.10.11` | `PHP/8.4.26` |
| Apache | `curl -sI http://10.10.10.11` | `Apache/2.4.49` |
| Redis | `redis-cli -h 10.10.10.12 INFO server` | 6.2.6 |
| Samba | `nmap -sV -p445 10.10.10.13` | 4.5.9/4.5.10 |
| vsftpd | `nc 10.10.10.13 21` | `220 (vsFTPd 2.3.4)` |
| Windows | `nmap -sV -p445 10.10.10.14` | WS2016 14393 |
| VNC | `nmap --script vnc-info -p5900 10.10.10.15` | 2.8.90 / auth None |

## 4. Requisitos EARS

- **REQ-004-01 (Evento).** CUANDO se inicie el reconocimiento, M6 DEBE descubrir los hosts activos de `10.10.10.0/24`.
  - Verificación: `nmap -sn 10.10.10.0/24`; tabla de hosts.
- **REQ-004-02 (Ubicuo).** M6 DEBE identificar puertos y servicios de M1–M5.
  - Verificación: `nmap -sV -Pn -p ... 10.10.10.11-15`.
- **REQ-004-03 (Ubicuo).** M6 DEBE identificar versiones de Apache/PHP/WordPress, MariaDB/Redis, Samba/vsftpd, DNS/SMB y VNC/RDP.
  - Verificación: `curl -sI`; `wpscan`; `redis-cli INFO`; `smbd --version`; `dig`; `nmap --script`.
- **REQ-004-04 (Ubicuo).** Cada servicio DEBE correlacionarse con un CVE/CWE y una fuente NVD/CVE.org.
  - Verificación: tabla de correlación.
- **REQ-004-05 (Ubicuo).** M6 DEBE enumerar WordPress (`u`, `vp`, `vt`), SMB (`shares`, `users`), DNS (`AXFR`), NFS (`showmount`) y FTP (`anonymous`).
  - Verificación: `wpscan`, `smbclient`, `dig axfr`, `showmount`, `ftp`.
- **REQ-004-06 (No deseado).** SI M6 alcanza M2–M5 directamente, ENTONCES el laboratorio DEBE documentar la desviación de firewall y corregirla en Fase 5.
  - Verificación: `nmap` directo vs vía pivote.
- **REQ-004-07 (Ubicuo).** Cada comando DEBE tener captura fechada, log y SHA256.
  - Verificación: `EV-004-*`, `LOG-004-*`, `hashes.txt`.
- **REQ-004-08 (No deseado).** SI un host no responde, ENTONCES el laboratorio DEBE documentar el filtrado y no asumir que está caído.
  - Verificación: `nmap` con estado `filtered`.
- **REQ-004-09 (Estado).** MIENTRAS se esté en Fase 3, el laboratorio NO DEBE explotar ni modificar servicios.
  - Verificación: revisión de la bitácora; solo comandos read-only.

## 5. Criterios de aceptación

- [ ] Inventario de hosts.
- [ ] Matriz de puertos/servicios/versiones.
- [ ] Correlación CVE/CWE por servicio.
- [ ] Enumeración web/SMB/DNS/NFS/FTP.
- [ ] Desviaciones de firewall documentadas.
- [ ] Evidencias con hash.
- [ ] Version gate: fingerprint externo de cada versión.

## 6. Trazabilidad

| REQ | Test/evidencia | Tarea |
|---|---|---|
| REQ-004-01 | `EV-004-01` | T-004-01 |
| REQ-004-02 | `EV-004-02` | T-004-02 |
| REQ-004-03 | `EV-004-03` | T-004-03 |
| REQ-004-04 | `version-matrix.md` | T-004-04 |
| REQ-004-05 | `EV-004-05` | T-004-05 |
| REQ-004-06 | `EV-004-06` | T-004-06 |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| `nmap -sV` da timeout en M1 | `-Pn` + `--host-timeout 30s` |
| WPScan sin API token | Correlacionar a mano con NVD |
| M4/M5 filtrados | Documentar y usar pivote |
| Falso positivo de versión | Confirmar con banner/CLI |

## 8. Fuera de alcance

- Explotar.
- Cambiar configuración.
- Parchear.
