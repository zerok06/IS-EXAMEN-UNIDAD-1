# Whisper · control de calidad de la narración

- Motor: `faster-whisper` 1.2.1, modelo `small`, CPU, `compute_type=int8`.
- Entrada: los 31 MP3 de `../public/audio/`.
- Salida: `transcripcion-whisper.json` y `transcripcion-whisper.md`.

Whisper es **reconocimiento** de voz, no síntesis. El audio del video se genera
con Edge TTS (voces neuronales en español); Whisper se usa para transcribir y
comprobar que la narración sea inteligible.

La transcripción automática confunde nombres técnicos (`PHP2Shell`, `M1`,
`Chain A`, `www-data`). Por eso los subtítulos del video salen del guion curado
(`../out/subtitulos.srt`), no de esta transcripción. Esta carpeta queda como
evidencia del control de calidad y para buscar alguna frase concreta.
