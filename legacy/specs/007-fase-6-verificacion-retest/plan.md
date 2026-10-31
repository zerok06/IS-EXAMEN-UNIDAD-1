# Plan 007 · Verificación y retest

## 1. Enfoque

Se parte de `estado-parcheado`, se repiten los comandos de la Fase 4 y se captura el “después”. Si un comando sigue funcionando, se corrige la remediación y se repite. Al final se actualizan `06` y `07` con la misma verdad.

## 2. Matriz de retest

| ID | Comando (el mismo del antes) | Antes | Después esperado |
|---|---|---|---|
| W1 | `curl -s http://wp.uni.lab/wp-json/ \| grep -o 'batch[^"]*'` + `wp core version` | `batch/v1`; 7.0.1 | 7.0.2; ruta bloqueada |
| W2 | `curl -sI http://wp.uni.lab \| grep -i x-powered-by` | PHP/8.4.26 | PHP/8.4.27+ |
| W3 | `curl --path-as-is .../etc/passwd` | 503/200 | 403/404 |
| W4 | login `usc.admin`/`Admin13.-` | 302 + cookie | falla / 2FA |
| M1-SSH | `ssh ubuntu@...` con `Admin13.-` | root | falla; sudo no escala |
| D1 | `redis-cli -h ... PING` | PONG | NOAUTH |
| D2 | `mysql ... -u wp_user -p'wp_pass123'` | 12 tablas | denegado |
| D3 | `nmap -p 3306,6379,161` | open | filtered |
| D4 | `snmpwalk -v2c -c public` | responde | falla |
| B1 | `smbd --version` + `smb-vuln*` | 4.5.9 | 4.5.10; limpio |
| B2 | `nc -zv ... 6200` | cerrado | cerrado |
| B3 | `curl ftp://anonymous...` | credenciales | 530 |
| B4 | `mount` + `touch` | root | denegado |
| S1 | `nmap --script smb-vuln-ms17-010` | vulnerable | limpio |
| S2 | `Get-Service Spooler` + MSF | activo | stopped/disabled |
| S3 | `nxc smb ... -p 'password_2026'` | Pwn3d | falla |
| S4 | `dig axfr` | zona | REFUSED |
| S5 | `smb-security-mode` | signing off | required |
| C2 | `nxc smb ... -p 'Admin13.-'` | acceso | falla |
| C3 | `xfreerdp` | escritorio | NLA requerido |
| C4 | `vncviewer` | escritorio | pide clave/cerrado |
| W5–W7 | `curl` | 200/Index | 403/404 |

## 3. Evidencia

```text
ANTES:  EV-<ID>-antes.png  + LOG-<ID>-antes.txt
DESPUÉS: EV-<ID>-despues.png + LOG-<ID>-despues.txt
```

Cada par se pega lado a lado en el anexo y se referencia desde la sección 7 del informe.

## 4. Coherencia documental

Actualizar en el mismo commit:

- `informe/06-remediacion.md` → estado real por hallazgo.
- `informe/07-retest.md` → tabla antes/después.
- `informe/04-inventario-vulnerabilidades.md` → estado final.
- `MEMORY.md` → estado y decisiones.
- `informe/anexos/c-snapshots.md` → `estado-parcheado`.

**Regla:** si `06` dice pendiente y `07` dice ejecutado, el retest no es válido. Una sola fuente de verdad.

## 5. Riesgos y rollback

| Riesgo | Acción |
|---|---|
| El comando cambió | Repetir con el original |
| El hallazgo sigue abierto | Corregir remediación y repetir |
| El servicio no arranca | Restaurar `estado-inicial-vulnerable` |
| El snapshot no existe | Tomarlo antes de la demo |

## 6. Definición de terminado

- [ ] Todos los hallazgos con antes/después.
- [ ] Versión/config final.
- [ ] Riesgo residual documentado.
- [ ] `06` y `07` coherentes.
- [ ] `estado-parcheado` confirmado.
- [ ] Demo ensayada.

## 7. Estimación

| Actividad | Horas |
|---|---|
| Retest M1–M3 | 2.0 |
| Retest M4–M5 | 1.5 |
| Evidencia y documentación | 1.5 |
| **Total** | **5.0** |
