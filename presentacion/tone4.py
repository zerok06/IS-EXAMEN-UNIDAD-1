# -*- coding: utf-8 -*-
from pathlib import Path
p = Path("build.js")
s = p.read_text(encoding="utf-8")
s = s.replace(
    'chip(s, "Aislamiento lógico", M + 2.3, 3.95, 1.95, PANEL, NAVY, 10);',
    'chip(s, "Red corporativa", M + 2.3, 3.95, 1.95, PANEL, NAVY, 10);',
)
s = s.replace(
    'chip(s, "Sin Internet", M + 4.45, 3.95, 1.55, PANEL, NAVY, 10);',
    'chip(s, "Servicios activos", M + 4.45, 3.95, 1.85, PANEL, NAVY, 10);',
)
p.write_text(s, encoding="utf-8")
print("ok")
