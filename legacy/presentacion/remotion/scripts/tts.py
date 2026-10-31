# -*- coding: utf-8 -*-
"""Genera un MP3 por diapositiva con Edge TTS y calcula la duración real."""
import asyncio
import json
import subprocess
import sys
from pathlib import Path

import edge_tts

ROOT = Path(__file__).resolve().parent.parent
GUION = ROOT.parent / "guion" / "guion.json"
AUDIO = ROOT / "public" / "audio"
AUDIO.mkdir(parents=True, exist_ok=True)

RATE = "+5%"
GAP_SECONDS = 0.65

# La voz neural interpreta mejor los números y las versiones si se escriben
# con palabras. El texto visible del guion no cambia.
SPEECH_REPLACEMENTS = [
    ("PHP2Shell", "PHP dos Shell"),
    ("CVE-2026-109618", "CVE dos mil veintiséis, diez noventa y seis, dieciocho"),
    ("CVE-2026-109619", "CVE dos mil veintiséis, diez noventa y seis, diecinueve"),
    ("PHP 8.4.26", "PHP ocho punto cuatro punto veintiséis"),
    ("PHP 8.4.27", "PHP ocho punto cuatro punto veintisiete"),
    ("PHP 8.4.0", "PHP ocho punto cuatro punto cero"),
    ("Apache 2.4.49", "Apache dos punto cuatro punto cuarenta y nueve"),
    ("Apache 2.4.51", "Apache dos punto cuatro punto cincuenta y uno"),
    ("WordPress 7.0.1", "WordPress siete punto cero punto uno"),
    ("WordPress 7.0.2", "WordPress siete punto cero punto dos"),
    ("Redis 6.2.6", "Redis seis punto dos punto seis"),
    ("Redis 6.2.7", "Redis seis punto dos punto siete"),
    ("MariaDB 10.11.19", "MariaDB diez punto once punto diecinueve"),
    ("8.4.26", "ocho punto cuatro punto veintiséis"),
    ("8.4.27", "ocho punto cuatro punto veintisiete"),
    ("8.4.0", "ocho punto cuatro punto cero"),
    ("2.4.49", "dos punto cuatro punto cuarenta y nueve"),
    ("2.4.51", "dos punto cuatro punto cincuenta y uno"),
    ("7.0.1", "siete punto cero punto uno"),
    ("7.0.2", "siete punto cero punto dos"),
    ("6.2.6", "seis punto dos punto seis"),
    ("6.2.7", "seis punto dos punto siete"),
    ("10.11.19", "diez punto once punto diecinueve"),
    ("uid=33", "uid treinta y tres"),
    ("uid=0", "uid cero"),
]


def to_speech(text: str) -> str:
    for old, new in SPEECH_REPLACEMENTS:
        text = text.replace(old, new)
    return text


def ffprobe_duration(path: Path) -> float:
    out = subprocess.check_output(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=nw=1:nk=1", str(path)],
        text=True,
    ).strip()
    return float(out)


async def synth(slide: dict, sem: asyncio.Semaphore) -> None:
    n = slide["n"]
    out = AUDIO / f"{n:02d}.mp3"
    speech = to_speech(slide["text"])
    slide["speech"] = speech
    if out.exists() and out.stat().st_size > 1000:
        slide["audio"] = f"audio/{out.name}"
        slide["duration"] = round(ffprobe_duration(out), 3)
        print(f"{n:02d} cached {slide['duration']:.2f}s")
        return
    async with sem:
        for attempt in range(1, 7):
            try:
                tts = edge_tts.Communicate(
                    speech, slide["voice"], rate=RATE, volume="+0%", pitch="+0Hz"
                )
                await tts.save(str(out))
                if out.stat().st_size < 1000:
                    raise RuntimeError("archivo vacío")
                slide["audio"] = f"audio/{out.name}"
                slide["duration"] = round(ffprobe_duration(out), 3)
                print(f"{n:02d} ok {slide['duration']:.2f}s · {slide['voice']}")
                return
            except Exception as exc:
                print(f"{n:02d} intento {attempt} falló: {exc}", file=sys.stderr)
                await asyncio.sleep(2.5 * attempt)
        raise RuntimeError(f"No se pudo generar el audio de la diapositiva {n}")


async def main() -> None:
    slides = json.loads(GUION.read_text(encoding="utf-8"))
    sem = asyncio.Semaphore(1)
    for slide in slides:
        await synth(slide, sem)
        await asyncio.sleep(0.6)

    total = 0.0
    fps = 15
    for s in slides:
        s["gap"] = GAP_SECONDS
        s["durationInFrames"] = int(round((s["duration"] + GAP_SECONDS) * fps))
        total += s["duration"] + GAP_SECONDS

    (ROOT / "src" / "timeline.json").write_text(
        json.dumps(slides, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (ROOT.parent / "guion" / "guion.json").write_text(
        json.dumps(slides, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"TOTAL {total:.1f}s = {total/60:.1f} min · {sum(s['durationInFrames'] for s in slides)} frames")


if __name__ == "__main__":
    asyncio.run(main())
