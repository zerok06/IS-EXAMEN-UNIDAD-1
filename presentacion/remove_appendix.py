# -*- coding: utf-8 -*-
"""Quita el anexo de comandos: los comandos se integran en las slides de máquina."""
from pathlib import Path

p = Path("build.js")
s = p.read_text(encoding="utf-8")
a = s.index("// ANEXO · COMANDOS DE RÉPLICA")
start = s.rindex("// =", 0, a)
marker = "// ---------- Guardar ----------"
end = s.index(marker)
s = s[:start] + s[end:]
p.write_text(s, encoding="utf-8")
print("OK sin anexo")
