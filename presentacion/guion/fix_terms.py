# -*- coding: utf-8 -*-
import json
from pathlib import Path
p = Path("guion.json")
slides = json.loads(p.read_text(encoding="utf-8"))
for s in slides:
    if s["n"] == 17:
        s["support"] = "Recorrer las seis condiciones del servicio: NTS, prefork, display_errors, memory_limit, session.upload_progress y offsets."
        s["transition"] = "Así se presenta el servicio en 8080."
    if s["n"] == 26:
        s["transition"] = "El resto de la red también aporta a la cadena."
    if s["n"] == 27:
        s["title"] = "Resto de la red"
p.write_text(json.dumps(slides, ensure_ascii=False, indent=2), encoding="utf-8")
print("ok")
