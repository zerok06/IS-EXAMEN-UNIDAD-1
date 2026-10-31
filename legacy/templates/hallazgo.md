# Hallazgo {{ID}} · {{NOMBRE}}

> Plantilla por vulnerabilidad. Se usa en Fase 4 (validación), Fase 5 (remediación) y Fase 6 (retest).

## 1. Identificación

| Campo | Valor |
|---|---|
| ID | {{W1/D1/B1/S1/C4}} |
| Máquina | {{M1…M5}} |
| Servicio | {{producto}} |
| Versión instalada | {{x.y.z}} |
| CVE / CWE | {{CVE-AAAA-NNNN / CWE-XX}} |
| CVSS | {{n.n}} |
| Métrica | {{v3.1 / v4.0 / ambiental}} |
| NVD | {{URL}} |
| Fecha de consulta | {{AAAA-MM-DD}} |

## 2. Versión

| Campo | Valor |
|---|---|
| Rango vulnerable | {{...}} |
| Versión que corrige | {{...}} |
| ¿La instalada es vulnerable? | {{sí/no}} |
| Evidencia de versión | {{comando + captura}} |

## 3. Descripción e impacto

**Qué es:** {{...}}.

**Impacto demostrado:** {{acceso/datos/control}}.

**A qué máquina permite llegar:** {{...}}.

## 4. Validación

| Campo | Valor |
|---|---|
| Técnica/herramienta | {{...}} |
| Comando (anexo interno) | {{...}} |
| Resultado observado | {{...}} |
| Evidencia | `EV-{{ID}}-antes.png`, `LOG-{{ID}}-antes.txt` |
| Snapshot previo | `previo-a-{{ID}}` |
| Estado | {{validado/parcial/no explotable}} |

## 5. Remediación

| Campo | Valor |
|---|---|
| Medida | {{parche/reconfiguración/mitigación}} |
| Versión/config final | {{...}} |
| Fecha UTC | {{...}} |
| Responsable | {{...}} |
| Evidencia | `EV-{{ID}}-fix.png` |

## 6. Retest

| Campo | Valor |
|---|---|
| Mismo comando | {{...}} |
| Resultado después | {{...}} |
| Evidencia | `EV-{{ID}}-despues.png`, `LOG-{{ID}}-despues.txt` |
| Estado | {{cerrado/residual}} |

## 7. Riesgo residual

{{Si no se pudo cerrar: mitigación compensatoria y riesgo}}.

## 8. Checklist

- [ ] Versión vulnerable verificada.
- [ ] Versión que corrige verificada.
- [ ] Evidencia de presencia.
- [ ] Evidencia de explotación o no explotabilidad.
- [ ] Remediación aplicada.
- [ ] Retest con el mismo comando.
- [ ] Antes/después en el informe.
