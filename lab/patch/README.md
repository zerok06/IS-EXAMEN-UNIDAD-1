# Parchado del laboratorio

> **Regla:** no se parchea el estado comprometido. Primero se restaura el
> snapshot `estado-inicial` y se ejecuta el parche desde ahí.
> Después se corre el retest y se guarda como `estado-parcheado`.

## Orden

| VM | Script | Qué corrige |
|---|---|---|
| M1 | `m1-php.sh` | PHP 8.4.27, `upload_progress=Off`, sink LFI eliminado |
| M2 | `m2-redis.sh` | Redis 6.2.7, `requirepass`, `bind 127.0.0.1`, sin root |
| M3 | `m3-nfs.sh` | NFS con `root_squash`, cron sobre el export eliminado |
| M4 | `m4.ps1` | SMB1 off, Spooler detenido, SMB anónimo off |
| M5 | `m5.ps1` | VNC solo loopback + auth, RDP con NLA, SMB anónimo off |
| M6 | `retest.sh` | Repite los ataques y exige que fallen |

## Uso

```bash
# 1. restaurar snapshot estado-inicial en la VM
# 2. en la VM:
sudo bash /opt/lab/lab/patch/m1-php.sh
# 3. desde M6:
bash lab/patch/retest.sh
# 4. tomar snapshot estado-parcheado
```

## Evidencia

- `LOG-PATCH-M1.txt` … `LOG-PATCH-M5.txt`
- `EV-PATCH-01` … `EV-PATCH-05` (captura del retest)
- `sha256sum` de cada log.

## Qué NO es esto

- No es "bloquear una ruta": se cambia versión o se elimina la condición.
- M4 no aplica el KB de PrintNightmare (no hay Internet): se **detiene y
  deshabilita el Spooler**, que elimina el vector. Se declara así.
- M5 no rota la contraseña de VNC (TightVNC la guarda ofuscada): se limita a
  loopback y se bloquea 5900 en el firewall. Se declara así.
