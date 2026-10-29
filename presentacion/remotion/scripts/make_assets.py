# -*- coding: utf-8 -*-
"""Genera subtítulos curados y el audio concatenado a partir del timeline."""
import json
import re
import subprocess
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src" / "timeline.json"
AUDIO = ROOT / "public" / "audio"
OUT = ROOT / "out"
OUT.mkdir(parents=True, exist_ok=True)
GUION = ROOT.parent / "guion"

slides = json.loads(SRC.read_text(encoding="utf-8"))


def fmt(t: float) -> str:
    ms = int(round(t * 1000))
    h, ms = divmod(ms, 3_600_000)
    m, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def chunks(text: str):
    parts = re.split(r"(?<=[.!?])\s+", text.strip())
    out = []
    for part in parts:
        if len(part) <= 150:
            out.append(part)
        else:
            # dividir por comas o por palabras
            sub = re.split(r"(?<=,)\s+", part)
            if len(sub) > 1:
                out.extend(sub)
            else:
                words = part.split()
                buf = []
                for w in words:
                    if len(" ".join(buf + [w])) > 150 and buf:
                        out.append(" ".join(buf))
                        buf = [w]
                    else:
                        buf.append(w)
                if buf:
                    out.append(" ".join(buf))
    return [c for c in out if c.strip()]


srt = []
timeline_rows = []
cursor = 0.0
idx = 1

for slide in slides:
    dur = float(slide["duration"])
    start = cursor
    end = start + dur
    timeline_rows.append(
        (slide["n"], slide["speaker"], slide["voice"], dur, start, end, slide["caption"])
    )

    parts = chunks(slide["text"])
    total_chars = sum(len(p) for p in parts) or 1
    local = 0.0
    for part in parts:
        part_dur = dur * (len(part) / total_chars)
        p_start = start + local
        p_end = p_start + part_dur
        local += part_dur
        body = "\n".join(textwrap.wrap(part, width=78))
        srt.append(f"{idx}\n{fmt(p_start)} --> {fmt(p_end)}\n{body}\n")
        idx += 1

    cursor = end + float(slide.get("gap", 0.65))

(OUT / "subtitulos.srt").write_text("\n".join(srt), encoding="utf-8")

# Tabla de tiempos
lines = [
    "# Tiempos de la narración",
    "",
    "| # | Voz | Inicio | Fin | Duración | Diapositiva |",
    "|---|---|---|---|---|---|",
]
for n, speaker, voice, dur, start, end, caption in timeline_rows:
    lines.append(
        f"| {n:02d} | {speaker} ({voice}) | {fmt(start)} | {fmt(end)} | {dur:.1f}s | {caption} |"
    )
lines.append("")
lines.append(f"**Total:** {cursor/60:.1f} minutos · {cursor:.1f} segundos")
(GUION / "tiempos.md").write_text("\n".join(lines), encoding="utf-8")

# Audio concatenado con silencios
silence = OUT / "silencio-065.mp3"
subprocess.run(
    [
        "ffmpeg", "-y", "-f", "lavfi", "-i", "anullsrc=r=24000:cl=mono",
        "-t", "0.65", "-q:a", "9", str(silence),
    ],
    check=True,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)

concat = OUT / "concat.txt"
entries = []
for slide in slides:
    entries.append(f"file '{(AUDIO / f'{slide[chr(110)]:02d}.mp3').as_posix()}'")
    entries.append(f"file '{silence.as_posix()}'")
concat.write_text("\n".join(entries), encoding="utf-8")

subprocess.run(
    [
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(concat),
        "-c:a", "libmp3lame", "-b:a", "128k", str(OUT / "PHP2Shell-IS1023.mp3"),
    ],
    check=True,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)

print(f"OK SRT: {idx-1} entradas · audio {cursor/60:.1f} min")
