# Version gate · control de versiones por fase

> Se completa en cada fase. Si una fila no cumple, no se avanza. Fuente de verdad: [`../docs/version-matrix.md`](../docs/version-matrix.md).

## 1. Tabla maestra

| ID | Producto | Instalada | Rango vulnerable | Corrige | ¿Vulnerable? | Evidencia | Fase |
|---|---|---|---|---|---|---|---|
| W1 | WordPress | {{7.0.1}} | 6.9.0–6.9.4 / 7.0.0–7.0.1 | 6.9.5 / 7.0.2 | {{sí/no}} | {{cmd}} | {{0–6}} |
| W2 | PHP | {{8.4.26}} | 8.4.x < 8.4.27 | 8.4.27 | {{sí/no}} | {{cmd}} | {{0–6}} |
| W3 | Apache | {{2.4.49}} | 2.4.49 | 2.4.50/2.4.51+ | {{sí/no}} | {{cmd}} | {{0–6}} |
| D1 | Redis | {{6.2.6}} | 6.2.x < 6.2.7 | 6.2.7 | {{sí/no}} | {{cmd}} | {{0–6}} |
| B1 | Samba | {{4.5.9}} | < 4.5.10 | 4.5.10 | {{sí/no}} | {{cmd}} | {{0–6}} |
| B2 | vsftpd | {{2.3.4}} | tarball troyanizado | 2.3.4 limpio | {{sí/no}} | {{cmd}} | {{0–6}} |
| S2 | Spooler | {{build}} | < umbral | KB / off | {{sí/no}} | {{cmd}} | {{0–6}} |
| C4 | TightVNC | {{2.8.90}} | auth None | password | {{sí/no}} | {{cmd}} | {{0–6}} |

## 2. Gate por fase

### Fase 0 · Línea base
- [ ] Versiones base registradas.
- [ ] Evidencia de cada `--version`.
- [ ] Snapshots.

### Fase 1 · Instaladas
- [ ] Versiones coinciden con la matriz.
- [ ] Servicios arriba.
- [ ] Dependencias.

### Fase 2 · Vulnerables
- [ ] Instalada dentro del rango vulnerable.
- [ ] Instalada **menor** que el fix.
- [ ] Evidencia de presencia.
- [ ] Si es igual o mayor que el fix: retirar o bajar.

### Fase 3 · Fingerprint
- [ ] La versión se ve desde M6.
- [ ] Correlación CVE.
- [ ] Sin explotación.

### Fase 4 · Explotabilidad
- [ ] PoC ejecutado.
- [ ] `id`/`whoami`/marcador.
- [ ] Evidencia.
- [ ] Si falla: limitación y fallback.

### Fase 5 · Corregida
- [ ] Instalada **igual o mayor** que el fix.
- [ ] Configuración segura.
- [ ] Registro de cambio.
- [ ] `estado-parcheado`.

### Fase 6 · Retest
- [ ] Mismo comando.
- [ ] Versión corregida confirmada.
- [ ] PoC falla.
- [ ] Antes/después.

### Fase 7 · Informe
- [ ] Tabla de versiones antes/después.
- [ ] NVD con fecha.
- [ ] Cada hallazgo con versión vulnerable y corregida.

## 3. Reglas

1. No se declara “vulnerable” sin comparar la instalada con el fix.
2. No se declara “parcheado” sin confirmar la versión corregida.
3. No se mezclan CVSS v3.1 y v4.0.
4. No se cuenta un CVE no aplicable como profundidad.
5. Si no hay fix, se documenta la mitigación compensatoria.
