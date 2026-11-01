# AGENTS.md · Lab PHP2Shell (IS-1023)

## 1. Contexto

Trabajo Final de la Unidad I de **IS-1023 Seguridad de la Información** (UNAM/EPISI).
El entregable es una **cadena de intrusión demostrable** en una red aislada:

```
M6 (Kali) --PHP2Shell--> M1 (www-data) --> M2 --> M3 --> M4 (DNS) --> M5
```

La única entrada es **PHP2Shell** en M1. Todo lo demás es pivoteo y escalada.
La arquitectura completa está en [`lab/README.md`](./lab/README.md).

## 2. Reglas no negociables

1. **Alcance:** solo `10.10.10.0/24`, solo VM del grupo, solo con autorización del docente.
2. **Aislamiento:** sin Internet mientras los servicios vulnerables estén activos.
3. **Ética:** nada de terceros, DoS, ransomware, cifrado simulado ni datos reales.
4. **Snapshots:** antes de cada cambio: `00-base`, `01-<rol>-listo`, `estado-inicial`, `estado-parcheado`.
5. **Verdad:** no se inventan salidas. Si un PoC falla, se documenta la etapa y la limitación.
6. **Evidencia:** no se afirma RCE sin `id`/`whoami` y un marcador recuperado por un canal independiente.
7. **Artefactos:** solo lo que está en `artifacts/` con SHA256 verificado. Nada se descarga de Internet.
8. **No mezclar vectores:** `entry-b` (session injection + LFI) se declara como tal; **no** es el UAF de CVE-2026-109618.
9. **No parchear el estado comprometido:** restaurar `estado-inicial` y parchear desde ahí.
10. **Credenciales:** solo laboratorio; rotar al cerrar la práctica.

## 3. Orden de lectura

1. [`lab/README.md`](./lab/README.md) — red, servicios, cadena, credenciales, contrato.
2. [`lab/GUIA-EXPLOTACION.md`](./lab/GUIA-EXPLOTACION.md) — comandos por salto y evidencias.
3. [`lab/GUION-SUSTENTACION.md`](./lab/GUION-SUSTENTACION.md) — cómo explicarlo y defenderlo.
4. [`lab/GUIA-RETEST.md`](./lab/GUIA-RETEST.md) — verificar que el parchado funciona.
5. [`MEMORY.md`](./MEMORY.md) — estado real, decisiones y pendientes.
6. [`lab/common/lib.sh`](./lab/common/lib.sh) — API que usan todos los instaladores.
7. `lab/m1` … `lab/m6` — instaladores y `verify.sh` por máquina.
8. [`lab/chain`](./lab/chain) — comandos por salto.
9. [`legacy/`](./legacy) — material anterior, **solo consulta**.

## 4. Flujo de trabajo

```text
snapshot → instalar rol → verify.sh → explotar salto → evidencia → siguiente salto
```

- No se instala nada sin snapshot previo.
- No se cierra un salto sin evidencia y sin `verify.sh` en verde.
- Si cambia un requisito: actualizar `lab/README.md`, el instalador y `MEMORY.md`.

## 5. Mapa de máquinas

| VM | IP | Rol | Instalador |
|---|---|---|---|
| M1 | .11 | nginx TLS → Apache prefork → PHP 8.4.26 + WP/Moodle | `lab/m1/install.sh` |
| M2 | .12 | MariaDB + Redis + SSH débil | `lab/m2/install.sh` |
| M3 | .13 | FTP anónimo + NFS `no_root_squash` + cron root | `lab/m3/install.sh` |
| M4 | .14 | DNS `uni.lab` + SMB + WinRM | `lab/m4/install.ps1` |
| M5 | .15 | cliente Windows (SMB/RDP/VNC) | `lab/m5/install.ps1` |
| M6 | .20 | Kali: repo, artefactos, ataque | `lab/m6/install.sh` |

## 6. Convenciones

- Evidencias: `EV-<salto>-NN.png`, `LOG-<salto>-NN.txt`, con SHA256 y hora UTC.
- Snapshots: `00-base`, `01-<rol>-listo`, `estado-inicial`, `estado-parcheado`.
- Nombres: `M1`…`M6`, `R0`.
- Scripts: bash estricto, idempotentes, sin descargas de Internet, comentarios en español.

## 7. Validación

```bash
bash lab/tests/smoke.sh          # desde M6: puertos, DNS y HTTPS
bash lab/chain/00-preflight.sh    # condiciones de los 5 saltos
bash lab/m1/verify.sh            # en cada VM, tras instalar
bash lab/chain/01-m1-php2shell.sh --run
```

## 8. Qué no hacer

- No editar evidencias a mano ni borrar logs reales.
- No afirmar `entry-a` resuelto sin `id` real.
- No presentar el LFI del plugin como si fuera el UAF de CVE-2026-109618.
- No usar `nmap -p-` en la demo; solo en bitácora interna.
- No declarar "parcheado" si solo se bloqueó una ruta.
- No tocar `legacy/` salvo para consultar.
