# -*- coding: utf-8 -*-
from pathlib import Path
p = Path("build.js")
s = p.read_text(encoding="utf-8")
s = s.replace(
    '["C2-C4 · VNC/RDP", "M5 filtrado; sin acceso", "Pendiente"]',
    '["C2-C4 · VNC/RDP", "M5 filtrado; pendiente", "Pendiente"]',
)
p.write_text(s, encoding="utf-8")
print("ok")
