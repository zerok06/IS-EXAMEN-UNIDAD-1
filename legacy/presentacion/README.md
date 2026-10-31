# Presentación · PHP2Shell (IS-1023)

Deck de **31 diapositivas** para exponer y replicar en vivo la cadena completa:
PHP2Shell → `www-data` → B3/SSH/sudo → root. Fondo blanco, azul marino y cian.

## Archivos

- `PHP2Shell-IS1023.pptx` — presentación final (31 diapositivas, con notas).
- `PHP2Shell-IS1023.pdf` — vista previa de 31 páginas.
- `build.js` — generador con `pptxgenjs`.
- `guion/guion.md` — guion detallado por diapositiva (narración, apoyo visual y transición).
- `guion/Guion-PHP2Shell.pdf` — guion maquetado para leer o imprimir.
- `guion/Guion-PHP2Shell.docx` — guion editable.
- `guion/guion.json` — guion + voz + audio + duración real por diapositiva.
- `guion/tiempos.md` — tabla de tiempos y voces.
- `remotion/` — proyecto Remotion que convierte el deck en video.
- `PHP2Shell-IS1023.mp4` — video final listo para exponer (16:06, 1920×1080).
- `PHP2Shell-IS1023.mp3` — narración completa.
- `subtitulos.srt` — subtítulos para reproductores.
- `remotion/out/PHP2Shell-IS1023.mp4` — copia del video dentro del proyecto Remotion.
- `remotion/whisper/transcripcion-whisper.json` — transcripción automática con Whisper.

## Recorrido

| # | Diapositiva | Responsable |
|---|---|---|
| 1 | Portada | Equipo completo |
| 2 | Recorrido | Equipo completo |
| 3 | Contexto: qué quisimos montar | M1 · Erick |
| 4 | Arquitectura y camino de ataque | M1 · Erick |
| 5 | Activos: qué expone cada máquina | M1 · Erick |
| 6 | M1 · Aplicación | M1 · Erick |
| 7 | M2 · Base de datos | M2 · Doris |
| 8 | M3 · Respaldos | M3 · Rony |
| 9 | M4 · Windows Server | M4 · Fabiola |
| 10 | M5 · Cliente | M5 · Marco |
| 11 | M6 · Auditoría | M6 · Jose |
| 12 | Reparto de PHP2Shell | Equipo completo |
| 13 | Metodología y version gate | M1 · Erick |
| 14 | Qué es PHP2Shell y por qué importa | M1 · Erick |
| 15 | W2 · Ficha (CVSS/EPSS/CVE) | M1 · Erick |
| 16 | W2 · Version gate | M1 · Erick |
| 17 | W2 · Precondiciones | M2 · Doris |
| 18 | W2 · Rebuild | M2 · Doris |
| 19 | W2 · Configuración y offsets | M3 · Rony |
| 20 | W2 · Chain A | M4 · Fabiola |
| 21 | W2 · Comandos | M5 · Marco |
| 22 | W3 · Apache 2.4.49 | M1 · Erick |
| 23 | B3 · FTP anónimo | M3 · Rony |
| 24 | W2 · Evidencia | M6 · Jose |
| 25 | W2 · Impacto | M6 · Jose |
| 26 | Cadena completa a root | M1 Erick · M3 Rony · M6 Jose |
| 27 | Resto del laboratorio | M2 Doris · M3 Rony · M4 Fabiola · M5 Marco |
| 28 | Remediación | Equipo completo |
| 29 | Retest | Equipo completo |
| 30 | Lecciones | Equipo completo |
| 31 | Cierre y réplica | Equipo completo |

## Comandos y mitigación

Las slides 6–11 incluyen **2 comandos de exploración** por máquina, con salida y explicación. Las slides 28–29 incluyen la tabla de cambios por máquina y los comandos de verificación del retest.

## Recompilar el deck

```bash
npm install pptxgenjs
node build.js
```

## Video y audio

Ver `remotion/README.md`. Resumen:

```bash
cd remotion
npm install
npm run start       # vista previa en Remotion Studio
npm run render      # genera out/PHP2Shell-IS1023.mp4
```

La narración usa voces neuronales en español: Erick (`es-PE-AlexNeural`),
Doris (`es-PE-CamilaNeural`), Rony (`es-BO-MarceloNeural`), Fabiola
(`es-MX-DaliaNeural`), Marco (`es-CO-GonzaloNeural`), Jose
(`es-AR-TomasNeural`) y la voz del equipo (`es-MX-JorgeNeural`). Whisper se
usa para transcribir y validar el audio; no sintetiza voz.
