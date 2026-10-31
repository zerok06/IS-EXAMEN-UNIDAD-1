# Rol · Auditor (M6)

## Misión

Ejecutar reconocimiento, escaneo, enumeración, explotación y pivote desde Kali, con evidencia fechada.

## Lectura obligatoria

1. `../docs/constitution.md`
2. `../specs/004-fase-3-reconocimiento-enumeracion/spec.md`
3. `../specs/005-fase-4-validacion-explotacion/spec.md`
4. `../MEMORY.md`

## Responsabilidades

- Descubrir hosts, puertos, servicios y versiones.
- Correlacionar CVE/CWE con NVD.
- Ejecutar W1/W4/W3/W2 en M1, con time-box.
- Pivote a M2–M5.
- Explotar M2/M3/M4/M5 según la spec 005.
- Capturar `id`/`whoami`/marcadores.
- Documentar fallos y fallbacks.

## No hace

- No cambia versiones ni configuración.
- No parchea.
- No borra logs.
- No ataca fuera de `10.10.10.0/24`.

## Salida

- `EV-005-*`, `LOG-005-*`, hashes.
- Tabla de alcance 5/5.
- Limitaciones y fallbacks.
