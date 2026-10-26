# Tareas 003 · Implementación de vulnerabilidades

| ID | Tarea | Depende | Dueño | Est. | Evidencia | Estado |
|---|---|---|---|---|---|---|
| T-003-01 | Completar inventario por máquina con CVE/CWE/CVSS | T-002-12 | Coordinador | 30 min | `version-matrix.md` | ⬜ |
| T-003-02 | Fijar WP 7.0.1 / PHP 8.4.26 / Apache 2.4.49 | T-002-04 | M1 | 60 min | `EV-003-M1-01` | ⬜ |
| T-003-03 | Configurar prefork + `upload_progress` para W2 | T-003-02 | M1 | 45 min | `EV-003-M1-02` | ⬜ |
| T-003-04 | Configurar CGI para W3 | T-003-02 | M1 | 30 min | `EV-003-M1-03` | ⬜ |
| T-003-05 | Verificar W4–W7 | T-003-02 | M1 | 20 min | `EV-003-M1-04` | ⬜ |
| T-003-06 | Configurar Redis/MariaDB/SNMP | T-002-02 | M2 | 45 min | `EV-003-M2-01` | ⬜ |
| T-003-07 | Decidir Redis distro vs fuente para D1 | T-003-06 | M2 | 30 min | `EV-003-M2-02` | ⬜ |
| T-003-08 | Verificar D2/D3/D4 | T-003-06 | M2 | 20 min | `EV-003-M2-03` | ⬜ |
| T-003-09 | Instalar Samba 4.5.9 | T-002-03 | M3 | 60 min | `EV-003-M3-01` | ⬜ |
| T-003-10 | Configurar FTP anónimo + `credenciales.txt` | T-002-03 | M3 | 20 min | `EV-003-M3-02` | ⬜ |
| T-003-11 | Configurar NFS `no_root_squash` + SSH débil | T-002-03 | M3 | 20 min | `EV-003-M3-03` | ⬜ |
| T-003-12 | Configurar S3 + `soporte` + WinRM | T-002-01 | M4 | 45 min | `EV-003-M4-01` | ⬜ |
| T-003-13 | Configurar S2/S4/S5 | T-003-12 | M4 | 30 min | `EV-003-M4-02` | ⬜ |
| T-003-14 | Verificar S1 (solo si aplica) | T-003-12 | M4 | 20 min | `EV-003-M4-03` | ⬜ |
| T-003-15 | Configurar C2/C3/C4 | T-002-07 | M5 | 30 min | `EV-003-M5-01` | ⬜ |
| T-003-16 | Verificar C1 (no aplica en 19045) | T-003-15 | M5 | 10 min | `EV-003-M5-02` | ⬜ |
| T-003-17 | Tomar `estado-inicial-vulnerable` | T-003-02–16 | Cada dueño | 40 min | `EV-003-SNAP` | ⬜ |

## Checklist de cierre

- [ ] ≥3 vulnerabilidades por máquina.
- [ ] Versiones y CVSS verificados.
- [ ] Evidencias de presencia.
- [ ] `estado-inicial-vulnerable` tomado.
- [ ] `MEMORY.md` actualizado.
- [ ] Coordinador valida.
