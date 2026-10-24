# 7. Verificación de la remediación (retest)

**Estado:** 🟢 retest ejecutado el 2026-10-24 (F07-001…F07-005). M1/M2/M3/M4/M5 verificados. **Versiones sin cambiar** en ningún servicio; mitigación = configuración + endurecimiento.

---

## 7.1 Método

1. Restaurar/partir de `estado-parcheado`.
2. Repetir los mismos comandos de validación de las fases 3–4 (no otros).
3. Capturar antes/después lado a lado.
4. Registrar versión/config final y hash de la evidencia.

---

## 7.2 Tabla antes/después

| ID | Antes (evidencia) | Después real (F07) | Estado |
|---|---|---|---|---|
| W1 | `F03-001` (`batch\/v1`) | **403** (bloqueo Apache; WP sigue 7.0.1) | 🟡 compensado |
| W2 | `F01-004`, `F02-002` | `upload_progress.enabled = Off` (PHP sigue 8.4.26) | 🟡 compensado |
| W3 | `F03-002` (503) | **500**, sin `root:x:0:0` (cgi-bin denegado; Apache sigue 2.4.49) | 🟡 compensado |
| W4 | `F03-001` (302) | ⬜ no retesteado (sin cambio de clave WP) | ⬜ |
| W5 | `F02-004` (200) | **403** | ✅ `F07-001` |
| W6 | `F02-004` (200) | archivo borrado; 0 menciones `phpinfo` (HTTP 500 de WP) | ✅ `F07-001` |
| W7 | `F02-004` (Index of) | **403** | ✅ `F07-001` |
| M1-SSH | `F04-000b` (root) | ⬜ sin rotación (requiere dueño) | ⬜ |
| D1 | `F04-001` (PONG) | `PING` → `NOAUTH`; desde M6 → timeout (filtrado) | ✅ `F07-005` |
| D2 | `F04-003` (12 tablas) | vieja → `Access denied`; nueva → `wordpress` + 487 tablas | ✅ `F07-005` |
| D3 | `F02-001` (6379) | `6379`/`3306`/`161` → `filtered` desde M6 | ✅ `F07-005` |
| D4 | `F02-001` (161) | `public`/`private` eliminadas; `161` filtrado desde M6 | ✅ `F07-005` |
| B1 | `F04-005` | servicio detenido (Samba 4.5.10 sin cambio de versión) | ✅ `F07-002` |
| B2 | manual (`:6200`) | **closed** (vsftpd detenido) | ✅ `F07-002` |
| B3 | `F04-002` | `credenciales.txt` fuera del share; FTP cerrado | ✅ `F07-002` |
| B4 | `F04-006` (root) | **Permission denied** (`root_squash`) | ✅ `F07-002` |
| S1 | `F02-001` | **EnableSMB1Protocol: False** | ✅ `F07-003` |
| S2 | `F04-016` | **Stopped / Disabled** | ✅ `F07-003` |
| S3 | `F04-015` | vieja `password_2026` → LOGON_FAILURE; nueva `M4_Admin_2026!` OK | ✅ `F07-003` |
| S4 | `F04-012` | **Transfer failed** | ✅ `F07-003` |
| S5 | `F04-013` | **RequireSecuritySignature: True** | ✅ `F07-003` |
| C1 | `F02-001` | **EnableSMB1Protocol: False** | ✅ `F06-005` |
| C2 | `F04-002`/`F04-007` | clave cambiada a `ClienteM5_2026!` | 🟡 `F06-006b` |
| C3 | `F02-001` | **UserAuthentication: 1** (NLA) | ✅ `F06-005` |
| C4 | `F02-001` | **5900 filtered**; `tvnserver` Stopped/Disabled | ✅ `F07-004` |

> **Versiones no cambiadas:** WP 7.0.1, PHP 8.4.26, Apache 2.4.49, Redis 6.2.6, Samba 4.5.10, WS2016 14393 y Win10 19045 siguen iguales. Mitigación = **configuración + endurecimiento**. El cambio de versión queda pendiente con snapshot `estado-parcheado`.

---

## 7.3 Capturas antes/después

Para cada fila:

```text
ANTES:  EV-<ID>-antes.png  + LOG-<ID>-antes.log
DESPUÉS: EV-<ID>-despues.png + LOG-<ID>-despues.log
```

Se pegan lado a lado en el anexo y se referencian desde la sección 7. Sin el par antes/después, el hallazgo no se considera cerrado.

---

## 7.4 Residuales

| ID | Si no se puede cerrar | Mitigación compensatoria |
|---|---|---|
| W1 | Sin actualización de WP | Bloquear `/wp-json/batch/v1` en Apache/WAF |
| W2 | Sin recompilar PHP | `session.upload_progress.enabled=0`; `pm.max_requests=1` |
| D1 | Sin actualizar Redis | `requirepass` + `bind 127.0.0.1` + firewall |
| B1 | Samba EOL | Aislar M3; SMB1 OFF; no exponer 445 |
| C4 | VNC necesario | Clave fuerte + solo localhost + túnel SSH |
