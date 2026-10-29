# -*- coding: utf-8 -*-
"""Transcribe la narración con Whisper (faster-whisper) para control de calidad."""
import json
import os
from pathlib import Path

os.environ.setdefault("HF_HUB_DISABLE_SYMLINKS_WARNING", "1")

import av

_orig_open = av.open


def _open(*args, **kwargs):
    kwargs.pop("metadata_errors", None)
    return _orig_open(*args, **kwargs)


av.open = _open

from faster_whisper import WhisperModel  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
TIMELINE = ROOT / "src" / "timeline.json"
AUDIO = ROOT / "public" / "audio"
OUT = ROOT / "whisper"
OUT.mkdir(exist_ok=True)

slides = json.loads(TIMELINE.read_text(encoding="utf-8"))
model = WhisperModel("small", device="cpu", compute_type="int8")

rows = []
for slide in slides:
    path = AUDIO / f"{slide['n']:02d}.mp3"
    segments, info = model.transcribe(
        str(path),
        language="es",
        beam_size=5,
        vad_filter=True,
        condition_on_previous_text=False,
    )
    segs = [
        {
            "start": round(s.start, 3),
            "end": round(s.end, 3),
            "text": s.text.strip(),
        }
        for s in segments
    ]
    text = " ".join(s["text"] for s in segs).strip()
    rows.append(
        {
            "n": slide["n"],
            "title": slide["title"],
            "voice": slide["voice"],
            "duration": slide["duration"],
            "language": info.language,
            "text": text,
            "segments": segs,
        }
    )
    print(f"{slide['n']:02d} {info.language} {slide['duration']:.1f}s · {text[:80]}")

(OUT / "transcripcion-whisper.json").write_text(
    json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8"
)

lines = ["# Transcripción automática con Whisper", ""]
for row in rows:
    lines.append(f"## {row['n']:02d} · {row['title']}")
    lines.append("")
    lines.append(f"**Voz:** {row['voice']} · **Duración:** {row['duration']:.1f}s")
    lines.append("")
    lines.append(row["text"])
    lines.append("")
(OUT / "transcripcion-whisper.md").write_text("\n".join(lines), encoding="utf-8")

print("OK")
