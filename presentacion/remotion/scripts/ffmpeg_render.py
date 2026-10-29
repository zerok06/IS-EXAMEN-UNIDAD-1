# -*- coding: utf-8 -*-
"""Render rápido de respaldo: mismo timeline, slides + audio + subtítulos."""
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TIMELINE = json.loads((ROOT / "src" / "timeline.json").read_text(encoding="utf-8"))
SLIDES = ROOT / "public" / "slides"
SEG = ROOT / "out" / "segments"
SEG.mkdir(parents=True, exist_ok=True)
OUT = ROOT / "out" / "PHP2Shell-IS1023.mp4"
FPS = 30

segments = []
for slide in TIMELINE:
    n = slide["n"]
    dur = float(slide["duration"]) + float(slide.get("gap", 0.65))
    out = SEG / f"seg-{n:02d}.mp4"
    if not out.exists() or out.stat().st_size < 1000:
        fade_out = max(0.0, dur - 0.35)
        vf = (
            "scale=1920:1080:flags=lanczos,format=yuv420p,"
            f"fade=t=in:st=0:d=0.35,fade=t=out:st={fade_out:.3f}:d=0.35"
        )
        cmd = [
            "ffmpeg", "-y", "-loop", "1", "-framerate", str(FPS),
            "-i", str(SLIDES / f"slide-{n:02d}.png"),
            "-t", f"{dur:.3f}", "-vf", vf, "-r", str(FPS),
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "20",
            "-pix_fmt", "yuv420p", "-an", str(out),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    segments.append(out)
    print(f"{n:02d}/31 {dur:.2f}s")

concat = SEG / "concat.txt"
concat.write_text(
    "\n".join(f"file '{p.as_posix()}'" for p in segments), encoding="utf-8"
)
joined = ROOT / "out" / "video-sin-audio.mp4"
subprocess.run(
    [
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(concat),
        "-c", "copy", str(joined),
    ],
    check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
)

subprocess.run(
    [
        "ffmpeg", "-y", "-i", str(joined),
        "-i", str(ROOT / "out" / "PHP2Shell-IS1023.mp3"),
        "-i", str(ROOT / "out" / "subtitulos.srt"),
        "-map", "0:v:0", "-map", "1:a:0", "-map", "2:s:0",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
        "-c:s", "mov_text", "-metadata:s:s:0", "language=spa",
        "-metadata", "title=PHP2Shell - IS-1023",
        "-movflags", "+faststart", "-shortest", str(OUT),
    ],
    check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
)
print(f"OK {OUT}")
