# Fase 7 · Retest

**Objetivo:** repetir exactamente las validaciones de las fases 3–4 sobre el estado parcheado y demostrar que ya no funcionan.
**Estado:** ⬜ pendiente de la fase 6.

---

## 7.1 Regla

Se usa **el mismo comando** del “antes”. Si el comando cambia, no sirve como comparación. Se captura el “después” y se pega al lado del “antes”.

---

## 7.2 Tabla de retest

| ID | Comando (el mismo del antes) | Antes | Después esperado | Estado |
|---|---|---|---|---|
| W1 | `curl -s http://wp.uni.lab/wp-json/ \| grep -o 'batch[^"]*'` + `wp core version` | `batch\/v1`; 7.0.1 | 7.0.2; ruta bloqueada | ⬜ |
| W2 | `curl -sI http://wp.uni.lab \| grep -i x-powered-by` | PHP/8.4.26 | PHP/8.4.27+ | ⬜ |
| W3 | `curl -s -o /dev/null -w '%{http_code}\n' --path-as-is '.../%2e/...'` | 503 | 403 | ⬜ |
| W4 | login `usc.admin` / `Admin13.-` | 302 + cookie | falla / 2FA | ⬜ |
| W5 | `curl .../server-status` | 200 | 403 | ⬜ |
| W6 | `curl .../info.php` | 200 | 404 | ⬜ |
| W7 | `curl .../uploads/` | Index of | 403 | ⬜ |
| M1-SSH | `ssh ubuntu@...` con `Admin13.-` | root | falla; sudo no escala | ⬜ |
| D1 | `redis-cli -h 10.10.10.12 PING` | PONG | NOAUTH | ⬜ |
| D2 | `mysql ... -u wp_user -p'wp_pass123'` | 12 tablas | denegado | ⬜ |
| D3 | `nmap -Pn -p 6379 10.10.10.12` | open | filtered | ⬜ |
| B2 | `nc -zv 10.10.10.13 6200` | cerrado (no explotable) | cerrado | ⬜ |
| B3 | `curl ftp://anonymous:...` | credenciales | 530 | ⬜ |
| B4 | montar y `touch` | root root | denegado / nobody | ⬜ |
| S1 | `nmap --script smb-vuln-ms17-010 -p 445 10.10.10.14` | pendiente | limpio | ⬜ |
| S2 | `Get-Service Spooler` + MSF | pendiente | módulo falla | ⬜ |
| S3 | `nxc smb ... -p 'Admin13.-'` | pendiente | falla | ⬜ |
| S4 | `dig axfr uni.lab @10.10.10.14` | pendiente | REFUSED | ⬜ |
| S5 | `nmap --script smb-security-mode` | pendiente | signing required | ⬜ |
| C2 | `nxc smb .15 -u cliente -p 'Admin13.-'` | pendiente | falla | ⬜ |
| C3 | `xfreerdp /v:.15` | pendiente | NLA requerido | ⬜ |
| C4 | `vncviewer .15` | pendiente | pide clave / cerrado | ⬜ |

---

## 7.3 Evidencia del retest

```text
ANTES:  evidencias/png/<ID>-antes.png  + logs/<ID>-antes.log
DESPUÉS: evidencias/png/<ID>-despues.png + logs/<ID>-despues.log
```

Se agregan al índice B y se referencian desde `07-retest.md`.

---

## 7.4 Criterio de cierre

- [ ] Cada hallazgo tiene antes y después.
- [ ] La versión/config final está registrada.
- [ ] Los que no se puedan cerrar tienen mitigación compensatoria.
- [ ] El snapshot `estado-parcheado` está tomado y documentado.
