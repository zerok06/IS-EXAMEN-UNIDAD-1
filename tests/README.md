# Tests · validación read-only

Estos tests validan las specs sin explotar, sin borrar y sin cambiar configuración. Se ejecutan desde **M6** (Linux) o desde el host Windows según el archivo.

| Test | Qué valida | Specs |
|---|---|---|
| `check-artifacts.sh` | Presencia y SHA256 de los artefactos | `000` |
| `check-versions.sh` | Inventario de versiones y presencia de servicios | `002`, `003`, `004` |
| `check-version-gates.sh` | Versión vulnerable vs. versión corregida (`vuln`/`patched`) | `001`–`007` |
| `check-retest.sh` | Estado parcheado: las vulnerabilidades ya no responden | `006`, `007` |
| `check-evidence.sh` | Integridad documental: logs, capturas, hashes, placeholders | `001`, `007`, `008` |
| `check-lab.ps1` | Conectividad básica desde el host Windows | `001` |

## Uso

```bash
# En M6, con el laboratorio encendido
chmod +x tests/*.sh
./tests/check-artifacts.sh
./tests/check-versions.sh
./tests/check-version-gates.sh vuln
./tests/check-version-gates.sh patched
./tests/check-retest.sh

# En el repo, sin laboratorio
./tests/check-evidence.sh
```

```powershell
# En el host Windows
powershell -ExecutionPolicy Bypass -File .\tests\check-lab.ps1
```

## Convenciones

- `PASS`: cumple.
- `FAIL`: no cumple; revisar.
- `WARN`: no se pudo verificar; revisar manualmente.
- El test no modifica nada. Si un comando no está instalado, lo marca `WARN`, no `FAIL`.

## Variables

| Variable | Default | Uso |
|---|---|---|
| `M1` | `10.10.10.11` | Aplicación |
| `M2` | `10.10.10.12` | Base de datos |
| `M3` | `10.10.10.13` | Respaldos |
| `M4` | `10.10.10.14` | Windows heredado |
| `M5` | `10.10.10.15` | Cliente |
| `M6` | `10.10.10.20` | Kali |

## Mapeo con requisitos

| Requisito | Test |
|---|---|
| REQ-000-03 | `check-artifacts.sh` |
| REQ-002-01/04 | `check-versions.sh` |
| REQ-003-05/09/12/15/18 | `check-versions.sh` |
| REQ-004-02/03 | `check-versions.sh` |
| REQ-003-05/09/12/15/18 | `check-version-gates.sh vuln` |
| REQ-006-05/10/14/19/23 | `check-version-gates.sh patched` |
| REQ-006-05/10/14/19/23 | `check-retest.sh` |
| REQ-007-01/02 | `check-retest.sh` |
| REQ-001-09/10 | `check-evidence.sh` |
| REQ-008-01/06 | `check-evidence.sh` |
