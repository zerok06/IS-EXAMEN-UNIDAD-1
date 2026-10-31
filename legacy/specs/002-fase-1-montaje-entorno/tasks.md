# Tareas 002 · Montaje del entorno

| ID | Tarea | Depende | Dueño | Est. | Evidencia | Estado |
|---|---|---|---|---|---|---|
| T-002-01 | Configurar M4 DNS `uni.lab` | T-001-05 | M4 | 45 min | `EV-002-01` | ⬜ |
| T-002-02 | Configurar M2 MariaDB/Redis/SNMP | T-001-05 | M2 | 45 min | `EV-002-02` | ⬜ |
| T-002-03 | Configurar M3 NFS/Samba/FTP/backups | T-001-05 | M3 | 60 min | `EV-002-03` | ⬜ |
| T-002-04 | Configurar M1 Apache/PHP/WP/Moodle | T-002-01–03 | M1 | 90 min | `EV-002-04` | ⬜ |
| T-002-05 | Verificar M1 → M2 y M1 → M3 | T-002-04 | M1 | 20 min | `LOG-002-05` | ⬜ |
| T-002-06 | Verificar backups M2 → M3 | T-002-02–03 | M2/M3 | 20 min | `LOG-002-06` | ⬜ |
| T-002-07 | Configurar M5 cliente | T-002-01 | M5 | 45 min | `EV-002-07` | ⬜ |
| T-002-08 | Instalar/verificar herramientas M6 | T-001-01 | M6 | 30 min | `LOG-002-08` | ⬜ |
| T-002-09 | Verificar R0 aislado | T-001-02 | Coordinador | 10 min | `EV-002-09` | ⬜ |
| T-002-10 | Reiniciar y verificar arranque automático | T-002-04–07 | Cada dueño | 30 min | `LOG-002-10` | ⬜ |
| T-002-11 | Tomar `01-rol-listo` | T-002-10 | Cada dueño | 30 min | `EV-002-11` | ⬜ |
| T-002-12 | Registrar versiones en `MEMORY.md` | T-002-08 | Coordinador | 15 min | `MEMORY.md` §4 | ⬜ |

## Checklist de cierre

- [ ] T-002-01 a T-002-12 en ✅.
- [ ] Dependencias funcionando.
- [ ] `01-rol-listo` tomado.
- [ ] Evidencias y versiones registradas.
- [ ] Coordinador valida.
