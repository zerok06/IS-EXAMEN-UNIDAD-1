# Tareas 005 · Validación, explotación y cadena

| ID | Tarea | Depende | Dueño | Est. | Evidencia | Estado |
|---|---|---|---|---|---|---|
| T-005-00 | Leer specs por vuln y completar version gate | T-004-08 | Coordinador | 20 min | `EV-000-11` / `version-gate-2026-10-27` | ✅ |
| T-005-01 | Snapshot `previo-a-W1` y PoC wp2shell | T-005-00 | M1/M6 | 2 h | `EV-005-M1-01` | ⬜ |
| T-005-02 | W4 login + plugin + `id` | T-005-01 | M1/M6 | 30 min | `EV-005-M1-02` | ⬜ |
| T-005-03 | W3 traversal + RCE | T-003-04 | M1/M6 | 2 h | `EV-005-M1-03` | ✅ |
| T-005-04 | W2 PHP2Shell con time-box | T-003-03 | M1/M6 | 3–4 h | `EV-W2-01`, log PoC | 🟡 limitación |
| T-005-05 | SSH root + `wp-config.php` | T-005-01 | M6 | 15 min | `EV-W2-ROOT` | ✅ |
| T-005-06 | Pivote SSH/ligolo + verificación | T-005-05 | M6 | 30 min | `EV-005-PIVOTE` | ⬜ |
| T-005-07 | M2: Redis/DB/SNMP | T-005-06 | M6 | 1 h | `EV-005-M2-01` | ⬜ |
| T-005-08 | M2: D1 Lua (si distro) | T-005-07 | M6 | 2 h | `EV-005-M2-02` | ⬜ |
| T-005-09 | M3: FTP/NFS | T-005-06 | M6 | 1 h | `EV-005-M3-01` | ⬜ |
| T-005-10 | M3: Samba 4.5.9 | T-005-09 | M6 | 2–3 h | `EV-005-M3-02` | ⬜ |
| T-005-11 | M3: B2/B5 (opcional) | T-005-10 | M6 | 1 h | `EV-005-M3-03` | ⬜ |
| T-005-12 | M4: S3/S4/S5 | T-005-06 | M6 | 1 h | `EV-005-M4-01` | ⬜ |
| T-005-13 | M4: sesión `soporte` | T-003-12 | M6 | 30 min | `EV-005-M4-02` | ⬜ |
| T-005-14 | M4: PrintNightmare LPE | T-005-13 | M6 | 2–3 h | `EV-005-M4-03` | ⬜ |
| T-005-15 | M4: S1 (si aplica) | T-005-12 | M6 | 1 h | `EV-005-M4-04` | ⬜ |
| T-005-16 | M5: C2 | T-005-06 | M6 | 20 min | `EV-005-M5-01` | ⬜ |
| T-005-17 | M5: C4 VNC | T-005-16 | M6 | 20 min | `EV-005-M5-02` | ⬜ |
| T-005-18 | M5: C3 RDP | T-005-16 | M6 | 30 min | `EV-005-M5-03` | ⬜ |
| T-005-19 | Marcadores e impacto | T-005-01–18 | M6 | 30 min | `EV-005-IMPACTO` | ⬜ |
| T-005-20 | Tabla de alcance 5/5 + hashes | T-005-19 | Coordinador | 30 min | `alcance.md` | ⬜ |

## Checklist de cierre

- [ ] 5/5 con presencia.
- [ ] W1 o W4 con `id`.
- [ ] W3/W2 con resultado real.
- [ ] M4 con `soporte` → SYSTEM.
- [ ] Evidencias y hashes.
- [ ] `MEMORY.md` actualizado.
- [ ] Coordinador valida.
