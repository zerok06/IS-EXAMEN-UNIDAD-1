# Video Remotion · PHP2Shell (IS-1023)

Video de **31 diapositivas narradas** con narración en español, caption de idea clave,
barra de progreso y transiciones suaves. Salida principal:

- `out/PHP2Shell-IS1023.mp4` — 1920×1080, 30 fps, H.264 + AAC + subtítulos suaves.
- `out/PHP2Shell-IS1023.mp3` — narración completa con pausas.
- `out/subtitulos.srt` — subtítulos curados (184 entradas).
- `whisper/transcripcion-whisper.json` — transcripción automática de control.

## Estructura

```text
remotion/
  public/slides/       # 31 páginas del PDF exportadas a PNG 1920×1080
  public/audio/        # 31 MP3, uno por diapositiva
  src/timeline.json    # duración, texto, voz, audio y frames
  src/Root.jsx         # composición PHP2ShellVideo
  src/Video.jsx        # slide + caption + progreso + audio
  scripts/tts.py       # Edge TTS + normalización de versiones
  scripts/make_assets.py
  scripts/whisper_transcribe.py
  out/                 # video, audio, SRT, stills
  whisper/             # transcripción ASR
```

## Reproducir o renderizar

```bash
npm install
npm run start      # Remotion Studio
npm run render     # out/PHP2Shell-IS1023.mp4
```

En esta laptop, el render de Remotion con Chrome es lento para 15–16 minutos de
video. Para entregar rápido se incluye el mismo timeline renderizado con
FFmpeg:

```bash
python scripts/ffmpeg_render.py
```

Ese comando usa las 31 imágenes, el audio ya generado y los subtítulos; produce
`out/PHP2Shell-IS1023.mp4` con H.264, AAC y subtítulos suaves. El proyecto
Remotion queda como composición editable y como fuente de la línea de tiempo.

Si el render de Remotion tarda demasiado en esta laptop, existe un render
rápido de respaldo con la misma línea de tiempo, las mismas diapositivas y el
mismo audio:

```bash
python scripts/ffmpeg_render.py
```

Ese comando genera el MP4 final con subtítulos suaves (`mov_text`). El
proyecto Remotion queda como fuente editable y para previsualizar la animación
de caption y progreso.

Para renderizar se usa Chrome instalado en Windows:

```powershell
--browser-executable="C:\Program Files\Google\Chrome\Application\chrome.exe"
```

## Voces

| Persona | Voz Edge TTS |
|---|---|
| Erick | `es-PE-AlexNeural` |
| Doris | `es-PE-CamilaNeural` |
| Rony | `es-BO-MarceloNeural` |
| Fabiola | `es-MX-DaliaNeural` |
| Marco | `es-CO-GonzaloNeural` |
| Jose | `es-AR-TomasNeural` |
| Equipo | `es-MX-JorgeNeural` |

Cada integrante narra sus diapositivas. La voz del equipo se usa en portada,
agenda, reparto, cierre y resúmenes.

## Audio y Whisper

- El audio se genera con **Edge TTS** (voces neuronales en español). Es la
  parte que suena; el texto visible del guion no cambia.
- Antes de sintetizar, `tts.py` convierte versiones y CVE a palabras
  (`8.4.26` → «ocho punto cuatro punto veintiséis») para que la voz no lea
  «8 de abril de 26».
- **Whisper no sintetiza voz.** Se usa `faster-whisper` (modelo `small`, CPU,
  `int8`) para transcribir el audio y validar que la narración sea inteligible.
  La transcripción automática tiene errores lógicos en nombres técnicos
  (`PHP2Shell`, `M1`, `Chain A`); por eso los subtítulos del video se generan
  desde el guion curado, no desde Whisper.

Regenerar audio y assets:

```bash
python scripts/tts.py
python scripts/make_assets.py
python scripts/whisper_transcribe.py
```

`tts.py` requiere Internet para Edge TTS y reutiliza los MP3 existentes. Para
forzar una regeneración, borrar `public/audio/*.mp3` antes de ejecutarlo.

## Guion

El guion detallado está en `../guion/guion.md`; los tiempos reales, en
`../guion/tiempos.md`. Cada entrada tiene narración, apoyo visual y transición.
