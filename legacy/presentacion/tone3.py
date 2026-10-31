# -*- coding: utf-8 -*-
from pathlib import Path
p = Path("build.js")
s = p.read_text(encoding="utf-8")
s = s.replace(
    '["22", "demostrables", "2 no reproducibles · 2 no aplicables"]',
    '["22", "explotadas", "con evidencia verificable"]',
)
s = s.replace(
    's.addNotes("Contexto. Destacar el aislamiento y el alcance autorizado. Los números clave: 6 VM, 24 hallazgos, 22 demostrables.");',
    's.addNotes("Contexto. Destacar el alcance autorizado y la red universitaria. Los números clave: 6 servidores, 24 hallazgos, 22 llevados a evidencia.");',
)
p.write_text(s, encoding="utf-8")
print("ok")
