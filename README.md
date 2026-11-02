# IS-1023 · Lab PHP2Shell

Trabajo Final de la Unidad I de **IS-1023 Seguridad de la Información** (UNAM/EPISI).
Un solo vector de entrada —**PHP2Shell** en M1— y una cadena de cuatro saltos
hasta M5. M4 (PrintNightmare) es un salto **opcional** y requiere la cuenta
limitada `soporte` como precondición.

```
M6 ──php2shell──> M1 (www-data)
                     │ Redis sin auth, como root
                     ▼
                  M2 (root) ──NFS+cron──> M3 (root)
                                              │
                                              └──VNC sin auth──> M5 (cliente)

M4 (PrintNightmare, opcional; requiere cuenta `soporte`) ──> SYSTEM
```

- Arquitectura, red, credenciales y contrato de instalación: [`lab/README.md`](./lab/README.md)
- **Versiones exactas y SHA256: [`lab/VERSIONES.md`](./lab/VERSIONES.md)**
- **Guía de explotación paso a paso: [`lab/GUIA-EXPLOTACION.md`](./lab/GUIA-EXPLOTACION.md)**
- **Guion para explicarla en la sustentación: [`lab/GUION-SUSTENTACION.md`](./lab/GUION-SUSTENTACION.md)**
- **Parchado y retest: [`lab/patch/`](./lab/patch)** · **Guía de retest: [`lab/GUIA-RETEST.md`](./lab/GUIA-RETEST.md)**
- Estado, decisiones y pendientes: [`MEMORY.md`](./MEMORY.md)
- Instaladores por máquina: [`lab/m1`](./lab/m1), [`lab/m2`](./lab/m2), [`lab/m3`](./lab/m3), [`lab/m4`](./lab/m4), [`lab/m5`](./lab/m5), [`lab/m6`](./lab/m6)
- Cadena de ataque: [`lab/chain`](./lab/chain)
- Artefactos con SHA256: [`artifacts/`](./artifacts)
- Todo lo anterior (fases, informe, evidencias viejas): [`legacy/`](./legacy) — congelado, solo consulta.

## Arranque rápido

```bash
# En M6: prepara herramientas, sirve el repo y los artefactos
sudo bash lab/m6/install.sh

# En cada VM Ubuntu (consola):
curl -fsSL http://10.10.10.20:8000/bootstrap.sh | sudo bash -s m1

# En Windows (M4/M5, consola elevada):
iwr http://10.10.10.20:8000/bootstrap.ps1 -UseBasicParsing -OutFile $env:TEMP\bootstrap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File $env:TEMP\bootstrap.ps1 -Role m4

# Desde M6:
bash lab/tests/smoke.sh
bash lab/chain/00-preflight.sh --full
bash lab/chain/01-m1-php2shell.sh --run
bash lab/chain/01b-pivot.sh --run
```

## Estado del vector

`entry-b` (PHP2Shell Chain A: `session.upload_progress` + sink LFI) está **operativo** y es
el que alimenta la cadena. `entry-a` (CVE-2026-109618 puro) está **en investigación**: el
PoC público falla en stage 1 incluso contra la imagen oficial; no se declara resuelto sin
un `id` real. Ver `MEMORY.md` §3.
