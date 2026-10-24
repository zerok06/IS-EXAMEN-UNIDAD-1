# 4. Metodología

**Enfoque:** ciclo de gestión de vulnerabilidades sobre un laboratorio aislado y autorizado, con evidencia fechada y comandos reproducibles.

---

## 4.1 Fases seguidas

| Fase | Nombre | Qué se hizo | Evidencia |
|---|---|---|---|
| 0 | Preparación y snapshots | Inventario, red, versiones, snapshots | `anexos/c-snapshots.md` |
| 1 | Reconocimiento | DNS, cabeceras, fingerprint, hosts | `fases/fase-01` |
| 2 | Escaneo y enumeración | Puertos, versiones, WordPress, W5–W7 | `fases/fase-02` |
| 3 | Acceso inicial | W1 fingerprint, W4 login, W3 limitación, SSH/root | `fases/fase-03` |
| 4 | Movimiento lateral | Pivote, M2 Redis/MariaDB, M3 FTP/NFS | `fases/fase-04` |
| 5 | Impacto | Marcadores, volcados, logs | ⬜ pendiente |
| 6 | Mitigación | Parches y reconfiguración | ⬜ pendiente |
| 7 | Retest | Repetición de validaciones | ⬜ pendiente |

Las fases 1–7 de la guía se corresponden con la cadena de ataque: reconocimiento → escaneo → acceso → lateral → impacto → mitigación → retest.

---

## 4.2 Herramientas de Kali utilizadas

| Herramienta | Uso | Evidencia |
|---|---|---|
| `nmap` | Descubrimiento, puertos, versiones, scripts SMB/VNC | `F01-005`, `F02-001`, `F02-002` |
| `curl` | Cabeceras, wp-json, W5/W6/W7, login W4, FTP | `F01-003`, `F02-004`, `F03-001`, `F04-002` |
| `whatweb` | Fingerprint web | `F01-004` |
| `wpscan` | Versión y usuarios de WordPress | `F02-003b` |
| `dig` | DNS interno | `F01-002` |
| `sshpass` / `ssh` | Acceso y pivote a M1 | `F04-000` |
| `redis-cli` | Redis sin auth y versión | `F04-001` |
| `mysql` / `mariadb` | BD por túnel SSH | `F04-003` |
| `smbclient` | Shares de M3 | `F04-005` |
| `showmount` / `mount` | NFS y `no_root_squash` | `F04-006` |
| `nc` | FTP/backdoor y puertos | F04 manual |
| `nxc` | SMB Windows (pendiente M4/M5) | — |
| `vncviewer` / `xfreerdp` | Escritorio M5 (pendiente) | — |
| `metasploit` | EternalBlue/PrintNightmare (pendiente) | — |

---

## 4.3 Estilo de los comandos

- **Demo:** una línea, flags mínimos, salida clara; se puede teclear en vivo.
- **Evidencia:** el mismo comando con `tee`/captura y log completo.
- No se usan en la exposición `nmap -p-`, `-sS -sV -O`, PoCs de cientos de líneas ni módulos MSF sin explicación.
- Cada comando tiene: propósito, salida esperada, salida real, evidencia e interpretación.

---

## 4.4 Criterios de evidencia

1. Captura de terminal con fecha/hora y comando visible.
2. Log completo en `evidencias/logs/`.
3. SHA256 en `evidencias/hashes.txt`.
4. Referencia al CVE/debilidad y a la fase.
5. Si no se pudo ejecutar, se marca `⬜` y se explica la causa; no se inventa.

---

## 4.5 Ética y alcance

- Solo `10.10.10.0/24`, VM del grupo, con autorización del docente.
- Sin Internet durante la explotación; sin terceros.
- Sin DoS, ransomware, borrado de backups ni datos reales.
- La fase de “cubrir huellas” se documenta solo en el anexo interno y se prueba sobre logs de prueba con snapshot.
- Al terminar, restaurar snapshots y aislar el entorno.
