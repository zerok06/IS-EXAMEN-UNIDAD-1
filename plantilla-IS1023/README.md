# Plantilla IS-1023 — Informe de Laboratorio (APA 7)

Plantilla base extraída de `IS1023_Nmap_Ancco_Rafael_Fabiola.zip`, conservando la
carátula UNAM, los índices, la tipografía y el formato APA 7.

## Contenido

- `main.tex` — informe completo de la práctica (W2 · PHP2Shell como caso profundo).
- `main.pdf` — compilación lista para revisar.
- `capturas/` — logos y las 24 capturas de evidencia usadas en el informe.

## Compilar

Usar **XeLaTeX** (no pdfLaTeX) por `fontspec` + Arial:

```bash
xelatex main.tex
xelatex main.tex   # segunda pasada para índices
```

## Estructura del informe

1. Resumen
2. Objetivos y alcance
3. Desarrollo de la práctica
   - 3.1 Arquitectura del entorno
   - 3.2 Metodología y version gate
   - 3.3 Inventario de vulnerabilidades (24 hallazgos)
   - 3.4 W2 · PHP2Shell (ficha, precondiciones, rebuild, PoC, evidencia, impacto, remediación y retest)
   - 3.5 Otros hallazgos
   - 3.6 Limitaciones documentadas
   - 3.7 Remediación y verificación (antes/después)
4. Conclusiones y recomendaciones
5. Anexos A–F (evidencia gráfica, índice de evidencias, snapshots, comandos, CVE y SHA256)
6. Referencias APA 7

## Qué se conservó de la plantilla

- Márgenes 2.54 cm, Arial 11, doble espacio, sangría 1.27 cm.
- `Figura X` / `Tabla X` en negrita + título en cursiva arriba.
- Comandos `\figuranota{}` y `\tablanota{}`.
- Tablas `tabularx` + `booktabs`, listas `enumitem`.
- Bloques de terminal `listings` estilo `terminal`.
- Índices de contenido, figuras y tablas; paginación romana/arábiga.
- Referencias APA con sangría francesa.

## Datos por completar

En la carátula: apellidos y nombres del estudiante y código universitario.
