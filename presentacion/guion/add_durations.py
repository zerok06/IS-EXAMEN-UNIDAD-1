# -*- coding: utf-8 -*-
"""Añade la duración real a cada bloque del guion markdown."""
import json
from pathlib import Path

p = Path(__file__).parent
slides = json.loads((p / "guion.json").read_text(encoding="utf-8"))
durations = {s["n"]: s.get("duration", 0.0) for s in slides}
lines = (p / "guion.md").read_text(encoding="utf-8").splitlines()
out = []
current = None
for line in lines:
    out.append(line)
    if line.startswith("## ") and " · " in line:
        try:
            current = int(line[3:5])
        except ValueError:
            current = None
    if line.startswith("**Voz:**") and current in durations:
        out.append(f"**Duración:** {durations[current]:.1f} s")
(p / "guion.md").write_text("\n".join(out) + "\n", encoding="utf-8")
print("OK")
