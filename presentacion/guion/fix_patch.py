# -*- coding: utf-8 -*-
import json
from pathlib import Path
p = Path("guion.json")
slides = json.loads(p.read_text(encoding="utf-8"))
for s in slides:
    if s["n"] == 28:
        s["text"] = "El parcheo se aplicó en cada servidor. Cambiaron versiones y configuraciones: PHP pasó a 8.4.27, WordPress a 7.0.2, Apache a 2.4.51 y Redis a 6.2.7. Apagamos upload_progress, eliminamos el LFI, cerramos el FTP anónimo y deshabilitamos SMBv1. M1 a M4 quedaron cerrados. M5 no se pudo tocar porque 445, 3389 y 5900 quedaron filtrados; se declara pendiente, no remediado."
        s["support"] = "Explicar qué se cambió y el estado de cada servidor; no detallar el acceso usado para aplicar el parche."
        s["transition"] = "El retest confirma qué cambió."
p.write_text(json.dumps(slides, ensure_ascii=False, indent=2), encoding="utf-8")
print("ok")
