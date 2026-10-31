# Plan 001 · Preparación y snapshots

## 1. Enfoque

Primero se verifica la red y el aislamiento; después se toman snapshots en frío de cada VM; al final se clona y se registra. No se implementa ninguna vulnerabilidad en esta fase.

## 2. Preflight

| # | Verificación | Comando | Esperado |
|---|---|---|---|
| 0 | Artefactos | `tests/check-artifacts.sh` | PASS |
| 1 | IP de M6 | `ip -brief a` | `10.10.10.20/24` |
| 2 | Gateway | `ip route` | `default via 10.10.10.1` |
| 3 | DNS | `dig wp.uni.lab @10.10.10.14` | `10.10.10.11` |
| 4 | Sin Internet | `ping -c 1 8.8.8.8` | falla |
| 5 | M1 arriba | `curl -sI http://10.10.10.11` | `200`/`301` |
| 6 | M2 arriba | `redis-cli -h 10.10.10.12 PING` | `PONG` |
| 7 | M3 arriba | `nc -zv 10.10.10.13 21` | abierto |
| 8 | M4 arriba | `ping 10.10.10.14` | responde |
| 9 | M5 arriba | `nc -zv 10.10.10.15 5900` | abierto |
| 10 | Host Windows | `tests/check-lab.ps1` | PASS |

## 3. Red

| VM | IP | Gateway | DNS | Hostname |
|---|---|---|---|---|
| M1 | `10.10.10.11/24` | `.1` | `.14` | `app01` |
| M2 | `10.10.10.12/24` | `.1` | `.14` | `db01` |
| M3 | `10.10.10.13/24` | `.1` | `.14` | `bkp01` |
| M4 | `10.10.10.14/24` | `.1` | `127.0.0.1` | `SRVOLD` |
| M5 | `10.10.10.15/24` | `.1` | `.14` | `PC-EST01` |
| M6 | `10.10.10.20/24` | `.1` | `.14` | `kali01` |

## 4. Secuencia de snapshots

1. Apagar M1–M5.
2. `VM → Snapshots → Take Snapshot…` → `00-base`.
3. Encender, instalar servicios (Fase 1), apagar, snapshot `01-<rol>-listo`.
4. Implantar vulnerabilidades (Fase 2), verificar, apagar, snapshot `estado-inicial-vulnerable`.
5. `VM → Manage → Clone → Full Clone` de M1–M5.
6. Registrar en `informe/anexos/c-snapshots.md`.

## 5. Comandos (uso interno)

```bash
# M6
mkdir -p ~/evidence/{m1,m2,m3,m4,m5,parcheado}
script -a ~/evidence/sesion-$(date -u +%F-%H%M).log
date -u

# Verificación
ip -brief a
ip route
ping -c 2 10.10.10.1
ping -c 2 10.10.10.11
ping -c 2 10.10.10.14
dig wp.uni.lab @10.10.10.14
ping -c 1 8.8.8.8 || echo "SIN INTERNET OK"
```

## 6. Evidencia

- Captura de `ip -brief a` en M6.
- Captura de `ping 8.8.8.8` fallando.
- Captura de `Snapshot Manager` con los tres snapshots.
- Captura de `Clone` full.
- Registro en `c-snapshots.md`.

## 7. Riesgos y rollback

| Riesgo | Acción |
|---|---|
| VM no arranca | Restaurar `00-base`; documentar |
| Snapshot corrupto | Usar el clon full |
| Sin disco | Liberar espacio; no iniciar |
| Internet activo | Desconectar DSL/NAT; repetir verificación |

## 8. Definición de terminado

- [ ] Red y aislamiento verificados.
- [ ] Snapshots y clones tomados.
- [ ] Registro completo.
- [ ] `~/evidence/` listo.
- [ ] `MEMORY.md` actualizado.

## 9. Estimación

| Actividad | Horas |
|---|---|
| Encendido y red | 0.5 |
| Snapshots | 1.0 |
| Clones | 0.5 |
| Registro y evidencia | 0.5 |
| **Total** | **2.5** |
