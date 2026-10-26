# IS-1023 · Laboratorio de servicios vulnerables

Trabajo Final de la Unidad I de **IS-1023 Seguridad de la Información** (UNAM/EPISI, Semana 07). El proyecto monta una red aislada de 6 VM, implementa vulnerabilidades CVE, las explota, las remedia y verifica el antes/después.

## Estado

- **24 hallazgos** documentados (9 CVE + 15 configuraciones).
- **5/5** máquinas con presencia.
- **0 RCE** de los CVE estrella y **0 versiones parcheadas** al 2026-10-26.
- El detalle y las decisiones están en [`MEMORY.md`](./MEMORY.md).

## Cómo está organizado

| Ruta | Contenido |
|---|---|
| [`AGENTS.md`](./AGENTS.md) | Reglas para agentes y humanos |
| [`MEMORY.md`](./MEMORY.md) | Estado, decisiones, credenciales y limitaciones |
| [`docs/`](./docs/) | Constitución, plan maestro, proceso 7 fases, evaluación, versiones y snapshots |
| [`docs/VALIDACION-VULNERABILIDADES.md`](./docs/VALIDACION-VULNERABILIDADES.md) | Revalidación de las 24 vulns contra versiones y artefactos |
| [`templates/`](./templates/) | Plantillas de informe, hallazgo, version gate, snapshot y deck |
| [`artifacts/`](./artifacts/) | Versiones exactas, PoCs, SHA256 y FTP |
| [`specs/`](./specs/) | 8 specs de fase + 1 de artefactos, con EARS, plan y tareas |
| [`tests/`](./tests/) | Validación read-only |
| [`informe/`](./informe/) | Informe, hallazgos, evidencias y anexos |
| [`guias/`](./guias/) | Guías por máquina, router, Kali y playbook |
| [`arquitectura-universitaria.md`](./arquitectura-universitaria.md) | Arquitectura v4.1 |

## Orden de lectura

1. [`docs/constitution.md`](./docs/constitution.md)
2. [`docs/PROCESO-7-FASES.md`](./docs/PROCESO-7-FASES.md)
3. [`docs/PLAN-MAESTRO.md`](./docs/PLAN-MAESTRO.md)
4. [`docs/evaluacion-guia.md`](./docs/evaluacion-guia.md)
5. La spec de la fase en [`specs/`](./specs/)
6. [`MEMORY.md`](./MEMORY.md)

## Fases

| Fase | Spec | Objetivo |
|---|---|---|
| Pre-0 | [`000`](./specs/000-artefactos/) | Descargar, verificar y servir artefactos |
| 0 | [`001`](./specs/001-fase-0-preparacion-snapshots/) | Preparación y snapshots |
| 1 | [`002`](./specs/002-fase-1-montaje-entorno/) | Montaje del entorno |
| 2 | [`003`](./specs/003-fase-2-implementacion-vulnerabilidades/) | Implementación de vulnerabilidades |
| 3 | [`004`](./specs/004-fase-3-reconocimiento-enumeracion/) | Reconocimiento y enumeración |
| 4 | [`005`](./specs/005-fase-4-validacion-explotacion/) | Validación, explotación y cadena |
| 5 | [`006`](./specs/006-fase-5-remediacion/) | Remediación |
| 6 | [`007`](./specs/007-fase-6-verificacion-retest/) | Verificación y retest |
| 7 | [`008`](./specs/008-fase-7-documentacion-sustentacion/) | Informe final, plantillas y sustentación |

## Validación rápida

```bash
./tests/check-artifacts.sh
./tests/check-versions.sh
./tests/check-version-gates.sh vuln
./tests/check-version-gates.sh patched
./tests/check-retest.sh
./tests/check-evidence.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\check-lab.ps1
```

## Ética

Todo el trabajo se realiza en un **laboratorio aislado y autorizado**. No se ataca a terceros, no se usa Internet con servicios vulnerables activos y no se realizan acciones destructivas. Las credenciales y datos son ficticios.
