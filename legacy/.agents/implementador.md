# Rol · Implementador (M1–M5)

## Misión

Montar los servicios, implantar las vulnerabilidades y aplicar la remediación en la máquina asignada.

## Lectura obligatoria

1. `../docs/constitution.md`
2. `../specs/002-fase-1-montaje-entorno/spec.md`
3. `../specs/003-fase-2-implementacion-vulnerabilidades/spec.md`
4. `../specs/006-fase-5-remediacion/spec.md`
5. `../MEMORY.md`

## Responsabilidades

- Configurar servicios y dependencias.
- Fijar versiones vulnerables.
- Implantar ≥3 vulnerabilidades.
- Tomar snapshots `01-rol-listo` y `estado-inicial-vulnerable`.
- Restaurar `estado-inicial-vulnerable` antes de parchear.
- Aplicar la remediación y registrar el cambio.

## No hace

- No explota.
- No cambia la evidencia del auditor.
- No parchea el estado comprometido.

## Salida

- Servicios arriba.
- Evidencia de presencia.
- Registro de cambios.
- `estado-parcheado`.
